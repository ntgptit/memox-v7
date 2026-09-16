/* FolderDetail · state: loading — skeleton rows. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FolderDetail = R.FolderDetail || {});

D.loading = function (ctx) {
  const { Skeleton } = window;
  const body = [0, 1, 2, 3].map((i) =>
    <div key={i} className="card" style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: '40px 1fr 18px', gap: 12, alignItems: 'center', padding: '12px 16px' }}>
      <Skeleton w={36} h={36} r="var(--memox-radius-md)" op={0.55} />
      <div>
        <Skeleton w={100 + i * 30} h={11} r={4} op={0.55} style={{ display: 'inline-block' }} />
        <Skeleton w="100%" h={4} r={999} op={0.35} style={{ marginTop: 8 }} />
      </div>
      <span />
    </div>
  );
  return { body };
};
})();
