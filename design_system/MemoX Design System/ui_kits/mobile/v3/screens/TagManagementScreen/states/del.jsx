/* TagManagement · state: del — delete confirmation. Deletes the tag label only,
   never the cards under it. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});

D.del = function (ctx) {
  const { Ic, Scrim, Dialog, TagList, selectedTag } = ctx;
  const overlay = (
    <>
      <Scrim />
      <Dialog>
        <div style={{ padding: '20px 20px 4px', textAlign: 'center' }}>
          <div style={{ width: 48, height: 48, borderRadius: 16, background: 'var(--memox-danger-soft)', color: 'var(--memox-error)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
            <Ic name="tag" size="md" color="var(--memox-error)" />
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Delete this tag?</div>
          <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, padding: '0 4px' }}>
            <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{selectedTag.name}</strong> is removed from {selectedTag.count} cards and disappears from the catalog. Tags are not kept in Trash.
          </div>
        </div>
        <div style={{ padding: '16px 20px 4px' }}>
          <div style={{ padding: '8px 12px', background: 'color-mix(in srgb, var(--memox-mastery) 8%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-mastery) 20%, transparent)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'center' }}>
            <Ic name="shield-check" size="xs" color="var(--memox-mastery)" />
            <div style={{ flex: 1, fontSize: 12, color: 'var(--memox-on-surface)', lineHeight: 1.5 }}>
              No card is deleted, hidden or changed — <strong style={{ fontWeight: 700 }}>all {selectedTag.count} cards stay</strong> exactly where they are.
            </div>
          </div>
        </div>
        <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
          <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
          <button className="pill-btn" style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'var(--memox-error-fill)', color: 'var(--memox-on-error-fill)', border: 'none', fontWeight: 600, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 4 }}>
            <Ic name="trash-2" size="xs" color="var(--memox-on-error-fill)" />
            Remove from {selectedTag.count} cards
          </button>
        </div>
      </Dialog>
    </>);
  return { body: TagList(false), overlay };
};
})();
