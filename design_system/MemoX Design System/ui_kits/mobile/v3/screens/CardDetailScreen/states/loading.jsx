/* CardDetail · state: loading — skeleton timeline (v1). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.CardDetail = R.CardDetail || {});
D.loading = (ctx) => {
  const { Skel } = ctx;
  return (
    <div style={{ position: 'relative', paddingLeft: 24 }}>
      <div style={{ position: 'absolute', left: 11, top: 8, bottom: 8, width: 2, background: 'var(--memox-surface-container)', borderRadius: 999 }} />
      {[0, 1, 2].map((i) =>
        <div key={i} style={{ position: 'relative', marginBottom: 12 }}>
          <span style={{ position: 'absolute', left: -19, top: 8, width: 14, height: 14, borderRadius: 999, background: 'var(--memox-surface-container-high)', opacity: 0.6 }} />
          <div style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 12, padding: '12px 16px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}><Skel w={110} h={20} r={999} /><Skel w={70} h={11} op={0.4} /></div>
            <Skel w={i === 1 ? '60%' : '75%'} h={11} op={0.4} />
          </div>
        </div>)}
    </div>);
};
})();
