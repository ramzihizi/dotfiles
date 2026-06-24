import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, resolve, sep } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type Risk = {
	title: string;
	detail: string;
	blastRadius: string;
};

type PathCheck = {
	path: string;
	absolutePath: string;
	exists: boolean;
	risks: Risk[];
};

const HOME = homedir();

const bashRiskPatterns: Array<{ pattern: RegExp; title: string; blastRadius: string }> = [
	{
		pattern: /(^|[;&|]\s*)rm\s+[^\n;&|]*(?:-[^\s;&|]*[rR][^\s;&|]*|--recursive)\b/i,
		title: "Recursive delete",
		blastRadius: "Can permanently delete a directory tree and is difficult to undo.",
	},
	{
		pattern: /(^|[;&|]\s*)rm\s+[^\n;&|]*(?:\*|\?|\[[^\]]+\])/i,
		title: "Wildcard delete",
		blastRadius: "Can delete many files if the glob expands more broadly than expected.",
	},
	{
		pattern: /\bfind\b[^\n;&|]*\s-delete\b/i,
		title: "Bulk find delete",
		blastRadius: "Deletes every matching path found by find; a bad predicate can remove many files.",
	},
	{
		pattern: /\b(?:shred|truncate)\b/i,
		title: "Destructive file operation",
		blastRadius: "Can irreversibly erase or truncate file contents.",
	},
	{
		pattern: /(^|[^0-9>])>\s*[^\s;&|]+/,
		title: "Shell output overwrite",
		blastRadius: "The > redirect truncates or overwrites the target file before writing output.",
	},
	{
		pattern: /(^|[;&|]\s*)mv\s+[^\n;&|]+\s+[^\n;&|]+/i,
		title: "Move or rename",
		blastRadius: "Can overwrite a destination or move files out of their expected location.",
	},
	{
		pattern: /\b(?:chmod|chown|chgrp)\b[^\n;&|]*(?:\s-R\b|-R\b|--recursive|(?:\*|\?|\[[^\]]+\]))/i,
		title: "Bulk permission or ownership change",
		blastRadius: "Can recursively or broadly alter permissions/ownership and break access or security assumptions.",
	},
	{
		pattern: /\bgit\s+(?:push\b|reset\s+--hard\b|clean\s+-[^\n;&|]*[fd]|rebase\b|branch\s+-D\b|tag\s+-d\b|push\b[^\n;&|]*--(?:force|delete)|stash\s+(?:drop|clear)\b)/i,
		title: "Git history, cleanup, or remote change",
		blastRadius: "Can discard local work, rewrite history, delete refs/stashes, or publish changes remotely.",
	},
	{
		pattern: /\bgit\s+(?:checkout|restore)\b[^\n;&|]*(?:--\s+)?(?:\.|:\/|[^\s;&|]+\.[^\s;&|]+)/i,
		title: "Git checkout/restore of files",
		blastRadius: "Can discard uncommitted file changes.",
	},
	{
		pattern: /\b(?:npm|pnpm|yarn)\s+publish\b|\bgh\s+(?:pr|issue|release)\s+(?:create|edit|delete)\b|\bcurl\b[^\n;&|]*(?:-X\s*(?:POST|PUT|PATCH|DELETE)|--request\s*(?:POST|PUT|PATCH|DELETE)|\s-d\s|--data)/i,
		title: "Outward network or publishing action",
		blastRadius: "Can publish packages, create/edit remote resources, or send data to an external API.",
	},
	{
		pattern: /\b(?:deploy|vercel\s+deploy|netlify\s+deploy|flyctl\s+deploy|wrangler\s+deploy|firebase\s+deploy|kubectl\s+(?:apply|delete|replace|patch|scale)|docker\s+(?:push|rmi|rm|compose\s+down))\b/i,
		title: "Deployment or infrastructure mutation",
		blastRadius: "Can change live infrastructure, containers, or deployed services.",
	},
	{
		pattern: /\bsudo\b|\b(?:brew|apt|apt-get|dnf|yum|pacman|port)\s+(?:install|upgrade|update|remove|uninstall|autoremove)\b|\b(?:npm|pnpm|yarn)\s+(?:install|add|remove|uninstall|update)\b[^\n;&|]*\s-g\b/i,
		title: "Privileged or system package change",
		blastRadius: "Can alter system state, install/remove software, or run with elevated privileges.",
	},
	{
		pattern: /\b(?:DROP|TRUNCATE)\s+(?:DATABASE|SCHEMA|TABLE|INDEX)?\b|\bDELETE\s+FROM\b|\bUPDATE\s+\S+\s+SET\b/i,
		title: "Potentially destructive database statement",
		blastRadius: "Can mutate or remove database data. Verify target database and WHERE clauses first.",
	},
];

