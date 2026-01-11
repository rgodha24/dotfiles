{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    pkgsunstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:rgodha24/opencode";
      inputs.nixpkgs.follows = "pkgsunstable";
    };
    zellij = {
      url = "github:rgodha24/zellij";
      inputs.nixpkgs.follows = "pkgsunstable";
    };
  };

  outputs = {
    nixpkgs,
    pkgsunstable,
    home-manager,
    determinate,
    zen-browser,
    fenix,
    opencode,
    zellij,
    ...
  }: let
    linuxSystem = "x86_64-linux";
    darwinSystem = "aarch64-darwin";
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    unstableFor = system:
      import pkgsunstable {
        inherit system;
        config.allowUnfree = true;
      };
    unstable = unstableFor linuxSystem;
    fenixPkgs = fenix.packages.${linuxSystem};
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
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
            };
            extraSpecialArgs = {
              inherit zen-browser;
              inherit unstable;
              system = linuxSystem;
              inherit fenixPkgs;
              inherit opencode;
              inherit zellij;
            };
          };

          programs.nix-ld.enable = true;
          programs.nix-ld.package = unstable.nix-ld;
        }
      ];
    };

    homeConfigurations.mac = home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor darwinSystem;
      extraSpecialArgs = {
        system = darwinSystem;
        unstable = unstableFor darwinSystem;
        inherit opencode;
        inherit zellij;
      };
      modules = [
        ./home/common.nix
        ./home/darwin.nix
      ];
    };
  };
}
