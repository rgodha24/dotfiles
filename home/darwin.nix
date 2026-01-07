{pkgs, ...}: {
  home.username = "rohangodha";
  home.homeDirectory = "/Users/rohangodha";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    pinentry_mac

    unnaturalscrollwheels
    xquartz
    catclock
    kitty
    rustup
  ];
}
