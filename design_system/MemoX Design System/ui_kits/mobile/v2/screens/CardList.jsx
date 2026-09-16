/* MemoX v2 · A8 — Card list of a deck
   Refined from V1 FlashcardListScreen. KEPT: app bar + breadcrumb, the tinted
   deck-summary card (mastery donut · distribution bar · legend · full-width
   study CTA), the filter-chip row with counts, the count + sort row, and V1's
   CardRow (status dot · front · back · status label + tags · flag + due chip).
   No bottom nav — this is a drill-down, as in V1.
   REMOVED: the Mastered filter (not a filter the product offers).
   ADDED: overdue emphasis on the due chip, selection, and the missing states. */
(function () {
const { Ic, StatusBar, ScreenScroll, BottomBar, Fab, Skeleton, Spinner, EmptyState, ErrorState, BottomSheet, SearchField, Breadcrumb, masteryColor } = window;
const { useT, Note, SheetHead, ActionRow, Snackbar } = window;
const D = window.MemoXData;

const STATUS_TOKEN = { new: 'var(--memox-status-new)', beginning: 'var(--memox-status-learning)', reviewing: 'var(--memox-status-reviewing)', mastered: 'var(--memox-status-mastered)' };
const STATUS_LABEL = { new: { en: 'New', vi: 'Mới' }, beginning: { en: 'Beginning', vi: 'Bắt đầu' }, reviewing: { en: 'Reviewing', vi: 'Đang ôn' }, mastered: { en: 'Mastered', vi: 'Thành thạo' } };

const dist = D.cardDistribution;
const summary = {
  total: dist.total, due: D.cardCounts.due, new: D.cardCounts.new, flagged: D.cardCounts.flagged,
  mastery: dist.mastered / dist.total,
  isNew: dist.isNew, beginning: dist.beginning, reviewing: dist.reviewing, mastered: dist.mastered
};

function CardRow({ c, select, checked }) {
  const t = useT();
  const cols = select ? '22px 8px 1fr auto' : '8px 1fr auto';
  return (
    <div role="button" tabIndex={0} style={{
      marginBottom: 8, padding: 12, display: 'grid', gridTemplateColumns: cols, gap: 12, alignItems: 'flex-start',
      background: checked ? 'var(--memox-primary-soft)' : 'var(--memox-surface-container-lowest)',
      border: checked ? '1px solid var(--memox-primary)' : 'var(--memox-border-ghost)', borderRadius: 12, cursor: 'pointer'
    }}>
      {select &&
        <div style={{ paddingTop: 2 }}>
          <span style={{
            width: 20, height: 20, borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: checked ? 'var(--memox-primary)' : 'transparent', border: checked ? 'none' : '2px solid var(--memox-outline)'
          }}>{checked ? <Ic name="check" size="xs" color="var(--memox-on-primary)" /> : null}</span>
        </div>}
      <div style={{ paddingTop: 4 }}>
        <span className="status-dot" style={{ background: STATUS_TOKEN[c.state], width: 8, height: 8 }} />
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', lineHeight: 1.25, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.front}</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, lineHeight: 1.4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.back}</div>
        <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 4, overflow: 'hidden' }}>
          <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase', color: STATUS_TOKEN[c.state], flexShrink: 0 }}>
            {t(STATUS_LABEL[c.state].en, STATUS_LABEL[c.state].vi)}
          </span>
          {(c.tags || []).slice(0, 2).map((g) =>
            <span key={g} style={{ height: 18, padding: '0 8px', borderRadius: 999, background: 'var(--memox-surface-container)', color: 'var(--memox-on-surface-variant)', fontSize: 12, fontWeight: 600, display: 'inline-flex', alignItems: 'center', flexShrink: 0, maxWidth: 96, overflow: 'hidden', whiteSpace: 'nowrap' }}>{g}</span>)}
          {c.tags && c.tags.length > 2 &&
            <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-on-surface-variant)', flexShrink: 0 }}>+{c.tags.length - 2}</span>}
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4, paddingTop: 4 }}>
        {c.flagged && <Ic name="flag" size="xs" color="var(--memox-streak)" label={t('Flagged', 'Đã gắn cờ')} />}
        <span style={{
          fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', padding: '2px 4px', borderRadius: 4, whiteSpace: 'nowrap',
          color: c.overdue ? 'var(--memox-warning-ink)' : 'var(--memox-on-surface-variant)',
          background: c.overdue ? 'var(--memox-warning-soft)' : 'var(--memox-surface-container)'
        }}>{c.due || t('not due', 'chưa hạn')}</span>
      </div>
    </div>);
}

