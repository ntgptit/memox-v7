# Workflow templates

Scripts here are invocable by name: `Workflow({name: 'review-verify', args: {...}})`.

## Why this directory exists

M100.42 ran 528 subagents across 18 workflows. The measured cost:

| | tokens |
|---|---|
| output | 2,370,122 |
| cache write | 61,379,385 |
| **cache read** | **1,870,418,983** |

Cache read is 790× the output, which means the cost is not what the agents
*wrote* — it is 528 agents each dragging a context through many turns. Every
number in `review-verify.js` follows from two things that measurement showed.

**Depth costs more than count.** An agent at turn N re-reads turns 1…N-1, so
cache read grows close to quadratically with turns. Twelve agents at 142 turns
cost 268M; three hundred and fifty-one agents at 7.7 turns cost 316M — nearly
the same money for twenty-nine times fewer agents.

| run | agents | turns/agent | cache read |
|---|---|---|---|
| review pass | 351 | 7.7 | 316M |
| implement C3 | 26 | 90.4 | 284M |
| implement C4 | 12 | 142.6 | 268M |
| implement C5+C6 | 6 | 116.3 | 106M |

Across the whole series, **124 deep agents (>50 turns) took 66% of the cost and
386 shallow ones took 23%.** So the lever is the turn cap, not the fan-out.

**A stage whose output is judged again can be cheap.** The 351-agent review pass
produced a registry in which 50 of 105 actioned findings needed a corrected
target and 10 were refuted. That pass did not need the expensive model — it
needed to describe and to measure.

## The allocation

| stage | model | effort | why |
|---|---|---|---|
| describe / measure | `sonnet` | `medium` | its output is re-judged downstream |
| adversarial verdict | `opus` | `high` | its output is acted on |
| extract / count / regroup | — | — | plain code, not an agent |

Omitting `model` inherits the session model. That is how 528 agents came to run
on Opus without anyone choosing it, so pass it explicitly in every `agent()`
call — including the cheap ones, where the explicit `sonnet` is the point.

## What does not belong in a workflow

**An edit-and-test loop.** The five `implement-c*` workflows delegated
"read → edit → run tests → fix → re-run" to subagents; they averaged 90–143
turns each and cost 818M cache read between them. The three clusters done in the
main loop instead — C7, C8, C9 — cost zero subagent tokens and came out no
worse. The three worst defects of the whole series were caught by the golden job
and the emulator, not by any agent.

The main loop keeps its context cached across turns; a subagent rebuilds one.
Fan out to *find* and to *judge*; do the work yourself.
