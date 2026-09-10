# Stacked PRs

Sources: https://docs.github.com/en/pull-requests/how-tos/stacked-pull-requests,
https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands,
plus the installed `gh stack` (github/gh-stack v0.0.8) `--help`. Public
preview; subject to change. Requires the repo to have stacked PRs enabled
(exit code 9 from `gh stack` means it isn't; fall back to plain `--base`).

## How GitHub treats a stack

- Each PR targets the branch below it; the bottom PR targets `main`.
- Reviewers see a stack map in the merge box; each PR shows only its own
  layer's diff.
- Merge bottom-up. When a PR merges, the ones above stay open and re-target
  the base automatically. Branch protection and required checks apply to
  every PR in the stack.
- All branches must live in the same repo. Not supported in GitHub Desktop.

## Where the stack note goes

The clank block opens with `Stacked on #N.` (multi-PR stacks:
`Stack 2/3, base #N, followed by #M`). That line is AI bookkeeping, so it
never goes in his part. Keep it even when using `gh stack`, since the
Linear/Slack preview won't show the stack map.

## Two ways to stack

### A. Plain git + `--base` (no stack tracking)

```sh
git switch -c rohan/<next-slug> rohan/<parent-slug>
# commit…
git push -u origin HEAD
gh pr create --base rohan/<parent-slug> --title "…" --body-file body.md
```

After the parent merges, GitHub retargets to `main` only if the stack
feature is on; otherwise `gh pr edit <n> --base main` yourself.

### B. `gh stack link` (branches managed with plain git, GitHub knows the stack)

Best fit when the branches already exist. No local tracking state.

```sh
# bottom to top; args may be branch names, PR numbers, or PR URLs
gh stack link rohan/parent rohan/child
gh stack link 8034 8035              # existing PRs by number
gh stack link 7 rohan/third          # 7 = stack number: append to that stack
gh stack link --base develop a b     # non-main trunk
```

Branches get pushed, PRs without one get created (with auto titles — so
create PRs with `gh pr create` first to control the title/body, then link),
bases are chained, and the stack object is created or extended. Existing PRs
are never removed from a stack.

### C. `gh stack` local tracking (starting fresh)

```sh
gh stack init rohan/layer-one               # new stack off default branch
gh stack init feat/auth feat/api feat/ui    # adopt existing branches, bottom→top
gh stack init --base develop rohan/x

gh stack add rohan/layer-two                # new branch on top
gh stack add -Am "feat(editor): …" rohan/layer-two   # stage all + commit + branch

gh stack submit --auto --open               # push + create/update PRs, ready for review (default)
gh stack submit --auto                      # …as drafts, only if he asked for drafts
gh stack view --short
gh stack sync [--prune]                     # fetch, cascade-rebase, force-with-lease push, relink
gh stack rebase [--downstack|--upstack] [--continue|--abort]
gh stack merge [<stack>|<pr>] [--squash|--merge|--rebase] [-y]
gh stack up / down / top / bottom / trunk / switch / checkout <n|pr|url|branch>
gh stack unstack [<n>] [--local]
```

`submit` without `--auto` opens an interactive editor; in a non-interactive
terminal it behaves like `--auto` and uses generated titles. Since titles
must be in Rohan's format, either edit them afterwards with
`gh pr edit <n> --title "…" --body-file …` or prefer route B.

## Exit codes

| code | meaning |
|---|---|
| 0 | ok |
| 2 | not in a stack / stack not found |
| 3 | rebase conflict (run `gh stack rebase`) |
| 4 | GitHub API failure |
| 5 | bad args |
| 6 | disambiguation required |
| 7 | rebase already in progress |
| 8 | stack locked by another process |
| 9 | stacked PRs not enabled for the repo |
| 10 | `modify` interrupted; recovery required |
