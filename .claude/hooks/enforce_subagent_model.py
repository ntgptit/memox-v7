#!/usr/bin/env python3
"""Force every subagent onto Sonnet, and refuse workflow scripts that do not pin it.

Why this is a hook and not a setting: the Claude Code settings schema has no
subagent-model key. `model` sets the main thread; agent frontmatter only covers
named agent types; and Workflow's `agent()` calls inherit the *main-loop* model,
which is how a design pass once cost 5.05M Opus tokens. A PreToolUse hook is the
only place that sees every subagent spawn before it happens.

Two gates, one per tool:

  Agent     -> rewrite the call's `model` to sonnet via updatedInput. Silent,
               unconditional, and it covers agent types this repo does not own
               (plugin agents that declare `model: opus`, or declare nothing and
               therefore inherit).

  Workflow  -> a JS script cannot be rewritten safely by regex, so this refuses
               instead: every `agent(...)` call in the script must carry an
               explicit `model:` and `effort:` in its options object. Refusing
               teaches the right script; rewriting would corrupt it.

Reads the hook payload on stdin, writes one JSON object on stdout.
"""

import json
import re
import sys

REQUIRED_MODEL = "sonnet"

# `agent(` but not `subagent(`, `myAgent(`, `x.agent(`.
AGENT_CALL = re.compile(r"(?<![A-Za-z0-9_$.])agent\s*\(")

OPEN_TO_CLOSE = {"(": ")", "[": "]", "{": "}"}


def emit(payload):
    json.dump(payload, sys.stdout)
    sys.stdout.write("\n")
    sys.exit(0)


def allow():
    emit({})


def call_span(script, start):
    """Return the text of the agent(...) call beginning at `start`.

    Walks the source tracking paren depth, skipping string and template
    literals, so a `)` inside a prompt does not end the call early. Returns
    None when the call is unterminated (a truncated or malformed script).
    """
    depth = 0
    index = start
    length = len(script)
    while index < length:
        char = script[index]

        if char in "\"'`":
            quote = char
            index += 1
            while index < length:
                if script[index] == "\\":
                    index += 2
                    continue
                if script[index] == quote:
                    break
                index += 1
            index += 1
            continue

        if char in OPEN_TO_CLOSE:
            depth += 1
        elif char in ")]}":
            depth -= 1
            if depth == 0:
                return script[start : index + 1]

        index += 1
    return None


def mask_literals(script):
    """Blank out string/template/comment bodies, preserving length and newlines.

    Call sites are found on the masked text so that prose mentioning "agent("
    — in a meta description, a prompt, or a comment — is not mistaken for a
    call. Found by the guard's own liveness probe, whose meta.description
    contained the words "agent() call" and was reported as a second call site.
    """
    out = list(script)
    index = 0
    length = len(script)
    while index < length:
        char = script[index]

        if char == "/" and index + 1 < length and script[index + 1] in "/*":
            block = script[index + 1] == "*"
            end = script.find("*/", index + 2) if block else script.find("\n", index)
            end = length if end == -1 else (end + 2 if block else end)
            for position in range(index, end):
                if out[position] != "\n":
                    out[position] = " "
            index = end
            continue

        if char in "\"'`":
            quote = char
            index += 1
            while index < length:
                if script[index] == "\\":
                    out[index] = out[min(index + 1, length - 1)] = " "
                    index += 2
                    continue
                if script[index] == quote:
                    break
                if out[index] != "\n":
                    out[index] = " "
                index += 1
            index += 1
            continue

        index += 1
    return "".join(out)


def call_sites(script):
    """Return one record per agent() call: line, label, model, effort, missing keys."""
    masked = mask_literals(script)
    sites = []
    for match in AGENT_CALL.finditer(masked):
        span = call_span(script, match.end() - 1)
        if span is None:
            continue
        masked_span = mask_literals(span)
        missing = [key for key in ("model", "effort") if not re.search(r"\b%s\s*:" % key, masked_span)]
        sites.append(
            {
                "line": script.count("\n", 0, match.start()) + 1,
                "label": literal_after(span, masked_span, "label") or "-",
                "model": literal_after(span, masked_span, "model"),
                "effort": literal_after(span, masked_span, "effort"),
                "missing": missing,
            }
        )
    return sites


