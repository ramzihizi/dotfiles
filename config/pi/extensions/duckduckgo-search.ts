import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

function decodeHtml(input: string): string {
	return input
		.replace(/&amp;/g, "&")
		.replace(/&quot;/g, '"')
		.replace(/&#x27;/g, "'")
		.replace(/&#39;/g, "'")
		.replace(/&lt;/g, "<")
		.replace(/&gt;/g, ">")
		.replace(/&#(\d+);/g, (_match, code) => String.fromCharCode(Number(code)))
		.replace(/&#x([0-9a-fA-F]+);/g, (_match, code) => String.fromCharCode(parseInt(code, 16)));
}

function stripHtml(input: string): string {
	return decodeHtml(input.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim());
}

function normalizeDuckDuckGoUrl(href: string): string {
	let decoded = decodeHtml(href);

	if (decoded.startsWith("//")) decoded = `https:${decoded}`;
	if (decoded.startsWith("/")) decoded = `https://duckduckgo.com${decoded}`;

	try {
		const url = new URL(decoded);
		const target = url.searchParams.get("uddg");
		if (target) return decodeURIComponent(target);
		return decoded;
	} catch {
		return decoded;
	}
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Search the web using DuckDuckGo HTML results. No API key required. Results may be rate-limited or break if DuckDuckGo changes its HTML.",
		promptSnippet: "Search the public web using DuckDuckGo.",
		promptGuidelines: [
			"Use web_search when the user asks for current, recent, or internet-sourced information.",
			"Cite URLs returned by web_search when using web information.",
		],
		parameters: Type.Object({
			query: Type.String({ description: "Search query" }),
			count: Type.Optional(Type.Number({ description: "Number of results, default 5, max 10" })),
		}),

		async execute(_toolCallId, params, signal) {
			const count = Math.min(Math.max(params.count ?? 5, 1), 10);
			const searchUrl =
				"https://html.duckduckgo.com/html/?" + new URLSearchParams({ q: params.query }).toString();

			const response = await fetch(searchUrl, {
				signal,
				headers: {
					"User-Agent": "Mozilla/5.0 (compatible; pi-coding-agent; +https://pi.dev)",
					Accept: "text/html",
				},
			});

			if (!response.ok) {
				throw new Error(`DuckDuckGo search failed: ${response.status} ${response.statusText}`);
			}

			const html = await response.text();
			const results: Array<{ title: string; url: string; snippet: string }> = [];

			const blockRegex = /<div[^>]+class="[^"]*result[^"]*"[\s\S]*?(?=<div[^>]+class="[^"]*result[^"]*"|<\/body>)/g;
			const blocks = html.match(blockRegex) ?? [];

			for (const block of blocks) {
				const linkMatch = block.match(
					/<a[^>]+class="[^"]*result__a[^"]*"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/,
				);
				if (!linkMatch) continue;

				const snippetMatch = block.match(
					/<a[^>]+class="[^"]*result__snippet[^"]*"[^>]*>([\s\S]*?)<\/a>/,
				);

				results.push({
					title: stripHtml(linkMatch[2] ?? ""),
					url: normalizeDuckDuckGoUrl(linkMatch[1] ?? ""),
					snippet: snippetMatch ? stripHtml(snippetMatch[1] ?? "") : "",
				});

				if (results.length >= count) break;
			}

			if (results.length === 0) {
				return {
					content: [{ type: "text" as const, text: "No DuckDuckGo results found." }],
					details: { query: params.query, results: [] },
				};
			}

			const text = results
				.map((result, index) => `${index + 1}. ${result.title}\n${result.url}\n${result.snippet}`)
				.join("\n\n");

			return {
				content: [{ type: "text" as const, text }],
				details: { query: params.query, results },
			};
		},
	});
}
