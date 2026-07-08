#!/usr/bin/env python3
"""UserPromptSubmit hook — prompt-craft reminder.

Flags when RMH's own prompt matches one of the nine "DON'T SAY" vague stems
from raw/inbox/Prompt best practices.md (→ wiki concept: prompt-specificity)
and suggests the sharper rewrite. Non-blocking: it shows a systemMessage and
injects context, then always exits 0 so the request proceeds unchanged.

Guards against noise:
  - slash commands (/wiki:*, /model, ...) are skipped
  - only short prompts fire (vague asks are short; a detailed prompt is already specific)
  - prompts that already carry a specificity marker (a number, "ranked",
    "options", "keep my voice", "only", "assume the basics"...) are skipped
"""
import json
import re
import sys

# (compiled matcher, human label of the vague stem, sharper rewrite)
RULES = [
    (re.compile(r"^summari[sz]e (this|it|the following|that)\b"),
     "Summarize this", "Summarize this in 3 bullets I could act on today"),
    (re.compile(r"^explain\b"),
     "Explain X", "Explain X assuming I already know the basics"),
    (re.compile(r"\b(give me|gimme)( some)? ideas\b|^ideas\b"),
     "Give me ideas", "Give me 5 angles, ranked most to least obvious"),
    (re.compile(r"\bmake (it|this) better\b|^(improve|better) (it|this)\b"),
     "Make it better", "Improve the clarity and flow, keep my voice"),
    (re.compile(r"^what(\'s| is| are)\b.*\?*$"),
     "What is it?", "Break it down like you're teaching it to me"),
    (re.compile(r"\btips (for|on)\b|^tips\b"),
     "Tips for X", "Give me the 3 that actually move the needle"),
    (re.compile(r"\bmake (it|this) shorter\b|\bshorten (it|this)\b"),
     "Make it shorter", "Cut 30% without losing the main point"),
    (re.compile(r"\bwhat should i do\b"),
     "What should I do?", "Give me 3 options with the tradeoff of each"),
    (re.compile(r"\bfix (this|it)\b|^fix\b"),
     "Fix this", "Fix grammar and rhythm only, don't touch my structure"),
]

# If any of these already appear, the ask is specific enough — don't nag.
SPECIFIC_MARKERS = re.compile(
    r"\d|\branked?\b|\boptions?\b|\btrade-?offs?\b|\bkeep my\b|\bwithout losing\b"
    r"|\bonly\b|\bassum(e|ing)\b|\bstep[ -]by[ -]step\b|%|\bteaching\b|\bbullets?\b"
    r"|\bangles?\b|\bmove the needle\b"
)

MAX_WORDS = 12  # vague asks are short; longer prompts carry their own detail


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return  # no/garbled input → stay silent
    prompt = (data.get("prompt") or "").strip()
    if not prompt or prompt.startswith("/"):
        return
    norm = re.sub(r"\s+", " ", prompt.lower()).strip().strip('"\'`')
    if len(norm.split()) > MAX_WORDS or SPECIFIC_MARKERS.search(norm):
        return
    for rx, stem, rewrite in RULES:
        if rx.search(norm):
            out = {
                "systemMessage": (
                    f"\U0001f4a1 Prompt-craft: «{stem}» is vague — "
                    f"sharper: «{rewrite}». (non-blocking; from your prompt-craft cheat sheet)"
                ),
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": (
                        f"[prompt-craft reminder] The user's prompt matched the vague stem "
                        f"“{stem}” from their own prompt-craft cheat sheet "
                        f"([[sources/prompt-craft-cheat-sheet]] / [[concepts/prompt-specificity]]). "
                        f"A non-blocking reminder was shown suggesting: “{rewrite}”. "
                        f"Proceed with the request as given; if it is genuinely ambiguous, briefly "
                        f"confirm the sharper interpretation before doing heavy work."
                    ),
                },
            }
            print(json.dumps(out))
            return


if __name__ == "__main__":
    main()
