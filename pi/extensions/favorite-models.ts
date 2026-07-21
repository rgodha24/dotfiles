/**
 * Favorite Models
 *
 * Bookmark specific models and quickly switch between just your favorites.
 *
 * Commands:
 *   /fav            - toggle current model as favorite
 *   /favs           - pick a model from favorites (switches to it)
 *   /fav-list       - list favorites
 *   /fav-clear      - clear all favorites
 *
 * Favorites are stored at ~/.pi/agent/favorite-models.json as
 *   [{ "provider": "anthropic", "id": "claude-sonnet-4-5" }, ...]
 *
 * A small ★ status appears in the footer when the active model is favorited.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";

interface FavRef {
	provider: string;
	id: string;
}

const FILE = join(getAgentDir(), "favorite-models.json");
const STATUS_KEY = "favorite-models";

function load(): FavRef[] {
	if (!existsSync(FILE)) return [];
	try {
		const raw = JSON.parse(readFileSync(FILE, "utf-8"));
		if (!Array.isArray(raw)) return [];
		return raw
			.filter((x) => x && typeof x.provider === "string" && typeof x.id === "string")
			.map((x) => ({ provider: x.provider, id: x.id }));
	} catch {
		return [];
	}
}

function save(favs: FavRef[]): void {
	mkdirSync(dirname(FILE), { recursive: true });
	writeFileSync(FILE, `${JSON.stringify(favs, null, 2)}\n`);
}

function isFav(favs: FavRef[], provider: string, id: string): boolean {
	return favs.some((f) => f.provider === provider && f.id === id);
}

function currentModel(ctx: ExtensionContext) {
	return ctx.model;
}

function refreshStatus(pi: ExtensionAPI, ctx: ExtensionContext): void {
	const m = currentModel(ctx);
	if (!m) {
		ctx.ui.setStatus(STATUS_KEY, "");
		return;
	}
	const favs = load();
	ctx.ui.setStatus(STATUS_KEY, isFav(favs, m.provider, m.id) ? "★ favorite" : "");
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		refreshStatus(pi, ctx);
	});

	pi.on("model_select", async (_event, ctx) => {
		refreshStatus(pi, ctx);
	});

	pi.registerCommand("fav", {
		description: "Toggle current model as a favorite",
		handler: async (_args, ctx) => {
			const m = currentModel(ctx);
			if (!m) {
				ctx.ui.notify("No active model", "warning");
				return;
			}
			const favs = load();
			const idx = favs.findIndex((f) => f.provider === m.provider && f.id === m.id);
			if (idx >= 0) {
				favs.splice(idx, 1);
				save(favs);
				ctx.ui.notify(`Unfavorited ${m.provider}/${m.id}`, "info");
			} else {
				favs.push({ provider: m.provider, id: m.id });
				save(favs);
				ctx.ui.notify(`★ Favorited ${m.provider}/${m.id}`, "info");
			}
			refreshStatus(pi, ctx);
		},
	});

	pi.registerCommand("favs", {
		description: "Pick a model from your favorites",
		handler: async (_args, ctx) => {
			const favs = load();
			if (favs.length === 0) {
				ctx.ui.notify("No favorites yet. Use /fav to bookmark the current model.", "info");
				return;
			}

			const all = ctx.modelRegistry.getAll();
			const labels = favs.map((f) => {
				const found = all.find((m) => m.provider === f.provider && m.id === f.id);
				return found
					? `${found.provider}/${found.id}${found.name && found.name !== found.id ? `  (${found.name})` : ""}`
					: `${f.provider}/${f.id}  (not loaded)`;
			});

			const picked = await ctx.ui.select("Favorite models", labels);
			if (!picked) return;

			const idx = labels.indexOf(picked);
			if (idx < 0) return;
			const { provider, id } = favs[idx];
			const model = ctx.modelRegistry.find(provider, id);
			if (!model) {
				ctx.ui.notify(`Model ${provider}/${id} is not currently available.`, "error");
				return;
			}
			const ok = await pi.setModel(model);
			if (!ok) {
				ctx.ui.notify(`No API key configured for ${provider}.`, "error");
				return;
			}
			ctx.ui.notify(`Switched to ${provider}/${id}`, "info");
		},
	});

	pi.registerCommand("fav-list", {
		description: "List favorite models",
		handler: async (_args, ctx) => {
			const favs = load();
			if (favs.length === 0) {
				ctx.ui.notify("No favorites.", "info");
				return;
			}
			const all = ctx.modelRegistry.getAll();
			const lines = favs.map((f) => {
				const found = all.find((m) => m.provider === f.provider && m.id === f.id);
				return found ? `★ ${f.provider}/${f.id}` : `★ ${f.provider}/${f.id}  (not loaded)`;
			});
			ctx.ui.notify(lines.join("\n"), "info");
		},
	});

	pi.registerCommand("fav-clear", {
		description: "Clear all favorite models",
		handler: async (_args, ctx) => {
			const favs = load();
			if (favs.length === 0) {
				ctx.ui.notify("No favorites to clear.", "info");
				return;
			}
			const ok = await ctx.ui.confirm("Clear favorites?", `Delete ${favs.length} favorite(s)?`);
			if (!ok) return;
			save([]);
			refreshStatus(pi, ctx);
			ctx.ui.notify("Favorites cleared.", "info");
		},
	});
}
