/* MemoX Mobile v3 — TagManagementScreen · MAIN  (A13 · Tag catalog)
   Product corrections vs v1: tags are sorted A→Z by case-folded name and there
   is no sort choice (BR-230); the "Most used" flame is removed (no such data);
   zero-card tags exist and are listed (BR-230); the action sheet offers find ·
   rename · delete — merging happens only by renaming onto an existing name
   (BR-234), so the separate merge sheet is removed; "Study cards with this tag"
   is removed (no such action); delete is worded as removing the tag from N
   cards (BR-235); name-too-long and tag-gone states added. Reached from Library.
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     TagManagementScreen/
       TagManagementScreen.jsx  ← shell + shared sheet/dialog/row widgets + dispatch
       states/                  ← one file per state in window.MemoXStates.TagManagement

   Many states are overlays (action sheet, rename/renameMerge dialogs, merge sheet,
   delete dialog) over the tag list; `busy` shows a spinner on one row; `opError`
   floats a toast. So a state module returns { body, overlay, toast } — overlay
   states reuse ctx.TagList() behind the scrim. Each overlay/dialog lives in its
   own file; the shared list, widgets and search/count chrome stay in MAIN.

   ctx: { go, state, Ic, Scrim, Sheet, Dialog, TagPill, TagRow, TagList,
          tags, selectedTag, totalTags } */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, StudyTopBar, SearchField } = window;

const selectedTag = { name: 'động từ', count: 46 };
const totalTags = 16;
/* SAMPLE_DATA · tags[0] (abridged): case-folded A→Z, a 50-char tag, a tag used only by trashed cards (0), an unused tag (0). */
const baseTags = [
  { name: 'bài 12', count: 12 },
  { name: 'Cấu trúc thường gặp trong đề thi TOPIK II phần đọc', count: 3 },
  { name: 'cần ôn lại', count: 9 },
  { name: 'động từ', count: 46 },
  { name: 'hay nhầm', count: 14 },
  { name: 'Học', count: 5 },
  { name: 'liên kết câu', count: 4 },
  { name: 'ngữ pháp', count: 31 },
  { name: 'restaurant', count: 18 },
  { name: 'tạm', count: 0 },
  { name: 'TOPIK I', count: 210 },
  { name: 'TOPIK II', count: 142 },
  { name: 'travel', count: 22 },
  { name: 'viết', count: 8 }
];

const Scrim = window.Scrim;

/* states render <Scrim/> as a sibling, so the shell suppresses its own. */
const Sheet = (p) => <window.BottomSheet scrim={false} {...p} />;

const Dialog = (p) => <window.Dialog scrim={false} {...p} />;

const TagPill = ({ name, count, tone = 'indigo' }) => {
  const tones = {
    indigo: { bg: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', col: 'var(--memox-primary)' },
    neutral: { bg: 'var(--memox-surface-container)', col: 'var(--memox-on-surface)' },
    red: { bg: 'var(--memox-danger-soft)', col: 'var(--memox-error)' }
  }[tone];
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, height: 26, padding: '0 8px', background: tones.bg, color: tones.col, borderRadius: 999, fontSize: 12, fontWeight: 600 }}>
      <Ic name="tag" size="xs" color={tones.col} />
      {name}
      {count != null && <span style={{ fontSize: 12, fontWeight: 700, opacity: 0.7, fontVariantNumeric: 'tabular-nums' }}>· {count}</span>}
    </span>);
};

const TagRow = ({ tag, last }) =>
  <div role="button" tabIndex={0} style={{ display: 'grid', gridTemplateColumns: '32px 1fr auto auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: last ? 'none' : 'var(--memox-border-ghost)' }}>
    <div style={{ width: 28, height: 28, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Ic name="tag" size="xs" color="var(--memox-primary)" />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', lineHeight: 1.35, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{tag.name}</div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>{tag.count === 0 ? 'No cards' : `${tag.count} card${tag.count === 1 ? '' : 's'}`}</div>
    </div>
    <span />
    {tag.busy ?
      <window.Spinner size={14} /> :
      <button className="icon-btn" style={{ width: 28, height: 28 }} title="More">
        <Ic name="more-vertical" size="xs" color="var(--memox-on-surface-variant)" />
      </button>}
  </div>;

/* Tag list card. busy=true marks the "business" row with a spinner. */
const TagList = (busy) => {
  const tags = baseTags.map((t) => t.name === 'động từ' ? { ...t, busy } : t);
  return (
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
      {tags.map((t, i, a) => <TagRow key={t.name} tag={t} last={i === a.length - 1} />)}
    </div>);
};

/* ════════════ SCREEN ════════════ */
function TagManagementScreenV3({ go, state = 'loaded' }) {
  const searchActive = state === 'searchEmpty';

  const States = (window.MemoXStates && window.MemoXStates.TagManagement) || {};
  const ctx = { go, state, Ic, Scrim, Sheet, Dialog, TagPill, TagRow, TagList, tags: baseTags, selectedTag, totalTags };
  const mod = States[state] || States.loaded;
  const out = mod ? mod(ctx) : null;
  const body = out && out.body !== undefined ? out.body : out;
  const overlayNode = out && out.overlay !== undefined ? out.overlay : null;
  const toastNode = out && out.toast !== undefined ? out.toast : null;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" onClick={() => go('library')} aria-label="Back">
          <Ic name="arrow-left" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>Tags</div>
      </div>

      <div className="scroll">

        {/* Search input */}
        <SearchField placeholder="Search tags" value={searchActive ? 'hoc' : ''} active={searchActive} style={{ marginBottom: 16 }} />

        {/* Count + sort row */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0 4px 8px' }}>
          <span className="ov">{state === 'empty' ? 'No tags' : searchActive ? 'No matches' : `${totalTags} tags`}</span>
          <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            <Ic name="arrow-down-a-z" size="xs" color="var(--memox-on-surface-variant)" />
            A → Z
          </span>
        </div>

        {body}

        <div style={{ height: 20 }} />
      </div>

      {toastNode}
      {overlayNode}

    </div>);
}

Object.assign(window, { TagManagementScreenV3 });
})();
