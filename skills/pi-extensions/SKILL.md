---
name: pi-extensions
description: "Manage pi coding-agent config, extensions, and skills on this machine. Use for: adding/editing/removing pi extensions in the dotfiles, understanding how pi settings/keybindings/extensions are declared via Home Manager, debugging extension load issues, or porting an extension from another pi setup (e.g. davis7dotsh/my-pi-setup). Trigger on: 'pi extension', 'pi setup', 'add this to pi', 'my pi config', 'port this subagents extension'."
---

# pi-extensions

pi is installed via [github:lukasl-dev/pi.nix](https://github.com/lukasl-dev/pi.nix) and its config is managed declaratively in this dotfiles repo. This skill covers how to add/change/remove extensions and config.

## Where things live

```
dotfiles/pi/
  extensions/         # every .ts file here is loaded by pi        <- THIS is where extensions go
  keybindings.json
dotfiles/home/common.nix     # the programs.pi.coding-agent block + the extensions/ symlink
dotfiles/flake.nix           # the `pi` flake input
```

At activation, HM symlinks `~/.pi/agent/extensions` -> `dotfiles/pi/extensions` (read-only, into the nix store) and writes `~/.pi/agent/keybindings.json`. `settings.json` stays *mutable* — the pi.nix HM module jq-merges `programs.pi.coding-agent.settings` into it at launch, so runtime fields like `packages` and the changelog version persist.

## What this means in practice

- **Never edit `~/.pi/agent/extensions/*` directly** — that dir is a read-only symlink. Edit files under `dotfiles/pi/extensions/` and rebuild.
- **`herdr-agent-state.ts` is vendored, not hand-maintained.** It is owned by `herdr integration install pi`. To update it: run `herdr integration install pi`, then `cp ~/.pi/agent/extensions/herdr-agent-state.ts dotfiles/pi/extensions/`. (But when extensions/ is the HM symlink, the cp destination *is* the dotfiles file — see the update recipe below.)
- **Packages** (e.g. `npm:pi-cursor-sdk`) go in the `packages` array of `settings.json` at runtime via `pi install npm:foo`, OR declaratively by adding to `dotfiles/home/common.nix`'s `programs.pi.coding-agent.settings`. Prefer the nix route; it survives reinstalls.
- **Do NOT manage** `settings.json`, `auth.json`, `models-store.json`, `sessions/`, `npm/`, `favorite-models.json` via HM — these are runtime-owned by pi.

## Adding an extension (a single .ts file)

1. Drop the file at `dotfiles/pi/extensions/<name>.ts`. Most pi extensions are single-file and have **zero npm deps** (they import only `@earendil-works/pi-coding-agent` types and node builtins, both provided by pi at runtime).
2. `git -C dotfiles add pi/extensions/<name>.ts` — nix flakes require files to be git-tracked.
3. Rebuild: tell the user to run `sudo nixos-rebuild switch --flake .#nixos` (Linux) or `home-manager switch --flake .#mac` (Darwin). Do NOT run it yourself — it bugs out the CLI.
4. Restart pi / `/reload`.

## Adding an extension with npm dependencies

If the extension `import`s a real runtime npm package (not just type imports or pi internals):

- pi installs `packages` from `settings.json` into `~/.pi/agent/npm/` automatically on startup. Add the npm package to the `packages` array (`pi install npm:<pkg>` persists it to settings.json; or add it under `programs.pi.coding-agent.settings.packages` in `home/common.nix`).
- Real-world example: davis7dotsh's `subagents` extension needs `@anthropic-ai/claude-agent-sdk`, `effect`, and `typebox` — these would each be added as packages, and his whole repo has a root `package.json` + `npm install`. Porting such an extension means either vendoring its deps via `packages`, or running `npm install` in `~/.pi/agent`.
- Multi-file extensions (a directory with `package.json` + `src/`) are NOT supported by the single-file `extensions/` symlink approach as-is — they need a different layout (a `home.file."~/.pi/agent/extensions/<name>"` subtree, handled separately). Flag this to the user before attempting.

## Porting an extension from another pi setup

When the user points at a repo (e.g. `https://github.com/davis7dotsh/my-pi-setup`) and asks to port something:

1. Read it via ghfs at `/mnt/github/<owner>/<repo>/...` to understand dependencies first.
2. Check each candidate file's `import`s:
   - only `@earendil-works/pi-coding-agent` + node builtins → drop straight into `dotfiles/pi/extensions/`.
   - real npm deps → see "Adding an extension with npm dependencies" above, and warn the user about the multi-file case.
3. Copy, do not symlink, unless the whole external repo is the source of truth (vendoring a snapshot vs tracking upstream — confirm with the user).

## Updating the vendored herdr shim

```
herdr integration install pi
cp ~/.pi/agent/extensions/herdr-agent-state.ts dotfiles/pi/extensions/herdr-agent-state.ts
git -C dotfiles add pi/extensions/herdr-agent-state.ts
# then rebuild (tell user)
```
(When the HM symlink is active, `~/.pi/agent/extensions` already points at the dotfiles copy, so the `cp` is a no-op after the first vendoring — but keep the recipe for re-snapshotting after a `herdr integration install` that may have written to a real file before HM takes over.)

## nix specifics

- flake input: `pi.url = "github:lukasl-dev/pi.nix"` (follows `pkgsunstable`).
- HM module: `pi.homeModules.default`, imported in `home/common.nix`.
- options used: `programs.pi.coding-agent.{ enable, settings }`. Other available options: `rules`, `extensions`, `skills`, `themes`, `promptTemplates`, `models`, `extraArgs`, `environment`, `jail.enable`, `package`.
- binary cache keys for `pi.cachix.org` and `nix-community.cachix.org` are in `configuration.nix` `nix.settings.trusted-public-keys` (Linux only — darwin builds from source otherwise).
- replacing a bun-global pi install: after the first successful rebuild, remove the bun global with `bun remove -g @earendil-works/pi-coding-agent` so `~/.bun/bin/pi` no longer shadows the nix one on PATH.