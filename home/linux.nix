{
  config,
  pkgs,
  unstable,
  system,
  fenixPkgs,
  opencode,
  ...
}: {
  home.username = "rgodha";
  home.homeDirectory = "/home/rgodha";
  home.stateVersion = "25.05";

  # Fonts
  fonts.fontconfig.enable = true;
  home.packages =
    (with pkgs; [
      ghostty
      xorg.xauth

      # System utilities
      wl-clipboard
      grim
      slurp
      swappy

      # Hyprland ecosystem
      waybar
      wofi
      dunst
      hyprpaper

      nvitop
      fd

      # guis
      beeper
      geekbench
      discord
      davinci-resolve

      xdg-utils
      ncspot
    ])
    ++ [fenixPkgs.stable.toolchain];

  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ../hyprland.conf;
  };

  # Waybar configuration
  programs.waybar.enable = true;
  home.file.".config/waybar/config".source = ../waybar.config.json;
  home.file.".config/waybar/style.css".source = ../waybar.styles.css;

  # Dunst notification daemon
  services.dunst = {
    enable = true;
    configFile = ../dunstrc;
  };

  # Hyprpaper wallpaper daemon
  services.hyprpaper.enable = true;
  home.file.".config/hypr/hyprpaper.conf".source = ../hyprpaper.conf;

  # Background image
  home.file."Pictures/background.jpg".source = ../background.jpg;
}
