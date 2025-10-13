# Repository Guidelines

## Project Structure & Module Organization

- `flake.nix` defines the single entry-point for both NixOS (`configuration.nix`, `hardware-configuration.nix`) and Home Manager (`home.nix`). Update modules there so every system build pulls the same revisions.
- Desktop assets live at the top level for easy linking from Home Manager: `waybar.config.json`, `waybar.styles.css`, `hyprland.conf`, `hyprpaper.conf`, `dunstrc`, `ghostty.config`, and `background.jpg`.
- The Neovim profile sits in `nvim/` (`init.lua`, `lua/`, `lazy-lock.json`); keep plugin-specific logic grouped under `nvim/lua/`. Shell and prompt tweaks live beside it (`config.fish`, `starship.toml`, `cryptenv.toml`).

## Build, Test, and Development Commands

- `nix flake check` validates the flake, runs Nix formatter hooks, and catches missing module options early.
- `sudo nixos-rebuild switch --flake .#nixos` applies OS changes locally; use `test` instead of `switch` for a temporary boot.
  - NOTE: you should tell the user to run this. Running this yourself often bugs out the CLI you run in.
- `home-manager switch --flake .#rgodha` syncs the user environment; add `--dry-run` while iterating on dotfiles.

## Coding Style & Naming Conventions

- Format Nix files with `alejandra .` before committing; prefer two-space indentation and trailing commas in attribute sets.
- Use `stylua nvim` for Lua modules and match the NVChad-style tables already present under `nvim/lua/`.
- Keep TOML (`starship.toml`, `cryptenv.toml`) machine-aligned with `taplo fmt`, and run `fish_indent -w config.fish` for shell tweaks.
- Name new modules after their scope (`nvim/lua/plugins/git.lua`, `modules/waybar-theme.nix`) and default to lowercase-hyphenated filenames.

## Testing Guidelines

- Run `nix flake check` plus `home-manager switch --dry-run --flake .#rgodha` for every PR; both should pass without prompting.
- For window-manager updates, launch a nested session (`dbus-run-session hyprland`) and verify Waybar/Dunst without disrupting a daily driver.
- Capture Neovim health with `nvim --headless "+checkhealth" "+qa"` when touching LSP or plugin configs.

## Commit & Pull Request Guidelines

- Follow the existing log: a single, lowercase imperative summary (`fix zen browser`, `update waybar`) capped at ~60 chars.
- Squash noisy work-in-progress commits; sign commits via SSH keys as configured in `home.nix`.
- PRs should describe the scope, list validation commands, and attach UI screenshots for Waybar/Hyprland tweaks. Link related issues or upstream bumps when updating flakes or pinned packages.

## Security & Configuration Tips

- Never commit secrets—store environment credentials with `cryptenv` and reference them via its profiles.
- Keep binary assets (e.g., `background.jpg`) lightweight; prefer symlinks via Home Manager for personal files not meant for source control.
