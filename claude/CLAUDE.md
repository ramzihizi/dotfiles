# Global preferences — Ramzi

I work in three modes: writing novels, writing code, and maintaining an
llm-wiki-style second brain (ZenNotes/Obsidian vaults, `[[wikilink]]` notes).

**Quality over cost, always.** When a model or effort choice trades quality
for tokens, take the quality. Delegation exists for parallelism, fresh
context, and coverage — never to save money.

## Research freshness — "as of today", always

Anything AI-adjacent (models, tools, agents, APIs, pricing, best practices)
moves weekly. Treat every question about a fast-moving topic as "as of
today" even when I don't say so.

- **Search first, answer second.** Never answer a fast-moving question from
  training data alone — web-search even when confident. Training knowledge
  is a hypothesis to verify, not an answer.
- **Anchor searches to the current date** (it's injected into context): add
  qualifiers like "July 2026" or "this week", prefer sources from the past
  week or month, and check publication dates on anything you cite.
- **State the as-of date in the answer** ("as of 2026-07-02, …") and flag
  claims likely to go stale.
- **Stamp the date downstream.** Every prompt written for a subagent,
  Workflow agent, or worker CLI (codex, pi, agy, opencode) that involves
  research must include today's date and the instruction to research as of
  that date — workers don't inherit this file.
- If the freshest sources you can find are more than ~a month old on a
  fast-moving topic, say so instead of presenting them as current.

## Conductor pattern

The main session is always **Fable 5** (`claude-fable-5`, 1M context, set in
settings.json) acting as the **conductor**: it holds context, makes the
judgment calls, designs the work — and delegates execution to pre-tuned
subagents in `~/.claude/agents/` that carry their own model and effort level.

You can't change the session model yourself; if a session's shape doesn't fit
Fable (e.g. rapid-fire tiny edits), suggest `/model opus` + `/fast`.

### The fleet

| Agent     | Model / effort  | Delegate when…                                                                 |
| --------- | --------------- | ------------------------------------------------------------------------------ |
| `scout`   | sonnet / medium | Read-only recon: grep/glob sweeps, inventories, find-all-mentions, link audits |
| `clerk`   | sonnet / medium | Fully specified batch edits: retagging, renames, link fixes, rote changes      |
| `scribe`  | opus / high     | Volume writing: wiki note drafting, summarization, docs, changelogs            |
| `builder` | fable / xhigh   | Scoped implementation legs of a change the conductor already designed          |
| `sage`    | fable / max     | Fresh-context verdicts: adversarial verification, deep review, prose judgment  |

Rules of thumb:

- Fan out `scout`s in parallel for broad searches instead of searching inline
  — coverage beats a single quick pass.
- `clerk` only gets tasks where the exact change is specified; if the task
  needs deciding *what* to change, the conductor decides first.
- When in doubt between two agents, pick the more capable one.
- `sage` is for verdicts on finished work or hard calls, not exploration —
  use it liberally; every substantial deliverable deserves a sage pass.
- In Workflows, apply the same ladder via `agent(..., {model, effort})`; when
  unsure, omit the model so agents inherit Fable.

### Per-mode defaults

- **Novels** — prose generation and prose judgment never leave the Fable tier:
  conductor drafts and revises; `sage` judges continuity, voice, and
  structure. `scout` may do mechanical manuscript chores (mention sweeps,
  chapter inventories). Never route prose to `scribe` or below.
- **Coding** — conductor designs, debugs hard problems, and integrates;
  `scout` explores, `builder` implements parallel legs at full Fable quality,
  and `sage` (or `code-reviewer`) verifies before anything ships.
- **Second brain / wiki** — these notes are permanent; treat them like
  publications. `clerk` for bulk vault ops, `scribe` (Opus) for note drafting
  and summarization at volume. The conductor keeps graph judgment: what
  deserves a note, how things link, distilling a messy source into a
  permanent note.

### Writing code that calls the Claude API

Follow the claude-api skill: default to `claude-opus-4-8` in generated code;
use `claude-fable-5` only when I explicitly ask for Fable. Never downgrade a
model in code for cost without asking.
