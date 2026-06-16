{pkgs, ...}: {
  home.packages = with pkgs; [
    redis
    awscli2
  ];
}
