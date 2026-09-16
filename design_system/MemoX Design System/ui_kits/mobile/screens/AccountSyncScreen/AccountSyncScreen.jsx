/* MemoX Mobile — AccountSyncScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     AccountSyncScreen/
       AccountSyncScreen.jsx  ← shared widgets + signed-out / signed-in branches
       states/                ← one file per state in window.MemoXStates.AccountSync

   Nine states split across two layouts (signed-out: signedOut/signingIn/signInFailed;
   signed-in: noBackup/ready/uploading/restoreWarn/restoring/tokenExpired), each a
   flag-driven variation of its branch. Each state file declares a descriptor:
     signed-out → { branch:'out', isLoading, isFailed }
     signed-in  → { branch:'in', uploading, restoring, restoreWarn, noBackup, tokenExpired }
   and MAIN renders the shared branch from it. */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

/* white-on-primary default: these spinners sit inside filled CTAs. */
const Spinner = (p) => <window.Spinner color="#fff" {...p} />;

const Section = ({ title, children, gap = 10 }) =>
  <div style={{ marginBottom: 16 }}>
    <div className="ov" style={{ padding: '0 4px 8px' }}>{title}</div>
    <div style={{ display: 'flex', flexDirection: 'column', gap }}>{children}</div>
  </div>;

