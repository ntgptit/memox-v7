/* MemoX Mobile — AudioSpeechScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     AudioSpeechScreen/
       AudioSpeechScreen.jsx  ← shared TTS settings layout + per-language data
       states/                ← one file per state in window.MemoXStates.AudioSpeech

   Seven states are flag-driven variations of one layout (the language tab swaps a
   per-language data block). Each state file returns its flags:
     window.MemoXStates.AudioSpeech.<name> = () =>
       ({ lang:'ko'|'en', loading, empty, engineErr, playing, showSaved })
   and MAIN renders the shared sections from them. */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

const DATA = {
  ko: {
    flag: '한', label: 'Korean',
    voices: [
      { id: 'sys', name: 'System default', meta: 'Uses your phone’s default Korean voice', sys: true },
      { id: 'k-suji', name: 'Suji', meta: 'Female · neural · offline' },
      { id: 'k-minho', name: 'Minho', meta: 'Male · neural · offline' },
      { id: 'k-eun', name: 'Eunha', meta: 'Female · standard' }
    ],
    selected: 'k-suji', sample: '오늘도 한 단어 더 외워봐요.', sampleHint: 'Today, let’s remember one more word.',
    rate: 0.5, pitch: 1.0, volume: 0.85
  },
  en: {
    flag: 'EN', label: 'English',
    voices: [
      { id: 'sys', name: 'System default', meta: 'Uses your phone’s default English voice', sys: true },
      { id: 'e-emma', name: 'Emma', meta: 'Female · neural · offline' },
      { id: 'e-ryan', name: 'Ryan', meta: 'Male · neural · offline' }
    ],
    selected: 'e-emma', sample: 'One word a day keeps forgetting away.', sampleHint: null,
    rate: 0.55, pitch: 1.0, volume: 0.9
  }
};

const Toggle = window.Toggle;
const Skeleton = window.Skeleton;

const Section = ({ title, children, hint }) =>
  <div style={{ marginBottom: 20 }}>
    {title && <div className="ov" style={{ padding: '0 4px 8px' }}>{title}</div>}
    {children}
    {hint && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '8px 4px 0', lineHeight: 1.5 }}>{hint}</div>}
  </div>;

