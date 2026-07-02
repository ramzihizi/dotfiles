#!/usr/bin/env bash
# UserPromptSubmit — anchor every turn to today's date + research-freshness
# policy, so "as of today" holds even deep into long sessions and after
# compaction (where the CLAUDE.md directive's pull fades).
today=$(date +%F)
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Today is %s. If this turn touches a fast-moving topic (AI models, tools, agents, pricing, news), research as of %s: web-search with recency qualifiers, prefer past-week sources, state the as-of date in the answer, and stamp this date into any subagent/worker prompts. Never answer such topics from training data alone."}}\n' "$today" "$today"
