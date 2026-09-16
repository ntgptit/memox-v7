/* MemoX Mobile v3 — DeckImportScreen · MAIN  (A11 · Card import)
   Product corrections vs v1: sources are CSV, TSV, XLSX or pasted text, UTF-8
   (no Anki, no size cap in the contract); a column-mapping step (header row ·
   front · back · example · hint · pronunciation · tags, ";"-separated) replaces
   the fixed "column 1 = front" rule; row statuses are ready · invalid ·
   duplicate (in deck / in file) · blank; the only option is include/skip
   duplicates ("apply tags" and "mark as new" were not real options — imported
   cards are always new, BR-171); results are imported · imported with skips ·
   nothing added · failed; file-problem and deck-rejects states added.
   Step tracker, deck chip, dashed drop card, preview table, commit bar are v1's.
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
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, StudyTopBar } = window;

/* SAMPLE_DATA · import[0]: header "term, meaning, sentence, labels" auto-mapped; every row status once. */
const rowsAll = [
  { n: 2, front: 'reservation', back: 'sự đặt chỗ trước', ok: true },
  { n: 3, front: 'bill', back: 'hóa đơn', ok: true },
  { n: 4, front: 'tip', back: 'tiền boa', ok: true },
  { n: 5, front: 'menu', back: 'thực đơn', ok: true },
  { n: 6, front: 'waiter', back: 'người phục vụ', ok: true }
];
const rowsMix = [
  { n: 2, front: 'reservation', back: 'sự đặt chỗ trước', ok: true },
  { n: 3, front: 'bill', back: '', err: 'Meaning is empty' },
  { n: 4, front: 'tip', back: 'tiền boa', ok: true },
  { n: 5, front: 'Reservation', back: 'Sự đặt chỗ trước', dup: 'Already in this deck' },
  { n: 6, front: '', back: '', blank: true },
  { n: 7, front: 'tip', back: 'tiền boa', dup: 'Repeated in the file (row 4)' },
  { n: 8, front: 'a very long term that runs well past the sixty-character limit for a card front', back: 'quá dài', err: 'Term over 60 characters' },
  { n: 9, front: 'menu', back: 'thực đơn', ok: true }
];

const Spinner = window.Spinner;

