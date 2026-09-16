/* LibraryOverview · state: archiveFolder
   Sheet "Archive folder" → non-destructive confirm (hides from Library, keeps cards). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibraryOverview = R.LibraryOverview || {});

D.archiveFolder = function (ctx) {
  const { Ic, Dialog, FoldersList } = ctx;
  const overlay = (
    <Dialog>
      <div style={{ padding: '20px 20px 4px', textAlign: 'center' }}>
        <div style={{ width: 48, height: 48, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)', color: 'var(--memox-streak)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
          <Ic name="archive" size="md" color="var(--memox-streak)" />
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Archive this folder?</div>
        <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, padding: '0 4px' }}>
          <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>Korean</strong> leaves your Library list but keeps all 8 decks and 412 cards.
        </div>
      </div>

      <div style={{ padding: '16px 20px 4px' }}>
        <div style={{ padding: '8px 12px', background: 'var(--memox-surface-container-lowest)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'center' }}>
          <Ic name="rotate-ccw" size="xs" color="var(--memox-on-surface-variant)" />
          <div style={{ flex: 1, fontSize: 12, color: 'var(--memox-on-surface)', lineHeight: 1.5 }}>
            Find it any time under <strong style={{ fontWeight: 700 }}>Archive</strong> and restore in one tap.
          </div>
        </div>
      </div>

      <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn" style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'var(--memox-streak)', color: 'var(--memox-on-streak)', border: 'none', fontWeight: 600, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 4 }}>
          <Ic name="archive" size="xs" color="var(--memox-on-streak)" />
          Archive
        </button>
      </div>
    </Dialog>);
  return { body: FoldersList(), overlay };
};
})();
