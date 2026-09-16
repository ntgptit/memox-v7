/* MemoX Mobile — ProgressScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     ProgressScreen/
       ProgressScreen.jsx  ← shared analytics layout (charts + data + helpers)
       states/             ← one file per state in window.MemoXStates.Progress

   Seven states are flag-driven variations of one read-only analytics layout
   (each chart has its OWN empty/insufficient treatment — never one global empty).
   Each state file returns its flags:
     window.MemoXStates.Progress.<name> = () =>
       ({ range:'week'|'month', loading, allEmpty, insufficient, partial, error })
   and MAIN renders the shared charts from them (error swaps to the full-screen
   error layout). */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

const studied = {
  week: [12, 18, 0, 22, 14, 9, 17],
  month: [11, 14, 18, 16, 0, 9, 21, 19, 12, 16, 22, 14, 13, 18, 8, 11, 16, 19, 15, 12, 17, 14, 0, 13, 16, 22, 18, 14]
};
const accuracy = {
  week: [0.62, 0.68, null, 0.71, 0.78, 0.74, 0.82],
  month: [0.58, 0.61, 0.65, 0.64, null, 0.68, 0.72, 0.74, 0.71, 0.76, 0.78, 0.80, 0.78, 0.82, 0.79, 0.77, 0.80, 0.82, 0.85, 0.83, 0.79, 0.81, null, 0.84, 0.86, 0.88, 0.87, 0.85]
};
const boxes = [
  { n: 1, count: 24, label: 'New / lapsed' },
  { n: 2, count: 38, label: 'Learning' },
  { n: 3, count: 54, label: 'Short-term' },
  { n: 4, count: 71, label: 'Reviewing' },
  { n: 5, count: 86, label: 'Reinforcing' },
  { n: 6, count: 62, label: 'Strong' },
  { n: 7, count: 48, label: 'Long-term' },
  { n: 8, count: 31, label: 'Mastered' }
];
const maxBox = Math.max(...boxes.map((b) => b.count));
const dayLabels = {
  week: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  month: ['1', '', '', '', '5', '', '', '', '', '10', '', '', '', '', '15', '', '', '', '', '20', '', '', '', '', '25', '', '', '']
};
const accDelta = +0.04;

const Skel = window.Skeleton;

const Card = ({ title, value, sub, children, dim }) =>
  <div className="card" style={{ padding: '16px', marginBottom: 12, opacity: dim ? 0.6 : 1 }}>
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8, marginBottom: 12 }}>
      <div style={{ minWidth: 0 }}>
        <div className="ov">{title}</div>
        {value != null && <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px', lineHeight: 1.1, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{value}</div>}
        {sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4 }}>{sub}</div>}
      </div>
    </div>
    {children}
  </div>;