const LoadingList = () =>
  <>{[0, 1, 2, 3, 4].map((i) =>
    <div key={i} style={{ marginBottom: 8, padding: 12, display: 'grid', gridTemplateColumns: '8px 1fr auto', gap: 12, background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 12 }}>
      <Skeleton w={8} h={8} r={999} op={0.5} style={{ marginTop: 4 }} />
      <div>
        <Skeleton w={70 + i * 20} h={14} op={0.55} />
        <Skeleton w="72%" h={10} op={0.4} style={{ marginTop: 6 }} />
        <Skeleton w={110} h={14} r={999} op={0.32} style={{ marginTop: 8 }} />
      </div>
      <Skeleton w={34} h={16} r={4} op={0.35} style={{ marginTop: 4 }} />
    </div>)}</>;

function DeckMenu() {
  const t = useT();
  return (
    <BottomSheet scrim={false} maxHeight="none">
      <SheetHead title={D.deckContext.name} sub={t(`${summary.total} cards · ${summary.mastered} mastered`, `${summary.total} thẻ · ${summary.mastered} thành thạo`)} />
      <div style={{ padding: '4px 8px 8px' }}>
        <ActionRow icon="check-square" label={t('Select cards', 'Chọn thẻ')} sub={t('Move, flag, tag, export or delete several at once', 'Chuyển, gắn cờ, gắn nhãn, xuất hoặc xoá nhiều thẻ')} />
        <ActionRow icon="upload" label={t('Import cards', 'Nhập thẻ')} sub={t('CSV, TSV, XLSX or pasted text', 'CSV, TSV, XLSX hoặc văn bản dán vào')} />
        <ActionRow icon="download" label={t('Export all cards', 'Xuất tất cả thẻ')} sub={t('All 420 cards, ignoring filters', 'Cả 420 thẻ, bỏ qua bộ lọc')} />
        <ActionRow icon="pencil" label={t('Rename deck', 'Đổi tên bộ thẻ')} />
        <ActionRow icon="folder-tree" label={t('Move deck', 'Di chuyển bộ thẻ')} />
        <ActionRow icon="arrow-down-up" label={t('Reorder cards', 'Sắp xếp lại thẻ')} />
        <div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: 8 }} />
        <ActionRow icon="trash-2" danger label={t('Move deck to Trash', 'Chuyển bộ thẻ vào Thùng rác')}
          sub={t('420 cards go with it, recoverable for 30 days', '420 thẻ đi cùng, phục hồi được trong 30 ngày')} />
      </div>
      <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
    </BottomSheet>);
}

