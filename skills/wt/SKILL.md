---
name: wt
description: "Create or adopt an isolated task worktree. Use for /wt, fresh worktree requests, and existing T3 Code worktrees."
---

# wt — new worktree

If already inside a T3 Code worktree, use it and skip worktree creation. It is
an acceptable isolation boundary and does not require Herdr.

Otherwise, when `HERDR_ENV=1`, invoke the **herdr** skill for steps 1–2:

1. `herdr worktree create --cwd "$(git rev-parse --show-toplevel)" --branch <kebab-case-branch> --no-focus --json`.
   This opens a whole new workspace. Take `result.workspace.workspace_id` and
   `result.worktree.path` from the response.

2. Move this agent in and follow with focus:
   `herdr pane move "$HERDR_PANE_ID" --new-tab --workspace <workspace_id> --label agent --focus`.
   Afterwards `$HERDR_PANE_ID` is stale (new id is in the move response) and
   your cwd is unchanged — treat the worktree path as the project root from
   now on; never edit the original checkout.

When neither condition applies, create a regular sibling worktree from
`origin/main` with `git worktree add -b <branch> <path> origin/main`, then run
all later commands from that path.

3. Only when the task needs a running app — a browser check, a real backend —
   always use **tesser-cli**, regardless of T3 or Herdr. Follow the repo's
   **devboxes** skill when present (`.claude/skills/devboxes/SKILL.md` in
   server and mint); devboxes are Tesser boxes. Run every tesser command in the
   worktree — `(cd "$WT" && tesser ...)` — since it syncs the _current_
   worktree. Detect install/dev commands from the repo instead of assuming
   pnpm. Use T3's browser to record the fix when useful for a PR.

4. Report branch, worktree path, workspace id if any, box id if any, and the address
   `tesser dev` printed — `http://<box_id>.localhost:<port>` — which stays on
   that box when focus moves. Work per the tesser skill from then on.

Use the **kys** skill for teardown only when this session created the worktree.
Do not remove a T3-owned worktree.

ur branch name should be `rohan/<name>` if no linear ticket, or if there is a linear ticket it should match the linear ticket's suggested branch name

it should be based off of `origin/main` in basically ~every case unless you are like explicitly stacking on top of an existing change. you should check unmerged commits on your branch and make sure they are as you expect.

install deps as normal eg with `pnpm i` or `yarn`. assume the package managers handle the symlinks

## Commit hooks

Installing deps is also what installs the commit hooks, and a worktree with
no hooks means lint/format failures land in CI instead of at commit time. So
after installing, verify they actually run — don't assume the `prepare`
script fired.

- Find what the repo uses: a `prepare`/`postinstall` script in
  `package.json`, a `.husky/` dir, `lefthook.yml`, `.pre-commit-config.yaml`,
  or a committed `.githooks/`.
- Check git is pointed at them and the hook is executable:
  ```sh
  git config core.hooksPath                    # .husky, .githooks, … or empty
  ls -l "$(git rev-parse --git-common-dir)/hooks/pre-commit" 2>/dev/null
  ls -l .husky/pre-commit 2>/dev/null
  ```
  Empty `core.hooksPath` plus no `pre-commit` in either place means nothing is
  wired up.
- If it's missing, run the repo's installer in the worktree: `pnpm prepare`
  (or `npx husky`, `lefthook install`, `pre-commit install`) and re-check.
- Prove it once on the first commit: run it normally and watch the hook
  output. If it didn't run, fix that before writing more code. **Never**
  `--no-verify` to get a commit through.
