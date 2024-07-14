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
          neovim
          lazygit
          gh
          bat
          zoxide
          fnm
          jq
          rustup
          corepack
          bun

          # lsps and formatters
          prettierd
          stylua
          rustywind
          alejandra

          # ... add your tools here
        ];
      };
  };
}
