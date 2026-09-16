/* MemoX v2 · A1 — Library deck tree
   Refined from V1 LibraryOverviewScreen, not redesigned. KEPT: large-title app
   bar, inline SearchField, the today summary strip, the overline + sort-pill
   header row, and V1's FolderCard anatomy (44px tile · name + due badge ·
   icon/label meta row · 5px mastery bar). REMOVED: the folder description line
   and per-folder seed colour (no such fields in the product), archive.
   ADDED: overdue and new counts, sub-deck vs card content, deeper levels. */
(function () {
const { Ic, StatusBar, ScreenScroll, Fab, Skeleton, EmptyState, ErrorState, BottomSheet, SearchField, Badge, Breadcrumb, masteryColor } = window;
const { useT, NavBar, Note, SheetHead, ActionRow, schedLabel } = window;
const D = window.MemoXData;

const SORTS = [
  { id: 'manual', en: 'Manual order', vi: 'Thứ tự tự đặt' },
  { id: 'added', en: 'Date added', vi: 'Ngày thêm' },
  { id: 'name', en: 'Name A→Z', vi: 'Tên A→Z' },
  { id: 'due', en: 'Most due', vi: 'Đến hạn nhiều nhất' },
  { id: 'progress', en: 'Least mastered', vi: 'Ít thành thạo nhất' }
];

/* V1's FolderCard, corrected to the product's fields. */
function DeckCard({ d }) {
  const t = useT();
  const mastery = d.total ? d.learned / d.total : 0;
  const empty = d.contentType === 'unset';
  return (
    <div className="card" role="button" tabIndex={0} style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: '48px 1fr 24px', gap: 16, alignItems: 'center', padding: 16, cursor: 'pointer' }}>
      <div style={{
        width: 44, height: 44, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: empty ? 'transparent' : 'color-mix(in srgb, var(--memox-primary) 12%, transparent)',
        border: empty ? '1px dashed var(--memox-outline-variant)' : 'none'
      }}>
        <Ic name={d.contentType === 'deck' ? 'folder-tree' : d.contentType === 'unset' ? 'square-dashed' : 'layers'} size="sm"
          color={empty ? 'var(--memox-on-surface-variant)' : 'var(--memox-primary)'} />
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8 }}>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', lineHeight: 1.3, minWidth: 0, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{d.name}</div>
          {d.due > 0 && <Badge tone="primary">{t(`${t.n(d.due)} due`, `${t.n(d.due)} đến hạn`)}</Badge>}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: 8, marginTop: 8, fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>
          {d.contentType === 'deck' &&
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <Ic name="folder-tree" size="xs" color="var(--memox-on-surface-variant)" />
              {t.n(d.subDecks)} {t('sub-decks', 'bộ con')}
            </span>}
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            <Ic name="copy" size="xs" color="var(--memox-on-surface-variant)" />
            {t.n(d.total)} {t('cards', 'thẻ')}
          </span>
          {d.overdue > 0 &&
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--memox-warning-ink)', fontWeight: 600 }}>
              <span className="status-dot" style={{ background: 'var(--memox-warning)', width: 6, height: 6 }} />
              {t.n(d.overdue)} {t('overdue', 'quá hạn')}
            </span>}
          {d.new > 0 &&
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <span className="status-dot" style={{ background: 'var(--memox-status-new)', width: 6, height: 6 }} />
              {t.n(d.new)} {t('new', 'thẻ mới')}
            </span>}
          {empty && <span>{t('empty — add cards or sub-decks', 'trống — thêm thẻ hoặc bộ con')}</span>}
        </div>
        {d.total > 0 &&
          <div style={{ marginTop: 8, height: 5, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${Math.max(mastery * 100, mastery > 0 ? 2 : 0)}%`, background: masteryColor(mastery), borderRadius: 999 }} />
          </div>}
      </div>
      <button className="icon-btn" style={{ width: 28, height: 28 }} aria-label={t('More', 'Thêm')} onClick={(e) => e.stopPropagation()}>
        <Ic name="more-vertical" size="xs" color="var(--memox-on-surface-variant)" />
      </button>
    </div>);
}

const LoadingList = () =>
  <>{[0, 1, 2, 3].map((i) =>
    <div key={i} className="card" style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: '48px 1fr 24px', gap: 16, alignItems: 'center', padding: 16 }}>
      <Skeleton w={44} h={44} r={12} op={0.55} />
      <div>
        <Skeleton w={100 + i * 30} r={4} op={0.55} style={{ display: 'inline-block' }} />
        <Skeleton w={140} h={10} r={4} op={0.4} style={{ marginTop: 6 }} />
        <Skeleton w="100%" h={5} r={999} op={0.35} style={{ marginTop: 8 }} />
      </div>
      <span />
    </div>)}</>;

/* V1's overflow sheet, with archive removed and the schedule row added. */
function DeckMenu({ root }) {
  const t = useT();
  const d = D.level2[1];
  return (
    <BottomSheet scrim={false} maxHeight="none">
      <SheetHead title={d.name} sub={t(`${d.subDecks} sub-decks · ${t.n(d.total)} cards`, `${d.subDecks} bộ con · ${t.n(d.total)} thẻ`)} />
      <div style={{ padding: '4px 8px 8px' }}>
        <ActionRow icon="folder-open" label={t('Open deck', 'Mở bộ thẻ')} />
        <ActionRow icon="play" label={t('Study this deck', 'Học bộ thẻ này')}
          sub={t(`${d.due} due · ${d.new} new`, `${d.due} đến hạn · ${d.new} thẻ mới`)} />
        <ActionRow icon="pencil" label={t('Rename deck', 'Đổi tên bộ thẻ')} />
        <ActionRow icon="folder-tree" label={t('Move deck', 'Di chuyển bộ thẻ')} />
        {root
          ? <ActionRow icon="calendar-clock" label={t('Review schedule', 'Lịch ôn tập')} sub={t(`${schedLabel(d.sched, t)} · locked`, `${schedLabel(d.sched, t)} · đã khoá`)} />
          : <ActionRow icon="arrow-down-up" label={t('Reorder', 'Sắp xếp lại')} sub={t('Available in manual order', 'Chỉ khi đang ở thứ tự tự đặt')} />}
        <div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: 8 }} />
        <ActionRow icon="trash-2" label={t('Move to Trash', 'Chuyển vào Thùng rác')} danger
          sub={t('800 cards go with it, recoverable for 30 days', '800 thẻ đi cùng, phục hồi được trong 30 ngày')} />
      </div>
      <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
    </BottomSheet>);
}

function SortSheet({ sort = 'manual', filterDue }) {
  const t = useT();
  return (
    <BottomSheet maxHeight="none">
      <SheetHead title={t('Sort and filter', 'Sắp xếp và lọc')} sub={t('Applies to this level only', 'Chỉ áp dụng cho mức này')} />
      <div style={{ padding: '0 8px 4px' }}>
        {SORTS.map((s) => <ActionRow key={s.id} icon={s.id === sort ? 'check' : 'minus'} label={t(s.en, s.vi)} />)}
      </div>
      <div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: '4px 8px' }} />
      <div style={{ padding: '0 8px 8px' }}>
        <ActionRow icon={filterDue ? 'check' : 'minus'} label={t('Only decks with due cards', 'Chỉ bộ có thẻ đến hạn')} />
      </div>
      <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
    </BottomSheet>);
}

function LibraryDeckList({ state = 'topLevel' }) {
  const t = useT();
  const inside = ['inside', 'insideEmpty', 'dueFilterEmpty', 'allZero', 'deep', 'sortSheet', 'deckMenu'].includes(state);
  const deep = state === 'deep';
  const unset = state === 'insideEmpty';

  let decks = D.rootDecks, totals = D.rootTotals, ancestors = [];
  if (['inside', 'sortSheet', 'deckMenu'].includes(state)) { decks = D.level2; totals = D.level2Totals; ancestors = D.level2Ancestors; }
  if (deep) { decks = D.level10; totals = { total: 12, new: 4, due: 3, overdue: 0, dueToday: 3, scheduled: 5 }; ancestors = D.level10Ancestors; }
  if (state === 'allZero') {
    decks = D.level2.map((d) => ({ ...d, new: 0, due: 0, overdue: 0, dueToday: 0, scheduled: d.total }));
    totals = { total: 1248, new: 0, due: 0, overdue: 0, dueToday: 0, scheduled: 1248 };
    ancestors = D.level2Ancestors;
  }
  if (state === 'dueFilterEmpty') { decks = []; totals = { total: 1248, new: 312, due: 0, overdue: 0, dueToday: 0, scheduled: 936 }; ancestors = D.level2Ancestors; }
  if (unset) { decks = []; totals = { total: 0, new: 0, due: 0, overdue: 0, dueToday: 0, scheduled: 0 }; ancestors = [...D.level2Ancestors, { id: 'd13', name: 'Tính từ · 형용사' }]; }

  const listStates = ['topLevel', 'inside', 'allZero', 'deep', 'sortSheet', 'deckMenu'];
  const showList = listStates.includes(state);
  const showChrome = showList || state === 'dueFilterEmpty' || unset;
  /* V1's Breadcrumb; at depth the middle collapses so the last two stay legible. */
  const segments = [{ label: t('Library', 'Thư viện') }].concat(
    ancestors.length > 3
      ? [{ label: ancestors[0].name }, { label: '…' }, { label: ancestors[ancestors.length - 1].name }]
      : ancestors.map((a) => ({ label: a.name })));

  let body = null;
  if (state === 'loading') body = <LoadingList />;
  else if (state === 'topEmpty') body =
    <EmptyState icon="library" title={t('Start your library', 'Bắt đầu thư viện')}
      body={t('A deck holds your cards, and can hold smaller decks instead. Create your first deck to begin.', 'Bộ thẻ chứa các thẻ của bạn, hoặc chứa các bộ nhỏ hơn. Hãy tạo bộ đầu tiên để bắt đầu.')}
      action={
        <button className="pill-btn primary" style={{ fontSize: 14 }}>
          <Ic name="plus" size="xs" color="var(--memox-on-primary)" />{t('Create deck', 'Tạo bộ thẻ')}
        </button>}
      footnote={t('You can also copy a ready-made deck, or import cards from a file.', 'Bạn cũng có thể sao chép bộ có sẵn, hoặc nhập thẻ từ tệp.')} />;
  else if (state === 'error') body =
    <ErrorState title={t("Couldn't load your library", 'Không tải được thư viện')}
      body={t('Your data is safe on this device. Try again in a moment.', 'Dữ liệu của bạn vẫn an toàn trên máy này. Hãy thử lại sau giây lát.')}
      action={<button className="pill-btn primary"><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />{t('Retry', 'Thử lại')}</button>} />;
  else if (state === 'notFound') body =
    <ErrorState icon="file-question" title={t('This deck is gone', 'Bộ thẻ này không còn')}
      body={t('It was moved to Trash somewhere else in the app. You can restore it from Trash.', 'Bộ thẻ đã được chuyển vào Thùng rác ở nơi khác. Bạn có thể phục hồi từ Thùng rác.')}
      action={
        <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
          <button className="pill-btn primary">{t('Back to Library', 'Về Thư viện')}</button>
          <button className="pill-btn outline">{t('Open Trash', 'Mở Thùng rác')}</button>
        </div>} />;
  else if (unset) body =
    <>
      <Note icon="square-dashed" style={{ marginBottom: 12 }}>
        {t('This deck is still empty. What you add first decides what it holds — cards or sub-decks, never both.', 'Bộ thẻ này còn trống. Thứ bạn thêm đầu tiên sẽ quyết định nó chứa gì — thẻ hoặc bộ con, không thể cả hai.')}
      </Note>
      <div style={{ display: 'grid', gap: 8 }}>
        {[
          { ic: 'plus', en: 'Add a card', vi: 'Thêm thẻ', sen: 'Front and back, written here', svi: 'Mặt trước và mặt sau, nhập tại đây' },
          { ic: 'upload', en: 'Import cards', vi: 'Nhập thẻ', sen: 'From CSV, TSV, XLSX or pasted text', svi: 'Từ CSV, TSV, XLSX hoặc văn bản dán vào' },
          { ic: 'folder-plus', en: 'Add a sub-deck', vi: 'Thêm bộ con', sen: 'Split this deck into smaller ones', svi: 'Chia bộ này thành các bộ nhỏ hơn' }
        ].map((a) =>
          <button key={a.en} className="card" style={{ padding: 16, display: 'grid', gridTemplateColumns: '36px 1fr 20px', gap: 12, alignItems: 'center', textAlign: 'left', border: 'none', cursor: 'pointer' }}>
            <span style={{ width: 36, height: 36, borderRadius: 12, background: 'color-mix(in srgb, var(--memox-primary) 12%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Ic name={a.ic} size="sm" color="var(--memox-primary)" />
            </span>
            <span>
              <span style={{ display: 'block', fontSize: 14, fontWeight: 700 }}>{t(a.en, a.vi)}</span>
              <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{t(a.sen, a.svi)}</span>
            </span>
            <Ic name="chevron-right" size="sm" color="var(--memox-on-surface-variant)" />
          </button>)}
      </div>
    </>;
  else if (state === 'dueFilterEmpty') body =
    <EmptyState compact icon="calendar-check" title={t('Nothing due here right now', 'Hiện chưa có thẻ nào đến hạn')}
      body={t('312 new cards are waiting, and 936 are scheduled for later. Clear the filter to see every deck.', '312 thẻ mới đang chờ, 936 thẻ đã lên lịch cho sau này. Bỏ lọc để xem tất cả bộ thẻ.')}
      action={<button className="pill-btn outline">{t('Show all decks', 'Hiện tất cả bộ thẻ')}</button>} />;
  else body =
    <>
      {decks.map((d) => <DeckCard key={d.id} d={d} />)}
      {state === 'allZero' &&
        <Note style={{ marginTop: 4 }}>{t('Everything here is scheduled for a later day. Nothing is wrong — new cards are still available to learn.', 'Mọi thẻ ở đây đã được xếp cho ngày khác. Không có gì sai — bạn vẫn có thể học thẻ mới.')}</Note>}
      {deep &&
        <Note icon="alert-circle" tone="warning" style={{ marginTop: 4 }}>
          {t('Level 10 is the deepest a deck can go, so no sub-deck can be created here.', 'Mức 10 là mức sâu nhất, nên không thể tạo bộ con ở đây.')}
        </Note>}
    </>;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      {inside ?
        <div className="appbar" style={{ justifyContent: 'space-between' }}>
          <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="sm" /></button>
          <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4, lineHeight: 1.25, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
            {unset ? 'Tính từ · 형용사' : deep ? 'Level 9 · 아홉' : '한국어 TOPIK I · Từ vựng'}
          </div>
          <button className="icon-btn" aria-label={t('Sort and filter', 'Sắp xếp và lọc')}>
            <Ic name="sliders-horizontal" size="sm" color="var(--memox-on-surface-variant)" />
          </button>
          <button className="icon-btn" aria-label={t('More', 'Thêm')}>
            <Ic name="more-vertical" size="sm" color="var(--memox-on-surface-variant)" />
          </button>
        </div> :
        <div className="appbar appbar-lg" style={{ justifyContent: 'space-between' }}>
          <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>{t('Library', 'Thư viện')}</div>
          <button className="icon-btn" aria-label={t('Sort and filter', 'Sắp xếp và lọc')}>
            <Ic name="sliders-horizontal" size="sm" color="var(--memox-on-surface-variant)" />
          </button>
        </div>}

      {inside && <Breadcrumb segments={segments} />}

      {!inside &&
        <div style={{ padding: '0 16px 8px' }}>
          <SearchField placeholder={t('Search decks, cards, tags', 'Tìm bộ thẻ, thẻ, nhãn')} />
        </div>}

      {/* V1's today strip — the one tap that answers "what should I study now". */}
      {showChrome && totals.due > 0 &&
        <div style={{ padding: '0 16px 12px' }}>
          <div role="button" tabIndex={0} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', background: 'color-mix(in srgb, var(--memox-primary) 6%, var(--memox-surface-bright))', borderRadius: 'var(--memox-radius-lg)', cursor: 'pointer' }}>
            <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Ic name="zap" size="sm" color="var(--memox-on-primary)" />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', fontVariantNumeric: 'tabular-nums' }}>
                {t(`${t.n(totals.due)} cards due`, `${t.n(totals.due)} thẻ đến hạn`)}
              </div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>
                {totals.overdue > 0
                  ? t(`${t.n(totals.overdue)} overdue · ${t.n(totals.dueToday)} today · ${t.n(totals.new)} new`, `${t.n(totals.overdue)} quá hạn · ${t.n(totals.dueToday)} hôm nay · ${t.n(totals.new)} thẻ mới`)
                  : t(`${t.n(totals.dueToday)} today · ${t.n(totals.new)} new`, `${t.n(totals.dueToday)} hôm nay · ${t.n(totals.new)} thẻ mới`)}
              </div>
            </div>
            <Ic name="chevron-right" size="sm" color="var(--memox-primary)" />
          </div>
        </div>}

      {/* V1's overline + sort pill. Zero-workload levels say so here, calmly. */}
      {(showList || state === 'loading' || state === 'dueFilterEmpty') &&
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, padding: '0 20px 8px' }}>
          <span className="ov">
            {state === 'loading' ? t('Loading decks', 'Đang tải bộ thẻ')
              : state === 'dueFilterEmpty' ? t('Due only · no match', 'Chỉ đến hạn · không khớp')
                : totals.due === 0
                  ? t(`${decks.length} decks · nothing due`, `${decks.length} bộ thẻ · không có thẻ đến hạn`)
                  : t(`${decks.length} decks`, `${decks.length} bộ thẻ`)}
          </span>
          <button className="pill-btn" style={{ height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, whiteSpace: 'nowrap', flexShrink: 0, background: 'transparent', border: 'none', color: 'var(--memox-on-surface-variant)' }}>
            <Ic name="arrow-down-up" size="xs" color="var(--memox-on-surface-variant)" />
            {state === 'dueFilterEmpty' ? t('Due', 'Đến hạn') : t('Manual', 'Tự đặt')}
            <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
          </button>
        </div>}

      <ScreenScroll clearance={showList && !deep ? 'fab-nav' : 'base'}>{body}</ScreenScroll>

      {showList && !deep &&
        <Fab icon={state === 'topLevel' ? 'plus' : 'folder-plus'}
          label={state === 'topLevel' ? t('New deck', 'Bộ thẻ mới') : t('New sub-deck', 'Bộ con mới')} aboveNav />}
      {state === 'sortSheet' && <SortSheet />}
      {state === 'deckMenu' && <DeckMenu />}
      <NavBar active="library" />
    </div>);
}

Object.assign(window, { LibraryDeckList });
})();
