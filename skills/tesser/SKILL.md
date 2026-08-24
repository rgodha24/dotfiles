---
name: tesser
description: Run dev servers, tests, and heavy commands on persistent cloud boxes while the code stays local. Use when the user wants a dev server (Next.js etc.) running remotely with localhost:3000 as the window into it, several worktrees running at once, or a box to run tests and builds on.
---

# tesser

The code stays on the laptop; the compute is a cloud box. tesser mirrors the
current git worktree to a box's `~/workspace` and runs commands there. The
human sees whatever is running through `http://localhost:3000` (a local
proxy run by `tesser daemon`) and switches which box it shows from the panel
injected into the page, the widget at `http://localhost:4100`, or
`tesser use <box_id>`. If `localhost:3000` refuses connections, ask the human
to start `tesser daemon`.

Each worktree gets its own boxes: a **workbench** for `exec` (tests,
typechecks, builds) and one **instance box** per service for `dev`. Boxes
persist until `rm`; a box you made an hour ago still has its node_modules.
Idle boxes sleep (workbench after 10 minutes, instance box after 2 hours); a
box asleep for 16 hours is removed. Any command that targets a sleeping box
wakes it (about a minute). `tesser ls` finds a box whose id you lost.

Boxes run Ubuntu 24.04 with Node 22 and rsync installed at boot. Nothing else
is promised: check with `tesser exec -- which pnpm` and install what you need
with `exec`. The `ubuntu` user has no sudo, so install user-level.

## Setup (once per laptop)

```sh
curl -fsSL https://tesser.sh/install | sh   # binary in ~/.tesser/bin
tesser login                                 # browser: sign in or sign up, pick or create an org
tesser daemon                                # keep running: localhost:3000 + :4100
```

If something else already holds port 3000, `tesser daemon --port 3300`
moves the viewport there (`dev` then says which port to open).

Every command runs in one org; `login` makes the org it authorized the
default. `tesser org ls` lists the orgs this laptop is logged in to,
`tesser org use <id>` switches, `TESSER_ORG=<id>` overrides for one shell.
`tesser whoami` shows the signed-in email and org. To join a teammate's org,
an owner runs `tesser member add <email>`; the next `tesser login` offers it.

## Commands

Contracts: commands that create or select print the `box_…` id as their ONLY
stdout (progress goes to stderr). `exec` and `logs` pass the remote exit code
through. Read commands take `--json`. `stop` and `rm` never confirm.

- `tesser make [service]` — new box. No service: a workbench. With a service
  (a manifest name): an instance box. Claims a prewarmed pool box in seconds
  when one exists, else cold-boots (about 90s). Prints the box id.
- `tesser exec [box_id] [--in <service>] [--deps-of <service>] -- <cmd…>` —
  sync the worktree, run the command in `~/workspace`, stream output, exit
  with its code. No box id: the worktree's workbench (created on first use).
  `--in` runs in that service's root; `--deps-of` wires that service's dep
  ports for the run. Use it for setup: `tesser exec -- pnpm install`.
- `tesser dev <service>` — box for (worktree, service), sync, `setup` if
  needed, start the manifest's `dev` recipe under the box supervisor, wait
  until its port listens, register it with the proxy. Prints the box id.
  Re-running replaces the server; that is also how to recover a crash.
  `tesser dev <box_id> -- <cmd…>` runs an explicit command instead of the
  recipe (it must listen on box port 3000 when there is no manifest).
- `tesser sync <box_id> [--restart]` — push local edits without running
  anything; the dev server's HMR picks them up. `--restart` then re-runs the
  manifest's dev recipe (even if nothing changed) for changes the server
  cannot hot-absorb. `exec` and `dev` sync implicitly.
- `tesser env push <box_id> [file…]` — send gitignored env files (default:
  every `.env*` at the worktree root that git ignores). `sync` respects
  .gitignore, so `.env.local` never arrives on its own unless the manifest
  lists it under `[env] files = [".env.local"]` (then every sync ships it); a
  dev server dying on a missing env var is usually this. After a push or an
  edit, `tesser sync <box_id> --restart`.
- `tesser env set <service> KEY=VALUE…` / `env unset <service> KEY…` /
  `env ls <service>` — values the control plane injects into that service's
  pinned instances.
- `tesser logs <box_id> [-f]` — dev server output (last 200 lines / follow).
- `tesser stop <box_id>` — stop the dev server and deregister the box from
  the proxy; the box stays awake.
- `tesser ls` / `tesser status <box_id>` — boxes, class, service, power,
  presence, public IP.
- `tesser use <box_id>` — point localhost:3000 at this box. Only when the
  user asks; they usually switch themselves.
- `tesser sleep <box_id>` — power off now (disk and id persist).
- `tesser ssh <box_id> [-- <cmd…>]` — interactive shell, or one command in
  `~/workspace`, for inspection only (no sync first).
- `tesser rm <box_id>` — the box is gone for good.
- `tesser pool fill [N]` / `pool ls` / `pool drain` — prewarm blanks so
  `make` is instant; unclaimed pool boxes self-destruct after an hour.
- `tesser override <box_id> <service> <target_box_id|--clear>` — point one
  box's dep at a specific box. `--clear` goes back to what auto-wiring would
  pick: the worktree sibling serving that service, else the org default.

## Manifests

A service is a TOML file at `.claude/skills/tesser/<service>.toml` (the file
name is the service name, org-global):

```toml
ports = [3000]

[run]
setup = "pnpm install"
dev   = "pnpm dev"

[deps]
5001 = "backend"      # localhost:5001 on this box reaches backend
```

Deps are loopback ports on the box, so the app keeps its `localhost:…`
config. `tesser dev <service>` wires a worktree's sibling services to each
other and everything else to the org's pinned instances
(`tesser make <service> --ensure-running <sha>` pins one).

## Canonical workflow

```sh
tesser exec -- pnpm install             # workbench: setup, tests, typechecks
tesser exec -- pnpm test
BOX=$(tesser dev frontend)              # instance box; tell the user: open http://localhost:3000
tesser env push "$BOX"                  # if the app needs .env.local, then re-run dev
# edit locally, then:
tesser sync "$BOX"                      # HMR updates their browser
tesser logs "$BOX" -f                   # when debugging (Ctrl-C detaches)
tesser rm "$BOX"                        # when the worktree is done
```

Without a manifest: `BOX=$(tesser make)`, `tesser exec "$BOX" -- pnpm install`,
`tesser dev "$BOX" -- pnpm dev` (listening on 127.0.0.1:3000).

## Warnings

- Never edit files on the box: the next sync overwrites remote changes with
  the local worktree. `ssh` is for looking, not editing.
- The box's repo is a shallow mirror of the worktree's HEAD. `git status`,
  `diff`, and `rev-parse` behave normally; `git log` shows one commit, and
  any commit or branch made on the box is wiped by the next sync after the
  local HEAD moves. Commit locally, always.
- One box per worktree. Syncing worktree B to a box made from worktree A
  replaces its whole workspace; a guard aborts obviously wrong syncs. Do not
  `--force` past it — `make` a new box instead.
- `dev` re-run kills and replaces the running server. `stop` and `rm` never
  ask; `rm` is unrecoverable.

Human install of this skill: `tesser skill install` (writes
`~/.claude/skills/tesser/SKILL.md`; `--project` for the repo's
`.claude/skills/tesser/`).
