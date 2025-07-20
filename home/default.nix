{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./user
  ];

  home.username = "rgodha";
  home.homeDirectory = "/home/rgodha";
  home.stateVersion = "23.11";
}
