/* MemoX Mobile — LearningSettingsScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     LearningSettingsScreen/
       LearningSettingsScreen.jsx  ← shared settings layout, rendered from a flag set
       states/                     ← one file per state in window.MemoXStates.LearningSettings

   Auto-saving settings page; the five states are flag-driven variations of one
   layout. Each state file returns its flags:
     window.MemoXStates.LearningSettings.<name> = () =>
       ({ goalEnabled, reminderOn, permDenied, showSaved })
   and MAIN renders the shared sections from them. */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

const dailyGoal = 20;
const goalMin = 5, goalMax = 200;
const goalPct = (dailyGoal - goalMin) / (goalMax - goalMin) * 100;
const reminderTime = '20:00';

const Toggle = window.Toggle;

const Section = ({ title, children, hint }) =>
  <div style={{ marginBottom: 20 }}>
    <div className="ov" style={{ padding: '0 4px 8px' }}>{title}</div>
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>{children}</div>
    {hint && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '8px 4px 0', lineHeight: 1.5 }}>{hint}</div>}
  </div>;

const Row = ({ icon, label, sub, right, dim, last, onTap }) =>
  <div onClick={onTap} role="button" tabIndex={dim ? -1 : 0} aria-disabled={dim || undefined} style={{ display: 'grid', gridTemplateColumns: icon ? '34px 1fr auto' : '1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: last ? 'none' : 'var(--memox-border-ghost)', opacity: dim ? 0.45 : 1, pointerEvents: dim ? 'none' : 'auto' }}>
    {icon &&
      <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Ic name={icon} size="xs" color="var(--memox-primary)" />
      </div>}
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{label}</div>
      {sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>{sub}</div>}
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>{right}</div>
  </div>;

/* ════════════ SCREEN ════════════ */
function LearningSettingsScreen({ go, state = 'goalOn' }) {
  const States = (window.MemoXStates && window.MemoXStates.LearningSettings) || {};
  const mod = States[state] || States.goalOn;
  const f = (mod ? mod() : {}) || {};
  const { goalEnabled = true, reminderOn = false, permDenied = false, showSaved = false } = f;

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" onClick={() => go('settings')}>
          <Ic name="arrow-left" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>Learning</div>
        <div style={{ opacity: showSaved ? 1 : 0, transition: 'opacity 200ms ease', display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 600, color: 'var(--memox-mastery)', padding: '4px 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', pointerEvents: 'none' }}>
          <Ic name="check" size="xs" color="var(--memox-mastery)" />
          Saved
        </div>
      </div>

      <div className="scroll">

        {/* Daily goal */}
        <Section title="Daily goal" hint={goalEnabled ? null : 'Goal is off. Your streak is frozen — it won’t reset while paused.'}>
          <Row label="Set a daily goal" sub={goalEnabled ? 'Track how many cards you complete each day.' : 'Pause goal tracking without losing your streak.'} right={<Toggle on={goalEnabled} />} />

          <div style={{ padding: '16px 16px 16px', borderTop: 'var(--memox-border-ghost)', opacity: goalEnabled ? 1 : 0.4, pointerEvents: goalEnabled ? 'auto' : 'none' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 16 }}>
              <div className="ov">Cards per day</div>
              <div style={{ display: 'inline-flex', alignItems: 'baseline', gap: 4, fontVariantNumeric: 'tabular-nums' }}>
                <span style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px', color: 'var(--memox-primary)' }}>{dailyGoal}</span>
                <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>cards</span>
              </div>
            </div>
            <div style={{ position: 'relative', height: 24, marginBottom: 8 }}>
              <div style={{ position: 'absolute', top: '50%', left: 0, right: 0, height: 6, transform: 'translateY(-50%)', background: 'var(--memox-surface-container-high)', borderRadius: 999 }} />
              <div style={{ position: 'absolute', top: '50%', left: 0, height: 6, width: `${goalPct}%`, transform: 'translateY(-50%)', background: 'var(--memox-primary)', borderRadius: 999 }} />
              <div style={{ position: 'absolute', top: '50%', left: `${goalPct}%`, transform: 'translate(-50%, -50%)', width: 22, height: 22, borderRadius: 999, background: 'var(--memox-surface-bright)', border: '2px solid var(--memox-primary)', boxShadow: '0 2px 6px color-mix(in srgb, var(--memox-primary) 25%, transparent)' }} />
              {[0, 25, 50, 75, 100].map((p) =>
                <div key={p} style={{ position: 'absolute', top: '50%', left: `${p}%`, transform: 'translate(-50%, -50%)', width: 2, height: 2, borderRadius: 999, background: p <= goalPct ? 'rgba(255,255,255,0.85)' : 'var(--memox-outline-variant)' }} />
              )}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', padding: '0 2px' }}>
              <span>{goalMin}</span>
              <span style={{ opacity: 0.7 }}>50</span>
              <span style={{ opacity: 0.7 }}>100</span>
              <span style={{ opacity: 0.7 }}>150</span>
              <span>{goalMax}</span>
            </div>
            <div style={{ marginTop: 8, fontSize: 12, color: 'var(--memox-on-surface-variant)', display: 'flex', alignItems: 'center', gap: 4 }}>
              <Ic name="info" size="xs" color="var(--memox-on-surface-variant)" />
              <span>Drag to adjust in steps of 5</span>
            </div>
          </div>

          <Row icon="flame" label="Show streak counter" sub="Display your current streak on Home and Stats." right={<Toggle on={true} disabled={!goalEnabled} />} dim={!goalEnabled} last />
        </Section>

        {/* Reminder */}
        <Section title="Reminder" hint={!reminderOn && !permDenied ? 'A gentle nudge once a day. Off by default.' : null}>
          <Row label="Daily reminder" sub={reminderOn ? 'Nudge me to study every day.' : 'You decide when to come back.'} right={<Toggle on={reminderOn} />} />
          <Row icon="clock" label="Reminder time" right={
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 14, fontWeight: 600, fontVariantNumeric: 'tabular-nums', color: reminderOn && !permDenied ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)' }}>
              {reminderTime}
              <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
            </div>
          } dim={!reminderOn || permDenied} last />

          {permDenied &&
            <div style={{ borderTop: 'var(--memox-border-ghost)', padding: '12px 16px', background: 'color-mix(in srgb, var(--memox-streak) 6%, transparent)', display: 'flex', gap: 8, alignItems: 'flex-start' }}>
              <Ic name="bell-off" size="xs" color="var(--memox-streak)" />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px' }}>Notifications are blocked</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.5 }}>
                  Allow MemoX in your phone’s notification settings to receive the reminder.
                </div>
                <button className="pill-btn primary" style={{ marginTop: 8, height: 34, fontSize: 12, padding: '0 16px', borderRadius: 8 }}>
                  <Ic name="external-link" size="xs" color="var(--memox-on-primary)" />
                  Open system settings
                </button>
              </div>
            </div>}
        </Section>

        {/* Tags */}
        <Section title="Tags">
          <Row icon="tag" label="Manage tags" sub="14 tags across all decks" right={<Ic name="chevron-right" size="sm" color="var(--memox-on-surface-variant)" />} last onTap={() => go && go('tags')} />
        </Section>

        {/* Study defaults */}
        <Section title="Study defaults" hint="Applied to every new session — you can still change them per study.">
          <Row icon="shuffle" label="Default shuffle" sub="Randomize card order in every session" right={<Toggle on={true} />} />
          <Row icon="layers" label="Default study mode" sub="Review, Match, Guess, Recall, or Fill" right={
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface)' }}>
              Review
              <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
            </div>
          } />
          <Row icon="eye" label="Show example sentence" sub="Reveal the example with the meaning" right={<Toggle on={true} />} last />
        </Section>

        <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 0 16px' }}>
          Changes save automatically.
        </div>
      </div>
    </div>);
}

Object.assign(window, { LearningSettingsScreen });
})();
