{
  config,
  pkgs,
  ...
}: {
  users.users.rgodha = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "qemu"
      "kvm"
      "libvirtd"
      "networkmanager"
    ];
  };
}