const Banner = ({ tone = 'info', icon, title, body, action }) => {
  const tones = {
    info: { bg: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', border: 'color-mix(in srgb, var(--memox-primary) 20%, transparent)', col: 'var(--memox-primary)' },
    warn: { bg: 'color-mix(in srgb, var(--memox-streak) 10%, transparent)', border: 'color-mix(in srgb, var(--memox-streak) 24%, transparent)', col: 'var(--memox-streak)' },
    danger: { bg: 'color-mix(in srgb, var(--memox-danger) 8%, transparent)', border: 'color-mix(in srgb, var(--memox-danger) 22%, transparent)', col: 'var(--memox-error)' },
    ok: { bg: 'color-mix(in srgb, var(--memox-mastery) 8%, transparent)', border: 'color-mix(in srgb, var(--memox-mastery) 20%, transparent)', col: 'var(--memox-mastery)' }
  }[tone];
  return (
    <div style={{ background: tones.bg, border: `1px solid ${tones.border}`, borderRadius: 12, padding: '12px 16px', display: 'flex', gap: 8, alignItems: 'flex-start' }}>
      <div style={{ paddingTop: 1 }}><Ic name={icon} size="xs" color={tones.col} /></div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--memox-on-surface)', letterSpacing: '-0.1px' }}>{title}</div>
        {body && <div style={{ fontSize: 12, lineHeight: 1.5, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{body}</div>}
        {action && <div style={{ marginTop: 8 }}>{action}</div>}
      </div>
    </div>);
};

const GoogleG = ({ size = 'sm' }) => {
  const px = (window.ICON || {})[size] || size;
  return <svg width={px} height={px} viewBox="0 0 18 18" aria-hidden="true">
    <path fill="#4285F4" d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84c-.21 1.12-.84 2.07-1.78 2.71v2.26h2.88c1.68-1.55 2.66-3.83 2.66-6.61z" />
    <path fill="#34A853" d="M9 18c2.43 0 4.46-.8 5.95-2.18l-2.88-2.26c-.8.54-1.83.86-3.07.86-2.36 0-4.36-1.59-5.07-3.74H.9v2.33A8.99 8.99 0 0 0 9 18z" />
    <path fill="#FBBC05" d="M3.93 10.68A5.41 5.41 0 0 1 3.64 9c0-.58.1-1.15.29-1.68V4.99H.9A8.99 8.99 0 0 0 0 9c0 1.45.35 2.83.9 4.01l3.03-2.33z" />
    <path fill="#EA4335" d="M9 3.58c1.32 0 2.51.45 3.44 1.35l2.58-2.58C13.46.89 11.43 0 9 0A8.99 8.99 0 0 0 .9 4.99l3.03 2.33C4.64 5.17 6.64 3.58 9 3.58z" />
  </svg>;
};

/* ── Signed-out branch ── */
function SignedOut({ go, isLoading, isFailed }) {
  return (
    <div className="app">
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" onClick={() => go('settings')}><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>Account & Drive sync</div>
      </div>
      <div className="scroll">
        <div className="card" style={{ padding: '24px 20px 20px', textAlign: 'center', marginBottom: 16 }}>
          <div style={{ width: 56, height: 56, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
            <Ic name="cloud" size="lg" color="var(--memox-primary)" />
          </div>
          <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.3px', marginBottom: 8 }}>Back up to your Google Drive</div>
          <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 16, padding: '0 4px' }}>
            MemoX works fully offline. Linking Drive lets you upload and restore your decks <em style={{ fontStyle: 'normal', color: 'var(--memox-on-surface)', fontWeight: 600 }}>when you choose</em> — never automatically.
          </div>
          {isFailed &&
            <div style={{ marginBottom: 12, textAlign: 'left' }}>
              <Banner tone="danger" icon="alert-circle" title="Couldn't sign in" body="Check your connection and try again. No data left your device." />
            </div>}
          <button className="pill-btn" disabled={isLoading} style={{ width: '100%', height: 44, borderRadius: 12, background: 'var(--memox-brand-google-surface)', color: 'var(--memox-brand-google-on-surface)', border: '1px solid var(--memox-brand-google-outline)', fontWeight: 600, fontSize: 14, gap: 8, boxShadow: '0 1px 2px rgba(25,28,30,0.04)', opacity: isLoading ? 0.85 : 1 }}>
            {isLoading ? <><Spinner color="var(--memox-primary)" size="xs" /> Signing in…</> : <><GoogleG size="sm" /> Sign in with Google</>}
          </button>
        </div>

        <div className="ov" style={{ padding: '0 4px 8px' }}>What stays local</div>
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {[
            { ic: 'smartphone', t: 'All your decks live on this device', s: 'Study, edit, and review work offline.' },
            { ic: 'shield-check', t: 'No account needed to use MemoX', s: 'Sign in only when you want a backup.' },
            { ic: 'upload-cloud', t: 'You decide when to upload', s: 'Drive backups are always manual.' }
          ].map((r, i, a) =>
            <div key={i} style={{ padding: '12px 16px', display: 'flex', gap: 12, alignItems: 'flex-start', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Ic name={r.ic} size="xs" color="var(--memox-primary)" />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{r.t}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>{r.s}</div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>);
}

/* ── Signed-in branch ── */
function SignedIn({ go, uploading, restoring, restoreWarn, noBackup, tokenExpired }) {
  const busy = uploading || restoring;
  const uploadPct = 64;
  const restorePct = 38;
  return (
    <div className="app">
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" onClick={() => go('settings')}><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>Account & Drive sync</div>
      </div>

      <div className="scroll">
        <Section title="Account">
          <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
            <div style={{ padding: '16px 16px', display: 'flex', gap: 12, alignItems: 'center' }}>
              <div style={{ width: 42, height: 42, borderRadius: 999, background: 'var(--memox-primary)', color: 'var(--memox-on-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, fontWeight: 700, letterSpacing: 0.2, flexShrink: 0 }}>AL</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>alex.minh@gmail.com</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  <GoogleG size="xs" />
                  <span>Google · linked Apr 8</span>
                </div>
              </div>
              {tokenExpired ?
                <span style={{ height: 24, padding: '0 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)', color: 'var(--memox-streak)', fontSize: 12, fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  <Ic name="alert-triangle" size="xs" color="var(--memox-streak)" />
                  Expired
                </span> :
                <button className="icon-btn" title="Refresh manifest">
                  <Ic name="refresh-cw" size="xs" color="var(--memox-on-surface-variant)" />
                </button>}
            </div>
            {tokenExpired &&
              <div style={{ padding: '0 16px 16px' }}>
                <Banner tone="warn" icon="key-round" title="Drive access expired" body="Sign in again to upload or restore. Your local data is untouched." action={<button className="pill-btn primary" style={{ height: 34, fontSize: 12, padding: '0 16px' }}>Sign in again</button>} />
              </div>}
            <div style={{ padding: '8px 16px', borderTop: 'var(--memox-border-ghost)', display: 'flex', gap: 8 }}>
              <button className="pill-btn outline" style={{ flex: 1, height: 36, fontSize: 12 }}>
                <Ic name="log-out" size="xs" color="var(--memox-primary)" />
                Sign out
              </button>
              <button className="pill-btn secondary" style={{ flex: 1, height: 36, fontSize: 12 }}>
                <Ic name="repeat" size="xs" />
                Switch account
              </button>
            </div>
          </div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '8px 4px 0', lineHeight: 1.5 }}>
            Signing out keeps every deck and card on this device.
          </div>
        </Section>

        <Section title="This device">
          <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
            <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12, borderBottom: 'var(--memox-border-ghost)' }}>
              <div className="icon-tile" style={{ width: 34, height: 34, borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name="smartphone" size="xs" />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>Alex's Pixel 8</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>Device label</div>
              </div>
              <button className="icon-btn" title="Rename device">
                <Ic name="pencil" size="xs" color="var(--memox-on-surface-variant)" />
              </button>
            </div>
            <div style={{ padding: '12px 16px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12 }}>
              {[{ n: '4', l: 'decks' }, { n: '142', l: 'cards' }, { n: '2 h', l: 'last active' }].map((s, i) =>
                <div key={i}>
                  <div style={{ fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.3px' }}>{s.n}</div>
                  <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>{s.l}</div>
                </div>
              )}
            </div>
          </div>
        </Section>

        <Section title="Drive backup">
          <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
            <div style={{ padding: '12px 16px', borderBottom: 'var(--memox-border-ghost)', display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ width: 34, height: 34, borderRadius: 'var(--memox-radius-md)', background: noBackup ? 'var(--memox-surface-container)' : restoreWarn ? 'color-mix(in srgb, var(--memox-streak) 12%, transparent)' : 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', color: noBackup ? 'var(--memox-on-surface-variant)' : restoreWarn ? 'var(--memox-streak)' : 'var(--memox-mastery)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name="cloud" size="xs" color={noBackup ? 'var(--memox-on-surface-variant)' : restoreWarn ? 'var(--memox-streak)' : 'var(--memox-mastery)'} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                {noBackup ?
                  <>
                    <div style={{ fontSize: 14, fontWeight: 600 }}>No backup yet</div>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>Upload to create your first backup.</div>
                  </> :
                  <>
                    <div style={{ fontSize: 14, fontWeight: 600 }}>Last upload {restoreWarn ? '11 days ago' : '2 days ago'}</div>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>{restoreWarn ? '178 cards · 5 decks · from Galaxy S23' : '142 cards · 4 decks'}</div>
                  </>}
              </div>
              {!noBackup && !restoreWarn &&
                <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--memox-mastery)', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  <Ic name="check" size="xs" color="var(--memox-mastery)" />
                  Matches
                </span>}
            </div>

            {uploading &&
              <div style={{ padding: '16px 16px', borderBottom: 'var(--memox-border-ghost)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                  <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--memox-primary)' }}>Uploading to Drive…</div>
                  <div style={{ fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: 'var(--memox-on-surface-variant)' }}>{uploadPct}%</div>
                </div>
                <div style={{ height: 6, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
                  <div style={{ height: '100%', width: `${uploadPct}%`, background: 'var(--memox-primary)', borderRadius: 999 }} />
                </div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4 }}>91 / 142 cards · keep this screen open</div>
              </div>}

            {restoring &&
              <div style={{ padding: '16px 16px', borderBottom: 'var(--memox-border-ghost)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                  <div style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase', color: 'var(--memox-on-surface-variant)' }}>Step 1 of 2</div>
                  <div style={{ fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: 'var(--memox-on-surface-variant)' }}>{restorePct}%</div>
                </div>
                <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface)', marginBottom: 8 }}>Snapshotting local data first…</div>
                <div style={{ height: 6, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
                  <div style={{ height: '100%', width: `${restorePct}%`, background: 'var(--memox-primary)', borderRadius: 999 }} />
                </div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, lineHeight: 1.5 }}>You can cancel until step 2 starts. Local data stays safe either way.</div>
              </div>}

            {restoreWarn &&
              <div style={{ padding: '12px 16px', borderBottom: 'var(--memox-border-ghost)' }}>
                <Banner tone="warn" icon="alert-triangle" title="Backup is from a different device" body="Restoring will replace the 142 cards on this device with the 178 cards from Galaxy S23. Upload local first to keep both safe." />
              </div>}

            <div style={{ padding: '12px 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
              {restoreWarn ?
                <>
                  <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)' }}>
                    <Ic name="upload-cloud" size="xs" color="var(--memox-on-primary)" />
                    Upload local first
                  </button>
                  <button className="pill-btn" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'transparent', border: '1px solid color-mix(in srgb, var(--memox-danger) 40%, transparent)', color: 'var(--memox-error)' }}>
                    <Ic name="download" size="xs" color="var(--memox-error)" />
                    Restore anyway
                  </button>
                </> :
                restoring ?
                  <button className="pill-btn outline" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)' }}>Cancel restore</button> :
                  <>
                    <button className="pill-btn primary" disabled={busy || tokenExpired} style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', opacity: busy || tokenExpired ? 0.5 : 1 }}>
                      {uploading ? <><Spinner color="var(--memox-on-primary)" size="xs" /> Uploading… {uploadPct}%</> : <><Ic name="upload-cloud" size="xs" color="var(--memox-on-primary)" /> Upload to Drive</>}
                    </button>
                    <button className="pill-btn outline" disabled={busy || tokenExpired || noBackup} style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', opacity: busy || tokenExpired || noBackup ? 0.45 : 1 }}>
                      <Ic name="download" size="xs" color="var(--memox-primary)" />
                      Restore from Drive
                    </button>
                  </>}
            </div>

            <div style={{ padding: '0 16px 12px', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>
              {noBackup ? 'Uploads include decks, cards, tags, and review history. Settings stay local.' :
                restoreWarn ? 'Restore replaces everything on this device. There is no undo after step 2.' :
                'Backups are manual — MemoX never uploads automatically.'}
            </div>
          </div>
        </Section>

        <Section title="Danger zone">
          <div className="card" style={{ padding: '16px', borderColor: 'color-mix(in srgb, var(--memox-danger) 20%, transparent)', background: 'color-mix(in srgb, var(--memox-danger) 3%, transparent)' }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface)', marginBottom: 4 }}>Remove account from MemoX</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginBottom: 12 }}>
              Unlinks Google Drive and clears the linked email from this app. Your decks, cards, and review history stay on this device.
            </div>
            <button className="pill-btn" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'var(--memox-error-fill)', color: 'var(--memox-on-error-fill)' }}>
              <Ic name="trash-2" size="xs" color="var(--memox-on-error-fill)" />
              Remove account
            </button>
          </div>
        </Section>
      </div>

    </div>);
}

/* ════════════ SCREEN ════════════ */
function AccountSyncScreen({ go, state = 'ready' }) {
  const States = (window.MemoXStates && window.MemoXStates.AccountSync) || {};
  const mod = States[state] || States.ready;
  const cfg = (mod ? mod() : {}) || {};
  if (cfg.branch === 'out') return <SignedOut go={go} isLoading={!!cfg.isLoading} isFailed={!!cfg.isFailed} />;
  return <SignedIn go={go} uploading={!!cfg.uploading} restoring={!!cfg.restoring} restoreWarn={!!cfg.restoreWarn} noBackup={!!cfg.noBackup} tokenExpired={!!cfg.tokenExpired} />;
}

Object.assign(window, { AccountSyncScreen });
})();