def literal_after(span, masked_span, key):
    """Read a quoted literal value for `key`, or <dynamic> when it is an expression.

    The key is located on the masked span so a `model:` inside a prompt string is
    not mistaken for the option; the value is read from the real span.
    """
    found = re.search(r"\b%s\s*:" % key, masked_span)
    if not found:
        return None
    tail = span[found.end() :]
    literal = re.match(r"\s*(['\"])(.*?)\1", tail)
    if literal:
        return literal.group(2)
    return "<dynamic>"


def fanout_constructs(script):
    """Names of fan-out helpers present, which make the real agent count dynamic."""
    masked = mask_literals(script)
    return [name for name in ("parallel", "pipeline") if re.search(r"\b%s\s*\(" % name, masked)]


def unpinned_calls(script):
    return [(site["line"], site["missing"]) for site in call_sites(script) if site["missing"]]


def read_script(tool_input):
    inline = tool_input.get("script")
    if inline:
        return inline, None
    path = tool_input.get("scriptPath")
    if not path:
        return None, None
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read(), path
    except OSError as error:
        return None, "unreadable: %s" % error


def gate_agent(tool_input):
    if tool_input.get("model") == REQUIRED_MODEL:
        allow()
    updated = dict(tool_input)
    updated["model"] = REQUIRED_MODEL
    emit(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "updatedInput": updated,
            }
        }
    )


def gate_workflow(tool_input):
    script, note = read_script(tool_input)
    if script is None:
        # A saved workflow invoked by name has no script to inspect here.
        allow()

    sites = call_sites(script)
    if not sites:
        allow()

    findings = [(site["line"], site["missing"]) for site in sites if site["missing"]]
    if findings:
        lines = ", ".join(
            "line %d (missing %s)" % (line, " and ".join(keys)) for line, keys in findings[:8]
        )
        more = "" if len(findings) <= 8 else " and %d more" % (len(findings) - 8)
        where = " in %s" % note if note else ""
        emit(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": (
                        "Blocked: %d agent() call(s)%s do not pin model and effort — %s%s. "
                        "Workflow agents inherit the main-loop model, so an unpinned call runs on "
                        "Opus. Give every agent() an explicit "
                        "{model: 'sonnet', effort: 'low'|'medium'|'high'|'max'} and re-run. "
                        "Effort tiers are in CLAUDE.md under 'Subagent model and effort'."
                    )
                    % (len(findings), where, lines, more),
                }
            }
        )

    # The approval popup shows meta.description and nothing else — confirmed from a
    # screenshot of the prompt on 2026-09-09, where permissionDecisionReason was not
    # rendered at all. So the spend summary has to live in the description, or the
    # owner approves blind. Checked after the pin check, because an unpinned call is
    # the more fundamental error and its message is the more actionable one.
    described = description_of(script)
    if described is not None and not re.search(r"\d+\+?\s*agent", described, re.IGNORECASE):
        emit(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": (
                        "meta.description must state the spend: the approval popup shows that "
                        "field and nothing else — not this text. Current: %r. Use: %r"
                    )
                    % (described[:80], description_line(sites, script)),
                }
            }
        )

    # `ask` is the switch: the owner sees the manifest and approves or refuses
    # before a single agent spawns. Verified live on 2026-09-09 — a probe workflow
    # was refused at the prompt and never ran.
    #
    # It needs `permissions.ask: ["Workflow"]` in .claude/settings.json to fire while
    # the session runs in `defaultMode: bypassPermissions`. Two earlier probes went
    # straight through and briefly looked like proof that the mode swallows `ask`;
    # they had simply run seconds after that rule was written, before the settings
    # watcher reloaded. If a prompt ever stops appearing, suspect the reload before
    # the mechanism, and check that the rule is still present.
    #
    # `systemMessage` carries the same text so the manifest is visible even where a
    # prompt is not shown. That half is an announcement, not consent — the two are
    # named separately here so nobody later mistakes one for the other.
    summary = manifest(sites, script)
    emit(
        {
            "systemMessage": summary,
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "ask",
                "permissionDecisionReason": summary,
            },
        }
    )


# Measured on this machine: one subagent replying with two words cost 68 567
# tokens. That is the fixed floor per spawn — system prompt, context and tool
# schemas — before the agent does any work at all.
FLOOR_TOKENS_PER_AGENT = 68_000

