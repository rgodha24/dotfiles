---
name: tesser
description: Run dev servers, tests, and heavy commands on persistent cloud boxes while the code stays local. Use when the user wants a dev server (Next.js etc.) running remotely with localhost:3000 as the window into it, several worktrees running at once, or a box to run tests and builds on.
---

# tesser

The code stays on the laptop; the compute is a cloud box. tesser mirrors the
current git worktree to a box's `~/workspace` and runs commands there. The
human sees a box through a local proxy run by `tesser daemon`: every box has
its own address, `http://<box_id>.localhost:<port>` for each port the
service declares, and bare `http://localhost:<port>` shows whichever box with
that port the human focused last from the panel injected into every page (or
`tesser use <box_id>`). Selection includes the box’s full dependency graph;
ports outside that graph keep their previous selection.
If a box address refuses connections, ask the human to start `tesser daemon`.

Each worktree gets its own boxes: a **workbench** for `exec` (tests,
typechecks, builds) and one **instance box** per service for `dev`. Boxes
persist until `rm`; a box you made an hour ago still has its node_modules.
A brand-new box warms its package stores (pnpm/npm/yarn classic+berry/bun/
cargo/go/uv) from awake org boxes automatically; the first `dev`/`exec` on it
waits for that copy and prints the result, so a first install is usually
fast — nothing to do on your side.
Idle boxes sleep (workbench after 10 minutes, instance box after 2 hours); a
box asleep for 16 hours is removed. Any command that targets a sleeping box
wakes it (about a minute). `tesser ls` finds a box whose id you lost.

Boxes run Ubuntu 24.04 with Node 22, rsync, and Docker (compose included)
baked into the image. The `ubuntu` user has passwordless sudo and is in the
docker group, so `sudo apt-get install`, `docker compose up`, and the repo's
existing container setup all just work. Anything else: check with
`tesser exec -- which pnpm` and install it with `exec`.

## Setup (once per laptop)

```sh
curl -fsSL https://tesser.sh/install | sh   # binary in ~/.tesser/bin
tesser login                                 # browser: sign in or sign up, pick or create an org
tesser daemon                                # keep running: the localhost proxy
```

If something else already holds port 3000, `tesser daemon --port 3300`
moves the viewport there (`dev` then says which port to open).

Every command runs in one org; `login` makes the org it authorized the
default. `tesser org ls` lists the orgs this laptop is logged in to,
`tesser org use <id>` switches, `TESSER_ORG=<id>` overrides for one shell.
`tesser whoami` shows the signed-in email and org. To join a teammate's org,
an owner runs `tesser member add <email>`, which emails them; the next
`tesser login` offers it.

## Commands

Contracts: commands that create or select print the `box_…` id as their ONLY
stdout (progress goes to stderr). `exec` and `logs` pass the remote exit code
through. Read commands take `--json`. `rm` never confirms.

- `tesser make [service] [--size small|standard|large|xlarge]` — new box. No
  service: a workbench. With a service (a manifest name): an instance box.
  `--size` picks RAM/CPU (standard = 2 vCPU/8 GB; each step doubles); the
  service manifest may set a default `size`. Claims a prewarmed pool box in
  seconds when one exists (standard size only), else cold-boots (about 90s).
  Prints the box id.
- `tesser exec [box_id] [--in <service>] [--deps-of <service>] -- <cmd…>` —
  sync the worktree, run the command in `~/workspace`, stream output, exit
  with its code. No box id: the worktree's workbench (created on first use).
  `--in` runs in that service's root; `--deps-of` wires that service's dep
  ports for the run. Use it for setup: `tesser exec -- pnpm install`.
- `tesser dev <service>` — box for (worktree, service), sync, run the
  manifest's `setup` then `dev` recipe under the box supervisor, wait until
  its primary port listens, register it with the proxy. Prints the box id.
  If setup or the server exits before the port listens, it prints the log
  tail and exits 1 (`--detach` skips the wait). Re-running replaces the
  server; that is also how to recover a crash.
  `tesser dev <box_id> -- <cmd…>` runs an explicit command instead of the
  recipe (it must listen on box port 3000 when there is no manifest).
  Deps are not started by `dev`: each resolves to a wire on this box or the
  org default, so a dep with neither needs `tesser make <dep> --ensure-running <sha>`.
- `tesser sync <box_id> [--restart]` — push local edits without running
  anything; the dev server's HMR picks them up. `--restart` then re-runs the
  manifest's `setup` and `dev` recipes (even if nothing changed) for changes
  the server cannot hot-absorb, a new dependency included. `exec` and `dev` sync implicitly.
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
  Current run only: each `dev` starts a fresh log, the previous run is at
  `~/.tesser/dev.log.1` on the box.
