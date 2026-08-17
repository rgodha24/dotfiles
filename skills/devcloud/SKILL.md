---
name: devcloud
description: Run dev servers on persistent cloud boxes. Use when the user wants their dev server (Next.js etc.) running remotely with localhost:3000 as their window into it — one box per git worktree.
---

# devcloud

Every git worktree gets its own persistent EC2 box. Your local files are the
source of truth: devcloud rsyncs the worktree to the box's `~/workspace` and
runs commands there. The human views whatever is running through
`http://localhost:3000` (a local proxy), and switches which box it shows via
the widget at `http://localhost:4100` or `devcloud use <box_id>`. The proxy
requires `devcloud daemon` to be running on the laptop — if localhost:3000
refuses connections, ask the human to start it.

Boxes are Ubuntu 24.04 with tmux, Node 22, and pnpm preinstalled. Everything
else you install yourself with `exec` (that is the config system). Boxes
persist until `rm` — a box you made an hour ago still has its node_modules.

## Commands

Contracts: commands that create/select print the `box_...` id as their ONLY
stdout (progress goes to stderr). `exec` and `logs` pass the remote exit code
through verbatim. Read commands take `--json`.

- `devcloud make` — new box; claims a prewarmed one in ~2-5s when available,
  else cold-boots (~60-90s). Prints the box id. Run it from anywhere.
  (Humans prewarm with `devcloud pool fill [N]`; `pool ls`/`pool drain` for
  hygiene. Unclaimed pool boxes self-destruct after 12h.)
- `devcloud ls` — your boxes (`--json` for fields). `devcloud status <box_id>`
  for one box.
- `devcloud exec <box_id> -- <cmd...>` — sync current worktree, then run the
  command in `~/workspace` over ssh, streaming output. Use for setup:
  `devcloud exec box_x -- pnpm install`.
- `devcloud dev <box_id> -- <cmd...>` — sync, then (re)start the dev server
  in a detached tmux session and wait until something listens on box port
  3000. Registers the box with the proxy. Re-running REPLACES the server.
  Dev servers must listen on 127.0.0.1:3000 (only ssh reaches the box).
- `devcloud sync <box_id>` — push local edits without running anything (the
  dev server's HMR picks them up). `exec`/`dev` already sync implicitly.
- `devcloud logs <box_id> [-f]` — dev server output (last 200 lines / follow).
- `devcloud stop <box_id>` — kill the dev server; box keeps running.
- `devcloud use <box_id>` — point localhost:3000 at this box.
- `devcloud ssh <box_id>` — interactive shell, escape hatch only (see below).
- `devcloud rm <box_id>` — terminate the box. Nothing on it survives.
  (EC2 termination is async: `ls` may show the box as running/shutting-down
  for a minute afterwards. That is not a failure.)

## Canonical workflow

```sh
BOX=$(devcloud make)                      # from the worktree you'll work in
devcloud exec "$BOX" -- pnpm install      # env setup, repeat for any tooling
devcloud dev "$BOX" -- pnpm dev           # starts + registers with the proxy
# tell the user: open http://localhost:3000
# ...edit code locally, then:
devcloud sync "$BOX"                      # HMR updates their browser
devcloud logs "$BOX" -f                   # when debugging (Ctrl-C to detach)
devcloud stop "$BOX" && devcloud rm "$BOX"   # when the worktree is done
```

## Warnings

- Never edit files on the box: the next sync OVERWRITES remote changes with
  the local worktree. `ssh` is for inspection (checking versions, poking at
  logs), not editing.
- One box per worktree. Syncing worktree B to a box made from worktree A
  REPLACES its whole workspace (a guard aborts obviously-wrong syncs; do not
  `--force` past it — `make` a new box instead).
- `dev` re-run kills and replaces the running server (same for a re-run after
  a crash — that is the recovery path).
- `stop`/`rm` never ask for confirmation. `rm` is unrecoverable.

Human install: `ln -s $(pwd)/skill/SKILL.md ~/.claude/skills/devcloud/SKILL.md`
(create the directory first) — plus `devcloud daemon` running somewhere.