const Slider = ({ value, min, max, format, label, sublabels }) => {
  const pct = (value - min) / (max - min) * 100;
  return (
    <div style={{ padding: '16px 16px', borderBottom: 'var(--memox-border-ghost)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
        <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{label}</div>
        <div style={{ fontSize: 14, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: 'var(--memox-primary)' }}>{format(value)}</div>
      </div>
      <div style={{ position: 'relative', height: 22, marginBottom: 4 }}>
        <div style={{ position: 'absolute', top: '50%', left: 0, right: 0, height: 5, transform: 'translateY(-50%)', background: 'var(--memox-surface-container-high)', borderRadius: 999 }} />
        <div style={{ position: 'absolute', top: '50%', left: 0, height: 5, width: `${pct}%`, transform: 'translateY(-50%)', background: 'var(--memox-primary)', borderRadius: 999 }} />
        <div style={{ position: 'absolute', top: '50%', left: `${pct}%`, transform: 'translate(-50%, -50%)', width: 20, height: 20, borderRadius: 999, background: 'var(--memox-surface-bright)', border: '2px solid var(--memox-primary)', boxShadow: '0 2px 6px color-mix(in srgb, var(--memox-primary) 22%, transparent)' }} />
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', padding: '0 2px' }}>
        {sublabels.map((s, i) => <span key={i}>{s}</span>)}
      </div>
    </div>);
};

const VoiceBars = () =>
  <div style={{ display: 'inline-flex', alignItems: 'flex-end', gap: 4, height: 14 }}>
    {[0, 1, 2, 3].map((i) =>
      <span key={i} style={{ display: 'inline-block', width: 3, borderRadius: 2, background: '#fff', height: 4 + i % 3 * 4, animation: `memoxVoiceBar 0.9s ease-in-out ${i * 0.12}s infinite alternate` }} />
    )}
  </div>;

/* ════════════ SCREEN ════════════ */
function AudioSpeechScreen({ go, state = 'loaded' }) {
  const States = (window.MemoXStates && window.MemoXStates.AudioSpeech) || {};
  const mod = States[state] || States.loaded;
  const f = (mod ? mod() : {}) || {};
  const { lang = 'ko', loading = false, empty = false, engineErr = false, playing = false, showSaved = false } = f;
  const data = DATA[lang];

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" onClick={() => go('settings')}>
          <Ic name="arrow-left" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>Audio & speech</div>
        <div style={{ opacity: showSaved ? 1 : 0, transition: 'opacity 200ms ease', display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 600, color: 'var(--memox-mastery)', padding: '4px 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', pointerEvents: 'none' }}>
          <Ic name="check" size="xs" color="var(--memox-mastery)" />
          Saved
        </div>
      </div>

      <div className="scroll">

        {engineErr &&
          <div style={{ background: 'color-mix(in srgb, var(--memox-danger) 6%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-danger) 22%, transparent)', borderRadius: 12, padding: '12px 16px', display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px' }}>Text-to-speech is unavailable</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.5 }}>
                Install a TTS engine in your phone’s settings to enable voice playback.
              </div>
              <button className="pill-btn primary" style={{ marginTop: 8, height: 34, fontSize: 12, padding: '0 16px', borderRadius: 8 }}>
                <Ic name="external-link" size="xs" color="var(--memox-on-primary)" />
                Open system settings
              </button>
            </div>
          </div>}

        {/* General */}
        <Section title="General">
          <div className="card" style={{ padding: 0, overflow: 'hidden', opacity: engineErr ? 0.5 : 1, pointerEvents: engineErr ? 'none' : 'auto' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '34px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: 'var(--memox-border-ghost)' }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name="play" size="xs" color="var(--memox-primary)" />
              </div>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>Auto-play on reveal</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>Speak the front when a new card appears.</div>
              </div>
              <Toggle on={false} />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '34px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px' }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name="award" size="xs" color="var(--memox-primary)" />
              </div>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>Play after grading</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>Replay the term after you rate the card.</div>
              </div>
              <Toggle on={false} />
            </div>
          </div>
        </Section>

        {/* Language tabs */}
        <Section title="Language">
          <div style={{ display: 'flex', gap: 4 }}>
            {[{ id: 'ko', flag: '한', label: 'Korean' }, { id: 'en', flag: 'EN', label: 'English' }].map((t) => {
              const active = lang === t.id;
              return (
                <button key={t.id} className="pill-btn" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, padding: '0 12px', background: active ? 'var(--memox-primary)' : 'var(--memox-surface-container-lowest)', color: active ? '#fff' : 'var(--memox-on-surface)', border: active ? 'none' : 'var(--memox-border-ghost)', fontSize: 14, fontWeight: 600, gap: 8 }}>
                  <span style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: 24, height: 24, borderRadius: 8, background: active ? 'rgba(255,255,255,0.18)' : 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: active ? '#fff' : 'var(--memox-primary)', fontSize: 12, fontWeight: 700, letterSpacing: 0.2 }}>{t.flag}</span>
                  {t.label}
                </button>);
            })}
          </div>
        </Section>

        {/* Voice for selected language */}
        <Section title={`Voice · ${data.label}`}>
          <div className="card" style={{ padding: 0, overflow: 'hidden', opacity: engineErr ? 0.4 : 1, pointerEvents: engineErr ? 'none' : 'auto' }}>
            {empty ?
              <div style={{ padding: '28px 20px', textAlign: 'center' }}>
                <div style={{ width: 44, height: 44, borderRadius: 12, background: 'var(--memox-surface-container)', color: 'var(--memox-on-surface-variant)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
                  <Ic name="mic-off" size="sm" color="var(--memox-on-surface-variant)" />
                </div>
                <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 4 }}>No {data.label} voices installed</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, padding: '0 12px', marginBottom: 16 }}>
                  Download a {data.label} voice from your phone’s speech settings to enable playback.
                </div>
                <button className="pill-btn primary" style={{ height: 36, fontSize: 12, padding: '0 16px', borderRadius: 'var(--memox-radius-md)' }}>
                  <Ic name="external-link" size="xs" color="var(--memox-on-primary)" />
                  Open system speech
                </button>
              </div> :
              loading ?
                <div style={{ padding: '8px 0' }}>
                  {[0, 1, 2, 3].map((i) =>
                    <div key={i} style={{ display: 'grid', gridTemplateColumns: '22px 1fr 30px', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < 3 ? 'var(--memox-border-ghost)' : 'none' }}>
                      <Skeleton w={18} h={18} shape="circle" op={0.6} />
                      <div>
                        <Skeleton w={i === 0 ? 120 : 90 + i * 10} h={11} r={4} op={0.6} style={{ display: 'inline-block' }} />
                        <Skeleton w={60 + i * 20} h={9} r={4} op={0.4} style={{ marginTop: 4 }} />
                      </div>
                      <span />
                    </div>
                  )}
                </div> :
                data.voices.map((v, i, a) => {
                  const sel = v.id === data.selected;
                  return (
                    <div key={v.id} style={{ display: 'grid', gridTemplateColumns: '22px 1fr 32px', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', background: sel ? 'color-mix(in srgb, var(--memox-primary) 4%, transparent)' : 'transparent' }}>
                      <span style={{ width: 18, height: 18, borderRadius: 999, border: sel ? '5px solid var(--memox-primary)' : '2px solid var(--memox-outline-variant)', background: sel ? '#fff' : 'transparent', boxSizing: 'border-box' }} />
                      <div style={{ minWidth: 0 }}>
                        <div style={{ fontSize: 14, fontWeight: sel ? 700 : 600, letterSpacing: '-0.1px', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                          {v.name}
                          {v.sys &&
                            <span style={{ height: 18, padding: '0 4px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', fontSize: 12, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase', display: 'inline-flex', alignItems: 'center' }}>Default</span>}
                        </div>
                        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.4 }}>{v.meta}</div>
                      </div>
                      <button className="icon-btn" title={`Preview ${v.name}`} style={{ width: 30, height: 30 }}>
                        <Ic name="volume-2" size="xs" color={sel ? 'var(--memox-primary)' : 'var(--memox-on-surface-variant)'} />
                      </button>
                    </div>);
                })}

            {!empty && !loading &&
              <>
                <Slider label="Speech rate" value={data.rate} min={0.3} max={0.7} format={(v) => `${v.toFixed(2)}×`} sublabels={['0.3×', 'Default', '0.7×']} />
                <Slider label="Pitch" value={data.pitch} min={0.7} max={1.5} format={(v) => v.toFixed(2)} sublabels={['0.70', '1.00', '1.50']} />
                <Slider label="Volume" value={data.volume} min={0.0} max={1.0} format={(v) => `${Math.round(v * 100)}%`} sublabels={['0%', '50%', '100%']} />
                <div style={{ padding: '12px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>Reset {data.label} voice settings</div>
                  <button className="pill-btn outline" style={{ height: 32, fontSize: 12, padding: '0 12px', borderRadius: 8 }}>
                    <Ic name="rotate-ccw" size="xs" color="var(--memox-primary)" />
                    Reset
                  </button>
                </div>
              </>}
          </div>
        </Section>

        {/* Preview */}
        {!empty && !loading &&
          <Section title="Preview" hint="A short safe phrase. Only the front of cards is spoken.">
            <div className="card" style={{ padding: '16px', opacity: engineErr ? 0.4 : 1, pointerEvents: engineErr ? 'none' : 'auto' }}>
              <div style={{ fontSize: 16, fontWeight: 600, letterSpacing: '-0.2px', lineHeight: 1.4, marginBottom: data.sampleHint ? 4 : 16 }}>{data.sample}</div>
              {data.sampleHint && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontStyle: 'italic', marginBottom: 16, lineHeight: 1.4 }}>{data.sampleHint}</div>}
              <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', background: playing ? 'var(--memox-mastery)' : 'var(--memox-primary)', gap: 8 }}>
                {playing ? <><VoiceBars /> Playing… tap to stop</> : <><Ic name="play" size="xs" color="var(--memox-on-primary)" /> Preview voice</>}
              </button>
            </div>
          </Section>}

        {/* About supported languages */}
        <Section title="About supported languages">
          <div style={{ padding: '12px 16px', background: 'color-mix(in srgb, var(--memox-primary) 5%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-primary) 16%, transparent)', borderRadius: 12, display: 'flex', gap: 8, alignItems: 'flex-start' }}>
            <Ic name="info" size="xs" color="var(--memox-primary)" />
            <div style={{ flex: 1, fontSize: 12, color: 'var(--memox-on-surface)', lineHeight: 1.55 }}>
              MemoX currently speaks <strong style={{ fontWeight: 700 }}>Korean</strong> and <strong style={{ fontWeight: 700 }}>English</strong>. Other-language cards stay silent and never read the back.
            </div>
          </div>
        </Section>

        <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 0 16px' }}>
          Changes save automatically.
        </div>
      </div>

      <style>{`
        @keyframes memoxVoiceBar { from { transform: scaleY(0.4); } to { transform: scaleY(1.4); } }
      `}</style>
    </div>);
}

Object.assign(window, { AudioSpeechScreen });
})();
