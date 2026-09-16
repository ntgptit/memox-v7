/* MemoX Mobile — FlashcardCreateScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     FlashcardCreateScreen/
       FlashcardCreateScreen.jsx  ← the shared form + helpers, rendered from a flag set
       states/                    ← one file per state in window.MemoXStates.FlashcardCreate

   This screen is ONE form whose six states are flag-driven variations of the same
   layout (not separate blocks). Splitting the markup per state would duplicate the
   form six times, so instead each state file declares its flag set:
     window.MemoXStates.FlashcardCreate.<name> = () => ({
       empty, valid, showDetails, validationErr, saving, saveFailed, front, back })
   and the MAIN file renders the single form from those flags. Editing one state's
   file changes only that state — the shared form is untouched. */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

const FieldHeader = ({ label, required, count, max }) =>
  <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '0 4px 4px' }}>
    <div style={{ display: 'inline-flex', alignItems: 'baseline', gap: 4 }}>
      <span className="ov">{label}</span>
      {required && <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-primary)', letterSpacing: 0.3 }}>Required</span>}
    </div>
    {count != null && <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.2, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>{count} / {max}</span>}
  </div>;

/* white-on-primary default: these spinners sit inside filled CTAs. */
const Spinner = (p) => <window.Spinner color="#fff" {...p} />;