const ChartEmpty = ({ line }) =>
  <div style={{ padding: '24px 16px', textAlign: 'center', background: 'var(--memox-surface-container-lowest)', borderRadius: 'var(--memox-radius-md)', border: '1px dashed var(--memox-outline-variant)', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>{line}</div>;

const InsufficientHint = ({ needed }) =>
  <div style={{ padding: '8px 12px', background: 'color-mix(in srgb, var(--memox-primary) 4%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-primary) 14%, transparent)', borderRadius: 'var(--memox-radius-md)', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, display: 'flex', gap: 8, alignItems: 'flex-start', marginTop: 8 }}>
    <Ic name="info" size="xs" color="var(--memox-primary)" />
    <span>Trend appears after <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{needed}</strong> of data.</span>
  </div>;

/* ════════════ SCREEN ════════════ */
function ProgressScreen({ go, state = 'loaded' }) {
  const States = (window.MemoXStates && window.MemoXStates.Progress) || {};
  const mod = States[state] || States.loaded;
  const f = (mod ? mod() : {}) || {};
  const { range = 'week', loading = false, allEmpty = false, insufficient = false, partial = false, error = false } = f;

  if (error) {
    return (
      <div className="app">
        <StatusBar />
        <div className="appbar appbar-lg">
          <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Progress</div>
        </div>
        <div className="scroll" style={{ padding: '24px 24px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div className="card" style={{ padding: '36px 24px', textAlign: 'center', width: '100%' }}>
            <div style={{ width: 52, height: 52, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-danger) 10%, transparent)', color: 'var(--memox-error)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
              <Ic name="cloud-off" size="md" color="var(--memox-error)" />
            </div>
            <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>Couldn't summarise your progress</div>
            <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 16 }}>
              Your study history is safe on this device. Try again in a moment.
            </div>
            <button className="pill-btn primary" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
              <Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />
              Retry
            </button>
          </div>
        </div>
        <BottomNav active="stats" onChange={go} />
      </div>);
  }

  const labels = dayLabels[range];
  const studyArr = studied[range];
  const accArr = accuracy[range];
  const totalStudied = studyArr.reduce((a, b) => a + b, 0);
  const avgAcc = (() => {
    const valid = accArr.filter((v) => v != null);
    return valid.reduce((a, b) => a + b, 0) / valid.length;
  })();

  return (
    <div className="app">
      <StatusBar />

      <div className="appbar appbar-lg" style={{ justifyContent: 'space-between' }}>
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Progress</div>
        <button className="icon-btn" title="About these numbers">
          <Ic name="help-circle" size="sm" color="var(--memox-on-surface-variant)" />
        </button>
      </div>

      <div className="scroll">

        {/* Range selector */}
        <div style={{ display: 'inline-flex', padding: 4, gap: 2, background: 'var(--memox-surface-container)', borderRadius: 'var(--memox-radius-md)', marginBottom: 16 }}>
          {[{ id: 'week', label: 'Week' }, { id: 'month', label: 'Month' }, { id: 'all', label: 'All time' }].map((t) => {
            const active = t.id === range;
            return (
              <button key={t.id} style={{ height: 32, padding: '0 16px', borderRadius: 8, background: active ? 'var(--memox-surface-container-lowest)' : 'transparent', border: 'none', color: active ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)', fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer', boxShadow: active ? 'var(--memox-shadow-soft)' : 'none' }}>{t.label}</button>);
          })}
        </div>

        {loading &&
          <>
            {[0, 1, 2].map((i) =>
              <div key={i} className="card" style={{ padding: '16px', marginBottom: 12 }}>
                <Skel w={80} h={9} op={0.4} />
                <div style={{ height: 8 }} />
                <Skel w={120} h={20} />
                <div style={{ height: 14 }} />
                <Skel w="100%" h={70} r={10} />
              </div>
            )}
          </>}

        {!loading &&
          <>
            {/* 1. Cards studied */}
            <Card title="Cards studied" value={allEmpty || insufficient ? null : totalStudied} sub={allEmpty || insufficient ? null : `over the past ${range === 'week' ? '7 days' : '28 days'}`}>
              {allEmpty ?
                <ChartEmpty line="No study sessions in this range yet. Start any deck to begin tracking trends." /> :
                insufficient ?
                  <>
                    <ChartEmpty line="Only 1 day of data so far." />
                    <InsufficientHint needed="3 days" />
                  </> :
                  <>
                    <div style={{ display: 'flex', alignItems: 'flex-end', gap: range === 'month' ? 4 : 8, height: 78, padding: '0 2px' }}>
                      {studyArr.map((v, i) => {
                        const max = Math.max(...studyArr);
                        const pct = max > 0 ? v / max : 0;
                        const isToday = i === studyArr.length - 1;
                        return (
                          <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-end', height: '100%' }}>
                            <div style={{ width: '100%', height: v === 0 ? 2 : `${Math.max(pct * 100, 6)}%`, borderRadius: 4, background: v === 0 ? 'var(--memox-surface-container-high)' : isToday ? 'var(--memox-primary)' : 'color-mix(in srgb, var(--memox-primary) 55%, transparent)' }} />
                          </div>);
                      })}
                    </div>
                    <div style={{ display: 'flex', gap: range === 'month' ? 4 : 8, marginTop: 4, padding: '0 2px', fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>
                      {labels.map((l, i) => <span key={i} style={{ flex: 1, textAlign: 'center' }}>{l}</span>)}
                    </div>
                  </>}
            </Card>

            {/* 2. Accuracy */}
            <Card title="Accuracy" value={allEmpty ? null : partial ? null : `${Math.round(avgAcc * 100)}%`} sub={allEmpty || partial ? null :
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                <Ic name={accDelta >= 0 ? 'trending-up' : 'trending-down'} size="xs" color={accDelta >= 0 ? 'var(--memox-mastery)' : 'var(--memox-error)'} />
                <span style={{ color: accDelta >= 0 ? 'var(--memox-mastery)' : 'var(--memox-error)', fontWeight: 600 }}>{accDelta >= 0 ? '+' : ''}{Math.round(accDelta * 100)}%</span>
                <span style={{ opacity: 0.7 }}>vs previous {range}</span>
              </span>}>
              {allEmpty ?
                <ChartEmpty line="Accuracy appears once you've answered cards." /> :
                partial ?
                  <ChartEmpty line="Not enough answered cards yet to show accuracy." /> :
                  <svg viewBox="0 0 280 80" style={{ width: '100%', height: 80, display: 'block' }}>
                    {[0, 0.25, 0.5, 0.75, 1].map((t) =>
                      <line key={t} x1="0" x2="280" y1={t * 70 + 5} y2={t * 70 + 5} stroke="var(--memox-surface-container)" strokeWidth="1" />
                    )}
                    {(() => {
                      const w = 280;
                      const pts = accArr.map((v, i) => ({ x: i / (accArr.length - 1) * w, y: v == null ? null : (1 - v) * 70 + 5, v }));
                      const validSegs = [];
                      let cur = [];
                      pts.forEach((p) => { if (p.y == null) { if (cur.length) { validSegs.push(cur); cur = []; } } else cur.push(p); });
                      if (cur.length) validSegs.push(cur);
                      return validSegs.map((seg, si) =>
                        <polyline key={si} fill="none" stroke="var(--memox-primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" points={seg.map((p) => `${p.x},${p.y}`).join(' ')} />
                      );
                    })()}
                    {(() => {
                      const last = accArr[accArr.length - 1];
                      if (last == null) return null;
                      const y = (1 - last) * 70 + 5;
                      return <circle cx={280} cy={y} r="4" fill="var(--memox-surface)" stroke="var(--memox-primary)" strokeWidth="2" />;
                    })()}
                  </svg>}
            </Card>

            {/* 3. Box distribution */}
            <Card title="Box distribution" value={allEmpty ? null : boxes.reduce((a, b) => a + b.count, 0)} sub={allEmpty ? null : 'total cards across boxes'}>
              {allEmpty ?
                <ChartEmpty line="Cards spread across boxes as you study them." /> :
                <>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    {boxes.map((b) => {
                      const pct = b.count / maxBox * 100;
                      return (
                        <div key={b.n} style={{ display: 'grid', gridTemplateColumns: '18px 1fr 32px', gap: 8, alignItems: 'center' }}>
                          <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', textAlign: 'right' }}>B{b.n}</span>
                          <div style={{ height: 14, borderRadius: 4, position: 'relative', background: 'var(--memox-surface-container)', overflow: 'hidden' }}>
                            <div style={{ height: '100%', width: `${pct}%`, background: b.n >= 6 ? 'var(--memox-mastery)' : 'var(--memox-primary)', opacity: 0.35 + b.n / 8 * 0.65, transition: 'width 200ms ease' }} />
                          </div>
                          <span style={{ fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', textAlign: 'right' }}>{b.count}</span>
                        </div>);
                    })}
                  </div>
                  <div style={{ marginTop: 8, fontSize: 12, color: 'var(--memox-on-surface-variant)', display: 'flex', justifyContent: 'space-between', padding: '0 24px 0 24px' }}>
                    <span>B1 · least known</span>
                    <span>B8 · best known</span>
                  </div>
                </>}
            </Card>

            {/* 4. Streak */}
            <Card title="Streak">
              {allEmpty ?
                <ChartEmpty line="A streak starts after one study session." /> :
                <div style={{ display: 'flex', gap: 8 }}>
                  {[
                    { l: 'Current', v: '11 days', ic: 'flame', c: 'var(--memox-streak)' },
                    { l: 'Longest', v: '42 days', ic: 'award', c: 'var(--memox-primary)' }
                  ].map((s) =>
                    <div key={s.l} style={{ flex: 1, padding: '12px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 8 }}>
                      <div style={{ width: 32, height: 32, borderRadius: 8, background: `${s.c}1F`, color: s.c, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                        <Ic name={s.ic} size="xs" color={s.c} />
                      </div>
                      <div style={{ minWidth: 0 }}>
                        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 700 }}>{s.l}</div>
                        <div style={{ fontSize: 14, fontWeight: 700, marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>{s.v}</div>
                      </div>
                    </div>
                  )}
                </div>}
            </Card>

            {/* 5. Card states */}
            <div className="ov" style={{ padding: '2px 4px 8px' }}>Card states</div>
            <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
              {[
                { ic: 'pause-circle', c: 'var(--memox-on-surface-variant)', label: 'Suspended', sub: 'Out of rotation until you resume them', count: allEmpty ? 0 : 8, scope: 'in your library' },
                { ic: 'moon', c: 'var(--memox-on-surface-variant)', label: 'Buried today', sub: 'Skipped until tomorrow', count: allEmpty ? 0 : 4, scope: 'today only' }
              ].map((r, i, a) =>
                <div key={r.label} style={{ display: 'grid', gridTemplateColumns: '32px 1fr auto auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', cursor: 'pointer' }}>
                  <div style={{ width: 30, height: 30, borderRadius: 8, background: 'var(--memox-surface-container)', color: r.c, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Ic name={r.ic} size="xs" color={r.c} />
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{r.label}</div>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1, lineHeight: 1.4 }}>{r.sub}</div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>{r.count}</div>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>{r.scope}</div>
                  </div>
                  <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
                </div>
              )}
            </div>

            <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 0 12px' }}>
              Read-only summary · {range === 'week' ? 'last 7 days' : range === 'month' ? 'last 28 days' : 'all time'}
            </div>
          </>}
      </div>

      <BottomNav active="stats" onChange={go} />

    </div>);
}

Object.assign(window, { ProgressScreen });
})();
