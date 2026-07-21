import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const OPENCODE_AUTH_PATH = join(homedir(), ".local", "share", "opencode", "auth.json");
const OPENAI_PROVIDER = "openai";
const PI_CODEX_PROVIDER = "openai-codex";

interface OpencodeOAuth {
  type: "oauth";
  refresh: string;
  access: string;
  expires: number;
  accountId?: string;
}

function readOpencodeAuth(): OpencodeOAuth | undefined {
  try {
    const raw = readFileSync(OPENCODE_AUTH_PATH, "utf-8");
    const data = JSON.parse(raw);
    const entry = data[OPENAI_PROVIDER];
    if (entry?.type === "oauth" && entry.access) {
      return entry as OpencodeOAuth;
    }
  } catch {
    // ignore
  }
  return undefined;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    const auth = readOpencodeAuth();
    if (!auth) {
      ctx.ui.notify("OpenCode auth not found at ~/.local/share/opencode/auth.json", "warning");
      return;
    }

    const now = Date.now();
    const bufferMs = 60_000; // 1 minute safety buffer
    if (auth.expires < now + bufferMs) {
      const mins = Math.round((auth.expires - now) / 60_000);
      ctx.ui.notify(
        `OpenCode token expired (${mins}m ago). Run opencode once to refresh, then /reload pi.`,
        "warning"
      );
      return;
    }

    // Inject as a runtime API key via an in-memory extension provider overlay.
    // ctx.modelRegistry is pi's facade; it has no `authStorage`/`setRuntimeApiKey`.
    // registerProvider stores the overlay in memory only (never written to
    // models.json), so it stays read-only to opencode's auth.json file.
    ctx.modelRegistry.registerProvider(PI_CODEX_PROVIDER, { apiKey: auth.access });
    ctx.ui.notify(
      `Bridged OpenCode auth → pi/${PI_CODEX_PROVIDER} (expires ${new Date(auth.expires).toLocaleTimeString()})`,
      "info"
    );
  });
}
