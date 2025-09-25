{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    pkgsunstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    nixpkgs,
    pkgsunstable,
    home-manager,
    determinate,
    zen-browser,
    ...
  }: let
    unstable = import pkgsunstable {
      inherit system;
      config.allowUnfree = true;
    };
    system = "x86_64-linux";
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      modules = [
        determinate.nixosModules.default
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.rgodha = {
              imports = [
                zen-browser.homeModules.beta
                ./home.nix
              ];
              home.stateVersion = "25.05";
            };
            extraSpecialArgs = {
              inherit zen-browser;
              inherit unstable;
              inherit system;
            };
          };

          programs.nix-ld.enable = true;
          programs.nix-ld.package = unstable.nix-ld;
        }
      ];
    };
  };
}
