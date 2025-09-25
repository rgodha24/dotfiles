{
  config,
  pkgs,
  unstable,
  zen-browser,
  system,
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
    unstable.opencode

    # Development tools
    git
    unstable.neovim
    fnm
    nodejs_20
    go
    gopls
    rustup
    cargo-lambda
    (unstable.rustPlatform.buildRustPackage {
      pname = "cryptenv";
      version = "0.3.0";
      src = pkgs.fetchFromGitHub {
        owner = "rgodha24";
        repo = "cryptenv";
        rev = "a4e0f6cc30ec8df50524e6a8ec4366fa7abf3a10";
        sha256 = "sha256-XHogXpnbbzjqcvA/qCp9JaOjE1Dm6FHac+/m4NfVxPA=";
      };
      cargoHash = "sha256-dVqsumAa1HxGgBYhI5/NaMJoLJftWx1SIU6rNQGykr8=";

      # Debugging aids
      cargoBuildFlags = ["-vv"];
      CARGO_BUILD_JOBS = "1";
      RUST_BACKTRACE = "full";
    })

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
    geekbench
    discord
    davinci-resolve

    # Formatters and LSPs
    prettierd
    stylua
    alejandra
    tailwindcss-language-server
    pyright
    tinymist
    luajitPackages.tiktoken_core
    lynx

    zulu17
    jdt-language-server
    typescript
    zig_0_12
    postgresql_17_jit
    typescript-language-server
    svelte-language-server
    clang-tools
    astro-language-server

    corepack
    unstable.bun

    unstable.uv
    unstable.ruff
    python313Full

    xdg-utils
    ncspot
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Rohan Godha";
    userEmail = "git@rohangodha.com";
    signing = {
      key = "~/.ssh/id_ed25519";
      signByDefault = true;
    };
    extraConfig = {
      init.defaultBranch = "main"; # im too woke 💔🥀
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      user.signingkey = "~/.ssh/id_ed25519";
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
  home.file.".config/cryptenv.toml".source = ./cryptenv.toml;

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

  # SSH allowed signers for git commit verification
  home.file.".ssh/allowed_signers".text = "git@rohangodha.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGSYGWEg9n6XlaYavB1MyYk+H6IEBPec5DYLGWz6lPm rgodha@nixos";

  # Zen Browser configuration
  programs.zen-browser = {
    enable = true;
    package = zenWrapped;
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
    EDITOR = "nvim";
    BROWSER = "zen";
    TERMINAL = "ghostty";
  };
}
