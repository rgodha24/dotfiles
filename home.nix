{
  config,
  pkgs,
  pkgsunstable,
  zen-browser,
  system,
  ...
}: let
  unstable = import pkgsunstable {
    inherit system;
    config.allowUnfree = true;
  };
in {
  home.username = "rgodha";
  home.homeDirectory = "/home/rgodha";
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Fonts
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # Fonts
    intel-one-mono
    nerd-fonts.intone-mono

    # Terminal and shell tools
    ghostty
    fish
    starship
    zoxide
    eza
    lazygit

    # Development tools
    git
    unstable.neovim
    fnm
    nodejs_20
    go
    gopls
    rustup
    cargo-lambda

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

    # General tools from old flake
    ripgrep
    bat
    gh
    jq
    gnupg
    fzf
    ffmpeg-full
    yt-dlp
    gimp
    gnuplot
    htop
    unzip
    btop
    fd

    # Nix tools
    cachix

    # Document tools
    typst
    typstyle
    typst-live
    taplo
    just
    delta
    aoc-cli

    # Pulumi tools
    pulumictl
    pulumiPackages.pulumi-nodejs
    pulumiPackages.pulumi-python
    pulumiPackages.pulumi-go

    # guis
    unstable.vscode
    unstable.code-cursor
    beeper

    # Formatters and LSPs
    prettierd
    stylua
    alejandra
    tailwindcss-language-server
    pyright
    tinymist
    luajitPackages.tiktoken_core
    lynx

    # Language tools
    zulu17
    jdt-language-server
    typescript
    zig_0_12
    postgresql_17_jit

    corepack
    unstable.bun

    uv
    ruff
    python314

    xdg-utils
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Rohan Godha";
    userEmail = "git@rohangodha.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # shell stuff
  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./config.fish;
  };
  programs.starship.enable = true;
  home.file.".config/starship.toml".source = ./starship.toml;
  home.file.".config/ghostty/config".source = ./ghostty.config;

  # Neovim configuration
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };

  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./hyprland.conf;
  };

  # Waybar configuration
  programs.waybar.enable = true;
  home.file.".config/waybar/config".source = ./waybar.config.json;
  home.file.".config/waybar/style.css".source = ./waybar.styles.css;

  # Dunst notification daemon
  services.dunst = {
    enable = true;
    configFile = ./dunstrc;
  };

  # Hyprpaper wallpaper daemon
  services.hyprpaper.enable = true;
  home.file.".config/hypr/hyprpaper.conf".source = ./hyprpaper.conf;

  # Background image
  home.file."Pictures/background.jpg".source = ./background.jpg;

  # Zen Browser configuration
  programs.zen-browser = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
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
    EDITOR = "nvim";
    BROWSER = "zen";
    TERMINAL = "ghostty";
  };
}
