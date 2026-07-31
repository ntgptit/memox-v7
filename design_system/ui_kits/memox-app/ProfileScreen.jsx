const { MxContentShell, MxCard, MxIcon, MxProgressBar, MxTextButton } = window.MemoxDesignSystem_3a620f;

/**
 * The third tab the redesign adds. Not an account screen — the app is
 * local-first with no auth, so there is no name, no avatar and no sign-out to
 * show. It is what the user has actually accumulated, plus the settings that
 * were previously buried behind an app-bar icon nobody found.
 */
function ProfileScreen({ onReset, isCompact }) {
  const [reminder, setReminder] = React.useState(true);
  const [largerText, setLargerText] = React.useState(false);
  const s = window.MEMOX_STATS;
  const tree = window.MEMOX_TREE;
  const mastery = tree.cards ? tree.learned / tree.cards : 0;

  return (
    <MxContentShell title="You" isScrollable isCompact={isCompact}>
      <div className="mx-today">
        <div className="mx-today__row">
          <span style={{ flex: 1, minWidth: 0 }}>
            <span className="mx-today__figure">{s.streakDays} days</span>
            <span className="mx-today__sub">current streak · best so far {s.bestStreak}</span>
          </span>
          <span className="mx-streak"><MxIcon name="schedule" filled size="var(--icon-sm)" />{s.minutesToday} min today</span>
        </div>
        <MxProgressBar value={mastery} label={tree.learned + ' of ' + tree.cards + ' cards learned'} valueLabel={Math.round(mastery * 100) + '%'} size="sm" />
      </div>

      <div style={{ height: 'var(--space-lg)' }} />
      <div className="mx-stats">
        <Stat value={s.reviewedThisWeek} label="Reviews this week" />
        <Stat value={tree.children.length} label="Decks" />
      </div>

      <div style={{ height: 'var(--space-xl)' }} />
      <p className="mx-section-label">Study</p>
      <MxCard padding="var(--space-xs) 0">
        <SwitchRow title="Daily reminder" subtitle="20:00" value={reminder} onChange={() => setReminder(!reminder)} />
        <RowDivider />
        <ValueRow title="Scheduler" value="Eight box" />
        <RowDivider />
        <ValueRow title="New cards per day" value="20" />
      </MxCard>

      <div style={{ height: 'var(--space-xl)' }} />
      <p className="mx-section-label">Appearance</p>
      <MxCard padding="var(--space-xs) 0">
        <ValueRow title="Theme" value="System" />
        <RowDivider />
        <SwitchRow title="Larger text" value={largerText} onChange={() => setLargerText(!largerText)} />
      </MxCard>

      <div style={{ height: 'var(--space-xl)' }} />
      <p className="mx-section-label">Data</p>
      <MxCard padding="var(--space-xs) 0">
        {/* Actions, not settings — a verb gets a text button, not a ValueRow
            whose chevron promises a detail screen that does not exist. The
            row supplies only the horizontal gutter; the button's own 48
            min-height is the row height. */}
        <ActionRow>
          <MxTextButton label="Export decks" icon="download" onClick={() => {}} />
        </ActionRow>
        <RowDivider />
        <ActionRow>
          <MxTextButton label="Reset learning progress" icon="restart_alt" isDestructive onClick={onReset} />
        </ActionRow>
      </MxCard>
      <div style={{ height: 'var(--space-xl)' }} />
    </MxContentShell>
  );
}

function Stat({ value, label }) {
  return (
    <div className="mx-stat">
      <div className="mx-stat__value">{value}</div>
      <span className="mx-stat__label">{label}</span>
    </div>
  );
}

function SwitchRow({ title, subtitle, value, onChange }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', padding: 'var(--space-sm) var(--space-lg)', minHeight: 48, boxSizing: 'border-box' }}>
      <span style={{ flex: 1, minWidth: 0 }}>
        <span style={{ display: 'block', fontSize: 'var(--text-body-lg)' }}>{title}</span>
        {subtitle ? <span style={{ display: 'block', fontSize: 'var(--text-body-sm)', color: 'var(--color-text-secondary)' }}>{subtitle}</span> : null}
      </span>
      <button type="button" role="switch" aria-checked={value} aria-label={title} onClick={onChange}
        style={{ width: 52, height: 32, flex: 'none', borderRadius: 'var(--radius-pill)', cursor: 'pointer', position: 'relative',
          background: value ? 'var(--color-primary)' : 'var(--color-surface-muted)',
          border: value ? 'none' : '2px solid var(--color-border-subtle)',
          transition: 'background-color var(--duration-fast) var(--ease-standard)' }}>
        <span style={{ position: 'absolute', top: value ? 4 : 6, left: value ? 26 : 6, width: value ? 24 : 16, height: value ? 24 : 16, borderRadius: '50%',
          background: value ? 'var(--color-on-primary)' : 'var(--color-text-secondary)', transition: 'all var(--duration-fast) var(--ease-standard)' }} />
      </button>
    </div>
  );
}

function ValueRow({ title, value }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', padding: 'var(--space-md) var(--space-lg)', minHeight: 48, boxSizing: 'border-box' }}>
      <span style={{ flex: 1, fontSize: 'var(--text-body-lg)' }}>{title}</span>
      <span style={{ fontSize: 'var(--text-body-md)', color: 'var(--color-text-secondary)' }}>{value}</span>
      <span style={{ width: 'var(--space-sm)' }} />
      <MxIcon name="chevron_right" filled size={20} color="var(--color-text-secondary)" />
    </div>
  );
}

/** The horizontal gutter for a row that holds an MxTextButton; the button's
    own 48 min-height is the row height, so the row adds none of its own. */
function ActionRow({ children }) {
  return <div style={{ padding: '0 var(--space-lg)' }}>{children}</div>;
}

function RowDivider() {
  return <div style={{ height: 1, background: 'var(--color-border-subtle)', marginLeft: 'var(--space-lg)' }} />;
}

Object.assign(window, { ProfileScreen, Stat, SwitchRow, ValueRow, ActionRow, RowDivider });
