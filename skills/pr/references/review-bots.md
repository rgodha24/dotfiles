# Review bots on mintlify/mint and mintlify/server

Logins that post inline review comments, in the order they usually land:

| bot | login | what it posts |
|---|---|---|
| Devin Review | `devin-ai-integration[bot]` | inline comments with a `<!-- devin-review-comment … -->` header, plus a badge in the body |
| greptile | `greptile-apps[bot]` | inline `P1`/`P2` comments, plus a "Confidence Score" issue comment |
| Cursor Bugbot | `cursor[bot]` | inline `### Title **High/Medium/Low Severity**` comments, plus a `CURSOR_SUMMARY` block in the body |

Noise to ignore: `socket-security[bot]` (dependency diffs), `github-actions[bot]`
(bundle analysis). The Devin badge and Cursor summary that get injected into
the PR body are theirs; leave them alone when editing the body.

Timing: 2 to 5 minutes after every push. Wait about 4 minutes, then fetch;
if a bot hasn't posted a review yet, poll once more a minute later.

## Fetch new inline comments since a push

```sh
SINCE=$(git log -1 --format=%cI)   # or the push timestamp you noted
gh api --paginate repos/{owner}/{repo}/pulls/<n>/comments \
  --jq '.[] | select(.created_at > "'"$SINCE"'")
        | select(.user.login | test("greptile-apps|devin-ai-integration|cursor"))
        | "\(.id) \(.user.login) \(.path):\(.line // .original_line)\n\(.body)\n---"'
```

`{owner}/{repo}` is filled in by gh from the current repo. Bodies carry HTML
badges and hidden JSON; the actual claim is the prose after them.

Review-level state (did each bot post yet):

```sh
gh api repos/{owner}/{repo}/pulls/<n>/reviews \
  --jq '.[] | "\(.user.login) \(.state) \(.submitted_at)"'
```

## Reply in a thread

Reply to the thread's first comment by its database id (the `id` from the
comments listing above). Every reply starts with `clank:` and stays to one
or two lines.

```sh
gh api repos/{owner}/{repo}/pulls/<n>/comments/<comment id>/replies \
  -f body='clank: fixed in abc1234, the fallback now checks `pageIdWhenPage` first'
gh api repos/{owner}/{repo}/pulls/<n>/comments/<comment id>/replies \
  -f body='clank: not reachable, `branch` is narrowed to string by the schema on line 40'
gh api repos/{owner}/{repo}/pulls/<n>/comments/<comment id>/replies \
  -f body='clank: real but ~40 lines to fix properly, asked rohan'
```

## Resolve a thread after replying

Threads are resolved through GraphQL. List unresolved threads with their
first comment's database id, then resolve by thread id:

```sh
gh api graphql -f query='
  query($owner:String!,$repo:String!,$n:Int!){
    repository(owner:$owner,name:$repo){ pullRequest(number:$n){
      reviewThreads(first:100){ nodes{
        id isResolved path
        comments(first:1){ nodes{ databaseId author{login} } } } } } } }' \
  -f owner=mintlify -f repo=<repo> -F n=<n> \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[]
        | select(.isResolved|not)
        | "\(.id) \(.comments.nodes[0].author.login) \(.path) comment=\(.comments.nodes[0].databaseId)"'

gh api graphql -f query='
  mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }' \
  -f id=<thread id>
```

Resolve threads you fixed and threads you judged bogus, right after
replying. Leave open anything you're asking Rohan about, and anything from
a human.

## Order of operations per round

1. Push. Note the timestamp.
2. Wait ~4 minutes, then poll the comments endpoint every minute until all
   three bots have posted a review (or 10 minutes pass).
3. For each new thread, in arrival order: read the code, decide, reply
   with `clank:`, fix if warranted, resolve. Handle a thread as soon as it
   appears; don't wait for the other bots to finish.
4. If anything was fixed, commit, push, and go to 1. Stop when a round
   produced no new actionable threads or after 3 rounds.

## Triage rule of thumb

- Real and about 10 lines or fewer: reply, fix, resolve, push, next round.
- Real but bigger: reply that it's escalated, leave open, ask Rohan with
  the comment, your verdict, and the cost.
- Not real: reply with the one-line reason, resolve.
- Same finding from two bots: fix once, reply and resolve both.
