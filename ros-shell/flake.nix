{
  inputs = {
    nix-ros-overlay.url = "/Users/rohangodha/Coding/nix-ros-overlay/";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs"; # IMPORTANT!!!
  };
  outputs = {
    self,
    nix-ros-overlay,
    nixpkgs,
  }:
    nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [nix-ros-overlay.overlays.default];
      };
    in {
      devShells.default = pkgs.mkShell {
        name = "Example project";
        packages = with pkgs; [
          colcon
          vcstool
          # ... other non-ROS packages
          (with rosPackages.humble;
            buildEnv {
              paths = [
                ros-core
                demo-nodes-cpp
                demo-nodes-py
                turtlesim
                # ... other ROS packages
              ];
            })
        ];
      };
    });
  nixConfig = {
    extra-substituters = ["https://ros.cachix.org"];
    extra-trusted-public-keys = ["ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="];
  };
}
