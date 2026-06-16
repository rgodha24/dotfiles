{pkgs, username, ...}: {
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    pinentry_mac

    unnaturalscrollwheels
    xquartz
    catclock
    kitty
    rustup
    pkgconf

    openconnect
    vpn-slice
  ];
}
