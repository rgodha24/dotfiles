{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    packages."aarch64-darwin".default = let
      pkgs = nixpkgs.legacyPackages."aarch64-darwin";
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

          rustup

          neovim

          corepack
          bun
          fnm
          # only really used for gh copilot in neovim cuz it doesn't play nicely with fnm
          nodejs_20

          # formatters
          prettierd
          stylua
          rustywind
          alejandra # for nix
        ];
      };
  };
}
