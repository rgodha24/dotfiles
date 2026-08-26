{
  pkgs,
  username,
  ...
}: {
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.05";

  home.sessionVariables = {
    TESSER_RSYNC = "${pkgs.rsync}/bin/rsync";
  };

  home.packages = with pkgs; [
    pinentry_mac

    rsync

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
