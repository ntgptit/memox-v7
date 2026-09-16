/* TagManagement · state: rename — rename dialog (no conflict). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});

D.rename = function (ctx) {
  const { Ic, Scrim, Dialog, TagList, selectedTag } = ctx;
  const overlay = (
    <>
      <Scrim />
      <Dialog>
        <div style={{ padding: '20px 20px 4px' }}>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Rename tag</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>
            Renaming updates every card that uses <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{selectedTag.name}</strong>.
          </div>
        </div>
        <div style={{ padding: '12px 20px 4px' }}>
          <div className="ov" style={{ marginBottom: 4 }}>New name</div>
          <div style={{ height: 44, padding: '0 12px', background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-primary)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 8, fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface)', fontVariantNumeric: 'tabular-nums' }}>
            <span>humans</span>
            <span style={{ display: 'inline-block', width: 2, height: 18, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite' }} />
          </div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, padding: '0 2px' }}>Tag names are case-insensitive.</div>
        </div>
        <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
          <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
          <button className="pill-btn primary" style={{ flex: 1.4, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'var(--memox-primary)' }}>Rename</button>
        </div>
      </Dialog>
    </>);
  return { body: TagList(false), overlay };
};
})();
