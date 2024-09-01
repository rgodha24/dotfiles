{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    packages."aarch64-darwin".default = let
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        # config.allowUnfree = true;
      };
    in
      pkgs.buildEnv {
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

          neovim
          # really wish i could install it with nix, but it's only setup for linux
          # im only really using it as a non-lsp text editor for classes
          # sublime

          corepack
          bun
          fnm
          # only really used for gh copilot in neovim cuz it doesn't play nicely with fnm
          nodejs_20

          # formatters + lsps
          prettierd
          stylua
          rustywind
          alejandra # for nix
          tailwindcss-language-server

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
  };
}
