{
  config,
  lib,
  unstable,
  ...
}: let
  version = "8.0.48";

  # built from source to carry the soonest-reset routing strategy, which upstream
  # won't merge (quota-aware routing is out of scope for core, see issue #4715)
  cliproxyapi = (unstable.buildGoModule.override {go = unstable.go_latest;}) {
    pname = "cliproxyapi";
    inherit version;

    src = unstable.fetchFromGitHub {
      owner = "router-for-me";
      repo = "CLIProxyAPI";
      rev = "v${version}";
      hash = "sha256-BD/FxJWgY9WzPtXb8z2RtLrrL4s8Wj/6ny0VM13ON/w=";
    };
    vendorHash = "sha256-yMO0DdE0pjtFxWaQXV17enV8u0KA5fIUbE8Gui/RvWU=";

    # https://github.com/router-for-me/CLIProxyAPI/pull/7040
    patches = [
      ./patches/cliproxyapi-soonest-reset.patch
      # spend the last 3% (auth json weekly_reserve_percent) of a weekly window only in its last 4h
      # or once every account is there; never the last 1%
      ./patches/cliproxyapi-weekly-reserve.patch
      # session bindings only hold within the best ready priority tier, so sessions that fell back
      # to the anthropic api keys move back to a subscription as soon as one recovers
      ./patches/cliproxyapi-tier-affinity.patch
      # log 16 chars of session ids (was 8, i.e. "claude:" + 1 char) so claude-status can tell threads apart
      ./patches/cliproxyapi-session-log.patch
    ];

    subPackages = ["cmd/server"];
    ldflags = ["-s" "-w" "-X main.Version=${version}"];

    postInstall = ''
      mv $out/bin/server $out/bin/cli-proxy-api
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

  # secret file names under secretsDir; empty files are fine, the key is then just unusable
  anthropicKeys = ["anthropic-gatech" "anthropic-gmail"];
  secretNames = ["management-key" "opencode-go-key"] ++ anthropicKeys;

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
      strategy = "soonest-reset";
      session-affinity = true;
      session-affinity-ttl = "1h";
      retry = {
        request-retry = 3;
        max-retry-interval = 30;
      };
    };

    oauth.auth-dir = cpaHome;

    # worst-case fallback on paid api credits: subscription logins sit at priority 0, so these
    # only get traffic once every subscription is out of quota or cooling down
    api-keys.claude = [
      {
        name = "anthropic-api";
        priority = -10;
        keys = [
          {api-key = "@anthropic-gatech@";} # gatech account
          {api-key = "@anthropic-gmail@";} # gmail acc
        ];
      }
    ];

    api-keys.openai-compatibility = [
      {
        name = "opencode-go";
        prefix = "go";
        base-url = "https://opencode.ai/inference/go/openai/v1";
        # go rejects requests without a per-conversation session id; $CPA-SESSION-ID is the
        # session the proxy derives for any client (falls back to a hash of the conversation)
        headers = {
          x-opencode-session = "$CPA-SESSION-ID";
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
    export PATH=${lib.makeBinPath [unstable.coreutils]}

    for _ in $(seq 1 30); do
      if ${lib.getBin unstable.glibc}/bin/getent hosts models.router-for.me >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done

    install -m600 ${configTemplate} ${cpaHome}/config.yaml
    for name in ${lib.concatStringsSep " " secretNames}; do
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
    for name in opencode-go-key ${lib.concatStringsSep " " anthropicKeys}; do
      if [ ! -e ${secretsDir}/$name ]; then
        run install -m600 /dev/null ${secretsDir}/$name
      fi
    done
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