const sensitivePathPatterns = [
	/(^|\/)\.env(?:\.|$)/i,
	/(^|\/)\.npmrc$/i,
	/(^|\/)\.pypirc$/i,
	/(^|\/)id_(?:rsa|dsa|ecdsa|ed25519)(?:\.pub)?$/i,
	/(^|\/)\.ssh(\/|$)/i,
	/(^|\/)\.gnupg(\/|$)/i,
	/(^|\/)secrets?(\/|\.|-|_|$)/i,
	/(^|\/)(?:credentials|tokens?|apikeys?|api_keys?)(?:\.|-|_|$)/i,
];

const homeConfigPatterns = [
	/^\.zshrc$/,
	/^\.bashrc$/,
	/^\.bash_profile$/,
	/^\.profile$/,
	/^\.config(\/|$)/,
	/^Library\/(LaunchAgents|LaunchDaemons)(\/|$)/,
];

const systemPrefixes = ["/etc/", "/usr/", "/var/", "/bin/", "/sbin/", "/System/", "/Library/"];

function normalizeCommand(command: string): string {
	return command.replace(/\\\n/g, " ").trim();
}

function isInside(parent: string, child: string): boolean {
	const normalizedParent = parent.endsWith(sep) ? parent : `${parent}${sep}`;
	return child === parent || child.startsWith(normalizedParent);
}

function displayPath(path: string, cwd: string): string {
	return isAbsolute(path) ? path : `${cwd}/${path}`;
}

function resolveToolPath(path: string, cwd: string): string {
	const cleaned = path.replace(/^@/, "");
	return resolve(cwd, cleaned);
}

function classifyBash(command: string): Risk[] {
	const normalized = normalizeCommand(command);
	const risks = bashRiskPatterns
		.filter(({ pattern }) => pattern.test(normalized))
		.map(({ title, blastRadius }) => ({ title, detail: command, blastRadius }));

	if (/\b(?:rm|mv|cp|chmod|chown|chgrp)\b[^\n;&|]*(?:\/etc\/|\/usr\/|\/var\/|\/System\/|\/Library\/|~\/\.ssh|~\/\.config|\$HOME\/\.ssh|\$HOME\/\.config)/i.test(normalized)) {
		risks.push({
			title: "Mutation under system or home configuration path",
			detail: command,
			blastRadius: "Can affect shell, SSH, application, or system configuration outside the current project.",
		});
	}

	return dedupeRisks(risks);
}

