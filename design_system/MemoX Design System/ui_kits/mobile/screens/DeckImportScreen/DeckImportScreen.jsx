/* MemoX Mobile — DeckImportScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     DeckImportScreen/
       DeckImportScreen.jsx  ← the shared multi-step flow + result screens
       states/               ← one file per state in window.MemoXStates.DeckImport

   Import is a 3-step flow (source → preview → import) plus three terminal result
   screens. All nine states share one layout, so splitting the markup per state
   would duplicate the flow many times. Instead each state file declares a small
   descriptor:
     flow states  → { kind:'flow', fileChosen, parsing, preview:'all'|'mix'|null, importing }
     result states→ { kind:'result', result:'success'|'partial'|'failed' }
   and the MAIN file renders the shared layout / result branch from it. Editing one
   state file changes only that state. */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

const rowsAll = [
  { front: '연구자', back: 'researcher', ok: true },
  { front: '공부하다', back: 'to study', ok: true },
  { front: '도서관', back: 'library, reading room', ok: true },
  { front: '친구', back: 'friend, close companion', ok: true },
  { front: '바다', back: 'sea, ocean', ok: true }
];
const rowsMix = [
  { front: '연구자', back: 'researcher', ok: true },
  { front: '공부하다', back: '', err: 'Missing meaning' },
  { front: '도서관', back: 'library, reading room', ok: true },
  { front: '', back: 'sky', err: 'Missing term' },
  { front: '친구', back: 'friend, close companion', dup: 'Already in this deck' },
  { front: '바다', back: 'sea, ocean', ok: true },
  { front: '영화', back: 'movie / film', ok: true }
];

const Spinner = window.Spinner;

