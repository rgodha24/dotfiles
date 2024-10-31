{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    fenix,
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
        macPackages =
          if system == "aarch64-darwin"
          then
            with pkgs; [
              pinentry_mac
              xquartz
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
              ffmpeg_7-headless
              cachix
              typst
              typst-lsp
              typstyle
              typst-live
              taplo
              just
              delta
              aoc-cli
              mold

              # pulumi stuff
              pulumictl
              pulumiPackages.pulumi-language-nodejs
              pulumiPackages.pulumi-language-python
              pulumiPackages.pulumi-language-go

              # terminal + editing
              starship
              kitty
              neovim
              vscode
              fish

              # js tooling
              corepack
              bun
              fnm

              # formatters + lsps
              prettierd
              stylua
              rustywind
              alejandra # for nix
              tailwindcss-language-server
              pyright
              kotlin-language-server
              ktlint

              # language tools
              zulu17
              jdt-language-server
              go
              gopls
              typescript
              (fenix.packages.${system}.fromToolchainFile {
                dir = ./.;
                sha256 = "sha256-yMuSb5eQPO/bHv+Bcf/US8LVMbf/G/0MSfiPwBhiPpk=";
              })
            ]
            ++ macPackages;
        };
      }
    );
  };
}
