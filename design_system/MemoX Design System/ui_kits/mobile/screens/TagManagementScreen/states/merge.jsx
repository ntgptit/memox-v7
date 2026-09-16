/* TagManagement · state: merge — merge sheet with target tag picker. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});

D.merge = function (ctx) {
  const { Ic, Scrim, Sheet, TagPill, TagList, selectedTag } = ctx;
  const overlay = (
    <>
      <Scrim />
      <Sheet>
        <div style={{ padding: '4px 20px 12px' }}>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Merge "{selectedTag.name}" into…</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>
            Cards under <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{selectedTag.name}</strong> will move to the tag you pick. No cards are deleted.
          </div>
        </div>
        <div style={{ padding: '0 20px 8px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, height: 'var(--memox-size-button)', padding: '0 12px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)' }}>
            <Ic name="search" size="xs" color="var(--memox-on-surface-variant)" />
            <span style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', opacity: 0.7 }}>Search tags</span>
          </div>
        </div>
        <div className="hide-scroll" style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden', padding: '0 8px 16px' }}>
          {[
            { name: 'noun', count: 88, sel: true },
            { name: 'verb', count: 71 },
            { name: 'food', count: 34 },
            { name: 'business', count: 22 }
          ].map((t) =>
            <button key={t.name} style={{ width: '100%', display: 'grid', gridTemplateColumns: '22px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 8px', background: t.sel ? 'color-mix(in srgb, var(--memox-primary) 6%, transparent)' : 'transparent', border: 'none', borderRadius: 'var(--memox-radius-md)', color: 'var(--memox-on-surface)', fontFamily: 'inherit', textAlign: 'left', cursor: 'pointer' }}>
              <span style={{ width: 18, height: 18, borderRadius: 999, border: t.sel ? '5px solid var(--memox-primary)' : '2px solid var(--memox-outline-variant)', background: t.sel ? '#fff' : 'transparent', boxSizing: 'border-box' }} />
              <div>
                <div style={{ fontSize: 14, fontWeight: t.sel ? 700 : 600 }}>{t.name}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>{t.count} cards</div>
              </div>
              <Ic name="tag" size="xs" color="var(--memox-on-surface-variant)" />
            </button>
          )}
        </div>
        <div style={{ padding: '0 20px 12px' }}>
          <div style={{ padding: '8px 12px', background: 'color-mix(in srgb, var(--memox-primary) 6%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-primary) 16%, transparent)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
            <TagPill name={selectedTag.name} count={selectedTag.count} tone="neutral" />
            <Ic name="arrow-right" size="xs" color="var(--memox-on-surface-variant)" />
            <TagPill name="noun" count={88 + selectedTag.count} />
          </div>
        </div>
        <div style={{ padding: '0 16px 16px', display: 'flex', gap: 8 }}>
          <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
          <button className="pill-btn primary" style={{ flex: 1.4, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
            <Ic name="git-merge" size="xs" color="var(--memox-on-primary)" />
            Merge {selectedTag.count} cards
          </button>
        </div>
      </Sheet>
    </>);
  return { body: TagList(false), overlay };
};
})();
