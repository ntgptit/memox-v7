/* TagManagement · state: renameMerge — rename dialog where the new name collides
   with an existing tag → explicit merge warning (no silent merge). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});

D.renameMerge = function (ctx) {
  const { Ic, Scrim, Dialog, TagPill, TagList, selectedTag } = ctx;
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
          <div style={{ height: 44, padding: '0 12px', background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-streak)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 8, fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface)', fontVariantNumeric: 'tabular-nums' }}>
            <span>noun</span>
            <span style={{ display: 'inline-block', width: 2, height: 18, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite' }} />
          </div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, padding: '0 2px' }}>Tag names are case-insensitive.</div>
        </div>
        <div style={{ padding: '8px 20px 0' }}>
          <div style={{ background: 'color-mix(in srgb, var(--memox-streak) 8%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-streak) 22%, transparent)', borderRadius: 12, padding: '12px 12px' }}>
            <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 8 }}>
              <Ic name="git-merge" size="xs" color="var(--memox-streak)" />
              <div style={{ flex: 1, fontSize: 12, lineHeight: 1.5, color: 'var(--memox-on-surface)' }}>
                A tag called <strong style={{ fontWeight: 700 }}>noun</strong> already exists. Continuing will <strong style={{ fontWeight: 700 }}>merge</strong> these two tags.
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 8px', borderRadius: 'var(--memox-radius-md)', background: 'rgba(255,255,255,0.5)', flexWrap: 'wrap' }}>
              <TagPill name="people" count={46} tone="neutral" />
              <Ic name="arrow-right" size="xs" color="var(--memox-on-surface-variant)" />
              <TagPill name="noun" count={88 + 46} />
            </div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 8, lineHeight: 1.5 }}>
              No cards are deleted. The combined tag will hold all 134 cards.
            </div>
          </div>
        </div>
        <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
          <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
          <button className="pill-btn primary" style={{ flex: 1.4, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'var(--memox-streak)' }}>
            <Ic name="git-merge" size="xs" color="var(--memox-on-primary)" />
            Merge tags
          </button>
        </div>
      </Dialog>
    </>);
  return { body: TagList(false), overlay };
};
})();
