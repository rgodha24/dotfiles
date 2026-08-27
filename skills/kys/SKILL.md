---
name: kys
description: "Kill Your Session: spin down everything this session started (background dev servers, http servers, headless browsers, seeded test state), then close the current herdr pane, terminating the agent. Use only when the user explicitly invokes /kys or tells the agent to shut itself down."
disable-model-invocation: true
---

# kys — kill your session

Wind the session down completely, then close the pane this agent lives in. Closing the pane kills the agent process, so it is the very last action — after every cleanup is done and reported.

## 1. Stop what this session started

- Stop background tasks started this session: dev servers, file watchers, http servers, tunnels.
- If this session made a **tesser** box (e.g. via the wt skill), `tesser rm <box_id>` it — the box is throwaway per-worktree compute, and the local worktree/commits are unaffected. `tesser ls` finds a box whose id was lost.
- Close headless browsers or drivers spawned for screenshots/tests.
- Verify nothing is left: check the ports and process names this session used (`pgrep -af`, `curl` the ports). Kill only processes this session started — never ones the user runs themselves; check the command line and port before killing anything.

## 2. Undo temporary external state

If the session created throwaway state purely for its own verification — seeded test users, database rows, preview deploys — delete it now.

Leave real work products alone: code changes, worktrees, commits, screenshots, artifacts. If in a worktree session, make sure everything is committed on your branch.
then, delete your worktree directory entirely. also if you created a herdr worktree/session, delete the whole session (not just your pane!)

## 3. Report, then close the pane

Send one short final message: what was stopped, what was cleaned up, where kept work lives. Then confirm herdr and close:

```bash
test "${HERDR_ENV:-}" = 1 && test -n "${HERDR_PANE_ID:-}"
herdr pane close "$HERDR_PANE_ID"
```

Nothing runs after the close — do not plan any output past it. If not inside herdr (check fails), say so and stop after the cleanup steps instead of closing anything.
