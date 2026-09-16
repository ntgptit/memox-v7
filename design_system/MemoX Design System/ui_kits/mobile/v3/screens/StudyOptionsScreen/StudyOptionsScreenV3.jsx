/* MemoX Mobile v3 — StudyOptionsScreenV3  (A17 · Study options per root deck)  ADDED in v3
   Drawn like Settings (Section + Row) so it reads as the deck-level twin of the
   app defaults. Rules: options live on the root deck; sub-decks use their
   root's (BR-147); "Use app defaults" lives here, not in Settings (BR-212);
   changes apply only to sessions started afterwards (BR-213); limit 1–200.
   States: defaults · override · invalid · saving · saved · saveFailed · loading */
(function () {
const { StatusBar, Ic, Breadcrumb, Note, OptionRow, Toggle, Snackbar, Spinner, Skeleton } = window;

const Stepper = ({ value, invalid = false, busy = false, disabled = false }) =>
  <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, opacity: disabled ? 'var(--memox-op-disabled)' : 1 }}>
    <button className="icon-btn" disabled={disabled} aria-label="Fewer cards" style={{ width: 36, height: 36, background: 'var(--memox-surface-container)', borderRadius: 'var(--memox-radius-md)' }}><Ic name="minus" size="xs" /></button>
    <span style={{ minWidth: 48, textAlign: 'center', fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: invalid ? 'var(--memox-error)' : 'var(--memox-on-surface)', padding: '6px 4px', borderRadius: 'var(--memox-radius-sm)', border: invalid ? '1px solid var(--memox-error)' : '1px solid transparent' }}>{busy ? <Spinner size="xs" /> : value}</span>
    <button className="icon-btn" disabled={disabled} aria-label="More cards" style={{ width: 36, height: 36, background: 'var(--memox-surface-container)', borderRadius: 'var(--memox-radius-md)' }}><Ic name="plus" size="xs" /></button>
  </div>;

function StudyOptionsScreenV3({ go, state = 'override' }) {
  const loading = state === 'loading';
  const defaults = state === 'defaults';
  const invalid = state === 'invalid';
  const saving = state === 'saving';
  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('deck')} aria-label="Back"><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>Study options</div>
      </div>
      <Breadcrumb segments={[{ label: 'Library' }, { label: '한국어 TOPIK I · Từ vựng' }, { label: 'Study options' }]} />
      <div className="scroll">
        <Note icon="layers" style={{ marginBottom: 16 }}>These options belong to <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>한국어 TOPIK I · Từ vựng</strong> and every sub-deck in it.</Note>

        <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', minHeight: 48 }}>
            <div><div style={{ fontSize: 16, fontWeight: 600 }}>Use app defaults</div><div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, lineHeight: 1.45 }}>{loading ? <Skeleton w={160} h={10} /> : defaults ? 'Following Settings · 20 cards, created order' : 'Off · this deck has its own options'}</div></div>
            {loading ? <Skeleton w={44} h={26} r={999} /> : <Toggle on={defaults} />}
          </div>
        </div>

        <div className="ov" style={{ padding: '0 4px 8px' }}>{defaults ? 'App defaults (read-only here)' : 'This deck'}</div>
        <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 8 }}>
          <div style={{ padding: '12px 16px', borderBottom: 'var(--memox-border-ghost)' }}>
            <div style={{ fontSize: 16, fontWeight: 600 }}>Cards per session</div>
            <div style={{ fontSize: 12, color: invalid ? 'var(--memox-error)' : 'var(--memox-on-surface-variant)', marginTop: 4, fontWeight: invalid ? 600 : 400 }}>{invalid ? 'Enter a number from 1 to 200' : '1 to 200'}</div>
            <div style={{ marginTop: 12 }}>{loading ? <Skeleton w={140} h={36} r={12} /> : <Stepper value={defaults ? 20 : invalid ? 0 : 50} invalid={invalid} busy={saving} disabled={defaults} />}</div>
          </div>
          <div style={{ padding: '12px 16px 4px', fontSize: 16, fontWeight: 600 }}>New-card order</div>
          <div style={{ opacity: defaults ? 'var(--memox-op-disabled)' : 1 }}>
            <OptionRow title="Creation order" sub="Oldest cards first — the order you added or imported them" selected={defaults} disabled={defaults} />
            <OptionRow title="Random" sub="Shuffled each learning session" selected={!defaults} disabled={defaults} last />
          </div>
        </div>
        <Note style={{ marginBottom: 16 }}>Changes apply to sessions started from now on. A session already open keeps the options it started with.</Note>
      </div>
      {!loading &&
        <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', gap: 8 }}>
          <button className="pill-btn primary" disabled={invalid || saving} style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: invalid ? 0.45 : 1 }}>{saving ? <><Spinner color="var(--memox-on-primary)" size="xs" />Saving…</> : state === 'saveFailed' ? <><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />Retry save</> : <><Ic name="check" size="xs" color="var(--memox-on-primary)" />Save</>}</button>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center', opacity: 0.7 }}>{invalid ? 'Fix the limit to enable save.' : state === 'saveFailed' ? 'Couldn’t save. The deck still uses 20 cards, created order.' : 'Saved to this device only.'}</div>
        </div>}
      {state === 'saved' && <Snackbar>Saved · applies to the next session</Snackbar>}
    </div>);
}

Object.assign(window, { StudyOptionsScreenV3 });
})();
