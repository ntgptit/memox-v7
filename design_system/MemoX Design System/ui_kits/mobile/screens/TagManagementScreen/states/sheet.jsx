/* TagManagement · state: sheet — tag action sheet over the list. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});

D.sheet = function (ctx) {
  const { Ic, Scrim, Sheet, TagPill, TagList, selectedTag } = ctx;
  const overlay = (
    <>
      <Scrim />
      <Sheet>
        <div style={{ padding: '8px 20px 4px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
            <TagPill name={selectedTag.name} count={selectedTag.count} />
          </div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '0 2px' }}>Tag actions</div>
        </div>
        <div style={{ padding: '4px 8px 16px' }}>
          {[
            { ic: 'play', label: 'Study cards with this tag', sub: `Start a session with the ${selectedTag.count} cards` },
            { ic: 'list', label: 'View cards with this tag', sub: 'Open the global tag-filtered list' },
            { ic: 'pencil', label: 'Rename tag', sub: null },
            { ic: 'git-merge', label: 'Merge into another tag', sub: null }
          ].map((a) =>
            <button key={a.label} style={{ width: '100%', display: 'grid', gridTemplateColumns: '32px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left' }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name={a.ic} size="xs" color="var(--memox-primary)" />
              </div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{a.label}</div>
                {a.sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{a.sub}</div>}
              </div>
              <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
            </button>
          )}
          <div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: '8px 8px' }} />
          <button style={{ width: '100%', display: 'grid', gridTemplateColumns: '32px 1fr', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left' }}>
            <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-danger) 10%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Ic name="trash-2" size="xs" color="var(--memox-error)" />
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--memox-error)', letterSpacing: '-0.1px' }}>Delete tag</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>Keeps all {selectedTag.count} cards</div>
            </div>
          </button>
        </div>
      </Sheet>
    </>);
  return { body: TagList(false), overlay };
};
})();