- `tesser ls` / `tesser status <box_id>` — boxes, class, service, power,
  presence, instance, IP. Presence is boxd's socket; instance is whether the
  dev server is actually up: `none`, `exited`, or `running on :3000 (healthy)`.
  Trust the instance column, not presence, when deciding whether a service works.
- `tesser top` — the same, live, as a terminal UI with a wiring graph. For
  a person at a terminal, never for an agent: it needs a TTY and never exits
  on its own.
- `tesser usage --json` — the org's meter: credit left, boxes awake, and awake
  time by size and service for the last day, week, and all time. Without
  `--json` in a terminal it is a TUI, for a person, never for an agent.
- `tesser cloud status|connect|disconnect|template` — owners only: run the
  org's boxes in the org's own AWS account. Only when the user asks.
- `tesser cloud aws-profile <name>` — when ssh fails asking for it: the
  org's boxes are reached through AWS Session Manager, and this laptop's
  AWS CLI profile for that account must be named once.
- `tesser use [--off] <box_id>...` — select (or remove) boxes and their
  recursive dependencies on localhost. The latest explicit selection wins
  within its subtree; select the same box again to reapply its whole graph.
  `tesser use` reports destinations and availability; `tesser use --json`
  returns the daemon’s graph and route status. Selection is saved even if
  the daemon cannot verify it; that command fails with an explanation.
  Change selection only when the user asks. Give them the fixed box URL
  printed by `dev`; the panel can select its graph and open localhost.
  Selection changes laptop routes, never remote wiring or running processes.
  Re-running `dev` preserves an existing selection’s priority.
- `tesser sleep <box_id>` — power off now (disk and id persist).
- `tesser ssh <box_id> [-- <cmd…>]` — interactive shell, or one command in
  `~/workspace`, for inspection only (no sync first). For `ssh`, `exec`, and
  `dev` overrides, everything after `--` is exact argv — no shell parses it,
  so `-- "a; b"` looks for a program named `a; b`; use `-- bash -c 'a && b'`.
- `tesser rm <box_id>` — the box is gone for good.
- `tesser service ls` — one line per service: ports, the org's default box
  (`-` when none), and each pin as `state sha power` or `no pins`. Manifests
  in this worktree the org has never seen show as `unregistered`. Run it
  before `dev` when a dep might have no shared instance.
- `tesser service rm <name>` — unregister a service: its pinned shared
  instances are removed with its default, pins, and env. Dev boxes stay.
- `tesser pool fill [N]` / `pool ls` / `pool drain` — prewarm blanks so
  `make` is instant; unclaimed pool boxes self-destruct after an hour.
- `tesser wire <box_id> <service> <target_box_id|--shared>` — point one
  box's dep at a specific box; `--shared` returns it to the org's shared
  instance. Bare `tesser wire <box_id>` shows where every dep points.
  Nothing is ever wired for you: after starting two dev boxes that should
  talk to each other — same worktree or different repos — wire them
  (`tesser wire "$WEB" api "$API"`).

## Manifests

A service is a TOML file at `.claude/skills/tesser/<service>.toml` (the file
name is the service name, org-global):

```toml
ports = [3000]        # several allowed: ports = [5432, 6379]; first = primary

[run]
setup = "pnpm install"
dev   = "pnpm dev"

[deps]
5001 = "backend"      # localhost:5001 on this box reaches backend's primary port
9091 = "search:9090"  # a specific port of a dependency
```

Deps are loopback ports on the box, so the app keeps its `localhost:…`
config. Each dep reaches the box it is wired to (`tesser wire`), else the
org's pinned shared instance (`tesser make <service> --ensure-running <sha>`
pins one; `tesser service ls` shows which services have one), else nothing
and the port fails loud. Starting a second service's
box never rewires anything — connect dev boxes with `tesser wire`.

## Canonical workflow

```sh
tesser exec -- pnpm install             # workbench: setup, tests, typechecks
tesser exec -- pnpm test
BOX=$(tesser dev frontend)              # instance box; tell the user: open http://$BOX.localhost:3000
tesser env push "$BOX"                  # if the app needs .env.local, then re-run dev
# edit locally, then:
tesser sync "$BOX"                      # HMR updates their browser
tesser logs "$BOX" -f                   # when debugging (Ctrl-C detaches)
tesser rm "$BOX"                        # when the worktree is done
```

Without a manifest: `BOX=$(tesser make)`, `tesser exec "$BOX" -- pnpm install`,
`tesser dev "$BOX" -- pnpm dev` (listening on 127.0.0.1:3000).

## Browser-testing a backend change

Deliver a runnable personal dashboard whenever a backend change needs browser
review, even if no dashboard source changed. A backend box alone is not a
complete browser test setup.

