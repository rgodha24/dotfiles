{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = {
    self,
    nixpkgs,
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
              rustup
              go
              gopls
              typescript
            ]
            ++ macPackages;
        };
      }
    );
  };
}
