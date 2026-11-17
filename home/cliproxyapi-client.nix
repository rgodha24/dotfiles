{
  lib,
  unstable,
  ...
}: let
  # nixos hosts the proxy; other machines (mac) reach it over the tailnet.
  hub =
    if unstable.stdenv.hostPlatform.isLinux
    then "http://127.0.0.1:8317"
    else "https://nixos.tail76974f.ts.net:8317";
  # The checked-in configs use the local address; rewrite it to this machine's hub.
  withHub = name: file:
    unstable.writeText name
    (builtins.replaceStrings ["http://127.0.0.1:8317"] [hub] (builtins.readFile file));
  python = unstable.python3.withPackages (p: [p.tomlkit]);

  pointClientsAtHub = unstable.writeScript "point-clients-at-cliproxy" ''
    #!${python}/bin/python3
    import json, pathlib, tomlkit

    home = pathlib.Path.home()

    codex = home / ".codex/config.toml"
    codex.parent.mkdir(exist_ok=True)
    doc = tomlkit.parse(codex.read_text()) if codex.exists() else tomlkit.document()
    doc["model_provider"] = "cliproxy"
    doc.setdefault("model_providers", tomlkit.table())["cliproxy"] = {
        "name": "CLIProxyAPI",
        "base_url": "${hub}/v1",
        "wire_api": "responses",
        "requires_openai_auth": False,
        "supports_websockets": True,
        "experimental_bearer_token": "cliproxy",
    }
    codex.write_text(tomlkit.dumps(doc))

    claude = home / ".claude/settings.json"
    claude.parent.mkdir(exist_ok=True)
    settings = json.loads(claude.read_text()) if claude.exists() else {}
    settings.setdefault("env", {}).update(
        ANTHROPIC_BASE_URL="${hub}",
        ANTHROPIC_AUTH_TOKEN="cliproxy",
    )
    claude.write_text(json.dumps(settings, indent=2) + "\n")
  '';
  piModels = withHub "models.json" ../pi/models.json;
in {
  programs.pi.coding-agent.models = piModels;
  home.file.".config/opencode/opencode.jsonc".source = withHub "opencode.jsonc" ../opencode/config.json5;

  home.activation.cliproxyapiClients = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pointClientsAtHub}
    # the pi wrapper only seeds models.json when missing, so changes would never land
    run install -D -m600 ${piModels} "$HOME/.pi/agent/models.json"
  '';
}
