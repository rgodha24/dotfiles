# Babysitting CI

CI starts on every push and finishes on its own clock, usually slower than the
review bots. Watch both in the same loop: poll checks, and when one fails,
pull the failing job's log and fix it the same way you'd handle a bot comment.

## Poll

```sh
gh pr checks <n> --watch --interval 30        # blocks until every check settles
gh pr checks <n>                              # one-shot snapshot
gh pr checks <n> --json name,state,link --jq \
  '.[] | select(.state != "SUCCESS" and .state != "SKIPPED") | "\(.state) \(.name) \(.link)"'
```

`--watch` is the right default after a push; give it a ~15 minute ceiling and
fall back to one-shot polling if it hangs. `PENDING`/`IN_PROGRESS` means keep
waiting, `SUCCESS`/`SKIPPED` means done, anything else (`FAILURE`, `ERROR`,
`CANCELLED`, `TIMED_OUT`, `ACTION_REQUIRED`) is yours to triage.

## Read a failure

Get the run for the branch's head, then the failed job's log. Don't dump a
whole run's log into context; go step by step.

```sh
gh run list --branch "$(git branch --show-current)" --limit 5 \
  --json databaseId,workflowName,status,conclusion,headSha

gh run view <run id> --json jobs --jq \
  '.jobs[] | select(.conclusion=="failure")
   | "\(.name)\n" + (.steps[] | select(.conclusion=="failure") | "  step: \(.name)")'

gh run view --job <job id> --log-failed        # only the failing steps
gh run view --job <job id> --log | tail -200   # full log, last lines, if needed
```

`--log-failed` is the one to reach for first. For a long test job, grep it:

```sh
gh run view --job <job id> --log-failed | grep -iE 'error|fail|✕|✗|Expected|Received' | head -60
```

## Triage

Same posture as the review bots: decide what it is before touching code.

- **Real failure caused by this branch** (lint, formatting, a type error, a
  test the diff broke): fix it yourself, push, wait for the next round. No
  size cap here the way there is for bot comments — most of these are style
  checks and take one commit. Don't ask, just fix. The only thing worth
  escalating is a failure whose honest fix would change the approach of the
  PR.
- **Flake** (timeout, network, a known-flaky e2e, a runner dying): re-run it
  once and move on. Don't "fix" a flake by loosening an assertion or adding a
  sleep.
  ```sh
  gh run rerun <run id> --failed
  ```
  If the same job fails twice on the same commit, treat it as real.
- **Pre-existing failure on main**: check whether the job is red on `main` too
  (`gh run list --branch main --workflow "<name>" --limit 5`). If it is, say so
  in the report and leave it; it's not this PR's problem.
- **Required-check config / permissions** (`ACTION_REQUIRED`, a check waiting
  for approval, a missing secret): that's Rohan's, report it, don't retry.

Never skip a check, edit a workflow to make it pass, add `continue-on-error`,
or mark a test `.skip` to get green, unless Rohan asks for exactly that.

A lint or format check failing at all usually means the commit hooks never
ran in this worktree. Fix the failure, then check the hooks are actually
installed (see the `wt` skill) so the next push doesn't repeat it.

## Fixing

Fix CI in its own commit with a real subject (`chore: fix editor e2e tests`,
`fix(editor): type error in draft resolver`), not `fix ci` or `wip`. Where
possible reproduce locally first so the push isn't a guess — run the same
command the failing step ran.

After pushing a CI fix, update the clank block's test plan if what you
verified changed, following the re-read-before-edit rule in SKILL.md.

## Loop with the bots

One loop, two signals:

1. Push. Note the timestamp.
2. Start `gh pr checks <n> --watch` and, in parallel, poll bot comments at
   ~4 minutes (see review-bots.md). Handle whichever lands first.
3. Fix real CI failures and real small bot findings; reply and resolve bot
   threads as they arrive.
4. If anything was pushed, go to 1. Stop when CI is green and a bot round
   adds nothing new, or after 3 rounds.

If CI is still red after 3 rounds, stop and report: which job, the failing
step, the last ~10 lines that matter, and what you think it needs.
