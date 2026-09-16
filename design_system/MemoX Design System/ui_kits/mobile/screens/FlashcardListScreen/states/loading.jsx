/* FlashcardList · state: loading — skeleton card rows. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});

D.loading = function () {
  const { Skeleton } = window;
  const body = [0, 1, 2, 3, 4].map((i) =>
    <div key={i} style={{ marginBottom: 8, padding: '12px 16px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 12, display: 'grid', gridTemplateColumns: '8px 1fr 36px', gap: 12, alignItems: 'flex-start' }}>
      <Skeleton w={8} h={8} shape="circle" style={{ marginTop: 4 }} />
      <div>
        <Skeleton w={100 + i * 18} h={13} r={4} op={0.55} style={{ display: 'inline-block' }} />
        <Skeleton w={160} h={10} r={4} op={0.4} style={{ marginTop: 4 }} />
        <Skeleton w={80} h={8} r={4} op={0.3} style={{ marginTop: 8 }} />
      </div>
      <span />
    </div>
  );
  return { body };
};
})();