1. Start or reuse the changed services with `tesser dev` in their worktrees.
2. Start or reuse a **personal dashboard for this test setup**. In a monorepo,
   run its service from the same worktree. For a separate frontend repo, use
   a dedicated main worktree named for the backend branch/setup. Each
   simultaneous setup needs a different frontend worktree: `dev` reuses by
   worktree and service, so one shared main worktree would reuse one box.
3. Explicitly wire that dashboard to the changed backend, and wire changed
   descendants. Check each box with `tesser wire <box_id>`. If the dashboard
   and server both use hp, wire both to the intended hp instance; choosing a
   box on localhost does not make their remote bindings agree.
4. Leave unchanged dependencies on healthy shared defaults. `ensure-running`
   creates org defaults; it does not create a personal test dashboard.
5. Verify the dashboard through its fixed URL and exercise the changed
   backend path. Check logs/status for all required services, then return
   the dashboard URL and describe the wiring. Do not present only a backend
   URL as a browser-ready result.

A dashboard process’s `localhost:5000` binding belongs to that box. Sharing
one dashboard across B and C cannot give each user different remote wiring.
Personal dashboards B and C can run identical code with different bindings.
Unit tests and builds alone do not require launching a dashboard.

## Wiring topologies

Deps not wired anywhere fall to the org's shared instances, so a
single-service change needs no wiring at all: `tesser dev web` against the
shared `api` just works. Everything else is `tesser wire`:

```sh
# full-stack change (works the same when web and api are different repos —
# run each dev from its own worktree):
API=$(tesser dev api)
WEB=$(tesser dev web)
tesser wire "$WEB" api "$API"

# backend change, viewed through the frontend at main (frontend repo cloned
# but untouched): make a worktree of it at origin/main, dev it, wire it back.
API=$(tesser dev api)                       # in the backend worktree
git -C ../frontend worktree add /tmp/web-backend-B origin/main
WEB=$(cd /tmp/web-backend-B && tesser dev web)
tesser wire "$WEB" api "$API"               # user opens http://$WEB.localhost:3000

tesser wire "$WEB" api --shared             # done: back to the shared api
```

The org's shared instances' deps never point at anyone's dev box; a personal
box for that is cheap (above). Direct `<box_id>.localhost:<port>` calls are
unrestricted in both directions. A wire to a box that is later `rm`'d dangles and
fails loud — re-wire it or return it to `--shared`.

## Warnings

- Declared ports may be bound on `127.0.0.1` or `0.0.0.0` — either works, and
  an all-interfaces bind is not public: other boxes reach declared ports only
  through the box's mesh ingress. Pin the port in the dev server's config so
  a collision fails loudly instead of drifting to the next port and breaking
  routing.
- Never edit files on the box: the next sync overwrites remote changes with
  the local worktree. `ssh` is for looking, not editing.
- The box's repo is a shallow mirror of the worktree's HEAD. `git status`,
  `diff`, and `rev-parse` behave normally; `git log` shows one commit, and
  any commit or branch made on the box is wiped by the next sync after the
  local HEAD moves. Commit locally, always.
- One instance box per (worktree, service), plus a workbench. Syncing worktree B to a box made from worktree A
  replaces its whole workspace; a guard aborts obviously wrong syncs. Do not
  `--force` past it — `make` a new box instead.
- `dev` re-run kills and replaces the running server. `rm` never asks and is
  unrecoverable.
- `dev` waits on the box's own port, never its deps'. Starting a box in parallel
  with the infra it depends on lands it against a service that is not up yet;
  restart it once the dep is listening.
- A wire reaches the dep port immediately, but an app that started while the dep
  had nothing behind it can keep a dead connection — redis clients loop on
  `EPIPE` instead of reconnecting — so restart it after wiring. A manifest edit
  does not hot-register: after adding a dep, re-run `dev` before `wire` will
  accept the new name.
- Every `.toml` in `.claude/skills/tesser/` is read as a service manifest, so an
  unrelated config file there fails `service ls` for the whole worktree.
- The recipe runs as `exec <cmd>`, so a `dev` that starts with a shell builtin
  dies as `exec: set: not found`. Wrap it in a script.
- Serialize `dev`: several at once trip `Subrequest depth limit exceeded` from
  the control plane. Retrying works.
- One command per `ssh` — chained commands often come back empty over SSM.
- `logs` is a tail; read `~/.tesser/dev.log` on the box for anything cumulative.
- A local process already bound to a port wins over the box's door silently, so
  a request meant for the box can land on it instead.

Human install of this skill: `tesser skill install` (writes
`~/.claude/skills/tesser/SKILL.md`; `--project` for the repo's
`.claude/skills/tesser/`).