function CardList({ state = 'loaded' }) {
  const t = useT();
  const select = ['selection', 'bulkRunning', 'bulkFailed', 'moveNone'].includes(state);
  const searching = state === 'search' || state === 'noMatch';
  const showSummary = !['loading', 'empty', 'error', 'notFound'].includes(state) && !select && !searching;
  const showChips = showSummary;
  const showCount = !['loading', 'empty', 'error', 'notFound'].includes(state);

  let body;
  if (state === 'loading') body = <LoadingList />;
  else if (state === 'empty') body =
    <EmptyState icon="layers" title={t('No cards in this deck yet', 'Bộ thẻ này chưa có thẻ nào')}
      body={t('Write cards one at a time, or bring in a list you already have.', 'Bạn có thể tự viết từng thẻ, hoặc nhập danh sách có sẵn.')}
      action={
        <button className="pill-btn primary" style={{ fontSize: 14 }}>
          <Ic name="plus" size="xs" color="var(--memox-on-primary)" />{t('New card', 'Thẻ mới')}
        </button>}
      footnote={t('Importing from CSV, TSV or XLSX brings many cards in at once.', 'Nhập từ CSV, TSV hoặc XLSX sẽ thêm nhiều thẻ cùng lúc.')} />;
  else if (state === 'noMatch') body =
    <EmptyState compact icon="search-x" title={t('No card matches', 'Không có thẻ nào khớp')}
      body={t('Nothing in this deck matches “눈치” with the Due filter. Search looks at the front and the back only.', 'Không thẻ nào trong bộ này khớp “눈치” với bộ lọc Đến hạn. Tìm kiếm chỉ xét mặt trước và mặt sau.')}
      action={<button className="pill-btn outline">{t('Clear search and filters', 'Xoá tìm kiếm và bộ lọc')}</button>} />;
  else if (state === 'notFound') body =
    <ErrorState icon="file-question" title={t('This deck is gone', 'Bộ thẻ này không còn')}
      body={t('It was moved to Trash elsewhere in the app.', 'Bộ thẻ đã được chuyển vào Thùng rác ở nơi khác.')}
      action={<button className="pill-btn primary">{t('Back to Library', 'Về Thư viện')}</button>} />;
  else if (state === 'error') body =
    <ErrorState title={t("Couldn't load these cards", 'Không tải được danh sách thẻ')}
      body={t('Your data is safe on this device. Try again in a moment.', 'Dữ liệu của bạn vẫn an toàn trên máy này. Hãy thử lại sau giây lát.')} />;
  else body =
    <>
      {state === 'bulkFailed' &&
        <Note icon="alert-circle" tone="danger" style={{ marginBottom: 10 }}>
          {t('None of the 3 cards was moved — one of them no longer exists. Your selection is still here, so you can try again.', 'Không thẻ nào trong 3 thẻ được chuyển — một thẻ không còn tồn tại. Lựa chọn vẫn được giữ để bạn thử lại.')}
        </Note>}
      {D.cards.map((c, i) => <CardRow key={c.id} c={c} select={select} checked={select && i < 3} />)}
      {state === 'loadingMore' &&
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: '14px 0', fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
          <Spinner />{t('Loading more…', 'Đang tải thêm…')}
        </div>}
    </>;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      {select ?
        <div className="appbar" style={{ justifyContent: 'space-between', background: 'var(--memox-primary-soft)' }}>
          <button className="icon-btn" aria-label={t('Clear selection', 'Bỏ chọn')}><Ic name="x" size="sm" /></button>
          <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4, fontVariantNumeric: 'tabular-nums' }}>
            {t('3 selected', 'Đã chọn 3')}
          </div>
          <button className="pill-btn" style={{ height: 32, padding: '0 12px', borderRadius: 8, fontSize: 12, background: 'transparent', color: 'var(--memox-primary)', fontWeight: 700 }}>
            {t(`Select all ${summary.due}`, `Chọn cả ${summary.due}`)}
          </button>
        </div> :
        <div className="appbar" style={{ justifyContent: 'space-between' }}>
          <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="sm" /></button>
          <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {D.deckContext.name}
          </div>
          <button className="icon-btn" aria-label={t('Search', 'Tìm kiếm')}>
            <Ic name="search" size="sm" color="var(--memox-on-surface-variant)" />
          </button>
          <button className="icon-btn" aria-label={t('More', 'Thêm')}>
            <Ic name="more-vertical" size="sm" color="var(--memox-on-surface-variant)" />
          </button>
        </div>}

      {!select && <Breadcrumb segments={[{ label: t('Library', 'Thư viện') }, { label: '한국어 TOPIK I · Từ vựng' }, { label: D.deckContext.name }]} />}

      <ScreenScroll clearance={select ? 'base' : 'fab'}>
        {searching &&
          <div style={{ padding: '0 0 10px' }}>
            <SearchField placeholder={t('Search front and back', 'Tìm mặt trước và mặt sau')} active value={state === 'noMatch' ? '눈치' : ''} />
          </div>}

        {/* V1's deck summary — mastery donut, state distribution, one clear CTA. */}
        {showSummary &&
          <div className="card" style={{ padding: 16, marginBottom: 12, background: 'color-mix(in srgb, var(--memox-primary) 6%, var(--memox-surface-bright))', border: 'none' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 12 }}>
              <svg width="56" height="56" viewBox="0 0 40 40" aria-hidden="true">
                <circle cx="20" cy="20" r="17" fill="none" stroke="var(--memox-surface-container)" strokeWidth="3" />
                <circle cx="20" cy="20" r="17" fill="none" stroke={masteryColor(summary.mastery)} strokeWidth="3" strokeLinecap="round"
                  strokeDasharray="106.8" strokeDashoffset={(1 - summary.mastery) * 106.8} transform="rotate(-90 20 20)" />
                <text x="20" y="22.5" textAnchor="middle" fontSize="9" fontWeight="700" fill={masteryColor(summary.mastery)} style={{ fontFamily: 'var(--memox-font-sans)' }}>
                  {Math.round(summary.mastery * 100)}%
                </text>
              </svg>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="ov">{t('Deck progress', 'Tiến trình bộ thẻ')}</div>
                <div style={{ fontSize: 14, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>
                  {t(`${summary.mastered} of ${summary.total} cards mastered`, `${summary.mastered}/${summary.total} thẻ đã thành thạo`)}
                </div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, display: 'inline-flex', alignItems: 'center', gap: 4, fontVariantNumeric: 'tabular-nums' }}>
                  {summary.due > 0 ?
                    <>
                      <span className="status-dot" style={{ width: 6, height: 6, background: 'var(--memox-primary)' }} />
                      {t(`${summary.due} due · ${summary.new} new`, `${summary.due} đến hạn · ${summary.new} thẻ mới`)}
                    </> : t('Nothing due right now', 'Hiện không có thẻ đến hạn')}
                </div>
              </div>
            </div>
            <div style={{ display: 'flex', height: 6, borderRadius: 999, overflow: 'hidden', background: 'var(--memox-surface-container)', marginBottom: 8 }}>
              {[
                { v: summary.isNew, c: STATUS_TOKEN.new },
                { v: summary.beginning, c: STATUS_TOKEN.beginning },
                { v: summary.reviewing, c: STATUS_TOKEN.reviewing },
                { v: summary.mastered, c: STATUS_TOKEN.mastered }
              ].map((s, i) => <div key={i} style={{ width: `${s.v / summary.total * 100}%`, background: s.c }} />)}
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px 8px', fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', marginBottom: summary.due > 0 ? 12 : 0 }}>
              {[
                { l: t('New', 'Mới'), v: summary.isNew, c: STATUS_TOKEN.new },
                { l: t('Beginning', 'Bắt đầu'), v: summary.beginning, c: STATUS_TOKEN.beginning },
                { l: t('Reviewing', 'Đang ôn'), v: summary.reviewing, c: STATUS_TOKEN.reviewing },
                { l: t('Mastered', 'Thành thạo'), v: summary.mastered, c: STATUS_TOKEN.mastered }
              ].map((b) =>
                <span key={b.l} style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  <span className="status-dot" style={{ width: 6, height: 6, background: b.c }} />
                  {b.l} <span style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{b.v}</span>
                </span>)}
            </div>
            {summary.due > 0 &&
              <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14 }}>
                <Ic name="play" size="xs" color="var(--memox-on-primary)" />
                {t(`Study this deck · ${summary.due} due`, `Học bộ thẻ này · ${summary.due} đến hạn`)}
              </button>}
          </div>}

        {/* Filter chips with counts — V1's row, minus the filter the product lacks. */}
        {showChips &&
          <div className="scroll-x" style={{ display: 'flex', gap: 4, padding: '0 0 8px' }}>
            {[
              { label: t('All', 'Tất cả'), count: summary.total, active: true },
              { label: t('Due now', 'Đến hạn'), count: summary.due },
              { label: t('New', 'Mới'), count: summary.new },
              { label: t('Flagged', 'Gắn cờ'), count: summary.flagged, ic: 'flag' }
            ].map((f) =>
              <button key={f.label} className="pill-btn" style={{
                height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, flexShrink: 0, whiteSpace: 'nowrap',
                background: f.active ? 'var(--memox-primary)' : 'var(--memox-surface-container-lowest)',
                color: f.active ? 'var(--memox-on-primary)' : 'var(--memox-on-surface)',
                border: f.active ? 'none' : 'var(--memox-border-ghost)'
              }}>
                {f.ic && <Ic name={f.ic} size="xs" color={f.active ? 'var(--memox-on-primary)' : 'var(--memox-on-surface-variant)'} />}
                {f.label}
                <span style={{ fontSize: 12, fontWeight: 700, opacity: f.active ? 0.75 : 0.6, fontVariantNumeric: 'tabular-nums' }}>{f.count}</span>
              </button>)}
          </div>}

        {showCount &&
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, padding: '2px 4px 8px' }}>
            <span className="ov">
              {state === 'noMatch' ? t('No matches', 'Không có kết quả')
                : select ? t(`3 of ${summary.due} selected`, `Đã chọn 3/${summary.due}`)
                  : t(`${summary.total} cards`, `${summary.total} thẻ`)}
            </span>
            {!select &&
              <button className="pill-btn" style={{ height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, whiteSpace: 'nowrap', flexShrink: 0, background: 'transparent', border: 'none', color: 'var(--memox-on-surface-variant)' }}>
                <Ic name="arrow-down-up" size="xs" color="var(--memox-on-surface-variant)" />
                {t('Due first', 'Đến hạn trước')}
                <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
              </button>}
          </div>}

        {body}
      </ScreenScroll>

      {select &&
        <BottomBar style={{ flexDirection: 'row', gap: 4, justifyContent: 'space-between', alignItems: 'center' }}>
          {[
            { ic: 'folder-input', en: 'Move', vi: 'Chuyển' },
            { ic: 'flag', en: 'Flag', vi: 'Gắn cờ' },
            { ic: 'tag', en: 'Tag', vi: 'Gắn nhãn' },
            { ic: 'download', en: 'Export', vi: 'Xuất' },
            { ic: 'trash-2', en: 'Trash', vi: 'Thùng rác' }
          ].map((a) =>
            <button key={a.en} style={{
              flex: 1, minHeight: 48, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 3,
              background: 'transparent', border: 'none', fontFamily: 'inherit', fontSize: 12, fontWeight: 600,
              color: 'var(--memox-on-surface-variant)', cursor: 'pointer'
            }}>
              {state === 'bulkRunning' && a.en === 'Move' ? <Spinner /> : <Ic name={a.ic} size="sm" color="var(--memox-on-surface-variant)" />}
              {t(a.en, a.vi)}
            </button>)}
        </BottomBar>}

      {state === 'cardMenu' &&
        <BottomSheet scrim={false} maxHeight="none">
          <SheetHead title="눈치" sub={t('Reviewing · due in 6 days · flagged', 'Đang ôn · đến hạn sau 6 ngày · đã gắn cờ')} />
          <div style={{ padding: '4px 8px 8px' }}>
            <ActionRow icon="eye" label={t('Open card', 'Mở thẻ')} sub={t('Read-only — viewing is not studying', 'Chỉ đọc — xem không tính là học')} />
            <ActionRow icon="pencil" label={t('Edit card', 'Sửa thẻ')} />
            <ActionRow icon="flag-off" label={t('Remove flag', 'Bỏ cờ')} />
            <ActionRow icon="tag" label={t('Add a tag', 'Gắn nhãn')} />
            <ActionRow icon="folder-input" label={t('Move to another deck', 'Chuyển sang bộ khác')} />
            <div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: 8 }} />
            <ActionRow icon="trash-2" danger label={t('Move to Trash', 'Chuyển vào Thùng rác')} sub={t('Recoverable for 30 days', 'Phục hồi được trong 30 ngày')} />
          </div>
          <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
        </BottomSheet>}
      {state === 'deckMenu' && <DeckMenu />}
      {state === 'moveNone' &&
        <BottomSheet maxHeight="none">
          <SheetHead title={t('Move 3 cards', 'Di chuyển 3 thẻ')} />
          <div style={{ padding: '0 16px 16px' }}>
            <Note icon="folder-tree">
              {t('Cards can only move to another deck in the same tree that holds cards or is still empty. This tree has none right now — create one first.', 'Thẻ chỉ có thể chuyển sang bộ khác trong cùng cây, đang chứa thẻ hoặc còn trống. Hiện cây này chưa có bộ nào như vậy — hãy tạo trước.')}
            </Note>
            <button className="pill-btn outline" style={{ width: '100%', marginTop: 12 }}>{t('Create a deck here', 'Tạo bộ thẻ ở đây')}</button>
          </div>
          <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
        </BottomSheet>}
      {state === 'bulkDone' && <Snackbar icon="check">{t('3 cards moved to Ngữ pháp sơ cấp.', 'Đã chuyển 3 thẻ sang Ngữ pháp sơ cấp.')}</Snackbar>}
      {state === 'trashedUndo' && <Snackbar icon="trash-2" action={t('Undo', 'Hoàn tác')}>{t('물 moved to Trash.', 'Đã chuyển 물 vào Thùng rác.')}</Snackbar>}
      {!select && !['loading', 'error', 'notFound'].includes(state) && <Fab icon="plus" label={t('New card', 'Thẻ mới')} />}
    </div>);
}

Object.assign(window, { CardList });
})();
