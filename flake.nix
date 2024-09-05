{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };
  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            # config.allowUnfree = true;
          };
        in
        {
          default = pkgs.buildEnv {
            name = "home-packages";
            paths = with pkgs; [
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
              pulumictl
              pulumi
              pulumiPackages.pulumi-language-go
              pulumiPackages.pulumi-language-nodejs
              pulumiPackages.pulumi-language-python
              neovim
              corepack
              bun
              fnm
              nodejs_20
              # formatters + lsps
              prettierd
              stylua
              rustywind
              alejandra # for nix
              tailwindcss-language-server
              matlab-language-server
              # language tools
              zulu17
              jdt-language-server
              rustup
              go
              gopls
              # random dev deps
              gnum4
              # apps
              localsend
            ];
          };
        }
      );
    };
}