---
name: wt
description: "Spin up an isolated dev environment for a task: create a git worktree through Herdr, move this agent into the new workspace, and run the project on a devcloud box. Use when the user asks for a new worktree, /wt, or to start work in a fresh worktree. Requires HERDR_ENV=1 and the devcloud CLI."
---

# wt — new worktree

First, invoke the **herdr** and **devcloud** skills — they own all command
semantics. This skill is only the glue:

1. `herdr worktree create --cwd "$(git rev-parse --show-toplevel)" --branch <kebab-case-branch> --no-focus --json`.
   This opens a whole new workspace. Take `result.workspace.workspace_id` and
   `result.worktree.path` from the response.

2. Move this agent in and follow with focus:
   `herdr pane move "$HERDR_PANE_ID" --new-tab --workspace <workspace_id> --label agent --focus`.
   Afterwards `$HERDR_PANE_ID` is stale (new id is in the move response) and
   your cwd is unchanged — treat the worktree path as the project root from
   now on; never edit the original checkout.

3. Run the devcloud canonical workflow, with every devcloud command cwd'd into
   the worktree — `(cd "$WT" && devcloud ...)` — since it syncs the *current*
   worktree. Detect install/dev commands from the repo instead of assuming
   pnpm.

4. Report branch, worktree path, workspace id, box id, and tell the user to
   open http://localhost:3000. Work per the devcloud skill from then on.

Teardown is the **kys** skill. One caveat when it runs after this: the pane
move made `$HERDR_PANE_ID` stale, so close the pane id you parsed from the
move response instead.
