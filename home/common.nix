{
  config,
  pkgs,
  unstable,
  opencode,
  ...
}: let
  cryptenvPkg = unstable.rustPlatform.buildRustPackage {
    pname = "cryptenv";
    version = "0.4.0";
    src = pkgs.fetchFromGitHub {
      owner = "rgodha24";
      repo = "cryptenv";
      rev = "c38e548d0e2ca22ff568a996a949a0fedf2c2209";
      sha256 = "sha256-LAdtxBmrIt+E/qJF80rtBvztTJbOI7+dzkRQHjUlivQ=";
    };
    cargoHash = "sha256-ItqUp1mGO6hinWRRapJZdHjfkDe+/xqIPnkzKGV4dkM=";
  };
  zellijSrc = pkgs.fetchFromGitHub {
    owner = "rgodha24";
    repo = "zellij";
    rev = "89b055bf62189dc8dda570d23f9ec4a1a0e5f62a";
    hash = "sha256-JrIHSg5L241E8Aa2wZUzOzlfRU1bcYRtqjx87EBI5tI=";
  };
  zellijPkg = unstable.rustPlatform.buildRustPackage {
    pname = "zellij";
    version = "0.44.0";
    src = zellijSrc;

    # Match nixpkgs behavior: link against system curl.
    postPatch = ''
      substituteInPlace Cargo.toml \
        --replace-fail ', "vendored_curl"' ""
    '';

    cargoHash = "sha256-0vzYAIW7xWryqm3bJBpdzeJdPB8Y2ciJ+tMTTzpuK/M=";

    env.OPENSSL_NO_VENDOR = 1;

    nativeBuildInputs = [
      pkgs.mandown
      pkgs.installShellFiles
      pkgs.pkg-config
      (pkgs.lib.getDev pkgs.curl)
    ];

    buildInputs = [
      pkgs.curl
      pkgs.openssl
    ];

    doCheck = false;
    doInstallCheck = false;

    postInstall = ''
      mandown docs/MANPAGE.md > zellij.1
      installManPage zellij.1
    '';
  };
in {
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

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
    interactiveShellInit = builtins.readFile ../config.fish;
  };
  programs.starship.enable = true;

  home.file.".config/starship.toml".source = ../starship.toml;
  home.file.".config/ghostty/config".source = ../ghostty.config;
  home.file.".config/cryptenv.toml".source = ../cryptenv.toml;
  home.file.".config/zellij/config.kdl".source = ../zellij.kdl;
  home.file.".config/opencode/opencode.jsonc".source = ../opencode/config.json5;

  # Neovim configuration
  home.file.".config/nvim" = {
    source = ../nvim;
    recursive = true;
  };

  # SSH allowed signers for git commit verification
  home.file.".ssh/allowed_signers".text = ''
  git@rohangodha.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGSYGWEg9n6XlaYavB1MyYk+H6IEBPec5DYLGWz6lPm rgodha@nixos
  git@rohangodha.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZYjP2+kqmmf3GCUPe/zIC9pKf/L9Ex/zmiy8o30SX3 rohangodha@mac.lan
  '';

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "ghostty";
  };

  home.packages =
    (with pkgs; [
      ripgrep
      eza
      lazygit
      gh
      git
      bat
      zoxide
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
      zellijPkg

      cachix
      typst
      typstyle
      typst-live
      taplo
      just
      delta
      aoc-cli

      pulumictl
      pulumiPackages.pulumi-nodejs
      pulumiPackages.pulumi-python
      pulumiPackages.pulumi-go

      starship
      fish
      unstable.neovim
      unstable.vscode
      unstable.code-cursor

      opencode.packages.${system}.default
      unstable.codex

      unstable.prettierd
      stylua
      alejandra
      unstable.tailwindcss-language-server
      pyright
      unstable.tinymist
      luajitPackages.tiktoken_core
      lynx

      zulu17
      jdt-language-server
      go
      gopls
      typescript
      nodejs_20
      cargo-lambda
      zig_0_12
      postgresql_17_jit
      # Formatters and LSPs
      typescript-language-server
      svelte-language-server
      clang-tools
      astro-language-server

      corepack
      unstable.bun
      fnm

      unstable.uv
      unstable.ruff
      python313Full

      # Fonts
      intel-one-mono
      nerd-fonts.intone-mono
    ])
    ++ [
      cryptenvPkg
    ];
}
