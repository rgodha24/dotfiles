let
  userName = "rgodha24";
  email = "git@rohangodha.com";
in {
  programs.git = {
    enable = true;
    userName = userName;
    userEmail = email;
  };
}
