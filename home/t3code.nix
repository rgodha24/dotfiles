{
  config,
  lib,
  pkgs,
  unstable,
  system,
  claude-code-nix,
  codex-cli-nix,
  t3code,
  ...
}: let
  meta = builtins.fromJSON (builtins.readFile t3code);

  t3code-unwrapped = unstable.stdenv.mkDerivation {
    pname = "t3code-unwrapped";
    inherit (meta) version;

    src = unstable.fetchurl {
      url = meta.dist.tarball;
      hash = meta.dist.integrity;
    };

    nativeBuildInputs = lib.optionals unstable.stdenv.hostPlatform.isLinux [
      unstable.autoPatchelfHook
    ];
    buildInputs = lib.optionals unstable.stdenv.hostPlatform.isLinux [
      unstable.stdenv.cc.cc.lib
    ];

    dontStrip = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec $out/bin
      cp -R . $out/libexec/t3code
      chmod +x $out/libexec/t3code/t3
      ln -s ../libexec/t3code/t3 $out/bin/t3
      runHook postInstall
    '';

    meta = {
      description = "T3 Code CLI (prebuilt upstream release)";
      homepage = "https://t3.codes";
      changelog = "https://github.com/pingdotgg/t3code/releases/tag/v${meta.version}";
      license = lib.licenses.mit;
      mainProgram = "t3";
      platforms = ["x86_64-linux"];
    };
  };

  runtimePackages = [
    claude-code-nix.packages.${system}.default
    codex-cli-nix.packages.${system}.default
    pkgs.git
    pkgs.gh
  ];

  t3code-wrapped = unstable.symlinkJoin {
    pname = "t3code";
    inherit (t3code-unwrapped) version meta;
    paths = [t3code-unwrapped];
    nativeBuildInputs = [unstable.makeBinaryWrapper];
    postBuild = ''
      rm $out/bin/t3
      makeBinaryWrapper $out/libexec/t3code/t3 $out/bin/t3 \
        --prefix PATH : ${lib.makeBinPath runtimePackages}
    '';
    passthru.unwrapped = t3code-unwrapped;
  };

  t3Home = "${config.home.homeDirectory}/.t3";
in {
  home.packages = [t3code-wrapped];

  systemd.user.startServices = "sd-switch";

  systemd.user.services.t3code = {
    Unit = {
      Description = "T3 Code server";
      After = ["network-online.target"];
      StartLimitIntervalSec = 300;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "%h";
      Environment = [
        "T3CODE_HOME=${t3Home}"
        "T3_BOOT_SERVICE_UNIT=t3code.service"
      ];
      ExecStart = "${t3code-wrapped}/bin/t3 serve";
      KillMode = "mixed";
      OOMPolicy = "continue";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = ["default.target"];
  };
}
