/* LibraryOverview · state: renameFolder
   Sheet "Rename folder" → centered dialog, pre-filled name selected for overwrite. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibraryOverview = R.LibraryOverview || {});

D.renameFolder = function (ctx) {
  const { Ic, Dialog, FoldersList } = ctx;
  const overlay = (
    <Dialog>
      <div style={{ padding: '20px 20px 4px' }}>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Rename folder</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>
          Only the folder name changes — every deck and card inside stays put.
        </div>
      </div>

      <div style={{ padding: '12px 20px 4px' }}>
        <div className="ov" style={{ marginBottom: 4 }}>New name</div>
        <div style={{ height: 44, padding: '0 12px', background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-primary)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 0, fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface)' }}>
          <span style={{ background: 'color-mix(in srgb, var(--memox-primary) 22%, transparent)', borderRadius: 4, padding: '1px 1px' }}>Korean</span>
          <span style={{ display: 'inline-block', width: 2, height: 18, marginLeft: 1, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite' }} />
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, padding: '0 2px' }}>
          8 decks · 412 cards will keep this folder as their home.
        </div>
      </div>

      <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn primary" style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Rename</button>
      </div>
    </Dialog>);
  return { body: FoldersList(), overlay };
};
})();
