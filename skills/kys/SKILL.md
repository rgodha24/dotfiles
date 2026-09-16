---
name: kys
description: "Kill Your Session: spin down everything this session started (background dev servers, http servers, headless browsers, seeded test state), then remove the task worktree and its Herdr workspace, terminating the agent. Use only when the user explicitly invokes /kys or tells the agent to shut itself down."
disable-model-invocation: true
---

# kys — kill your session

Wind the session down completely. For a task worktree, remove both the Git checkout and its Herdr workspace. Removing the workspace kills the agent process, so it is the very last action — after every other cleanup is done and reported. Only use pane close when there is no task worktree or dedicated task workspace to remove.

## 1. Stop what this session started

- Stop background tasks started this session: dev servers, file watchers, http servers, tunnels.
- If this session made a **tesser** box (e.g. via the wt skill), `tesser rm <box_id>` it — the box is throwaway per-worktree compute, and the local worktree/commits are unaffected. `tesser ls` finds a box whose id was lost.
- Close headless browsers or drivers spawned for screenshots/tests.
- Verify nothing is left: check the ports and process names this session used (`pgrep -af`, `curl` the ports). Kill only processes this session started — never ones the user runs themselves; check the command line and port before killing anything.

## 2. Undo temporary external state

If the session created throwaway state purely for its own verification — seeded test users, database rows, preview deploys — delete it now.

## 3. Preserve work and identify the teardown target

Use the **herdr** skill for command discovery and live state. Only inspect or control Herdr when `HERDR_ENV=1`.

- Identify the task's worktree path, branch, and workspace ID from this session's create/move responses, then verify them against `herdr workspace list` and `herdr worktree list --workspace <workspace_id>`. Never target the UI-focused workspace or guess an ID.
- After a pane move, injected `$HERDR_PANE_ID` and `$HERDR_WORKSPACE_ID` can be stale. Use the IDs returned by the move and confirmed in live state.
- Preserve code changes in commits on the task branch before removal. Check tracked and untracked files; move wanted screenshots/artifacts outside the checkout or commit them when appropriate. Never commit secrets. Keep the branch: removing a worktree does not delete its commits or branch.
- Remove only the task's linked worktree and dedicated workspace. Never remove the primary checkout or unrelated workspaces. Check for unrelated active work in the target workspace before closing all its panes.
- Do not delete the directory with `rm -rf`: that can leave Git registration and an empty Herdr workspace behind. Do not close the pane first: that terminates the agent before worktree cleanup.

## 4. Report, then remove the worktree and workspace

Report in a short **commentary/progress message** what was stopped, what was
cleaned up, where preserved work lives (repository and branch), and which
worktree/workspace is about to be removed. Do **not** send a final answer yet:
a final answer ends the agent turn, so the teardown command would never run.

For a Herdr task worktree, issue this as the last action, using the verified
workspace ID:

```bash
herdr worktree remove --workspace <workspace_id>
```

This is the normal worktree teardown: remove the Git checkout and its Herdr
workspace together, including the workspace's tabs and panes. `herdr pane close`
or `herdr workspace close` alone does not delete the checkout. Do not use
`--force` to bypass unsaved work; if removal fails, resolve the reported issue
and retry rather than falling back to pane close or claiming cleanup succeeded.

For a dedicated task workspace with no linked worktree, the last action is
`herdr workspace close <workspace_id>`. A workspace is not the entire shared
Herdr server/session: do not stop that server or close unrelated workspaces.

Only when neither a task worktree nor a dedicated task workspace exists, close
the verified current pane as the last action:

```bash
if test "${HERDR_ENV:-}" = 1 && test -n "$task_pane_id"; then
  herdr pane close "$task_pane_id"
fi
```

Set `task_pane_id` to the verified live pane ID first. Do not blindly reuse the
injected ID after a move.

Nothing runs after successful teardown — do not plan output or verification
past it. If not inside Herdr, preserve the work and remove only a confirmed
session-owned linked worktree with `git worktree remove` from outside that
checkout; verify removal with `git worktree list`, report cleanup, and stop.
