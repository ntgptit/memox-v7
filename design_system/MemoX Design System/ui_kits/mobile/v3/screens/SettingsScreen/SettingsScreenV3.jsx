/* MemoX Mobile v3 — SettingsScreenV3 · MAIN  (A22 · Settings)
   Cloned from v1 SettingsScreen. KEEP v1 hub layout: Section + icon-tile Row
   (36px tile · 16px label · 12px subtitle · trailing). REMOVE Account & sync,
   Audio & speech, Manage tags (tags live in Library), About version row (no
   such data). ADD Study defaults (cards per session 1–200, new-card order) with
   the future-sessions note (BR-213); Reset app options with a confirmation whose
   wording cannot be read as resetting learning progress (BR-217); per-option
   saving / saved / invalid / save-failed states (BR-216).
   States: loaded · loading · saving · saved · invalidLimit · saveFailed · resetConfirm · resetDone */
(function () {
const { StatusBar, Ic, BottomNav, Note, Dialog, Snackbar, OptionRow } = window;
const Skel = ({ w = 120 }) => <window.Skeleton w={w} h={12} op={0.55} r={4} style={{ display: 'inline-block' }} />;
const Spinner = window.Spinner;

const Section = ({ title, children, note }) =>
  <div style={{ marginBottom: 16 }}>
    <div className="ov" style={{ padding: '0 4px 8px' }}>{title}</div>
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>{children}</div>
    {note && <div style={{ padding: '8px 4px 0' }}>{note}</div>}
  </div>;

const Row = ({ icon, label, subtitle, trailing, control, last, onClick }) =>
  <div role="button" tabIndex={0} onClick={onClick} style={{ display: 'grid', gridTemplateColumns: '40px 1fr auto', gap: 16, alignItems: 'center', padding: '12px 16px', minHeight: 48, borderBottom: last ? 'none' : 'var(--memox-border-ghost)', cursor: 'pointer' }}>
    <div className="icon-tile" style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Ic name={icon} size="sm" color="var(--memox-primary)" />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 16, fontWeight: 600, letterSpacing: '-0.1px', textWrap: 'pretty' }}>{label}</div>
      {subtitle && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, lineHeight: 1.45 }}>{subtitle}</div>}
    </div>
    {control ? <span /> : trailing || <Ic name="chevron-right" size="sm" color="var(--memox-on-surface-variant)" />}
    {/* Wide control (stepper, segmented) gets its own line — a 3-chip segmented
        squeezes the label to ~22px at 360 if it stays in the trailing slot. */}
    {control ? <div style={{ gridColumn: '2 / -1', marginTop: 12 }}>{control}</div> : null}
  </div>;

/* Number stepper — the cards-per-session control (1–200). */
const Stepper = ({ value, invalid = false, busy = false }) =>
  <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
    <button className="icon-btn" aria-label="Fewer cards" style={{ width: 36, height: 36, background: 'var(--memox-surface-container)', borderRadius: 'var(--memox-radius-md)' }}><Ic name="minus" size="xs" /></button>
    <span style={{ minWidth: 48, textAlign: 'center', fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: invalid ? 'var(--memox-error)' : 'var(--memox-on-surface)', padding: '6px 4px', borderRadius: 'var(--memox-radius-sm)', border: invalid ? '1px solid var(--memox-error)' : '1px solid transparent' }}>{busy ? <Spinner size="xs" /> : value}</span>
    <button className="icon-btn" aria-label="More cards" style={{ width: 36, height: 36, background: 'var(--memox-surface-container)', borderRadius: 'var(--memox-radius-md)' }}><Ic name="plus" size="xs" /></button>
  </div>;

/* Segmented value — theme / new-card order. */
const Seg = ({ options, value }) =>
  <div style={{ display: 'inline-flex', padding: 4, gap: 2, background: 'var(--memox-surface-container)', borderRadius: 'var(--memox-radius-md)' }}>
    {options.map((o) => <button key={o} style={{ height: 32, padding: '0 12px', borderRadius: 'var(--memox-radius-sm)', border: 'none', fontFamily: 'inherit', fontSize: 12, fontWeight: 600, cursor: 'pointer', background: o === value ? 'var(--memox-surface-container-lowest)' : 'transparent', color: o === value ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)', boxShadow: o === value ? 'var(--memox-shadow-soft)' : 'none' }}>{o}</button>)}
  </div>;

function SettingsScreenV3({ go, state = 'loaded' }) {
  const loading = state === 'loading';
  const saving = state === 'saving';
  const invalid = state === 'invalidLimit';
  const sub = (t, w) => loading ? <Skel w={w} /> : t;
  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar appbar-lg"><div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Settings</div></div>
      <div className="scroll">
        <Section title="Study defaults" note={<Note>Apply to sessions started from now on. A deck with its own study options keeps them.</Note>}>
          <Row icon="layers" label="Cards per session" subtitle={invalid ? <span style={{ color: 'var(--memox-error)', fontWeight: 600 }}>Enter a number from 1 to 200</span> : sub('1 to 200 · default 20', 120)} control={loading ? <Skel w={140} /> : <Stepper value={invalid ? 250 : 20} invalid={invalid} busy={saving} />} />
          <Row icon="shuffle" label="New-card order" subtitle={sub('How new cards enter a learning session', 200)} control={loading ? <Skel w={140} /> : <Seg options={['Created', 'Random']} value="Created" />} last />
        </Section>
        <Section title="App">
          <Row icon="palette" label="Theme" subtitle={sub('Follows the system setting', 160)} control={loading ? <Skel w={180} /> : <Seg options={['System', 'Light', 'Dark']} value="System" />} />
          <Row icon="globe" label="Language" subtitle={sub('System · English', 110)} />
          <Row icon="bell" label="Daily reminder" subtitle={sub('Off', 40)} last />
        </Section>
        <Section title="Reset" note={<Note>Only these app options return to their defaults. Decks, cards, per-deck study options and learning progress are not touched.</Note>}>
          <Row icon="rotate-ccw" label="Reset app options" subtitle={sub('Theme, language, study defaults', 180)} last />
        </Section>
      </div>
      {state === 'saved' && <Snackbar aboveNav>Saved</Snackbar>}
      {state === 'saveFailed' && <Snackbar aboveNav action="Retry">Couldn’t save cards per session. Still 20.</Snackbar>}
      {state === 'resetDone' && <Snackbar aboveNav>App options reset to defaults</Snackbar>}
      {state === 'resetConfirm' &&
        <Dialog size="md">
          <div style={{ padding: '20px 20px 4px' }}>
            <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Reset app options?</div>
            <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55 }}>Theme, language, cards per session and new-card order go back to their defaults.</div>
            <Note icon="shield-check" style={{ marginTop: 12 }}>Your decks, cards, schedules and study history stay exactly as they are. This is not “Reset learning progress”.</Note>
          </div>
          <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
            <button className="pill-btn primary" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Reset options</button>
          </div>
        </Dialog>}
      <BottomNav active="settings" onChange={go} />
    </div>);
}

Object.assign(window, { SettingsScreenV3 });
})();
