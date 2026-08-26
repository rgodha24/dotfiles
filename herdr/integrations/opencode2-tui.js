// herdr session reporting for the opencode v2 cli (opencode2).
// herdr ships a v1 tui plugin ({ id, tui }); the v2 host requires { id, setup }.
import net from "node:net";

const SOURCE = "herdr:opencode";
const AGENT = "opencode";
const POLL_INTERVAL_MS = 250;

function report(sessionID) {
  const paneId = process.env.HERDR_PANE_ID;
  const socketPath = process.env.HERDR_SOCKET_PATH;
  const endpoint = process.platform === "win32" ? `\\\\.\\pipe\\${socketPath}` : socketPath;
  const request = {
    id: `${SOURCE}:tui:${Date.now()}:${Math.floor(Math.random() * 1_000_000)
      .toString()
      .padStart(6, "0")}`,
    method: "pane.report_agent_session",
    params: {
      pane_id: paneId,
      source: SOURCE,
      agent: AGENT,
      agent_session_id: sessionID,
      session_start_source: "select",
    },
  };

  return new Promise((resolve, reject) => {
    const client = net.createConnection(endpoint, () => {
      client.write(`${JSON.stringify(request)}\n`);
    });
    let settled = false;
    const finish = (error) => {
      if (settled) return;
      settled = true;
      client.destroy();
      if (error) reject(error);
      else resolve();
    };
    client.setTimeout(1_000, () => finish(new Error("herdr socket timeout")));
    client.on("data", () => finish());
    client.on("error", finish);
    client.on("close", () => finish());
  });
}

export default {
  id: "herdr.opencode.session",
  setup(context) {
    if (
      process.env.HERDR_ENV !== "1" ||
      !process.env.HERDR_SOCKET_PATH ||
      !process.env.HERDR_PANE_ID
    ) {
      return;
    }

    let reported;
    let inflight = false;
    const sync = async () => {
      const route = context.ui.router.current();
      const sessionID = route?.type === "session" ? route.sessionID : undefined;
      if (!sessionID || sessionID === reported || inflight) return;
      if (context.data.session.get(sessionID)?.parentID) return;
      inflight = true;
      try {
        await report(sessionID);
        reported = sessionID;
      } catch {
        // retried on the next tick
      } finally {
        inflight = false;
      }
    };

    void sync();
    const timer = setInterval(() => void sync(), POLL_INTERVAL_MS);
    return () => clearInterval(timer);
  },
};
