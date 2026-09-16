/* MemoX Mobile — OnboardingScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     OnboardingScreen/
       OnboardingScreen.jsx  ← welcome screen + zero base + shared widgets + dispatch
       states/               ← one file per state in window.MemoXStates.Onboarding

   `welcome` is a full-screen alternate; `zero` is the base (3 ways to begin);
   the other seven states are overlays (sheets / dialogs) drawn over the zero base.
   So each state module returns one of:
     { welcome: true }              → render the welcome screen
     {}                             → zero base only
     { overlay: <node> }            → zero base + this overlay over a scrim
   Overlays are built with ctx ({ Ic, Spinner, Scrim }) and live in their own files.

   ctx: { go, Ic, Spinner, Scrim } */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

const Scrim = window.Scrim;
const Dialog = window.Dialog;

const Spinner = window.Spinner;

/* ── Welcome — one-screen, no carousel ── */
function WelcomeScreen() {
  return (
    <div className="app" style={{ background: 'linear-gradient(180deg, var(--memox-surface) 0%, rgba(82,101,245,0.04) 100%)' }}>
      <StatusBar />
      <div className="appbar" style={{ justifyContent: 'flex-end' }}>
        <button style={{ background: 'transparent', border: 'none', padding: '8px 12px', color: 'var(--memox-on-surface-variant)', fontSize: 14, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>Skip</button>
      </div>
      <div className="scroll" style={{ padding: '20px 24px 0', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
        <div style={{ textAlign: 'center', marginBottom: 24 }}>
          <div style={{ width: 80, height: 80, borderRadius: 24, background: 'var(--memox-primary)', color: 'var(--memox-on-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 20, boxShadow: '0 12px 32px color-mix(in srgb, var(--memox-primary) 32%, transparent)' }}>
            <Ic name="sparkles" size="xl" color="var(--memox-on-primary)" />
          </div>
          <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.6px', marginBottom: 8, lineHeight: 1.15 }}>
            Remember more,<br />at your own pace.
          </div>
          <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, padding: '0 4px' }}>
            Calm flashcards that surface what you need each day. Local-first — your cards live on this device.
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 20 }}>
          {[
            { ic: 'cloud', l: 'Local-first', s: 'No sign-in needed. Sync is optional, anytime.' },
            { ic: 'sun', l: 'A daily rhythm', s: 'Short sessions, surfaced by what’s due.' },
            { ic: 'shield-check', l: 'No streak pressure', s: 'Skip a day. Your progress is safe.' }
          ].map((b) =>
            <div key={b.l} className="card" style={{ padding: '12px 16px', display: 'grid', gridTemplateColumns: '34px 1fr', gap: 12, alignItems: 'center' }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name={b.ic} size="xs" color="var(--memox-primary)" />
              </div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px' }}>{b.l}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1, lineHeight: 1.45 }}>{b.s}</div>
              </div>
            </div>
          )}
        </div>
      </div>
      <div style={{ padding: '8px 20px 20px' }}>
        <button className="pill-btn primary" style={{ width: '100%', height: 44, borderRadius: 16, fontSize: 16, gap: 8 }}>
          Let’s start
          <Ic name="arrow-right" size="xs" color="var(--memox-on-primary)" />
        </button>
        <div style={{ textAlign: 'center', marginTop: 8, fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
          You’re always in control. Sign-in is optional.
        </div>
      </div>
    </div>);
}

/* ── Zero base — 3 ways to begin (underlies every non-welcome state) ── */
function ZeroBase() {
  return (
    <>
      <div className="appbar appbar-lg" style={{ flexDirection: 'column', alignItems: 'flex-start', gap: 2, paddingTop: 20, paddingBottom: 16, position: 'relative' }}>
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Welcome to MemoX</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>Let’s set up your first cards</div>
        <div style={{ position: 'absolute', right: 14, top: 18, display: 'flex', gap: 4 }}>
          <button className="icon-btn" title="Settings">
            <Ic name="settings" size="sm" color="var(--memox-on-surface-variant)" />
          </button>
        </div>
      </div>

      <div className="scroll">
        <div className="card" style={{ padding: '20px 16px 16px', marginBottom: 16, textAlign: 'center', background: 'color-mix(in srgb, var(--memox-primary) 6%, var(--memox-surface-bright))', border: 'none' }}>
          <div style={{ width: 52, height: 52, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-primary) 14%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
            <Ic name="sparkles" size="md" color="var(--memox-primary)" />
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Three ways to begin</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, padding: '0 4px' }}>
            Pick what fits. You can do the others later — none of these locks you in.
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 20 }}>
          <button style={{ padding: '16px 16px', background: 'var(--memox-primary)', color: 'var(--memox-on-primary)', border: 'none', borderRadius: 16, display: 'grid', gridTemplateColumns: '44px 1fr 18px', gap: 12, alignItems: 'center', textAlign: 'left', fontFamily: 'inherit', cursor: 'pointer', boxShadow: '0 6px 20px color-mix(in srgb, var(--memox-primary) 28%, transparent)' }}>
            <div style={{ width: 40, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', background: 'rgba(255,255,255,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Ic name="layers" size="sm" color="var(--memox-on-primary)" />
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', marginBottom: 2 }}>Create your first deck</div>
              <div style={{ fontSize: 12, opacity: 0.85, lineHeight: 1.4 }}>Start blank · add cards one at a time</div>
            </div>
            <Ic name="arrow-right" size="xs" color="var(--memox-on-primary)" />
          </button>

          <button style={{ padding: '16px 16px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 16, display: 'grid', gridTemplateColumns: '40px 1fr 18px', gap: 12, alignItems: 'center', textAlign: 'left', color: 'var(--memox-on-surface)', fontFamily: 'inherit', cursor: 'pointer' }}>
            <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-mastery) 12%, transparent)', color: 'var(--memox-mastery)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Ic name="upload" size="xs" color="var(--memox-mastery)" />
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', marginBottom: 2 }}>Import from a file</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.4 }}>CSV, TSV, or Excel · preview before adding</div>
            </div>
            <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
          </button>

          <button style={{ padding: '16px 16px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 16, display: 'grid', gridTemplateColumns: '40px 1fr 18px', gap: 12, alignItems: 'center', textAlign: 'left', color: 'var(--memox-on-surface)', fontFamily: 'inherit', cursor: 'pointer' }}>
            <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)', color: 'var(--memox-streak)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Ic name="cloud-download" size="xs" color="var(--memox-streak)" />
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', marginBottom: 2 }}>Sign in & restore</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.4 }}>Returning user · pull from Google Drive backup</div>
            </div>
            <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
          </button>
        </div>

        <div style={{ padding: '8px 12px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, display: 'flex', gap: 8, alignItems: 'flex-start' }}>
          <Ic name="lock" size="xs" color="var(--memox-on-surface-variant)" />
          <span>Your cards stay on this device. Sign-in is optional and never required.</span>
        </div>
      </div>
    </>);
}

/* ════════════ SCREEN ════════════ */
function OnboardingScreen({ go, state = 'zero' }) {
  const States = (window.MemoXStates && window.MemoXStates.Onboarding) || {};
  const mod = States[state] || States.zero;
  const ctx = { go, Ic, Spinner, Scrim, Dialog };
  const out = (mod ? mod(ctx) : {}) || {};

  if (out.welcome) return <WelcomeScreen />;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <ZeroBase />
      {out.overlay ? <><Scrim />{out.overlay}</> : null}
      <style>{`
        @keyframes memoxProgPulse { 0%, 100% { opacity: 0.85; } 50% { opacity: 1; } }
      `}</style>
    </div>);
}

Object.assign(window, { OnboardingScreen });
})();
