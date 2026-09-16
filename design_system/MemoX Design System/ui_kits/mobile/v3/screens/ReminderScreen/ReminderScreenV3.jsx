/* MemoX Mobile v3 — ReminderScreenV3  (A23 · Daily reminder)
   Cloned from v1 LearningSettingsScreen, reduced to its reminder half.
   REMOVE daily goal and study-defaults sections (no goals; defaults live in
   Settings). KEEP Section + Row + Toggle + time row. ADD: fires only when cards
   are due, privacy note (deck name + count, never card content, BR-222),
   unavailable-on-this-device (BR-229), turning on, could-not-schedule,
   turned-off-but-one-may-still-show, load error.
   States: off · turningOn · on · changingTime · permDenied · couldNotSchedule · unavailable · offMayShow · loading */
(function () {
const { StatusBar, Ic, Toggle, Note, Spinner } = window;
const Skel = window.Skeleton;

const Section = ({ title, children, note }) =>
  <div style={{ marginBottom: 16 }}>
    {title && <div className="ov" style={{ padding: '0 4px 8px' }}>{title}</div>}
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>{children}</div>
    {note && <div style={{ padding: '8px 4px 0' }}>{note}</div>}
  </div>;

const Row = ({ icon, label, sub, right, last, dim }) =>
  <div style={{ display: 'grid', gridTemplateColumns: icon ? '40px 1fr auto' : '1fr auto', gap: 16, alignItems: 'center', padding: '12px 16px', minHeight: 48, borderBottom: last ? 'none' : 'var(--memox-border-ghost)', opacity: dim ? 'var(--memox-op-disabled)' : 1 }}>
    {icon && <div className="icon-tile" style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Ic name={icon} size="sm" color="var(--memox-primary)" /></div>}
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 16, fontWeight: 600, letterSpacing: '-0.1px' }}>{label}</div>
      {sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, lineHeight: 1.45 }}>{sub}</div>}
    </div>
    {right}
  </div>;

function ReminderScreenV3({ go, state = 'off' }) {
  const on = ['on', 'changingTime'].includes(state);
  const loading = state === 'loading';
  const unavailable = state === 'unavailable';
  const denied = state === 'permDenied';
  const failed = state === 'couldNotSchedule';
  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" onClick={() => go('settings')} aria-label="Back"><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>Daily reminder</div>
      </div>
      <div className="scroll">
        {unavailable ?
          <Section>
            <Row icon="bell-off" label="Reminders are not available on this device" sub="This build cannot deliver notifications. Nothing to turn on here." last />
          </Section> :
          <>
            <Section note={<Note icon="bell">Fires once a day, only when cards are due. Never for new cards, never twice.</Note>}>
              <Row icon="bell" label="Daily reminder" sub={loading ? <Skel w={140} h={10} /> : on ? 'One notification a day at the time below' : denied ? 'Off · notification permission was refused' : 'Off · nothing is scheduled'}
                right={state === 'turningOn' ? <Spinner size="sm" /> : <Toggle on={on} disabled={loading} />} />
              <Row icon="clock" label="Time" sub={on ? 'Local time · stays the same if you travel' : 'Turn the reminder on to choose a time'} dim={!on}
                right={<button className="pill-btn" disabled={!on} style={{ height: 36, padding: '0 12px', borderRadius: 'var(--memox-radius-md)', fontSize: 14, fontWeight: 700, fontVariantNumeric: 'tabular-nums', background: state === 'changingTime' ? 'color-mix(in srgb, var(--memox-primary) 12%, transparent)' : 'var(--memox-surface-container)', border: state === 'changingTime' ? '1px solid var(--memox-primary)' : 'none', color: on ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)' }}>20:00</button>} last />
            </Section>
            {denied &&
              <div style={{ padding: '12px 16px', background: 'var(--memox-warning-soft)', border: '1px solid var(--memox-warning-border)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
                <Ic name="alert-circle" size="xs" color="var(--memox-warning)" />
                <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55 }}>
                  <div style={{ fontWeight: 700, marginBottom: 2 }}>Notifications are blocked for MemoX</div>
                  <div style={{ color: 'var(--memox-on-surface-variant)', marginBottom: 8 }}>Allow them in Android Settings › Apps › MemoX › Notifications, then turn the reminder on again.</div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button className="pill-btn primary" style={{ height: 32, padding: '0 12px', borderRadius: 'var(--memox-radius-md)', fontSize: 12 }}>Open system settings</button>
                    <button className="pill-btn outline" style={{ height: 32, padding: '0 12px', borderRadius: 'var(--memox-radius-md)', fontSize: 12 }}>Try again</button>
                  </div>
                </div>
              </div>}
            {failed &&
              <div style={{ padding: '12px 16px', background: 'var(--memox-danger-soft)', border: '1px solid var(--memox-danger-border)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
                <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
                <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55 }}><strong style={{ fontWeight: 700 }}>Couldn’t schedule the reminder.</strong> <span style={{ color: 'var(--memox-on-surface-variant)' }}>It stays off. Try turning it on again.</span></div>
                <button className="pill-btn primary" style={{ height: 32, padding: '0 12px', borderRadius: 'var(--memox-radius-sm)', fontSize: 12 }}>Retry</button>
              </div>}
            {state === 'offMayShow' && <Note icon="info" style={{ marginBottom: 16 }}>Turned off. A reminder already scheduled for today may still appear once.</Note>}
            <Section title="What it says">
              <Row label="“86 cards are due in 한국어 TOPIK I · Từ vựng, and 2 other decks have cards waiting.”" sub="Deck name and counts only — never a card, tag or history, including on the lock screen. Opening it lands on Study." last />
            </Section>
          </>}
      </div>
    </div>);
}

Object.assign(window, { ReminderScreenV3 });
})();
