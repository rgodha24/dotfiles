{inputs, ...}: {
  programs.firefox = {
    enable = true;

    profiles.rgodha = {
      extensions = with inputs.firefox-addons.packages."x86_64-linux"; [
        bitwarden
        ublock-origin
      ];
    };
  };

  programs.home-manager.enable = true;
}
