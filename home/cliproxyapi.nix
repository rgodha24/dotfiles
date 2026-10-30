{
  config,
  lib,
  unstable,
  ...
}: let
  version = "8.0.48";

  cliproxyapi = unstable.stdenv.mkDerivation {
    pname = "cliproxyapi";
    inherit version;

    src = unstable.fetchurl {
      url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_linux_amd64.tar.gz";
      hash = "sha256-CVxG5xZYQs9WP5ZlvobPJKKbqU5Xq5vWdYj+XMTHElw=";
    };
    sourceRoot = ".";

    nativeBuildInputs = [unstable.autoPatchelfHook];
    buildInputs = [unstable.stdenv.cc.cc.lib];

    dontStrip = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 cli-proxy-api $out/bin/cli-proxy-api
      runHook postInstall
    '';

    meta = {
      description = "Proxy exposing Claude Code / Codex subscriptions as an API";
      homepage = "https://github.com/router-for-me/CLIProxyAPI";
      license = lib.licenses.mit;
      mainProgram = "cli-proxy-api";
      platforms = ["x86_64-linux"];
    };
  };

  cpaHome = "${config.home.homeDirectory}/.cli-proxy-api";
  secretsDir = "${cpaHome}/secrets";

  settings = {
    config-version = 8;

    server = {
      host = "127.0.0.1";
      port = 8317;
      trusted-proxies = ["127.0.0.1" "::1"];
    };

    management = {
      allow-remote = true;
      secret-key = "@management-key@";
    };

    access.api-keys = [];

    routing = {
      strategy = "fill-first";
      session-affinity = true;
      session-affinity-ttl = "1h";
      retry = {
        request-retry = 3;
        max-retry-interval = 30;
      };
    };

    oauth.auth-dir = cpaHome;

    api-keys.openai-compatibility = [
      {
        name = "opencode-go";
        prefix = "go";
        base-url = "https://opencode.ai/inference/go/openai/v1";
        # go rejects requests without a per-conversation session id
        headers = {
          x-opencode-session = "$session_id";
          User-Agent = "$User-Agent";
        };
        keys = [{api-key = "@opencode-go-key@";}];
        models = map (name: {inherit name;}) [
          "kimi-k3.1-pro"
          "kimi-k3"
          "glm-5.3"
          "glm-5.3-flash"
          "deepseek-v4-pro"
          "deepseek-v4.1-flash"
          "mimo-v2.6-pro"
          "minimax-m3.1-flash"
        ];
      }
    ];
  };

  configTemplate = (unstable.formats.yaml {}).generate "cliproxyapi.yaml" settings;

  # the proxy rewrites its config, so it gets a fresh copy with secrets on every start
  prepare = unstable.writeShellScript "cliproxyapi-prepare" ''
    set -euo pipefail
    install -m600 ${configTemplate} ${cpaHome}/config.yaml
    for name in management-key opencode-go-key; do
      ${unstable.replace-secret}/bin/replace-secret "@$name@" ${secretsDir}/$name ${cpaHome}/config.yaml
    done

    for f in ${cpaHome}/*.json; do
      [ -e "$f" ] || continue
      if ${unstable.jq}/bin/jq -e '.type == "codex" and .websockets != true' "$f" >/dev/null; then
        ${unstable.jq}/bin/jq '.websockets = true' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      fi
    done
  '';
in {
  home.packages = [cliproxyapi];

  home.activation.cliproxyapiSecrets = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run mkdir -p ${secretsDir}
    run chmod 700 ${cpaHome} ${secretsDir}
    if [ ! -s ${secretsDir}/management-key ]; then
      run install -m600 /dev/null ${secretsDir}/management-key
      ${unstable.openssl}/bin/openssl rand -hex 24 > ${secretsDir}/management-key
    fi
    if [ ! -e ${secretsDir}/opencode-go-key ]; then
      run install -m600 /dev/null ${secretsDir}/opencode-go-key
    fi
  '';

  systemd.user.services.cliproxyapi = {
    Unit = {
      Description = "CLIProxyAPI hub";
      After = ["network-online.target"];
      X-Restart-Triggers = [configTemplate];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = cpaHome;
      ExecStartPre = prepare;
      ExecStart = "${cliproxyapi}/bin/cli-proxy-api -config ${cpaHome}/config.yaml";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = ["default.target"];
  };
}