# The owner set this on 2026-09-09: below it Claude picks model and effort alone;
# at or above it, or on any fan-out or non-sonnet run, the choice must be offered
# with AskUserQuestion before Workflow is called at all.
ASK_THRESHOLD_TOKENS = 300_000


def description_of(script):
    """The meta.description literal, or None when it is absent or an expression."""
    masked = mask_literals(script)
    found = re.search(r"\bdescription\s*:", masked)
    if not found:
        return None
    literal = re.match(r"\s*(['\"])(.*?)\1", script[found.end() :], re.DOTALL)
    return literal.group(2) if literal else None


def description_line(sites, script):
    """The one-line spend summary the approval popup should show."""
    efforts = sorted({site["effort"] for site in sites if site["effort"]})
    models = sorted({site["model"] for site in sites if site["model"]})
    fanout = fanout_constructs(script)
    plural = "" if len(sites) == 1 else "s"
    count = ("%d+ agent%s (fans out)" % (len(sites), plural)) if fanout else ("%d agent%s" % (len(sites), plural))
    return "%s · %s · effort %s · floor ~%.1fM tok — <what it does>" % (
        count,
        "/".join(models) or "?",
        "/".join(efforts) or "?",
        len(sites) * FLOOR_TOKENS_PER_AGENT / 1_000_000.0,
    )


def manifest(sites, script):
    """The confirmation text: what will run, on what, and what it costs at minimum."""
    rows = [
        "  line %-4d %-26s model=%-10s effort=%s"
        % (site["line"], site["label"][:26], site["model"], site["effort"])
        for site in sites[:12]
    ]
    if len(sites) > 12:
        rows.append("  ... and %d more call sites" % (len(sites) - 12))

    fanout = fanout_constructs(script)
    if fanout:
        count = (
            "%d call site(s), but %s fan out over a list — the REAL agent count is decided at "
            "run time and can be many times higher (a 4-site script once spawned 28 agents)."
            % (len(sites), "/".join(fanout))
        )
        floor = "at least %d x ~%dk = ~%.1fM tokens, and more per item fanned out" % (
            len(sites),
            FLOOR_TOKENS_PER_AGENT // 1000,
            len(sites) * FLOOR_TOKENS_PER_AGENT / 1_000_000.0,
        )
    else:
        count = "%d agent(s), no fan-out construct found — the count is fixed." % len(sites)
        floor = "~%.2fM tokens floor (%d x ~%dk)" % (
            len(sites) * FLOOR_TOKENS_PER_AGENT / 1_000_000.0,
            len(sites),
            FLOOR_TOKENS_PER_AGENT // 1000,
        )

    non_sonnet = sorted({site["model"] for site in sites if site["model"] != "sonnet"})
    warning = ""
    if non_sonnet:
        warning = "\n  !! non-sonnet model requested: %s" % ", ".join(non_sonnet)

    # The owner's standing rule (CLAUDE.md): below the threshold Claude decides
    # alone; at or above it, Claude must offer the choice with AskUserQuestion
    # BEFORE calling Workflow. Nothing can prove that happened, so the next best
    # thing is to say plainly that it should have — if the owner sees this line on
    # a prompt they were never asked about, the rule was skipped.
    triggers = []
    if len(sites) * FLOOR_TOKENS_PER_AGENT >= ASK_THRESHOLD_TOKENS:
        triggers.append("floor >= %dk" % (ASK_THRESHOLD_TOKENS // 1000))
    if fanout:
        triggers.append("fan-out of unknown size")
    if non_sonnet:
        triggers.append("non-sonnet model")
    if triggers:
        warning += (
            "\n  !! ABOVE THE ASK-THRESHOLD (%s) — you should have been offered the "
            "model/effort choice before this prompt. If you were not, say so." % ", ".join(triggers)
        )

    return "Confirm subagent spend before this workflow runs.\n%s\n\n%s\nFloor cost: %s%s" % (
        "\n".join(rows),
        count,
        floor,
        warning,
    )


def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        allow()

    tool_name = payload.get("tool_name")
    tool_input = payload.get("tool_input") or {}

    if tool_name == "Agent":
        gate_agent(tool_input)
    if tool_name == "Workflow":
        gate_workflow(tool_input)
    allow()


if __name__ == "__main__":
    main()
