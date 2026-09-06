export const meta = {
  name: 'review-verify',
  description:
    'Review N surface units against a rubric with cheap describe-only agents, then re-verify every finding with expensive agents that read the code',
  whenToUse:
    'An audit or review over many units — screens, features, files — where findings will be acted on. Not for implementing the fixes: see the note at the bottom of this file.',
  phases: [
    { title: 'Review', detail: 'one describe-only agent per unit', model: 'sonnet' },
    { title: 'Verify', detail: 'two independent passes per finding', model: 'opus' },
  ],
}

// ---------------------------------------------------------------------------
// The allocation, and the measurements it comes from
// ---------------------------------------------------------------------------
//
// Measured on M100.42 (528 agents across 18 runs, this repo):
//
//   output       2,370,122
//   cache write     61,379,385
//   cache read   1,870,418,983   <-- 790x the output
//
// Two facts decided every number below.
//
// **Depth costs more than count.** Cache read grows close to quadratically with
// turns, because the agent at turn N re-reads turns 1..N-1. Twelve agents at
// 142 turns cost 268M; three hundred and fifty-one agents at 7.7 turns cost
// 316M. Across the whole run, 124 deep agents (>50 turns) took 66% of the cost
// and 386 shallow ones took 23%. So the lever is the turn cap, not the fan-out.
//
// **A stage whose output gets judged again can be cheap.** The 351-agent review
// pass produced a registry in which 50 of 105 actioned findings needed a
// corrected target and 10 were refuted outright. That pass did not need the
// expensive model — it needed to describe and to measure. The verify pass, which
// reads the code as it stands and issues the verdict that is acted on, is where
// the expensive model earns its place.
//
// Hence: REVIEW is sonnet/medium and forbidden from proposing fixes; VERIFY is
// opus/high and is the only stage whose output is final.

const REVIEW = { model: 'sonnet', effort: 'medium' }
const VERIFY = { model: 'opus', effort: 'high' }

/// The turn cap handed to every agent, in its own prompt.
///
/// Not enforceable by the runtime — it is a budget the agent is told to keep,
/// and the prompts are written so that keeping it is possible: everything an
/// agent needs is inlined, so it opens files to *check* rather than to *find*.
const REVIEW_TURNS = 12
const VERIFY_TURNS = 20

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['title', 'severity', 'dimension', 'problem', 'evidence'],
        properties: {
          title: { type: 'string' },
          severity: { type: 'string', enum: ['P0', 'P1', 'P2', 'P3'] },
          dimension: { type: 'string' },
          problem: { type: 'string' },
          // file:line plus a number that was read, not estimated.
          evidence: { type: 'string' },
          // What a comparable surface does instead, with its own file:line.
          sibling: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['verdict', 'reason'],
  properties: {
    verdict: {
      type: 'string',
      enum: [
        'CONFIRMED',
        'REVISED_TARGET',
        'NO_LONGER_REPRODUCIBLE',
        'REFUTED',
        'BLOCKED',
      ],
    },
    reason: { type: 'string' },
    // Required in substance when the verdict is REVISED_TARGET: which file,
    // which construct, which token.
    target: { type: 'string' },
    // Which frozen contract, when the verdict is BLOCKED.
    contract: { type: 'string' },
  },
}

// ---------------------------------------------------------------------------

if (!args || !Array.isArray(args.units) || !args.units.length) {
  throw new Error(
    'review-verify needs args: { units: [{key, label, files}], rubric: string, ' +
      'passes?: number, constraints?: string }',
  )
}

const RUBRIC = args.rubric || 'consistency with the rest of the app'
const CONSTRAINTS = args.constraints || ''
// Two independent passes is the default, and it is what caught the errors worth
// catching. A third pays for itself only when the verdict gates something
// irreversible.
const PASSES = args.passes || 2

function reviewPrompt(unit) {
  return `Review ONE surface unit and report what is wrong with it. Nothing else.

UNIT: ${unit.label}
FILES: ${unit.files}

RUBRIC: ${RUBRIC}

**Describe and measure. Do NOT propose a fix.** Half the proposed fixes in the
last audit of this kind had to be corrected before they could be applied, and
each wrong proposal cost two more agents to refute. Your job ends at "here is
the defect, here is the number I read, here is what a comparable surface does
instead". Somebody who can see the code as it stands at fix time decides the
target.

Every finding MUST carry:
- \`evidence\`: file:line plus a value you actually read — a token name, a
  measured dp, a resolved colour. "Looks inconsistent" is not evidence.
- \`sibling\`: the comparable surface that does it differently, with its own
  file:line. A finding with no sibling is usually taste, not inconsistency.

Report nothing you could not point at. An empty list is a valid answer.

BUDGET: about ${REVIEW_TURNS} tool calls. Read the files named above; do not go
exploring. If the unit is bigger than the budget, say so in a finding rather
than spending twice the budget.${CONSTRAINTS ? '\n\n' + CONSTRAINTS : ''}`
}

