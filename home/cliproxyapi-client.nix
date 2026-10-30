{
  lib,
  unstable,
  ...
}: let
  hub = "https://nixos.tail76974f.ts.net:8317";
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
in {
  programs.pi.coding-agent.models = ../pi/models.json;

  home.activation.cliproxyapiClients = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pointClientsAtHub}
  '';
}
