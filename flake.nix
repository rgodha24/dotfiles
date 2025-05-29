{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    pkgsunstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    nixpkgs,
    pkgsunstable,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        unstable = import pkgsunstable {
          inherit system;
          config.allowUnfree = true;
        };
        macPackages =
          if system == "aarch64-darwin"
          then
            with pkgs; [
              pinentry_mac
            ]
          else [];
      in {
        default = pkgs.buildEnv {
          name = "home-packages";
          paths = with pkgs;
            [
              # general tools
              ripgrep
              eza
              lazygit
              gh
              bat
              zoxide
              jq
              gnupg
              fzf
              ffmpeg-full
              yt-dlp
              gimp
              gnuplot
              gimp
              htop
              unzip

              cachix
              typst
              typstyle
              typst-live
              taplo
              just
              delta
              aoc-cli
              unstable.devenv

              # pulumi stuff
              pulumictl
              pulumiPackages.pulumi-nodejs
              pulumiPackages.pulumi-python
              pulumiPackages.pulumi-go

              # terminal + editing
              starship
              fish
              neovim

              # formatters + lsps + editor plugins
              unstable.prettierd
              stylua
              alejandra # for nix
              unstable.tailwindcss-language-server
              pyright
              kotlin-language-server
              ktlint
              djlint
              unstable.tinymist
              luajitPackages.tiktoken_core
              lynx

              # language tools
              zulu17
              jdt-language-server
              go
              gopls
              typescript
              nodejs_20
              rustup
              cargo-lambda
              zig_0_12
              postgresql_17_jit

              # js tooling
              corepack
              unstable.bun
              fnm

              # python
              unstable.uv
              ruff
              python310Full
            ]
            ++ macPackages;
        };
      }
    );
  };
}
