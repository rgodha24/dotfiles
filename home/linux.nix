{
  config,
  pkgs,
  unstable,
  zen-browser,
  system,
  fenixPkgs,
  opencode,
  ...
}: let
  # Wrap Zen to disable profile-per-install
  # This ensures the .desktop entry and all launches use the env vars.
  zenPkg = zen-browser.packages.${system}.default;
  zenWrapped =
    pkgs.writeShellScriptBin "zen" ''
      export MOZ_LEGACY_PROFILES=1
      export MOZ_ALLOW_DOWNGRADE=1
      exec ${zenPkg}/bin/zen "$@"
    ''
    // {
      inherit (zenPkg) meta;
      override = _: zenWrapped;
    };
in {
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

  # Zen Browser configuration
  programs.zen-browser = {
    enable = true;
    package = zenWrapped;
    suppressXdgMigrationWarning = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
      ExtensionSettings = {
        # Bitwarden
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  # Environment variables
  home.sessionVariables = {
    BROWSER = "zen";
  };
}
