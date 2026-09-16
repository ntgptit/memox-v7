/* TagManagement · state: opError — transaction failure toast over the list. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});

D.opError = function (ctx) {
  const { Ic, TagList } = ctx;
  const toast = (
    <div style={{ position: 'absolute', left: 14, right: 14, bottom: 18, color: 'var(--memox-on-inverse-surface)', borderRadius: 12, padding: '12px 16px', display: 'flex', gap: 8, alignItems: 'flex-start', boxShadow: 'var(--memox-shadow-card)', zIndex: 60, backgroundColor: 'var(--memox-inverse-surface)' }}>
      <Ic name="alert-circle" size="xs" color="var(--memox-inverse-error)" />
      <div style={{ flex: 1, fontSize: 14, lineHeight: 1.45 }}>
        <div style={{ fontWeight: 700, marginBottom: 2 }}>Couldn't rename tag</div>
        <div style={{ opacity: 0.8, fontSize: 12 }}>Nothing changed. Try again in a moment.</div>
      </div>
      <button style={{ background: 'transparent', border: 'none', color: 'var(--memox-on-inverse-surface)', fontWeight: 600, fontSize: 14, padding: '2px 4px', cursor: 'pointer', fontFamily: 'inherit' }}>Retry</button>
    </div>);
  return { body: TagList(false), toast };
};
})();
