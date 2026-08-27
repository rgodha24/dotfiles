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
    pkgsunstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # pinned for neovim 0.11 until plugins are compatible with 0.12
    pkgs-neovim.url = "github:NixOS/nixpkgs/2fc6539b481e1d2569f25f8799236694180c0993";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      # v2 includes PR #43469 (feat(nix): update cli packaging), which fixed
      # node_modules.nix filtering the renamed-away `packages/opencode`.
      url = "github:anomalyco/opencode/v2";
    };
    ghfs = {
      url = "github:rgodha24/ghfs";
      inputs.nixpkgs.follows = "pkgsunstable";
    };
    docfs = {
      url = "github:rgodha24/docfs";
      inputs.nixpkgs.follows = "pkgsunstable";
    };
    lumen = {
      url = "github:rgodha24/lumen";
    };
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "pkgsunstable";
    };
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "pkgsunstable";
    };
    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "pkgsunstable";
    };
    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "pkgsunstable";
    };
  };

  outputs = {
    nixpkgs,
    pkgsunstable,
    pkgs-neovim,
    home-manager,
    determinate,
    fenix,
    opencode,
    ghfs,
    docfs,
    lumen,
    claude-code-nix,
    codex-cli-nix,
    herdr,
    pi,
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
    neovim-pin =
      (import pkgs-neovim {
        system = linuxSystem;
        config.allowUnfree = true;
      }).neovim;
    fenixPkgs = fenix.packages.${linuxSystem};
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit unstable home-manager;};
      system = linuxSystem;
      modules = [
        determinate.nixosModules.default
        ./configuration.nix
        {
          nixpkgs.config.allowUnfree = true;

          programs.nix-ld.enable = true;
          programs.nix-ld.package = unstable.nix-ld;
        }
      ];
    };

    homeConfigurations.nixos = home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor linuxSystem;
      extraSpecialArgs = {
        inherit unstable pkgsunstable fenixPkgs opencode ghfs docfs lumen claude-code-nix codex-cli-nix herdr pi neovim-pin;
        system = linuxSystem;
      };
      modules = [
        ghfs.homeManagerModules.default
        ./home.nix
      ];
    };

    homeConfigurations.mac = home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor darwinSystem;
      extraSpecialArgs = {
        system = darwinSystem;
        unstable = unstableFor darwinSystem;
        username = "rohangodha";
        inherit opencode;
        inherit ghfs;
        inherit docfs;
        inherit lumen;
        inherit claude-code-nix;
        inherit codex-cli-nix;
        inherit herdr;
        inherit pi;
        neovim-pin =
          (import pkgs-neovim {
            system = darwinSystem;
            config.allowUnfree = true;
          }).neovim;
      };
      modules = [
        ghfs.homeManagerModules.default
        ./home/common.nix
        ./home/darwin.nix
      ];
    };

    homeConfigurations.work = home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor darwinSystem;
      extraSpecialArgs = {
        system = darwinSystem;
        unstable = unstableFor darwinSystem;
        username = "rgodha";
        inherit opencode;
        inherit ghfs;
        inherit docfs;
        inherit lumen;
        inherit claude-code-nix;
        inherit codex-cli-nix;
        inherit herdr;
        inherit pi;
        neovim-pin =
          (import pkgs-neovim {
            system = darwinSystem;
            config.allowUnfree = true;
          }).neovim;
      };
      modules = [
        ghfs.homeManagerModules.default
        ./home/common.nix
        ./home/darwin.nix
        ./home/work.nix
      ];
    };
  };
}
