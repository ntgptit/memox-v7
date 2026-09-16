/* TagManagement · state: nameTooLong — rename to a name over 50 characters — validation on the field (A13). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});
D.nameTooLong = function (ctx) {
  const { Ic, Scrim, Dialog, TagList, selectedTag } = ctx;
  const overlay = (
    <>
      <Scrim />
      <Dialog>
        <div style={{ padding: '20px 20px 4px' }}>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Rename tag</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>Renaming updates every card that uses <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{selectedTag.name}</strong>.</div>
        </div>
        <div style={{ padding: '12px 20px 4px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 4 }}>
            <span className="ov">New name</span>
            <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-error)', fontVariantNumeric: 'tabular-nums' }}>57 / 50</span>
          </div>
          <div style={{ minHeight: 'var(--memox-size-input)', padding: '10px 12px', background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-error)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, fontWeight: 600, lineHeight: 1.4 }}>
            Động từ bất quy tắc thường gặp trong đề thi TOPIK II phần đọc<span style={{ display: 'inline-block', width: 2, height: 18, background: 'var(--memox-error)', animation: 'memoxBlink 1s infinite', verticalAlign: 'text-bottom', marginLeft: 1 }} />
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '4px 2px 0', color: 'var(--memox-error)', fontSize: 12, fontWeight: 600 }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            <span>A tag name can be at most 50 characters.</span>
          </div>
        </div>
        <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
          <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
          <button className="pill-btn primary" disabled style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, opacity: 0.45 }}>Rename</button>
        </div>
      </Dialog>
    </>);
  return { body: TagList(false), overlay };
};
})();
