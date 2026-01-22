# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages;

  # mount the windows fs
  boot.supportedFilesystems = ["ntfs"];
  fileSystems."/mnt/windows" = {
    device = "/dev/nvme0n1p3";
    fsType = "ntfs-3g";
    options = ["ro" "uid=1000" "gid=1000" "umask=0022"];
  };

  # nix flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];
  # cachix stuff
  nix.settings.trusted-users = ["root" "rgodha"];

  # NVIDIA CUDA binary caches
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://cuda-maintainers.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
  ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.interfaces.enp13s0f3u1c2 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "10.42.0.1";
        prefixLength = 24;
      }
    ];
  };
  networking.firewall.trustedInterfaces = ["enp13s0f3u1c2"];
  networking.nat = {
    enable = true;
    externalInterface = "enp9s0";
    internalInterfaces = ["enp13s0f3u1c2"];
    enableIPv6 = false;
  };

  networking.resolvconf.useLocalResolver = true;
  services.resolved = {
    enable = true;
    dnssec = "false";
    dnsovertls = "false";
    fallbackDns = ["1.1.1.1" "8.8.8.8"];
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = ["enp13s0f3u1c2"];
      bind-dynamic = true;
      listen-address = ["10.42.0.1"];
      dhcp-range = ["10.42.0.100,10.42.0.200,255.255.255.0,12h"];
      dhcp-option = [
        "option:router,10.42.0.1"
        "option:dns-server,1.1.1.1,8.8.8.8"
      ];
      server = ["1.1.1.1" "8.8.8.8"];
    };
  };
  systemd.network.wait-online.ignoredInterfaces = ["enp13s0f3u1c2"];

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.rgodha = {
    isNormalUser = true;
    description = "Rohan Godha";
    extraGroups = ["networkmanager" "wheel" "docker" "adbusers" "dialout"];
    packages = with pkgs; [git];
    shell = pkgs.fish;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    wget
    curl
    gcc
    openssl
    stdenv.cc.cc.lib
    adwaita-qt
    adwaita-qt6
    xorg.xauth
    xorg.xhost
    xorg.xclock
    xorg.xeyes
    tailscale
  ];

  programs.hyprland.enable = true;
  programs.fish.enable = true;
  programs.steam.enable = true;
  programs.adb.enable = true;

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

  # Global dark theme
  environment.variables = {
    GTK_THEME = "Adwaita:dark";
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  services.dbus.packages = with pkgs; [dconf];
  programs.dconf.enable = true;

  # Display manager for graphical login
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.defaultSession = "hyprland";

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      X11Forwarding = true;
      X11UseLocalhost = true;
    };
  };

  networking.firewall.allowedTCPPorts = [3000];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true; # Needed for some LE features
      };
    };
  };
  services.blueman.enable = true;
  security.polkit.enable = true;

  hardware.graphics.enable = true; #opengl
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # recommended for 5060ti
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  services.tailscale = {
    enable = true;
    extraUpFlags = ["--accept-dns=false"];
  };

  # XDG portal for screen sharing and file dialogs
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    intel-one-mono
    nerd-fonts.fira-code
    nerd-fonts.intone-mono
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
