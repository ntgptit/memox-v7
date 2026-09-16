/* LibraryOverview · state: createFolder
   "New folder" FAB → centered dialog: live preview tile + name + color + icon. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibraryOverview = R.LibraryOverview || {});

D.createFolder = function (ctx) {
  const { Ic, Dialog, FoldersList, seedSwatches, iconChoices } = ctx;
  const overlay = (
    <Dialog>
      <div style={{ padding: '20px 20px 4px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ width: 44, height: 44, borderRadius: 12, background: 'color-mix(in srgb, var(--memox-primary) 12%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <Ic name="flag" size="sm" color="var(--memox-primary)" />
        </div>
        <div>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px' }}>New folder</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>Group related decks together.</div>
        </div>
      </div>

      <div style={{ padding: '12px 20px 4px' }}>
        <div className="ov" style={{ marginBottom: 4 }}>Folder name</div>
        <div style={{ height: 44, padding: '0 12px', background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-primary)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 8, fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface)' }}>
          <span>Vietnamese</span>
          <span style={{ display: 'inline-block', width: 2, height: 18, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite' }} />
        </div>
      </div>

      <div style={{ padding: '12px 20px 4px' }}>
        <div className="ov" style={{ marginBottom: 8 }}>Color</div>
        <div style={{ display: 'flex', gap: 8 }}>
          {seedSwatches.map((c, i) =>
            <span key={c} style={{ width: 28, height: 28, borderRadius: 999, background: c, cursor: 'pointer', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: i === 0 ? `0 0 0 2px var(--memox-surface-container-high), 0 0 0 4px ${c}` : 'none' }}>
              {i === 0 && <Ic name="check" size="xs" color="#fff" />}
            </span>
          )}
        </div>
      </div>

      <div style={{ padding: '12px 20px 4px' }}>
        <div className="ov" style={{ marginBottom: 8 }}>Icon</div>
        <div style={{ display: 'flex', gap: 8 }}>
          {iconChoices.map((ic, i) =>
            <span key={ic} style={{ width: 38, height: 38, borderRadius: 'var(--memox-radius-md)', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', background: i === 0 ? 'color-mix(in srgb, var(--memox-primary) 12%, transparent)' : 'var(--memox-surface-container-lowest)', border: i === 0 ? '1px solid var(--memox-primary)' : 'var(--memox-border-ghost)' }}>
              <Ic name={ic} size="sm" color={i === 0 ? 'var(--memox-primary)' : 'var(--memox-on-surface-variant)'} />
            </span>
          )}
        </div>
      </div>

      <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn primary" style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
          <Ic name="folder-plus" size="xs" color="var(--memox-on-primary)" />
          Create folder
        </button>
      </div>
    </Dialog>);
  return { body: FoldersList(), overlay };
};
})();