function verifyPrompt(unit, finding, pass) {
  return `Re-verify ONE finding against the code as it stands now. This is pass
${pass} of ${PASSES}; another agent is doing the same finding independently.
Do not assume the finding is right.

UNIT: ${unit.label}
FILES: ${unit.files}

THE FINDING, IN FULL — everything you need is here, so open files to CHECK it,
not to FIND it:
  title:     ${finding.title}
  severity:  ${finding.severity}
  dimension: ${finding.dimension}
  problem:   ${finding.problem}
  evidence:  ${finding.evidence}
  sibling:   ${finding.sibling || '(none given)'}

Line numbers in the evidence are from an older commit and have drifted. Locate
the code by its content.

Reach ONE verdict:
- CONFIRMED — reproduces, and the obvious fix is right.
- REVISED_TARGET — real, but the obvious fix is wrong, overreaching, or would
  make things worse. Say precisely what the corrected target is: which file,
  which construct, which token.
- NO_LONGER_REPRODUCIBLE — a later change already closed it.
- REFUTED — not a defect. **Look for this shape first:** the finding cites a
  source to justify itself and that source says the opposite — a doc comment
  recording the thing it calls drift as a deliberate trade, metadata forbidding
  the change by name, an active spec that already decided it. That was the most
  common refutation in the last audit, by a wide margin.
- BLOCKED — fixing it needs a change to something this task may not touch. Name
  the contract.

BUDGET: about ${VERIFY_TURNS} tool calls.${CONSTRAINTS ? '\n\n' + CONSTRAINTS : ''}`
}

/// Picks one verdict when the passes disagree.
///
/// **Plain code, not an agent.** A third model asked to break a tie is a third
/// opinion, not an adjudication, and it costs a full agent to produce.
///
/// The order encodes one rule: prefer the verdict that carries more information
/// about the code. A pass that revised the target read something the confirming
/// pass did not, and it never discards a real defect — it only changes what to
/// do about it. BLOCKED and REFUTED outrank both because each is a claim that
/// acting at all would be wrong.
const RANK = {
  BLOCKED: 5,
  REFUTED: 4,
  NO_LONGER_REPRODUCIBLE: 3,
  REVISED_TARGET: 2,
  CONFIRMED: 1,
}

function adjudicate(votes) {
  const live = votes.filter(Boolean)
  if (!live.length) return null
  return live.reduce((a, b) => (RANK[b.verdict] > RANK[a.verdict] ? b : a))
}

phase('Review')
log(`${args.units.length} units · review ${REVIEW.model}/${REVIEW.effort} · verify ${VERIFY.model}/${VERIFY.effort} × ${PASSES}`)

// pipeline, not parallel: a unit's findings go to verification the moment that
// unit is reviewed, instead of every unit waiting on the slowest reviewer.
const perUnit = await pipeline(
  args.units,
  (unit) =>
    agent(reviewPrompt(unit), {
      label: `review:${unit.key}`,
      phase: 'Review',
      schema: FINDINGS_SCHEMA,
      ...REVIEW,
    }),
  (review, unit) =>
    parallel(
      (review ? review.findings : []).flatMap((finding) =>
        Array.from({ length: PASSES }, (_, i) => () =>
          agent(verifyPrompt(unit, finding, i + 1), {
            label: `verify:${unit.key}:${finding.title.slice(0, 32)}#${i + 1}`,
            phase: 'Verify',
            schema: VERDICT_SCHEMA,
            ...VERIFY,
          }).then((v) => ({ unit: unit.key, finding, pass: i + 1, ...(v || {}) })),
        ),
      ),
    ),
)

// Regroup the flat verdict stream back onto its findings, then adjudicate.
const byFinding = new Map()
for (const row of perUnit.flat().filter(Boolean)) {
  if (!row.verdict) continue
  const key = `${row.unit}::${row.finding.title}`
  if (!byFinding.has(key)) byFinding.set(key, { ...row.finding, unit: row.unit, votes: [] })
  byFinding.get(key).votes.push({ verdict: row.verdict, reason: row.reason, target: row.target, contract: row.contract })
}

const results = []
for (const entry of byFinding.values()) {
  const chosen = adjudicate(entry.votes)
  results.push({
    unit: entry.unit,
    title: entry.title,
    severity: entry.severity,
    dimension: entry.dimension,
    problem: entry.problem,
    evidence: entry.evidence,
    verdict: chosen ? chosen.verdict : 'UNVERIFIED',
    reason: chosen ? chosen.reason : 'every verification pass died',
    target: chosen ? chosen.target : undefined,
    contract: chosen ? chosen.contract : undefined,
    disputed: new Set(entry.votes.map((v) => v.verdict)).size > 1,
  })
}

const tally = {}
for (const r of results) tally[r.verdict] = (tally[r.verdict] || 0) + 1
log(`${results.length} findings · ${Object.entries(tally).map(([k, v]) => `${k} ${v}`).join(' · ')}`)

const disputed = results.filter((r) => r.disputed).length
if (disputed) log(`${disputed} disputed between passes — adjudicated by rank, see \`disputed: true\``)

return { findings: results, tally }

// ---------------------------------------------------------------------------
// What this template deliberately does NOT do: implement the fixes
// ---------------------------------------------------------------------------
//
// There is no third phase, and that is a measurement rather than an omission.
//
// In M100.42 the five `implement-c*` workflows delegated "read → edit → run
// tests → fix → re-run" to subagents. Those agents averaged 90 to 143 turns
// each and cost 818M cache read between them — more than the 351-agent review
// pass and the whole verification pass put together. The three clusters done in
// the main loop instead (C7, C8, C9) cost zero subagent tokens and came out no
// worse; the three worst defects of the whole series were caught by the golden
// job and the emulator, not by any agent.
//
// An edit-and-test loop belongs in the main loop, where the context is cached
// across turns instead of being rebuilt inside every agent. Take this
// workflow's output, and do the work.
