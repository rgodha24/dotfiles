# T3 Code CLI. The background server itself is managed by upstream's own installer
# (`t3 connect` / `t3 service install`), which writes ~/.config/systemd/user/t3code.service
# and keeps a self-updating copy under ~/.t3/runtime. This module only puts `t3` on PATH.
#
# Useful commands:
#   t3 connect status        # connect + relay state
#   t3 service status        # service health and log path
#   npx t3@latest service update
{
  pkgs,
  unstable,
  system,
  claude-code-nix,
  codex-cli-nix,
  ...
}: let
  # nixpkgs builds t3code without the T3 Connect public config (relay URL, Clerk
  # publishable key, CLI OAuth client id), so `t3 connect` refuses to run. Those are
  # public identifiers shipped in the repo's .env.example; copying it to .env before
  # the build bakes them into the server and web bundles like the official release.
  t3code-unwrapped = unstable.t3code.unwrapped.overrideAttrs (prev: {
    postPatch =
      (prev.postPatch or "")
      + ''
        cp .env.example .env
      '';
  });
  t3code = unstable.t3code.override {
    inherit t3code-unwrapped;
    enableClaude = true;
    claude-code = claude-code-nix.packages.${system}.default;
    enableCodex = true;
    codex = codex-cli-nix.packages.${system}.default;
    enableGit = true;
    enableGitHub = true;
  };
in {
  home.packages = [t3code];
}
