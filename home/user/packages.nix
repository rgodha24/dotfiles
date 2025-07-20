{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages = [
    # Dev stuff
    pkgs.gcc
    pkgs.go
    pkgs.lua
    pkgs.nodejs
    pkgs.nodePackages.pnpm
    (pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.pip
      python-pkgs.requests
    ]))
    pkgs.rustup
    pkgs.pkgsCross.mingwW64.stdenv.cc
    pkgs.pkgsCross.mingwW64.windows.pthreads
    pkgs.zig

    # Work stuff
    pkgs.obsidian
    pkgs.thunderbird
    pkgs.hunspell

    # Bluetooth
    pkgs.blueberry

    # Gaming
    pkgs.steam
    pkgs.steam-run
    pkgs.yuzu-mainline
    (pkgs.lutris.override {
      extraPkgs = pkgs: [
        pkgs.wineWowPackages.stable
        pkgs.winetricks
      ];
    })

    # Utils
    pkgs.viewnior
    pkgs-unstable.hyprshot
    pkgs.catppuccin-cursors.macchiatoBlue
    pkgs.catppuccin-gtk
    pkgs.papirus-folders
  ];
}
