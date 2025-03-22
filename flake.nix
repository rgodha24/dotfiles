{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    pkgsunstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    fenix,
    pkgsunstable,
  }: let
    supportedSystems = ["aarch64-linux" "aarch64-darwin"];
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

              cachix
              typst
              typstyle
              typst-live
              taplo
              just
              delta
              aoc-cli
              mold
              graphite-cli
              unstable.devenv

              # pulumi stuff
              pulumictl
              pulumiPackages.pulumi-language-nodejs
              pulumiPackages.pulumi-language-python
              pulumiPackages.pulumi-language-go

              # terminal + editing
              starship
              kitty
              vscode
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
              (fenix.packages.${system}.fromToolchainFile {
                dir = ./.;
                sha256 = "sha256-AJ6LX/Q/Er9kS15bn9iflkUwcgYqRQxiOIL2ToVAXaU=";
              })
              cargo-lambda

              # js tooling
              corepack
              unstable.bun
              fnm

              # python
              unstable.uv
              ruff
              (python312Full.withPackages (p:
                with p; [
                  numpy
                  psutil
                ]))
            ]
            ++ macPackages;
        };
      }
    );
  };
}
