/* FolderDetail · state: unlocked — empty new folder; dual create CTA, equal weight.
   (Main hides the summary card, section header and FAB for this mode.) */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FolderDetail = R.FolderDetail || {});

D.unlocked = function (ctx) {
  const { Ic } = ctx;
  const body = (
    <div style={{ marginTop: 4 }}>
      <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '4px 16px 4px 8px', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', borderRadius: 999, fontSize: 12, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 12 }}>
        <Ic name="folder-plus" size="xs" color="var(--memox-primary)" />
        Empty folder
      </div>
      <div className="card" style={{ padding: '24px 20px', textAlign: 'center', marginBottom: 16 }}>
        <div style={{ width: 60, height: 60, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
          <Ic name="folder-open" size="lg" color="var(--memox-primary)" />
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>What goes in here?</div>
        <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, padding: '0 4px' }}>
          Add decks to study cards directly, or nest subfolders to keep things organized. Folders hold one or the other once you start.
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <button className="pill-btn primary" style={{ flex: 1, height: 44, borderRadius: 12, fontSize: 14, gap: 8, flexDirection: 'column', padding: '8px 0', justifyContent: 'center', lineHeight: 1.1 }}>
          <Ic name="layers" size="sm" color="var(--memox-on-primary)" />
          <span>New deck</span>
        </button>
        <button className="pill-btn" style={{ flex: 1, height: 44, borderRadius: 12, fontSize: 14, gap: 8, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', border: 'none', flexDirection: 'column', padding: '8px 0', justifyContent: 'center', lineHeight: 1.1 }}>
          <Ic name="folder-plus" size="sm" color="var(--memox-primary)" />
          <span>New subfolder</span>
        </button>
      </div>
      <div style={{ padding: '8px 12px', background: 'var(--memox-surface-container-lowest)', borderRadius: 'var(--memox-radius-md)', border: 'var(--memox-border-ghost)', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, display: 'flex', gap: 8, alignItems: 'flex-start' }}>
        <Ic name="info" size="xs" color="var(--memox-on-surface-variant)" />
        <span>Once this folder holds decks or subfolders, the other option moves into the overflow menu.</span>
      </div>
    </div>);
  return { body };
};
})();
