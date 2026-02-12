{
  config,
  pkgs,
  unstable,
  opencode,
  system,
  zellij,
  worktrunk,
  lumen,
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

  cursorAgentVersion = "2026.01.28-fd13201";
  cursorAgentSha256 = {
    x86_64-linux = "sha256-Nj6q11iaa++b5stsEu1eBRAYUFRPft84XcHuTCZL5D0=";
    aarch64-linux = "sha256-6oajVZw599vzy2c1olEzoIlqbmfZRK1atb85fiR72y0=";
    x86_64-darwin = "sha256-G23LC7Sl1GjfaECndSuyCxHK4drkJKG3B1U2k5SAHJA=";
    aarch64-darwin = "sha256-R5kEfd84IaUXuN+PIzpGD1NGPzD6xxM9NAXAAt6d0N8=";
  };
  cursorAgentArch =
    if system == "x86_64-linux"
    then {
      os = "linux";
      arch = "x64";
    }
    else if system == "aarch64-linux"
    then {
      os = "linux";
      arch = "arm64";
    }
    else if system == "x86_64-darwin"
    then {
      os = "darwin";
      arch = "x64";
    }
    else if system == "aarch64-darwin"
    then {
      os = "darwin";
      arch = "arm64";
    }
    else throw "Unsupported system: ${system}";

  cursorAgentPkg = pkgs.stdenv.mkDerivation {
    pname = "cursor-agent";
    version = cursorAgentVersion;

    src = pkgs.fetchurl {
      url = "https://downloads.cursor.com/lab/${cursorAgentVersion}/${cursorAgentArch.os}/${cursorAgentArch.arch}/agent-cli-package.tar.gz";
      sha256 = cursorAgentSha256.${system};
    };

    nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.autoPatchelfHook];
    buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.stdenv.cc.cc.lib];

    sourceRoot = ".";

    unpackPhase = ''
      mkdir -p source
      tar -xzf $src -C source
      mv source/dist-package/* source/
      rmdir source/dist-package
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/cursor-agent
      cp -r source/* $out/lib/cursor-agent/

      # Create wrapper scripts in bin
      mkdir -p $out/bin
      cat > $out/bin/cursor-agent <<'WRAPPER'
      #!/usr/bin/env bash
      exec "@out@/lib/cursor-agent/node" "@out@/lib/cursor-agent/index.js" "$@"
      WRAPPER
      substituteInPlace $out/bin/cursor-agent --replace "@out@" "$out"
      chmod +x $out/bin/cursor-agent
      ln -s $out/bin/cursor-agent $out/bin/agent

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Cursor Agent CLI";
      homepage = "https://cursor.com";
      platforms = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      mainProgram = "agent";
    };
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
      rerere.enabled = true;
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        overrideGpg = true;
      };
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

  # works for everything EXCEPT claude code.
  # fuck claude code.
  home.file.".agents/skills" = {
    source = ../skills;
    recursive = true;
  };

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
      zellij.packages.${system}.default
      worktrunk.packages.${system}.default
      lumen.packages.${system}.default

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
      unstable.code-cursor
      unstable.antigravity

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
      unstable.zig
      postgresql_17_jit
      # Formatters and LSPs
      typescript-language-server
      svelte-language-server
      clang-tools
      astro-language-server
      cmake
      gnumake

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
      cursorAgentPkg
    ];
}