const OptionalField = ({ label, icon, value, placeholder, monospace, trailing }) =>
  <div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px 4px' }}>
      <Ic name={icon} size="xs" color="var(--memox-on-surface-variant)" />
      <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', color: 'var(--memox-on-surface-variant)' }}>{label}</span>
      <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', opacity: 0.55, fontWeight: 500 }}>· optional</span>
    </div>
    <div style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', padding: '8px 12px', minHeight: 40, fontSize: 14, fontFamily: monospace ? 'ui-monospace, "SF Mono", Menlo, monospace' : 'inherit', color: value ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)', opacity: value ? 1 : 0.6, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, lineHeight: 1.45 }}>
      <span style={{ flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{value || placeholder}</span>
      {trailing}
    </div>
  </div>;

/* ════════════ SCREEN ════════════ */
function FlashcardCreateScreen({ go, state = 'emptyForm' }) {
  const States = (window.MemoXStates && window.MemoXStates.FlashcardCreate) || {};
  const mod = States[state] || States.emptyForm;
  const f = (mod ? mod() : {}) || {};
  const { empty = false, valid = false, showDetails = false, validationErr = false, saving = false, saveFailed = false, front = '', back = '' } = f;

  return (
    <div className="app">
      <StatusBar />

      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('cards')}>
          <Ic name="x" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>New flashcard</div>
        <button className="pill-btn primary" disabled={!valid || saving} style={{ height: 32, padding: '0 16px', borderRadius: 8, fontSize: 12, gap: 4, opacity: !valid || saving ? 0.45 : 1, pointerEvents: !valid || saving ? 'none' : 'auto' }}>
          {saving ? <><Spinner size="xs" /> Saving…</> : 'Save'}
        </button>
      </div>

      <Breadcrumb segments={[{ label: 'Library' }, { label: 'Korean' }, { label: 'TOPIK II — Vocab' }, { label: 'New card' }]} />

      <div className="scroll">

        {/* Deck destination */}
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '4px 12px 4px 8px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 999, fontSize: 12, fontWeight: 600, marginBottom: 16 }}>
          <span style={{ width: 22, height: 22, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
            <Ic name="layers" size="xs" color="var(--memox-primary)" />
          </span>
          <span>TOPIK II — Vocab</span>
          <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
        </div>

        <div className="ov" style={{ padding: '0 4px 8px', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--memox-primary)' }} />
          Required
        </div>

        {/* Front */}
        <FieldHeader label="Front · Korean" required count={front.length} max={60} />
        <div className="card" style={{ padding: '16px 16px', minHeight: 66, display: 'flex', alignItems: 'center', position: 'relative', background: 'var(--memox-surface-container-lowest)', borderColor: empty ? 'var(--memox-primary)' : undefined, borderWidth: empty ? 1 : undefined, borderStyle: empty ? 'solid' : undefined, marginBottom: 16, paddingRight: 44 }}>
          {front ?
            <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px', lineHeight: 1.2 }}>{front}</div> :
            <div style={{ fontSize: 16, fontWeight: 500, color: 'var(--memox-on-surface-variant)', opacity: 0.6, display: 'inline-flex', alignItems: 'center', gap: 2 }}>
              <span>The term you want to remember</span>
              <span style={{ display: 'inline-block', width: 2, height: 18, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite', marginLeft: 2 }} />
            </div>}
          <button className="icon-btn" style={{ position: 'absolute', top: '50%', transform: 'translateY(-50%)', right: 6, width: 30, height: 30 }} title="Record pronunciation">
            <Ic name="mic" size="xs" color="var(--memox-on-surface-variant)" />
          </button>
        </div>

        {/* Back */}
        <FieldHeader label="Back · Meaning" required count={back.length} max={240} />
        <div className="card" style={{ padding: '12px 16px', minHeight: 76, background: 'var(--memox-surface-container-lowest)', borderColor: validationErr ? 'var(--memox-error)' : undefined, borderWidth: validationErr ? 1 : undefined, borderStyle: validationErr ? 'solid' : undefined, display: 'flex', alignItems: back ? 'flex-start' : 'center', marginBottom: validationErr ? 8 : 16 }}>
          {back ?
            <div style={{ fontSize: 16, fontWeight: 500, lineHeight: 1.45 }}>{back}</div> :
            <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', opacity: 0.65, lineHeight: 1.5 }}>
              English, Vietnamese, or both — comma-separated reads cleanest.
            </div>}
        </div>
        {validationErr &&
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px', color: 'var(--memox-error)', fontSize: 12, fontWeight: 600, marginBottom: 16 }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            <span>Add a meaning so this card can be answered.</span>
          </div>}

        {/* Optional details disclosure */}
        <button style={{ width: '100%', height: 42, background: showDetails ? 'color-mix(in srgb, var(--memox-primary) 6%, transparent)' : 'transparent', border: showDetails ? '1px solid color-mix(in srgb, var(--memox-primary) 20%, transparent)' : '1px dashed var(--memox-outline-variant)', color: 'var(--memox-primary)', fontSize: 12, fontWeight: 600, padding: '0 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontFamily: 'inherit', cursor: 'pointer', marginBottom: showDetails ? 16 : 20, borderRadius: 'var(--memox-radius-md)' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
            <Ic name="sparkles" size="xs" color="var(--memox-primary)" />
            Add details
            <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontWeight: 500 }}>example · hint · pronunciation</span>
          </span>
          <Ic name={showDetails ? 'chevron-up' : 'chevron-down'} size="xs" color="var(--memox-primary)" />
        </button>

        {showDetails &&
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 20 }}>
            <OptionalField icon="message-square" label="Example sentence" value="그는 유명한 언어학 연구자이다." placeholder="A sentence using this term…" />
            <OptionalField icon="lightbulb" label="Hint" value="연구 = research · 자 = person" placeholder="A clue that should jog memory without giving the answer." />
            <OptionalField icon="volume-2" label="Pronunciation · romanization" value="yeon-gu-ja" placeholder="yeon-gu-ja" monospace trailing={<button className="icon-btn" style={{ width: 26, height: 26 }}><Ic name="volume-2" size="xs" color="var(--memox-on-surface-variant)" /></button>} />
          </div>}

        {/* Tags */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px 8px' }}>
          <Ic name="tag" size="xs" color="var(--memox-on-surface-variant)" />
          <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', color: 'var(--memox-on-surface-variant)' }}>Tags</span>
          <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', opacity: 0.55, fontWeight: 500 }}>· optional</span>
        </div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginBottom: 20 }}>
          {valid && ['TOPIK II', 'noun', 'people'].map((t) =>
            <span key={t} style={{ height: 28, padding: '0 8px 0 12px', background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', borderRadius: 999, fontSize: 12, fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              {t}
              <Ic name="x" size="xs" color="var(--memox-primary)" />
            </span>
          )}
          <button style={{ height: 28, padding: '0 12px', background: 'transparent', color: 'var(--memox-on-surface-variant)', border: '1px dashed var(--memox-outline-variant)', borderRadius: 999, fontSize: 12, fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 4, fontFamily: 'inherit', cursor: 'pointer' }}>
            <Ic name="plus" size="xs" color="var(--memox-on-surface-variant)" />
            Add tag
          </button>
        </div>

        <div style={{ height: 6 }} />
      </div>

      {/* Bottom save bar */}
      <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {saveFailed &&
          <div style={{ padding: '8px 12px', background: 'color-mix(in srgb, var(--memox-danger) 8%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-danger) 22%, transparent)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'flex-start' }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            <div style={{ flex: 1, fontSize: 12, lineHeight: 1.45, color: 'var(--memox-on-surface)' }}>
              <strong style={{ fontWeight: 700 }}>Couldn't save card.</strong>{' '}
              <span style={{ color: 'var(--memox-on-surface-variant)' }}>Nothing was lost. Tap Save to try again.</span>
            </div>
          </div>}

        <div style={{ display: 'flex', gap: 8 }}>
          <button className="pill-btn outline" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 12, fontSize: 14, flexShrink: 0 }}>Cancel</button>
          <button className="pill-btn primary" disabled={!valid || saving} style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: !valid || saving ? 0.45 : 1, pointerEvents: !valid || saving ? 'none' : 'auto' }}>
            {saving ? <><Spinner size="xs" /> Saving…</> :
              saveFailed ? <><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" /> Retry save</> :
              <><Ic name="check" size="xs" color="var(--memox-on-primary)" /> Save card</>}
          </button>
        </div>

        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center', opacity: 0.7 }}>
          {empty ? 'Front and back are required to save.' :
            validationErr ? 'Add the missing field to enable save.' :
            saving ? 'Saving to this device…' :
            'You can keep adding cards after saving.'}
        </div>
      </div>

    </div>);
}

Object.assign(window, { FlashcardCreateScreen });
})();
