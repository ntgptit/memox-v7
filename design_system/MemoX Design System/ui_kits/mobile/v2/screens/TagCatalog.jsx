/* MemoX v2 · A13 — Tag catalog
   Refined from V1 TagManagementScreen. KEPT: the app bar, the 44px search box,
   the count + sort row, and V1's tag list — one card, TagRow with a 28px tile,
   name, card count, a "Most used" flame badge and the row ⋮; overlays over the
   list. REMOVED: nothing V1 had. ADDED: the library-wide note, the merge
   warning on rename, the 50-character limit, and the missing states. */
(function () {
const { Ic, StatusBar, ScreenScroll, Skeleton, Spinner, EmptyState, ErrorState, Dialog, BottomSheet, TextField } = window;
const { useT, NavBar, Note, SheetHead, ActionRow, ConfirmDialog, Snackbar, FieldLabel } = window;
/* Snackbar/Note/etc. come from _kit.jsx above. */
const D = window.MemoXData;

const sorted = [...D.tags].sort((a, b) => b.cards - a.cards);
const most = sorted[0].name;

function TagRow({ tag, last, busy }) {
  const t = useT();
  return (
    <div role="button" tabIndex={0} style={{ display: 'grid', gridTemplateColumns: '32px 1fr auto auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: last ? 'none' : 'var(--memox-border-ghost)', cursor: 'pointer' }}>
      <div style={{ width: 28, height: 28, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Ic name="tag" size="xs" color="var(--memox-primary)" />
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{tag.name}</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>
          {tag.cards === 0
            ? t('on no card right now', 'hiện không nằm trên thẻ nào')
            : t(`${t.n(tag.cards)} cards`, `${t.n(tag.cards)} thẻ`)}
        </div>
      </div>
      {tag.name === most ?
        <span style={{ height: 20, padding: '0 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)', color: 'var(--memox-streak)', fontSize: 12, fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: 4, whiteSpace: 'nowrap' }}>
          <Ic name="flame" size="xs" color="var(--memox-streak)" />{t('Most used', 'Dùng nhiều nhất')}
        </span> : <span />}
      {busy ?
        <Spinner size={14} /> :
        <button className="icon-btn" style={{ width: 30, height: 30 }} aria-label={t('More', 'Thêm')}>
          <Ic name="more-vertical" size="xs" color="var(--memox-on-surface-variant)" />
        </button>}
    </div>);
}

function TagCatalog({ state = 'list' }) {
  const t = useT();
  const searchActive = state === 'searchEmpty';
  const loading = state === 'loading';

  let body;
  if (loading) body =
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
      {[0, 1, 2, 3, 4].map((i, _, a) =>
        <div key={i} style={{ display: 'grid', gridTemplateColumns: '32px 1fr', gap: 12, padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
          <Skeleton w={28} h={28} r={8} op={0.45} />
          <div><Skeleton w={`${35 + i * 11}%`} h={12} op={0.5} /><Skeleton w={52} h={9} op={0.35} style={{ marginTop: 6 }} /></div>
        </div>)}
    </div>;
  else if (state === 'empty') body =
    <EmptyState icon="tag" title={t('No tags yet', 'Chưa có nhãn nào')}
      body={t('Tags come from the cards you write. Add one while creating or editing a card and it appears here.', 'Nhãn sinh ra từ các thẻ bạn viết. Hãy gắn nhãn khi tạo hoặc sửa thẻ, nhãn sẽ xuất hiện ở đây.')} />;
  else if (searchActive) body =
    <EmptyState compact icon="search-x" title={t('No tag matches “topik iii”', 'Không có nhãn nào khớp “topik iii”')}
      body={t('Your library has TOPIK I and TOPIK II.', 'Thư viện của bạn có TOPIK I và TOPIK II.')}
      action={<button className="pill-btn outline">{t('Clear search', 'Xoá tìm kiếm')}</button>} />;
  else if (state === 'loadFailed') body =
    <ErrorState title={t("Couldn't load your tags", 'Không tải được nhãn')}
      body={t('Your cards and their tags are safe on this device.', 'Thẻ và nhãn của bạn vẫn an toàn trên máy này.')} />;
  else body =
    <>
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {sorted.map((tag, i, a) => <TagRow key={tag.name} tag={tag} last={i === a.length - 1} busy={state === 'busy' && tag.name === 'nâng cao'} />)}
      </div>
      <Note style={{ marginTop: 12 }}>
        {t('Tags belong to the whole library, not to one deck. Cards in Trash keep their tags but are not counted here.', 'Nhãn thuộc cả thư viện, không thuộc riêng bộ nào. Thẻ trong Thùng rác vẫn giữ nhãn nhưng không được tính ở đây.')}
      </Note>
      {state === 'opFailed' &&
        <Note icon="alert-circle" tone="danger" style={{ marginTop: 10 }}>
          {t("Couldn't rename “nâng cao”. Nothing changed — the tag and its 57 cards are as they were.", 'Không đổi được tên “nâng cao”. Không có gì thay đổi — nhãn và 57 thẻ vẫn như trước.')}
        </Note>}
    </>;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>{t('Manage tags', 'Quản lý nhãn')}</div>
      </div>

      <ScreenScroll>
        {!['empty', 'loadFailed'].includes(state) &&
          <div role="search" style={{ display: 'flex', alignItems: 'center', gap: 8, height: 44, padding: '0 16px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 12, marginBottom: 16 }}>
            <Ic name="search" size="xs" color="var(--memox-on-surface-variant)" />
            <span style={{ flex: 1, minWidth: 0, fontSize: 14, color: searchActive ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)', opacity: searchActive ? 1 : 0.7, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {searchActive ? 'topik iii' : t('Search tags', 'Tìm nhãn')}
            </span>
            {searchActive &&
              <button className="icon-btn" style={{ width: 26, height: 26 }} aria-label={t('Clear', 'Xoá')}>
                <Ic name="x" size="xs" color="var(--memox-on-surface-variant)" />
              </button>}
          </div>}

        {!['empty', 'loadFailed'].includes(state) &&
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 8, padding: '0 4px 8px' }}>
            <span className="ov">
              {loading ? t('Loading tags', 'Đang tải nhãn')
                : searchActive ? t('No matches', 'Không có kết quả')
                  : t(`${sorted.length} tags`, `${sorted.length} nhãn`)}
            </span>
            <button className="pill-btn" style={{ height: 30, padding: '0 12px', borderRadius: 999, fontSize: 12, gap: 4, whiteSpace: 'nowrap', flexShrink: 0, background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', color: 'var(--memox-on-surface)' }}>
              <Ic name="arrow-down-up" size="xs" color="var(--memox-on-surface-variant)" />
              {t('Most used', 'Dùng nhiều nhất')}
              <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
            </button>
          </div>}

        {body}
        <div style={{ height: 20 }} />
      </ScreenScroll>

      {state === 'sheet' &&
        <BottomSheet scrim={false} maxHeight="none">
          <SheetHead title="nâng cao" sub={t('on 57 cards', 'trên 57 thẻ')} />
          <div style={{ padding: '4px 8px 8px' }}>
            <ActionRow icon="pencil" label={t('Rename', 'Đổi tên')} />
            <ActionRow icon="search" label={t('Find cards with this tag', 'Tìm thẻ có nhãn này')} />
            <div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: 8 }} />
            <ActionRow icon="trash-2" danger label={t('Delete tag', 'Xoá nhãn')} sub={t('Takes it off 57 cards; no card is deleted', 'Chỉ bỏ nhãn khỏi 57 thẻ; không xoá thẻ nào')} />
          </div>
          <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
        </BottomSheet>}

      {['rename', 'renameMerge', 'renameInvalid'].includes(state) &&
        <Dialog>
          <div style={{ padding: '20px 20px 4px' }}>
            <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 14 }}>{t('Rename tag', 'Đổi tên nhãn')}</div>
            <FieldLabel len={state === 'renameInvalid' ? 51 : 8} max={50} error={state === 'renameInvalid'}>{t('NAME', 'TÊN')}</FieldLabel>
            <TextField focused value={state === 'renameMerge' ? 'TOPIK II' : state === 'renameInvalid' ? 'Ghi chú dài để kiểm tra giới hạn năm mươi ký tự nhé!' : 'Nâng cao'}
              error={state === 'renameInvalid' ? t('1 character over the 50 limit.', 'Vượt giới hạn 50 ký tự 1 ký tự.') : undefined} />
            {state === 'renameMerge' &&
              <Note icon="merge" tone="warning" style={{ marginTop: 14 }}>
                {t('A tag named “TOPIK II” already exists. Renaming merges the two: its 57 cards join that tag, “nâng cao” disappears, and the spelling “TOPIK II” is kept. Cards already carrying both keep one copy.', 'Đã có nhãn tên “TOPIK II”. Đổi tên sẽ gộp hai nhãn: 57 thẻ chuyển sang nhãn đó, “nâng cao” biến mất và cách viết “TOPIK II” được giữ. Thẻ nào đã có cả hai thì chỉ còn một.')}
              </Note>}
            {state === 'rename' &&
              <Note style={{ marginTop: 14 }}>{t('Changing only the capitalisation is an ordinary rename — the same tag keeps its cards.', 'Chỉ đổi chữ hoa thường là đổi tên bình thường — vẫn là nhãn đó và giữ nguyên các thẻ.')}</Note>}
          </div>
          <div style={{ padding: 16, display: 'flex', gap: 8 }}>
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>{t('Cancel', 'Huỷ')}</button>
            <button className="pill-btn primary" disabled={state === 'renameInvalid'} style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, opacity: state === 'renameInvalid' ? 0.45 : 1 }}>
              {state === 'renameMerge' ? t('Merge tags', 'Gộp nhãn') : t('Rename', 'Đổi tên')}
            </button>
          </div>
        </Dialog>}

      {state === 'deleteConfirm' &&
        <ConfirmDialog title={t('Delete the tag “nâng cao”?', 'Xoá nhãn “nâng cao”?')} confirm={t('Delete tag', 'Xoá nhãn')}>
          {t('It comes off the 57 cards that carry it. The cards themselves, their content and their progress are untouched.', 'Nhãn sẽ được bỏ khỏi 57 thẻ đang mang nó. Bản thân các thẻ, nội dung và tiến trình không thay đổi.')}
        </ConfirmDialog>}

      {state === 'deleted' && <Snackbar icon="check">{t('“nâng cao” deleted. 57 cards kept, tag removed.', 'Đã xoá “nâng cao”. 57 thẻ vẫn còn, chỉ bỏ nhãn.')}</Snackbar>}
      {state === 'merged' && <Snackbar icon="check">{t('Merged into “TOPIK II” — now on 153 cards.', 'Đã gộp vào “TOPIK II” — hiện trên 153 thẻ.')}</Snackbar>}
      {state === 'gone' && <Snackbar icon="info">{t('That tag no longer exists — it was deleted elsewhere.', 'Nhãn đó không còn — đã bị xoá ở nơi khác.')}</Snackbar>}
      <NavBar active="library" />
    </div>);
}

Object.assign(window, { TagCatalog });
})();
