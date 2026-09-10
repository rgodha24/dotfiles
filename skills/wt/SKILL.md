---
name: wt
description: "Spin up an isolated dev environment for a task: create a git worktree through Herdr, move this agent into the new workspace, and run the project on a tesser box. Use when the user asks for a new worktree, /wt, or to start work in a fresh worktree. Requires HERDR_ENV=1 and the tesser CLI."
---

# wt — new worktree

First, invoke the **herdr** and **tesser** skills — they own all command
semantics. This skill is only the glue:

1. `herdr worktree create --cwd "$(git rev-parse --show-toplevel)" --branch <kebab-case-branch> --no-focus --json`.
   This opens a whole new workspace. Take `result.workspace.workspace_id` and
   `result.worktree.path` from the response.

2. Move this agent in and follow with focus:
   `herdr pane move "$HERDR_PANE_ID" --new-tab --workspace <workspace_id> --label agent --focus`.
   Afterwards `$HERDR_PANE_ID` is stale (new id is in the move response) and
   your cwd is unchanged — treat the worktree path as the project root from
   now on; never edit the original checkout.

3. If the checkout has `.claude/skills/tesser/` and the new worktree does not,
   copy it in before any tesser command: mint and server git-exclude it, so a
   fresh worktree has no manifests and `tesser dev` fails with
   `no manifest for service`.

4. Run the tesser canonical workflow, with every tesser command cwd'd into
   the worktree — `(cd "$WT" && tesser ...)` — since it syncs the _current_
   worktree. Detect install/dev commands from the repo instead of assuming
   pnpm.

5. Report branch, worktree path, workspace id, box id, and the address
   `tesser dev` printed — `http://<box_id>.localhost:<port>` — which stays on
   that box when focus moves. Work per the tesser skill from then on.

Teardown is the **kys** skill. One caveat when it runs after this: the pane
move made `$HERDR_PANE_ID` stale, so close the pane id you parsed from the
move response instead.

ur branch name should be `rohan/<name>` if no linear ticket, or if there is a linear ticket it should match the linear ticket's suggested branch name

it should be based off of `origin/main` in basically ~every case unless you are like explicitly stacking on top of an existing change. you should check unmerged commits on your branch and make sure they are as you expect.

install deps as normal eg with `pnpm i` or `yarn`. assume the package managers handle the symlinks
