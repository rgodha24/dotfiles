---
name: slack-bug
description: "Take a bug reported in Slack from thread to deployed fix: read the thread, repro on a devbox, find the root cause, open a PR, and reply in the thread once it is live in production. Use when handed a Slack link with 'can u repro', 'is this a known issue', 'look into this', or /slack-bug."
---

# slack-bug

Slack thread → repro → root cause → PR → merged → deployed → reply in the thread.

**Nothing goes to Slack until the fix is live in production.** Being merged
isn't enough, and neither is "should be live after the next deploy". Before
the deploy, post nothing at all, not even a heads-up.

**Never message anyone outside the Mintlify Slack.** Only post in internal
Mintlify channels. If the thread is in a Slack Connect / externally shared
channel (customer channels, `ext-*`, anything with people from another org),
or the reporter isn't a Mintlify workspace member, post nothing and hand
Rohan the draft reply instead. Never DM anyone.

## 1. Read the thread

Get `channel_id` and `message_ts` from the URL:
`/archives/C05THN86JDA/p1790284523222229` becomes `C05THN86JDA` and
`1790284523.222229` (put the dot six digits from the end). Read it with
`slack_read_thread`. Read every reply. People often mix up two issues
("that incident was the client site, not the editor"). Pin down exactly what
broke, where, and for whom before you touch code.

## 2. Worktree and box, in parallel with the code trace

- **wt** skill. A T3 worktree is fine as is. Branch `rohan/<slug>` off
  `origin/main`.
- **devboxes** skill in the repo:
  `tesser dev mint-dashboard > /tmp/dash-dev.log 2>&1` in the background.
  The box id appears within a minute; the dev server takes several.
- While the box comes up, start an Explore agent to trace the code path. Ask it
  for file:line refs, the branches that could make the bug "not always"
  happen, and `git log --since=<3 weeks ago>` on those files. Don't read the
  same files yourself.

## 3. Repro in the T3 preview browser

Use the `mcp__t3-code__preview_*` tools on
`http://box-<hex>.localhost:3000` (hyphen, not underscore). Don't run
Playwright on the laptop.

- Log in with the three `fetch` calls from the devboxes skill, run through
  `preview_evaluate` on `/login`.
- `preview_snapshot` output is huge on the editor. Prefer `preview_evaluate`
  that returns a small JSON object.
- Instrument the page in one evaluate. Wrap `window.fetch` to record
  `[method, url, status]` for the requests that matter, and filter out
  socket.io, `_next` and posthog. Wrap `console.error`. **A hard navigation
  wipes it**, so reinstall after every `preview_navigate`. In-app clicks keep
  it.
- Synthetic input: build a `File` on a canvas, put it in a `DataTransfer`, and
  dispatch `new ClipboardEvent('paste', { clipboardData: dt, bubbles: true,
  cancelable: true })`. `dispatchEvent` returning `false` means a handler took
  it.
- Target the right element. The editor has several `.ProseMirror`: the page
  title, the agent chat, and the body. The body is
  `.ProseMirror.prose[contenteditable="true"]`.
- **Always run a control first**, the same action on the path that should
  work. If the control fails, the harness is broken, not the app.
- To tell a stale closure from missing props, walk up from the DOM to the
  nearest `__reactFiber$…` and read `memoizedProps` on the component.
- Build a case matrix: fresh vs existing entity, hard load vs in-app nav,
  private vs site page. "Not always" is usually one row of it.
- Know the devbox-only failures and keep them out of the verdict. For
  example, presigned S3 PUTs to `127.0.0.1:9000` fail on CORS on every page
  (MinIO sits behind the tesser proxy).

Report before fixing: the matrix, the root cause with file:line refs, the
suspected regression commit, and the fix you propose. Then ask whether to fix.

## 4. Fix and check

- Keep it minimal and match the file's existing idioms.
- Sync to the same box with `tesser sync <box>` (no `--restart`) and rerun
  the failing matrix rows. Confirm they flip and the control still passes.
- Run format, typecheck and lint on the workbench through `tesser exec`,
  never locally. A fresh workbench needs `yarn install` first. Nothing syncs
  back, so apply the formatter's diff locally with `git diff` and `git apply`.
- Commit hooks need a local install: `yarn install && npx husky install` in
  the worktree. Never use `--no-verify`.

## 5. PR

- Use the **pr** skill for the title, the clank block and no attribution.
  Link the Slack thread in the clank block, not as `#C…`, since GitHub reads
  that as an issue ref. Put the case matrix in the test plan.
- `tesser share <box>` goes in a review block.
- Record a before/after video with **pr-demo-recording** only when the
  difference is visible on a devbox. If a devbox limit hides it (for example
  uploads that never finish), say so in the test plan and leave the video
  out.
- `link_pull_request` right after creating it.

## 6. Babysit until merge

- Watch CI and the review bots per the pr skill. Poll with the REST API
  (`gh api repos/<o>/<r>/pulls/<n>` and `.../commits/<sha>/check-runs`).
  `gh pr checks` and `gh pr view` use GraphQL and hit the rate limit on long
  polls. macOS has no `timeout`.
- Handle bot findings before auto-merge fires.
- Wait for merge with a background `until` loop that polls every 60s and
  ends on any non-open state.

## 7. Wait for the deploy

Merged is not live. Wait for production to finish before posting. If the PR
closed without merging, tell Rohan and post nothing.

Take the merge sha from `gh api repos/<o>/<r>/pulls/<n> --jq .merge_commit_sha`.
Then poll its commit statuses until the app's production context succeeds:

```sh
gh api "repos/mintlify/mint/commits/$sha/statuses?per_page=100" \
  --jq '.[] | select(.context == "Vercel – dashboard") | .state'
```

- dashboard: `Vercel – dashboard` goes `success` about 2 minutes after merge.
  Vercel ships main to production with no promote step.
- docs client: the `Production – slow-release-main` GitHub deployment for that
  sha (`repos/<o>/<r>/deployments?sha=$sha`).
- server (mintlify/server): check that repo's deploy workflow, and ask
  Rohan if it isn't clear.

## 8. Reply in the thread

Only after step 7 confirms production succeeded for the merge sha, and only
if the channel is internal to the Mintlify workspace (see the rule at the
top). Check the channel before sending: if it's shared with an external org
or has external members, don't send. Give Rohan the draft instead.

Reply **in the thread** with `slack_send_message` and `thread_ts` = the
parent `message_ts`. Never post to the channel top level. Write it in his
voice: lowercase, short, no AI tells, no em dashes. Say what was broken, in
product terms, link the PR, and say it's live now. Post one message, not a
"merged" followed by a "live". Leave out code internals.

Example:

```
found it: pasting/dropping images into a newly created private page silently did nothing (the /image menu still worked). fixed in https://github.com/mintlify/mint/pull/11905, live now so just refresh
```