function classifyPathMutation(toolName: string, inputPath: string, cwd: string, createdPaths: Set<string>): PathCheck {
	const absolutePath = resolveToolPath(inputPath, cwd);
	const exists = existsSync(absolutePath);
	const risks: Risk[] = [];

	if (!isInside(resolve(cwd), absolutePath)) {
		risks.push({
			title: "Path outside current project",
			detail: displayPath(inputPath, cwd),
			blastRadius: "Can modify files outside the active project checkout.",
		});
	}

	if (sensitivePathPatterns.some((pattern) => pattern.test(absolutePath))) {
		risks.push({
			title: "Sensitive path",
			detail: absolutePath,
			blastRadius: "Can expose, corrupt, or overwrite secrets, credentials, tokens, or key material.",
		});
	}

	if (absolutePath.startsWith(`${HOME}${sep}`)) {
		const relativeToHome = absolutePath.slice(HOME.length + 1);
		if (homeConfigPatterns.some((pattern) => pattern.test(relativeToHome))) {
			risks.push({
				title: "Home configuration path",
				detail: absolutePath,
				blastRadius: "Can change user-level shell, app, or launch configuration.",
			});
		}
	}

	if (systemPrefixes.some((prefix) => absolutePath.startsWith(prefix))) {
		risks.push({
			title: "System path",
			detail: absolutePath,
			blastRadius: "Can change operating-system or global application files.",
		});
	}

	if (toolName === "write" && exists && !createdPaths.has(absolutePath)) {
		risks.push({
			title: "Overwrite existing file",
			detail: absolutePath,
			blastRadius: "The write tool replaces the full file contents. Existing data could be lost.",
		});
	}

	return { path: inputPath, absolutePath, exists, risks: dedupeRisks(risks) };
}

function dedupeRisks(risks: Risk[]): Risk[] {
	const seen = new Set<string>();
	return risks.filter((risk) => {
		const key = `${risk.title}\0${risk.detail}`;
		if (seen.has(key)) return false;
		seen.add(key);
		return true;
	});
}

function formatRiskPrompt(action: string, risks: Risk[]): string {
	const lines = [`Action: ${action}`, "", "Why confirmation is required:"];
	for (const risk of risks) {
		lines.push(`- ${risk.title}: ${risk.blastRadius}`);
	}
	lines.push("", "Exact target/command:", risks[0]?.detail ?? action, "", "Proceed?");
	return lines.join("\n");
}

async function confirmOrBlock(ctx: ExtensionContext, action: string, risks: Risk[]) {
	if (risks.length === 0) return undefined;

	if (!ctx.hasUI) {
		return {
			block: true,
			reason: `Guardrails blocked ${action}: ${risks.map((risk) => risk.title).join(", ")} (no UI for confirmation)`,
		};
	}

	const confirmed = await ctx.ui.confirm("Guardrails confirmation required", formatRiskPrompt(action, risks));
	if (!confirmed) {
		return { block: true, reason: `Guardrails blocked ${action}` };
	}

	return undefined;
}

async function confirmUserBash(ctx: ExtensionContext, command: string, risks: Risk[]) {
	const decision = await confirmOrBlock(ctx, `user bash command`, risks);
	if (!decision?.block) return undefined;

	return {
		result: {
			output: decision.reason,
			exitCode: 1,
			cancelled: false,
			truncated: false,
		},
	};
}

export default function (pi: ExtensionAPI) {
	const createdPaths = new Set<string>();
	const pendingCreates = new Map<string, string>();

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName === "bash") {
			const command = (event.input as { command?: unknown }).command;
			if (typeof command !== "string") return undefined;
			return confirmOrBlock(ctx, "bash tool command", classifyBash(command));
		}

		if (event.toolName !== "write" && event.toolName !== "edit") return undefined;

		const path = (event.input as { path?: unknown }).path;
		if (typeof path !== "string") return undefined;

		const check = classifyPathMutation(event.toolName, path, ctx.cwd, createdPaths);
		if (event.toolName === "write" && !check.exists) {
			pendingCreates.set(event.toolCallId, check.absolutePath);
		}

		return confirmOrBlock(ctx, `${event.toolName} ${path}`, check.risks);
	});

	pi.on("tool_result", (event) => {
		if (event.toolName !== "write") return undefined;

		const pendingPath = pendingCreates.get(event.toolCallId);
		pendingCreates.delete(event.toolCallId);
		if (pendingPath && !event.isError) {
			createdPaths.add(pendingPath);
		}

		return undefined;
	});

	pi.on("user_bash", async (event, ctx) => {
		return confirmUserBash(ctx, event.command, classifyBash(event.command));
	});

	pi.registerCommand("guardrails", {
		description: "Show Pi guardrails status",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) return;
			ctx.ui.notify("Guardrails are active for destructive bash, write/edit paths, user ! commands, git, publishing, package, and DB mutations.", "info");
		},
	});
}