const RESULT_CFG = {
  success: { icon: 'check-circle-2', title: 'Import complete', body: 'Added 47 cards to TOPIK II — Vocab. They are ready to study.', bg: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', color: 'var(--memox-mastery)', bd: 'color-mix(in srgb, var(--memox-mastery) 22%, transparent)' },
  partial: { icon: 'alert-triangle', title: 'Imported with skips', body: 'Added 42 cards. 5 rows were skipped because of validation issues.', bg: 'color-mix(in srgb, var(--memox-streak) 10%, transparent)', color: 'var(--memox-streak)', bd: 'color-mix(in srgb, var(--memox-streak) 22%, transparent)' },
  failed: { icon: 'alert-circle', title: 'Import didn’t finish', body: 'No cards were added. Your file is unchanged and your deck is untouched.', bg: 'color-mix(in srgb, var(--memox-danger) 8%, transparent)', color: 'var(--memox-error)', bd: 'color-mix(in srgb, var(--memox-danger) 22%, transparent)' }
};

/* Terminal result screen (success / partial / failed). */
function ResultScreen({ go, result }) {
  const cfg = RESULT_CFG[result];
  return (
    <div className="app">
      <StatusBar />
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('cards')}>
          <Ic name="x" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>Import results</div>
      </div>
      <div className="scroll" style={{ paddingTop: 20 }}>
        <div className="card" style={{ padding: '24px 24px', textAlign: 'center', marginBottom: 16, background: cfg.bg, border: `1px solid ${cfg.bd}` }}>
          <div style={{ width: 64, height: 64, borderRadius: 20, background: `${cfg.color}24`, color: cfg.color, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
            <Ic name={cfg.icon} size="lg" color={cfg.color} />
          </div>
          <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 8 }}>{cfg.title}</div>
          <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55 }}>{cfg.body}</div>
        </div>

        {result !== 'failed' &&
          <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
            {[
              { l: 'Added', v: result === 'success' ? 47 : 42, c: 'var(--memox-mastery)', ic: 'check' },
              result === 'partial' ? { l: 'Skipped — missing fields', v: 3, c: 'var(--memox-error)', ic: 'alert-circle' } : null,
              result === 'partial' ? { l: 'Skipped — duplicates', v: 2, c: 'var(--memox-streak)', ic: 'copy' } : null
            ].filter(Boolean).map((r, i, a) =>
              <div key={r.l} style={{ display: 'grid', gridTemplateColumns: '28px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
                <div style={{ width: 24, height: 24, borderRadius: 8, background: `${r.c}1F`, color: r.c, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Ic name={r.ic} size="xs" color={r.c} />
                </div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{r.l}</div>
                <div style={{ fontSize: 14, fontWeight: 700, color: r.c, fontVariantNumeric: 'tabular-nums' }}>{r.v}</div>
              </div>
            )}
          </div>}

        {result === 'partial' &&
          <div style={{ padding: '8px 12px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
            <Ic name="info" size="xs" color="var(--memox-on-surface-variant)" />
            <span>Fix the skipped rows in your source file and import again to add them.</span>
          </div>}
      </div>
      <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14 }}>{result === 'failed' ? 'Close' : 'Back to deck'}</button>
        <button className="pill-btn primary" style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8 }}>
          {result === 'failed' ? <><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" /> Try again</> : <><Ic name="layers" size="xs" color="var(--memox-on-primary)" /> View imported cards</>}
        </button>
      </div>
    </div>);
}

/* ════════════ SCREEN ════════════ */
function DeckImportScreen({ go, state = 'empty' }) {
  const States = (window.MemoXStates && window.MemoXStates.DeckImport) || {};
  const mod = States[state] || States.empty;
  const cfg = (mod ? mod() : {}) || {};

  if (cfg.kind === 'result') return <ResultScreen go={go} result={cfg.result} />;

  const { fileChosen = false, parsing = false, preview = null, importing = false } = cfg;
  const isPreview = preview === 'all' || preview === 'mix';
  const rows = preview === 'all' ? rowsAll : rowsMix;
  const validCount = rows.filter((r) => r.ok).length;
  const invalidCount = rows.filter((r) => r.err).length;
  const duplicateCount = rows.filter((r) => r.dup).length;

  return (
    <div className="app">
      <StatusBar />

      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('cards')}>
          <Ic name="x" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>Import cards</div>
        <button className="icon-btn" title="Help">
          <Ic name="help-circle" size="sm" color="var(--memox-on-surface-variant)" />
        </button>
      </div>

      <Breadcrumb segments={[{ label: 'Library' }, { label: 'Korean' }, { label: 'TOPIK II — Vocab' }, { label: 'Import' }]} />

      <div className="scroll">

        {/* Step tracker */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
          {[
            { n: 1, label: 'Source', done: fileChosen || isPreview || importing },
            { n: 2, label: 'Preview', done: isPreview || importing, current: parsing || isPreview },
            { n: 3, label: 'Import', current: importing }
          ].map((s, i, a) =>
            <React.Fragment key={s.n}>
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 600, color: s.done || s.current ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)', opacity: s.done || s.current ? 1 : 0.6 }}>
                <span style={{ width: 20, height: 20, borderRadius: 999, background: s.done ? 'var(--memox-mastery)' : s.current ? 'var(--memox-primary)' : 'var(--memox-surface-container)', color: s.done || s.current ? 'var(--memox-on-primary)' : 'var(--memox-on-surface-variant)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 700 }}>
                  {s.done ? <Ic name="check" size="xs" color="var(--memox-on-primary)" /> : s.n}
                </span>
                {s.label}
              </div>
              {i < a.length - 1 && <div style={{ flex: 1, height: 2, borderRadius: 999, background: a[i].done ? 'var(--memox-mastery)' : 'var(--memox-surface-container)' }} />}
            </React.Fragment>
          )}
        </div>

        {/* Deck destination */}
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '4px 12px 4px 8px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 999, fontSize: 12, fontWeight: 600, marginBottom: 16 }}>
          <span style={{ width: 22, height: 22, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
            <Ic name="layers" size="xs" color="var(--memox-primary)" />
          </span>
          <span>TOPIK II — Vocab · 142 cards</span>
        </div>

        {/* Step 1: source picker */}
        <div className="ov" style={{ padding: '0 4px 8px' }}>1 · Choose a source</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 16 }}>
          {[
            { id: 'file', ic: 'file-up', label: 'Upload file', sub: 'CSV, TSV, Anki' },
            { id: 'paste', ic: 'clipboard', label: 'Paste text', sub: 'TSV or CSV rows' }
          ].map((s) => {
            const active = s.id === 'file';
            return (
              <button key={s.id} style={{ padding: '16px 12px', background: active ? 'color-mix(in srgb, var(--memox-primary) 6%, transparent)' : 'var(--memox-surface-container-lowest)', border: active ? '1px solid var(--memox-primary)' : 'var(--memox-border-ghost)', borderRadius: 12, display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 4, fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left', color: 'var(--memox-on-surface)' }}>
                <div style={{ width: 30, height: 30, borderRadius: 8, background: `color-mix(in srgb, var(--memox-primary) ${active ? 14 : 8}%, transparent)`, color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Ic name={s.ic} size="xs" color="var(--memox-primary)" />
                </div>
                <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px' }}>{s.label}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>{s.sub}</div>
              </button>);
          })}
        </div>

        {/* File picker / file chip */}
        {!fileChosen ?
          <div className="card" style={{ padding: '24px 20px', textAlign: 'center', marginBottom: 16, borderStyle: 'dashed', borderColor: 'var(--memox-outline-variant)' }}>
            <div style={{ width: 48, height: 48, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
              <Ic name="file-up" size="md" color="var(--memox-primary)" />
            </div>
            <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 4 }}>Drop a file or tap to browse</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginBottom: 16 }}>Supports .csv, .tsv, and .apkg (Anki) · up to 5 MB</div>
            <button className="pill-btn primary" style={{ height: 38, padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
              <Ic name="folder-open" size="xs" color="var(--memox-on-primary)" />
              Choose file
            </button>
          </div> :
          <div className="card" style={{ padding: '12px 16px', marginBottom: 16, display: 'grid', gridTemplateColumns: '36px 1fr auto', gap: 12, alignItems: 'center' }}>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Ic name="file-text" size="xs" color="var(--memox-primary)" />
            </div>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>topik-ii-vocab.tsv</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>
                TSV · 4.2 KB · {parsing ? 'parsing…' : isPreview ? `${rows.length} rows detected` : 'ready to preview'}
              </div>
            </div>
            <button className="icon-btn" title="Remove file" style={{ width: 30, height: 30 }}>
              <Ic name="x" size="xs" color="var(--memox-on-surface-variant)" />
            </button>
          </div>}

        {/* Format helper */}
        {!isPreview && !importing &&
          <div style={{ padding: '8px 12px', background: 'color-mix(in srgb, var(--memox-primary) 4%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-primary) 14%, transparent)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
            <Ic name="info" size="xs" color="var(--memox-primary)" />
            <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55, color: 'var(--memox-on-surface)' }}>
              <div style={{ fontWeight: 700, marginBottom: 4 }}>Each row makes one card</div>
              <div style={{ color: 'var(--memox-on-surface-variant)' }}>Column 1 = front · column 2 = back · column 3 = tags (optional, comma-separated). Quoted cells with commas are fine.</div>
            </div>
          </div>}

        {/* Step 2: preview */}
        {(isPreview || parsing) &&
          <>
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '8px 4px 8px' }}>
              <div className="ov">2 · Preview</div>
              {isPreview && <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>{validCount} of {rows.length} ready</span>}
            </div>

            {parsing ?
              <div className="card" style={{ padding: '28px 20px', textAlign: 'center', marginBottom: 16 }}>
                <Spinner size="lg" />
                <div style={{ fontSize: 14, fontWeight: 700, marginTop: 16, marginBottom: 4 }}>Reading your file…</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>No cards will be added until you tap Import.</div>
              </div> :
              <>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginBottom: 12 }}>
                  {[
                    { l: 'Valid', v: validCount, c: 'var(--memox-mastery)', bg: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', ic: 'check' },
                    invalidCount > 0 ? { l: 'Invalid', v: invalidCount, c: 'var(--memox-error)', bg: 'color-mix(in srgb, var(--memox-danger) 10%, transparent)', ic: 'alert-circle' } : null,
                    duplicateCount > 0 ? { l: 'Duplicate', v: duplicateCount, c: 'var(--memox-streak)', bg: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)', ic: 'copy' } : null
                  ].filter(Boolean).map((c) =>
                    <span key={c.l} style={{ height: 26, padding: '0 8px 0 8px', borderRadius: 999, background: c.bg, color: c.c, fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                      <Ic name={c.ic} size="xs" color={c.c} />
                      {c.l} · {c.v}
                    </span>
                  )}
                </div>

                <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
                  {rows.map((r, i, a) => {
                    const flagColor = r.err ? 'var(--memox-error)' : r.dup ? 'var(--memox-streak)' : 'var(--memox-mastery)';
                    return (
                      <div key={i} style={{ display: 'grid', gridTemplateColumns: '24px 1fr 1fr 20px', gap: 8, alignItems: 'center', padding: '8px 12px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', background: r.err ? 'color-mix(in srgb, var(--memox-danger) 4%, transparent)' : r.dup ? 'color-mix(in srgb, var(--memox-streak) 4%, transparent)' : 'transparent', opacity: r.err ? 0.85 : 1 }}>
                        <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>{i + 1}</span>
                        <div style={{ minWidth: 0 }}>
                          <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: r.front ? 'var(--memox-on-surface)' : 'var(--memox-error)', fontStyle: r.front ? 'normal' : 'italic' }}>{r.front || '(empty)'}</div>
                          {(r.err || r.dup) &&
                            <div style={{ fontSize: 12, marginTop: 2, color: flagColor, fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                              <Ic name={r.err ? 'alert-circle' : 'copy'} size="xs" color={flagColor} />
                              {r.err || r.dup}
                            </div>}
                        </div>
                        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', fontStyle: r.back ? 'normal' : 'italic' }}>{r.back || '(empty)'}</div>
                        <Ic name={r.ok ? 'check' : r.err ? 'x' : 'copy'} size="xs" color={flagColor} />
                      </div>);
                  })}
                </div>
              </>}

            {preview === 'mix' &&
              <div style={{ padding: '12px 16px', background: 'color-mix(in srgb, var(--memox-danger) 6%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-danger) 20%, transparent)', borderRadius: 12, display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
                <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
                <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55, color: 'var(--memox-on-surface)' }}>
                  <div style={{ fontWeight: 700, marginBottom: 2 }}>{invalidCount + duplicateCount} rows will be skipped</div>
                  <div style={{ color: 'var(--memox-on-surface-variant)' }}>{invalidCount} have missing fields · {duplicateCount} match an existing card. Fix them in your file and import again to include them.</div>
                </div>
              </div>}

            {isPreview &&
              <>
                <div className="ov" style={{ padding: '4px 4px 8px' }}>Import options</div>
                <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
                  {[
                    { ic: 'tag', label: 'Apply tags from column 3', sub: 'Detected: TOPIK II, noun, verb', on: true },
                    { ic: 'copy', label: 'Skip duplicates', sub: 'Cards matching front + back stay untouched', on: true },
                    { ic: 'flag', label: 'Mark imported as new', sub: 'Reset progress for matching cards', on: false }
                  ].map((o, i, a) =>
                    <div key={o.label} style={{ display: 'grid', gridTemplateColumns: '32px 1fr 44px', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
                      <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Ic name={o.ic} size="xs" color="var(--memox-primary)" />
                      </div>
                      <div>
                        <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{o.label}</div>
                        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.4 }}>{o.sub}</div>
                      </div>
                      <span style={{ display: 'inline-block', position: 'relative', width: 44, height: 26, borderRadius: 999, background: o.on ? 'var(--memox-primary)' : 'var(--memox-surface-container-high)' }}>
                        <span style={{ position: 'absolute', top: 3, left: o.on ? 21 : 3, width: 20, height: 20, borderRadius: 999, background: 'var(--memox-surface-bright)', boxShadow: 'var(--memox-shadow-soft)' }} />
                      </span>
                    </div>
                  )}
                </div>
              </>}
          </>}

        {/* Importing state */}
        {importing &&
          <div className="card" style={{ padding: '28px 20px', textAlign: 'center', marginTop: 8 }}>
            <Spinner size="lg" />
            <div style={{ fontSize: 14, fontWeight: 700, marginTop: 16, marginBottom: 4 }}>Adding {validCount} cards…</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>Saving to this device. Don't close the app yet.</div>
            <div style={{ marginTop: 20, height: 5, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
              <div style={{ height: '100%', width: '62%', background: 'var(--memox-primary)', borderRadius: 999, animation: 'memoxProgPulse 1.4s ease-in-out infinite' }} />
            </div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 8, fontVariantNumeric: 'tabular-nums' }}>29 of 47</div>
          </div>}
      </div>

      {/* Bottom commit bar */}
      <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', gap: 8 }}>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="pill-btn outline" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 12, fontSize: 14, flexShrink: 0 }}>Cancel</button>
          {!isPreview && !importing ?
            <button className="pill-btn primary" disabled={!fileChosen || parsing} style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: !fileChosen || parsing ? 0.45 : 1, pointerEvents: !fileChosen || parsing ? 'none' : 'auto' }}>
              {parsing ? <><Spinner color="var(--memox-on-primary)" size="xs" /> Parsing…</> : <><Ic name="eye" size="xs" color="var(--memox-on-primary)" /> Preview import</>}
            </button> :
            importing ?
              <button className="pill-btn primary" disabled style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: 0.6, pointerEvents: 'none' }}>
                <Spinner color="var(--memox-on-primary)" size="xs" />
                Importing…
              </button> :
              <button className="pill-btn primary" disabled={validCount === 0} style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: validCount === 0 ? 0.45 : 1, pointerEvents: validCount === 0 ? 'none' : 'auto' }}>
                <Ic name="download" size="xs" color="var(--memox-on-primary)" />
                Import {validCount} valid {validCount === 1 ? 'card' : 'cards'}
              </button>}
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center', opacity: 0.7 }}>
          {!fileChosen ? 'Pick a file or paste text to continue.' :
            parsing ? 'Reading file — no changes yet.' :
            !isPreview ? 'Next you’ll preview every row before anything is imported.' :
            preview === 'mix' ? `Only the ${validCount} valid rows will be imported.` :
            importing ? 'Imports save to this device only.' :
            'No cards are added until you tap Import.'}
        </div>
      </div>

      <style>{`
        @keyframes memoxProgPulse  { 0%, 100% { opacity: 0.85; } 50% { opacity: 1; } }
      `}</style>
    </div>);
}

Object.assign(window, { DeckImportScreen });
})();
