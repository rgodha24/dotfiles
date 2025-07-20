{ config, pkgs, ... }:

{
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
    neovim
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
    
    # Editors
    vscode
    code-cursor
    
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
    
    # JS tooling
    corepack
    bun
    
    # Python tools
    uv
    ruff
    python314
    
    # Linux-specific tools
    xdg-utils
    graphviz
    k9s
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Rohan Godha";
    userEmail = "your-email@example.com"; # Update this
  };

  # Fish shell configuration
  programs.fish = {
    enable = true;
    shellAliases = {
      cd = "z";
      ls = "eza";
      lg = "lazygit";
      where = "which";
      n = "nvim .";
      t = "eza -T --git-ignore";
    };
    shellInit = ''
      set -x GPG_TTY "$(tty)"
      set -x fish_greeting ""
      set -x EDITOR "$(which nvim)"
      
      # Initialize tools
      starship init fish | source
      zoxide init fish | source
      fnm env --use-on-cd --shell fish | source
      
      # Starship transient prompt
      function starship_transient_prompt_func
        starship module character
      end
      enable_transience
    '';
    functions = {
      gc = ''
        echo "pruning nix store"
        nix store gc
        echo "cleaning up home-manager generations"
        home-manager expire-generations "-7 days"
      '';
      shell = ''
        set -x IN_NIX_SHELL "impure"
        set -x name $argv
        nix shell "nixpkgs#$argv[1]" $argv[2..]
        set -e IN_NIX_SHELL
        set -e name
      '';
    };
  };

  # Starship prompt configuration
  programs.starship = {
    enable = true;
    settings = {
      format = ''
        [░▒▓](#a3aed2)\
        [](bg:#769ff0 fg:#a3aed2)\
        $directory\
        [](fg:#769ff0 bg:#394260)\
        $git_branch\
        $git_status\
        [](fg:#394260 bg:#212736)\
        $nodejs\
        $rust\
        $golang\
        $nix_shell\
        [](fg:#212736 bg:#1d2230)\
        [ ](fg:#1d2230)\
        $fill\
        [](fg:#1d2230)\
        $time\
        [█▓▒](#a3aed2)\
        [](bg:#1A1B26 fg:#4D5267)\
        \n$character
      '';
      
      command_timeout = 5000;
      
      fill = {
        symbol = " ";
      };
      
      directory = {
        style = "fg:#e3e5e5 bg:#769ff0";
        format = "[ $path ]($style)";
        truncation_length = 5;
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
          "Developer" = " ";
        };
      };
      
      git_branch = {
        symbol = "";
        style = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
      };
      
      git_status = {
        style = "bg:#394260";
        format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
      };
      
      nodejs = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };
      
      rust = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };
      
      golang = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };
      
      nix_shell = {
        disabled = false;
        symbol = "󱄅";
        format = "[[ $symbol ($name) ](fg:#769ff0 bg:#212736)]($style)";
      };
      
      time = {
        disabled = false;
        time_format = "%X";
        style = "bg:#1d2230";
        format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
      };
    };
  };

  # Ghostty terminal configuration
  home.file.".config/ghostty/config".text = ''
    font-family = "IntoneMono Nerd Font Mono"
    font-size = 12
    font-feature = -liga -calt -dlig
    font-thicken
    font-thicken-strength = 0
    theme = "tokyonight"
    window-padding-balance = false
    window-padding-y = 0
    quit-after-last-window-closed = true
    cursor-style = bar
    
    mouse-shift-capture = never
    auto-update = download
    keybind = shift+enter=text:\n
  '';

  # Neovim configuration - copy your existing nvim config
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };

  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Monitor configuration
      monitor = ",preferred,auto,auto";
      
      # Input configuration
      input = {
        kb_layout = "us";
        kb_options = "caps:escape";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        };
        sensitivity = 0;
      };
      
      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(7aa2f7ee) rgba(bb9af7ee) 45deg";
        "col.inactive_border" = "rgba(414868aa)";
        layout = "dwindle";
        allow_tearing = false;
      };
      
      # Decoration
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };
      
      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
      
      # Layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      
      # Window rules
      windowrulev2 = [
        "suppressevent maximize, class:.*"
        "float,class:^(ghostty)$,title:^(floating)$"
      ];
      
      # Key bindings
      "$mod" = "SUPER";
      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, E, exec, thunar"
        "$mod, V, togglefloating"
        "$mod, R, exec, wofi --show drun"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        
        # Move focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        
        # Switch workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        
        # Move active window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        
        # Screenshot
        ", Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
      ];
      
      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      
      # Startup
      exec-once = [
        "waybar"
        "dunst"
        "hyprpaper"
      ];
    };
  };

  # Waybar configuration
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;
        
        modules-left = [ "hyprland/workspaces" "hyprland/mode" ];
        modules-center = [ "hyprland/window" ];
        modules-right = [ "network" "battery" "clock" "tray" ];
        
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            urgent = "";
            focused = "";
            default = "";
          };
        };
        
        "hyprland/window" = {
          format = "{}";
          max-length = 50;
        };
        
        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
        
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          format-icons = [ "" "" "" "" "" ];
        };
        
        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };
      };
    };
    
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "IntoneMono Nerd Font Mono";
        font-size: 13px;
        min-height: 0;
      }
      
      window#waybar {
        background-color: rgba(26, 27, 38, 0.9);
        color: #c0caf5;
        transition-property: background-color;
        transition-duration: .5s;
      }
      
      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #c0caf5;
        border-bottom: 3px solid transparent;
      }
      
      #workspaces button:hover {
        background: rgba(0, 0, 0, 0.2);
      }
      
      #workspaces button.focused {
        background-color: #7aa2f7;
        border-bottom: 3px solid #7aa2f7;
      }
      
      #workspaces button.urgent {
        background-color: #f7768e;
      }
      
      #clock,
      #battery,
      #network,
      #tray {
        padding: 0 10px;
        color: #c0caf5;
      }
    '';
  };

  # Dunst notification daemon
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 300;
        offset = "30x50";
        origin = "top-right";
        transparency = 10;
        frame_color = "#7aa2f7";
        font = "IntoneMono Nerd Font Mono 10";
      };
      
      urgency_normal = {
        background = "#1a1b26";
        foreground = "#c0caf5";
        timeout = 10;
      };
    };
  };

  # Hyprpaper wallpaper daemon
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;
      
      preload = [
        "~/Pictures/wallpaper.jpg"
      ];
      
      wallpaper = [
        ",~/Pictures/wallpaper.jpg"
      ];
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "ghostty";
  };
}