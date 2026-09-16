/* MemoX Mobile — SettingsScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     SettingsScreen/
       SettingsScreen.jsx  ← shared nav-hub layout + Section/Row + dispatch
       states/             ← one file per state in window.MemoXStates.Settings

   This is a navigation-only hub; the five states only change the Account row
   (subtitle / chip / icon) and swap row subtitles for skeletons while loading.
   So each state file returns:
     window.MemoXStates.Settings.<name> = (ctx) =>
       ({ loading, account: { icon, iconBg, iconColor, label, subtitle, chip } })
   and MAIN renders the shared sections from it (ctx gives Ic/Skel/Spinner so the
   state files can build their subtitle/chip nodes). */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

/* settings value placeholders are inline, not block. */
const Skel = ({ w = 120 }) => <window.Skeleton w={w} h={12} op={0.55} r={4} style={{ display: 'inline-block' }} />;

const Spinner = window.Spinner;

const Section = ({ title, children }) =>
  <div style={{ marginBottom: 20 }}>
    <div className="ov" style={{ padding: '0 4px 8px' }}>{title}</div>
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>{children}</div>
  </div>;

const Row = ({ icon, iconBg, iconColor, label, subtitle, disabled, chip, last }) =>
  <div role="button" tabIndex={disabled ? -1 : 0} aria-disabled={disabled || undefined} style={{ display: 'grid', gridTemplateColumns: '40px 1fr auto', gap: 16, alignItems: 'center', padding: '16px 16px', borderBottom: last ? 'none' : 'var(--memox-border-ghost)', opacity: disabled ? 0.55 : 1, cursor: disabled ? 'default' : 'pointer' }}>
    <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: iconBg || 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: iconColor || 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Ic name={icon} size="sm" color={iconColor || 'var(--memox-primary)'} />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 16, fontWeight: 600, letterSpacing: '-0.1px' }}>{label}</div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', display: 'flex', alignItems: 'center', gap: 4 }}>{subtitle}</div>
    </div>
    {chip ? chip : <Ic name="chevron-right" size="sm" color="var(--memox-on-surface-variant)" />}
  </div>;

/* ════════════ SCREEN ════════════ */
function SettingsScreen({ go, state = 'populated' }) {
  const States = (window.MemoXStates && window.MemoXStates.Settings) || {};
  const mod = States[state] || States.populated;
  const cfg = (mod ? mod({ Ic, Skel, Spinner }) : {}) || {};
  const loading = !!cfg.loading;
  const account = cfg.account || {};
  const sub = (text, w) => loading ? <Skel w={w} /> : text;

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar appbar-lg">
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Settings</div>
      </div>

      <div className="scroll">
        <Section title="Account">
          <Row icon={account.icon} iconBg={account.iconBg} iconColor={account.iconColor} label={account.label} subtitle={account.subtitle} chip={account.chip} last />
        </Section>

        <Section title="Study">
          <Row icon="target" label="Learning" subtitle={sub('20 cards / day · 5 study modes', 170)} />
          <Row icon="volume-2" label="Audio & speech" subtitle={sub('Korean voice · 0.9× speed', 140)} />
          <Row icon="tag" label="Manage tags" subtitle={sub('14 tags', 60)} last />
        </Section>

        <Section title="App">
          <Row icon="palette" label="Appearance" subtitle={sub('System · matches your phone', 180)} />
          <Row icon="globe" label="Language" subtitle={sub('English', 70)} last />
        </Section>

        <Section title="About">
          <Row icon="info" label="About MemoX" subtitle={sub('Version 1.4.2 (build 248)', 150)} last />
        </Section>

        <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 0 16px', letterSpacing: 0.2 }}>
          Made for calm learning · MemoX
        </div>
      </div>

      <BottomNav active="settings" onChange={go} />

    </div>);
}

Object.assign(window, { SettingsScreen });
})();