const RESULT_CFG = {
  success: { icon: 'check-circle-2', title: 'Imported', body: 'Added 1,500 cards to Nhà hàng as new cards. They enter learning on your next session.', bg: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', color: 'var(--memox-mastery)', bd: 'color-mix(in srgb, var(--memox-mastery) 22%, transparent)', added: 1500 },
  partial: { icon: 'check-circle-2', title: 'Imported with skips', body: 'Added 3 cards. 2 duplicates and 2 invalid rows were skipped, and 1 blank row was ignored.', bg: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', color: 'var(--memox-mastery)', bd: 'color-mix(in srgb, var(--memox-mastery) 22%, transparent)', added: 3, dup: 2, invalid: 2 },
  none: { icon: 'copy', title: 'Nothing added', body: 'Every row already exists in this deck, so no card was created. The deck is unchanged.', bg: 'var(--memox-surface-container-lowest)', color: 'var(--memox-on-surface-variant)', bd: 'var(--memox-outline-variant)' },
  failed: { icon: 'alert-circle', title: 'Import didn’t finish', body: 'No cards were added — an import is all or nothing. Your file and your deck are unchanged.', bg: 'var(--memox-danger-soft)', color: 'var(--memox-error)', bd: 'var(--memox-danger-border)' },
  rejects: { icon: 'layers', title: 'This deck no longer accepts cards', body: 'Nhà hàng now holds sub-decks. No cards were added. Pick a deck that holds cards or is empty and import again.', bg: 'var(--memox-warning-soft)', color: 'var(--memox-warning)', bd: 'var(--memox-warning-border)' }
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

        {cfg.added &&
          <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
            {[
              { l: 'Added as new cards', v: cfg.added.toLocaleString('en-US'), c: 'var(--memox-mastery)', ic: 'check' },
              cfg.dup ? { l: 'Skipped — duplicates', v: cfg.dup, c: 'var(--memox-on-surface-variant)', ic: 'copy' } : null,
              cfg.invalid ? { l: 'Skipped — invalid rows', v: cfg.invalid, c: 'var(--memox-warning-ink)', ic: 'alert-circle' } : null
            ].filter(Boolean).map((r, i, a) =>
              <div key={r.l} style={{ display: 'grid', gridTemplateColumns: '28px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
                <div style={{ width: 24, height: 24, borderRadius: 'var(--memox-radius-sm)', background: 'var(--memox-surface-container)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
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
            <span>Fix the invalid rows in your source and import again; duplicates are skipped by the case-insensitive term + meaning.</span>
          </div>}
      </div>
      <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14 }}>{result === 'failed' || result === 'rejects' ? 'Close' : 'Back to deck'}</button>
        <button className="pill-btn primary" style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8 }}>
          {result === 'failed' ? <><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" /> Try again</> : result === 'rejects' ? <><Ic name="layers" size="xs" color="var(--memox-on-primary)" /> Choose another deck</> : result === 'none' ? 'Back to deck' : <><Ic name="copy" size="xs" color="var(--memox-on-primary)" /> View the cards</>}
        </button>
      </div>
    </div>);
}

/* ════════════ SCREEN ════════════ */
function DeckImportScreenV3({ go, state = 'empty' }) {
  const States = (window.MemoXStates && window.MemoXStates.DeckImport) || {};
  const mod = States[state] || States.empty;
  const cfg = (mod ? mod() : {}) || {};

  if (cfg.kind === 'result') return <ResultScreen go={go} result={cfg.result} />;

  const { fileChosen = false, parsing = false, preview = null, importing = false, fileProblem = null, mapping = false, mappingIncomplete = false, pasted = false } = cfg;
  const { Note, Toggle } = window;
  const isPreview = preview === 'all' || preview === 'mix';
  const rows = preview === 'all' ? rowsAll : rowsMix;
  const validCount = rows.filter((r) => r.ok).length;
  const invalidCount = rows.filter((r) => r.err).length;
  const duplicateCount = rows.filter((r) => r.dup).length;
  const blankCount = rows.filter((r) => r.blank).length;

  return (
    <div className="app">
      <StatusBar />

      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('cards')}>
          <Ic name="x" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>Import cards</div>
      </div>

      <Breadcrumb segments={[{ label: 'Library' }, { label: 'Tiếng Anh giao tiếp hằng ngày' }, { label: 'Nhà hàng' }, { label: 'Import' }]} />

      <div className="scroll">

        {/* Step tracker */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
          {[
            { n: 1, label: 'Source', done: (fileChosen && !fileProblem) || isPreview || importing },
            { n: 2, label: 'Columns', done: isPreview || importing, current: parsing || mapping },
            { n: 3, label: 'Preview', done: importing, current: isPreview },
            { n: 4, label: 'Import', current: importing }
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
          <span style={{ width: 22, height: 22, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
            <Ic name="layers" size="xs" color="var(--memox-primary)" />
          </span>
          <span>Nhà hàng · 64 cards</span>
        </div>

        {/* Step 1: source picker */}
        <div className="ov" style={{ padding: '0 4px 8px' }}>1 · Choose a source</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 16 }}>
          {[
            { id: 'file', ic: 'file-up', label: 'Choose a file', sub: 'CSV, TSV or XLSX · UTF-8' },
            { id: 'paste', ic: 'clipboard', label: 'Paste text', sub: 'Tab- or comma-separated rows' }
          ].map((s) => {
            const active = pasted ? s.id === 'paste' : s.id === 'file';
            return (
              <button key={s.id} style={{ padding: '16px 12px', background: active ? 'color-mix(in srgb, var(--memox-primary) 6%, transparent)' : 'var(--memox-surface-container-lowest)', border: active ? '1px solid var(--memox-primary)' : 'var(--memox-border-ghost)', borderRadius: 12, display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 4, fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left', color: 'var(--memox-on-surface)' }}>
                <div style={{ width: 30, height: 30, borderRadius: 'var(--memox-radius-sm)', background: `color-mix(in srgb, var(--memox-primary) ${active ? 14 : 8}%, transparent)`, color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Ic name={s.ic} size="xs" color="var(--memox-primary)" />
                </div>
                <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px' }}>{s.label}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>{s.sub}</div>
              </button>);
          })}
        </div>

        {/* File picker / file chip */}
        {fileProblem ?
          <div className="card" style={{ padding: '16px', marginBottom: 16, background: 'var(--memox-warning-soft)', border: '1px solid var(--memox-warning-border)' }}>
            <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
              <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-warning) 18%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Ic name="file-x" size="sm" color="var(--memox-warning)" />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 2 }}>{fileProblem.title}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>{fileProblem.body}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{fileProblem.file}</div>
              </div>
            </div>
            <button className="pill-btn outline" style={{ marginTop: 12, height: 38, padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
              <Ic name="folder-open" size="xs" color="var(--memox-on-surface)" />
              Choose another file
            </button>
          </div> :
          pasted && !isPreview && !importing ?
          <div className="card" style={{ padding: '12px 16px', marginBottom: 16, background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-primary)' }}>
            <div style={{ fontSize: 14, lineHeight: 1.5, fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace', whiteSpace: 'pre', overflow: 'hidden', textOverflow: 'ellipsis' }}>{'term\tmeaning\treservation\tsự đặt chỗ trước\nbill\thóa đơn\ntip\ttiền boa'}</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 8, fontVariantNumeric: 'tabular-nums' }}>4 lines · tab-separated</div>
          </div> :
          !fileChosen ?
          <div className="card" style={{ padding: '24px 20px', textAlign: 'center', marginBottom: 16, borderStyle: 'dashed', borderColor: 'var(--memox-outline-variant)' }}>
            <div style={{ width: 48, height: 48, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
              <Ic name="file-up" size="md" color="var(--memox-primary)" />
            </div>
            <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 4 }}>Pick a spreadsheet or text file</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginBottom: 16 }}>.csv, .tsv or .xlsx · UTF-8 · nothing is added until you confirm</div>
            <button className="pill-btn primary" style={{ height: 38, padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
              <Ic name="folder-open" size="xs" color="var(--memox-on-primary)" />
              Choose file
            </button>
          </div> :
          <div className="card" style={{ padding: '12px 16px', marginBottom: 16, display: 'grid', gridTemplateColumns: '36px 1fr auto', gap: 12, alignItems: 'center' }}>
            <div style={{ width: 32, height: 32, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Ic name="file-text" size="xs" color="var(--memox-primary)" />
            </div>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>nha-hang-vocab.csv</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>
                CSV · UTF-8 · {parsing ? 'reading…' : isPreview || mapping ? `${rows.length + 1} rows · 4 columns` : 'ready to read'}
              </div>
            </div>
            <button className="icon-btn" title="Remove file" style={{ width: 30, height: 30 }}>
              <Ic name="x" size="xs" color="var(--memox-on-surface-variant)" />
            </button>
          </div>}

        {/* Format helper */}
        {!isPreview && !importing && !mapping && !fileProblem &&
          <div style={{ padding: '8px 12px', background: 'color-mix(in srgb, var(--memox-primary) 4%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-primary) 14%, transparent)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
            <Ic name="info" size="xs" color="var(--memox-primary)" />
            <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55, color: 'var(--memox-on-surface)' }}>
              <div style={{ fontWeight: 700, marginBottom: 4 }}>Each row makes one card</div>
              <div style={{ color: 'var(--memox-on-surface-variant)' }}>You will map columns to term, meaning, example, hint, pronunciation and tags next. Several tags in one cell are separated by “;”.</div>
            </div>
          </div>}

        {/* Step 2: column mapping (A11) — header row toggle + one row per column. */}
        {mapping &&
          <>
            <div className="ov" style={{ padding: '0 4px 8px' }}>2 · Map columns</div>
            <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 8 }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: 'var(--memox-border-ghost)' }}>
                <div><div style={{ fontSize: 14, fontWeight: 600 }}>First row is a header</div><div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>term · meaning · sentence · labels</div></div>
                <Toggle on />
              </div>
              {[
                { col: 'term', to: 'Term (front)', ok: true },
                { col: 'meaning', to: mappingIncomplete ? 'Not imported' : 'Meaning (back)', ok: !mappingIncomplete },
                { col: 'sentence', to: 'Example', ok: true },
                { col: 'labels', to: 'Tags', ok: true }
              ].map((r, i, a) =>
                <div key={r.col} style={{ display: 'grid', gridTemplateColumns: '1fr 20px 1fr', gap: 8, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
                  <div style={{ minWidth: 0 }}><div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>Column {String.fromCharCode(65 + i)}</div><div style={{ fontSize: 14, fontWeight: 600, fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.col}</div></div>
                  <Ic name="arrow-right" size="xs" color="var(--memox-on-surface-variant)" />
                  <button className="pill-btn" style={{ height: 36, padding: '0 8px 0 12px', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 4, justifyContent: 'space-between', background: 'var(--memox-surface-container-lowest)', border: r.ok ? 'var(--memox-border-ghost)' : '1px solid var(--memox-error)', color: r.ok ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)' }}>
                    <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.to}</span>
                    <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
                  </button>
                </div>)}
            </div>
            {mappingIncomplete ?
              <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px', color: 'var(--memox-error)', fontSize: 12, fontWeight: 600, marginBottom: 16 }}>
                <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
                <span>Map a column to Meaning. Both term and meaning are required.</span>
              </div> :
              <Note style={{ marginBottom: 16 }}>Known header names were mapped for you. Term and meaning are required; the rest is optional.</Note>}
          </>}

        {/* Step 2: preview */}
        {(isPreview || parsing) &&
          <>
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '8px 4px 8px' }}>
              <div className="ov">3 · Preview</div>
              {isPreview && <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>{validCount} of {rows.length} rows ready</span>}
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
                    { l: 'Ready', v: validCount, c: 'var(--memox-mastery)', bg: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', ic: 'check' },
                    invalidCount > 0 ? { l: 'Invalid', v: invalidCount, c: 'var(--memox-warning-ink)', bg: 'var(--memox-warning-soft)', ic: 'alert-circle' } : null,
                    duplicateCount > 0 ? { l: 'Duplicate', v: duplicateCount, c: 'var(--memox-on-surface-variant)', bg: 'var(--memox-surface-container)', ic: 'copy' } : null,
                    blankCount > 0 ? { l: 'Blank', v: blankCount, c: 'var(--memox-on-surface-variant)', bg: 'var(--memox-surface-container)', ic: 'minus' } : null
                  ].filter(Boolean).map((c) =>
                    <span key={c.l} style={{ height: 26, padding: '0 8px 0 8px', borderRadius: 999, background: c.bg, color: c.c, fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                      <Ic name={c.ic} size="xs" color={c.c} />
                      {c.l} · {c.v}
                    </span>
                  )}
                </div>

                <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
                  {rows.map((r, i, a) => {
                    const flagColor = r.err ? 'var(--memox-warning-ink)' : r.dup || r.blank ? 'var(--memox-on-surface-variant)' : 'var(--memox-mastery)';
                    if (r.blank) return (
                      <div key={i} style={{ display: 'grid', gridTemplateColumns: '24px 1fr 20px', gap: 8, alignItems: 'center', padding: '8px 12px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', opacity: 0.6 }}>
                        <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>{r.n}</span>
                        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontStyle: 'italic' }}>Blank row · ignored</div>
                        <Ic name="minus" size="xs" color={flagColor} />
                      </div>);
                    return (
                      <div key={i} style={{ display: 'grid', gridTemplateColumns: '24px 1fr 1fr 20px', gap: 8, alignItems: 'center', padding: '8px 12px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', background: r.err ? 'color-mix(in srgb, var(--memox-warning) 5%, transparent)' : 'transparent', opacity: r.dup ? 0.75 : 1 }}>
                        <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>{r.n}</span>
                        <div style={{ minWidth: 0 }}>
                          <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: r.front ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)', fontStyle: r.front ? 'normal' : 'italic' }}>{r.front || '(empty)'}</div>
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
              <div style={{ padding: '12px 16px', background: 'var(--memox-warning-soft)', border: '1px solid var(--memox-warning-border)', borderRadius: 12, display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
                <Ic name="alert-circle" size="xs" color="var(--memox-warning)" />
                <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55, color: 'var(--memox-on-surface)' }}>
                  <div style={{ fontWeight: 700, marginBottom: 2 }}>{invalidCount} invalid {invalidCount === 1 ? 'row' : 'rows'} will be skipped</div>
                  <div style={{ color: 'var(--memox-on-surface-variant)' }}>Fix them in your source and import again to include them. Duplicates follow the option below.</div>
                </div>
              </div>}

            {isPreview &&
              <>
                <div className="ov" style={{ padding: '0 4px 8px' }}>Duplicates</div>
                <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 8 }}>
                  {[
                    { ic: 'copy', label: 'Skip duplicates', sub: `${duplicateCount} ${duplicateCount === 1 ? 'row matches' : 'rows match'} an existing card or an earlier row (same term + meaning, any letter case)`, on: true }
                  ].map((o, i, a) =>
                    <div key={o.label} style={{ display: 'grid', gridTemplateColumns: '32px 1fr 44px', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
                      <div style={{ width: 30, height: 30, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Ic name={o.ic} size="xs" color="var(--memox-primary)" />
                      </div>
                      <div>
                        <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{o.label}</div>
                        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.4 }}>{o.sub}</div>
                      </div>
                      <Toggle on={o.on} />
                    </div>
                  )}
                </div>
                <Note style={{ marginBottom: 16 }}>Imported cards are new — no schedule, no history. Tags in one cell are separated by “;”.</Note>
              </>}
          </>}

        {/* Importing state */}
        {importing &&
          <div className="card" style={{ padding: '28px 20px', textAlign: 'center', marginTop: 8 }}>
            <Spinner size="lg" />
            <div style={{ fontSize: 14, fontWeight: 700, marginTop: 16, marginBottom: 4 }}>Adding 1,500 cards…</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>Written in one step — either every card is added or none is.</div>
          </div>}
      </div>

      {/* Bottom commit bar */}
      <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', gap: 8 }}>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="pill-btn outline" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 12, fontSize: 14, flexShrink: 0 }}>Cancel</button>
          {!isPreview && !importing ?
            <button className="pill-btn primary" disabled={(!fileChosen && !pasted) || parsing || !!fileProblem || mappingIncomplete} style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: (!fileChosen && !pasted) || parsing || fileProblem || mappingIncomplete ? 0.45 : 1, pointerEvents: (!fileChosen && !pasted) || parsing || fileProblem || mappingIncomplete ? 'none' : 'auto' }}>
              {parsing ? <><Spinner color="var(--memox-on-primary)" size="xs" /> Reading…</> : mapping ? <><Ic name="eye" size="xs" color="var(--memox-on-primary)" /> Preview rows</> : <><Ic name="arrow-right" size="xs" color="var(--memox-on-primary)" /> Read and map columns</>}
            </button> :
            importing ?
              <button className="pill-btn primary" disabled style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: 0.6, pointerEvents: 'none' }}>
                <Spinner color="var(--memox-on-primary)" size="xs" />
                Importing…
              </button> :
              <button className="pill-btn primary" disabled={validCount === 0} style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: validCount === 0 ? 0.45 : 1, pointerEvents: validCount === 0 ? 'none' : 'auto' }}>
                <Ic name="download" size="xs" color="var(--memox-on-primary)" />
                Import {validCount} {validCount === 1 ? 'card' : 'cards'}
              </button>}
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center', opacity: 0.7 }}>
          {fileProblem ? 'Nothing was read. Choose another file to continue.' :
            !fileChosen && !pasted ? 'Pick a file or paste text to continue.' :
            parsing ? 'Reading — no changes yet.' :
            mappingIncomplete ? 'Term and meaning must both be mapped.' :
            mapping ? 'Next you’ll preview every row before anything is imported.' :
            !isPreview ? 'Your file is read on this device only.' :
            preview === 'mix' ? `${validCount} rows will become new cards.` :
            importing ? 'All or nothing — nothing partial is ever written.' :
            'No cards are added until you tap Import.'}
        </div>
      </div>

      <style>{`
        @keyframes memoxProgPulse  { 0%, 100% { opacity: 0.85; } 50% { opacity: 1; } }
      `}</style>
    </div>);
}

Object.assign(window, { DeckImportScreenV3 });
})();
