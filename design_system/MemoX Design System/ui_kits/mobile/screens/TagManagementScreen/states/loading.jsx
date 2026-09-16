/* TagManagement · state: loading — skeleton list. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});

D.loading = function () {
  const { Skeleton } = window;
  const body = (
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
      {[0, 1, 2, 3, 4].map((i) =>
        <div key={i} style={{ display: 'grid', gridTemplateColumns: '32px 1fr 30px', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < 4 ? 'var(--memox-border-ghost)' : 'none' }}>
          <Skeleton w={28} h={28} r={8} />
          <div>
            <Skeleton w={80 + i * 20} h={11} r={4} style={{ display: 'inline-block' }} />
            <Skeleton w={50} h={9} r={4} op={0.35} style={{ marginTop: 4 }} />
          </div>
          <span />
        </div>
      )}
    </div>);
  return { body };
};
})();
