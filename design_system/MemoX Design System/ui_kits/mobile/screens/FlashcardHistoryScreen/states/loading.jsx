/* FlashcardHistory · state: loading — skeleton timeline. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardHistory = R.FlashcardHistory || {});

D.loading = function (ctx) {
  const { Skel } = ctx;
  return (
    <div style={{ position: 'relative', paddingLeft: 24 }}>
      <div style={{ position: 'absolute', left: 11, top: 8, bottom: 8, width: 2, background: 'var(--memox-surface-container)', borderRadius: 999 }} />
      {[0, 1, 2, 3].map((i) =>
        <div key={i} style={{ position: 'relative', marginBottom: 16 }}>
          <Skel w={14} h={14} shape="circle" op={0.55} style={{ position: 'absolute', left: -19, top: 6 }} />
          <div style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 12, padding: '12px 16px' }}>
            <Skel w={70} h={9} op={0.4} />
            <div style={{ height: 8 }} />
            <Skel w={i === 1 ? '85%' : '70%'} h={13} />
            <div style={{ height: 8 }} />
            <Skel w={120} h={10} op={0.35} />
          </div>
        </div>
      )}
    </div>);
};
})();
