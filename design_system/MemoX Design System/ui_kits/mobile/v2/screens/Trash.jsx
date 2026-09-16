/* MemoX v2 · A14 — Trash
   Deleting is recoverable, so this screen is calm: only permanent deletion
   carries destructive emphasis (BR-266). Restore always asks where to put the
   item (BR-261), and the original location is shown as information, never as a
   promise of where it will land (BR-267). */
(function () {
const { Ic, StatusBar, ScreenScroll, BottomBar, Skeleton, Spinner, EmptyState, ErrorState, BottomSheet } = window;
const { useT, NavBar, Chip, ChipRow, Note, SheetHead, ConfirmDialog, Snackbar } = window;
const D = window.MemoXData;

function daysTone(e) {
  if (e.daysLeft === 0) return 'var(--memox-warning-ink)';
  if (e.daysLeft <= 3) return 'var(--memox-warning-ink)';
  return 'var(--memox-text-secondary)';
}

function Entry({ e, selecting, selected }) {
  const t = useT();
  const left = e.daysLeft === 0
    ? t(`${e.hoursLeft || 1}h left`, `còn ${e.hoursLeft || 1} giờ`)
    : t(`${e.daysLeft} days left`, `còn ${e.daysLeft} ngày`);
  return (
    <div className="card" style={{
      padding: 14, marginBottom: 8, display: 'grid', gridTemplateColumns: selecting ? '22px 28px 1fr 36px' : '28px 1fr 36px', gap: 10, alignItems: 'start',
      outline: selected ? '1.5px solid var(--memox-primary)' : 'none', background: selected ? 'var(--memox-primary-soft)' : undefined
    }}>
      {selecting &&
        <span style={{
          width: 20, height: 20, borderRadius: 6, marginTop: 2, display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: selected ? 'var(--memox-primary)' : 'transparent', border: selected ? 'none' : '2px solid var(--memox-outline)'
        }}>{selected ? <Ic name="check" size="xs" color="var(--memox-on-primary)" /> : null}</span>}
      <span style={{ width: 28, height: 28, borderRadius: 8, marginTop: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', background: e.type === 'card' ? 'var(--memox-surface-container)' : 'color-mix(in srgb, var(--memox-primary) 10%, transparent)' }}>
        <Ic name={e.type === 'card' ? 'copy' : 'layers'} size="xs" color={e.type === 'card' ? 'var(--memox-on-surface-variant)' : 'var(--memox-primary)'} />
      </span>
      <div style={{ minWidth: 0, display: 'flex', flexDirection: 'column', gap: 4 }}>
        <div style={{ fontSize: 14.5, fontWeight: 700, lineHeight: 1.35, wordBreak: 'break-word', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{e.name}</div>
        <div style={{ fontSize: 12, color: 'var(--memox-text-secondary)', fontVariantNumeric: 'tabular-nums' }}>
          {e.type === 'card'
            ? t('Card', 'Thẻ')
            : t(`Deck · ${e.decks} sub-decks · ${t.n(e.cards)} cards`, `Bộ thẻ · ${e.decks} bộ con · ${t.n(e.cards)} thẻ`)}
          {' · '}{t(`deleted ${e.deletedAt}`, `đã xoá ${e.deletedAt}`)}
        </div>
        <div style={{ fontSize: 11.5, color: 'var(--memox-text-secondary)' }}>
          {t('was in', 'trước ở')} {e.from}
        </div>
        <div style={{ fontSize: 11.5, fontWeight: 700, color: daysTone(e), fontVariantNumeric: 'tabular-nums' }}>{left}</div>
      </div>
      <button className="icon-btn" aria-label={t('Entry actions', 'Tác vụ')}><Ic name="more-vertical" size="sm" color="var(--memox-text-secondary)" /></button>
    </div>);
}

function Trash({ state = 'list' }) {
  const t = useT();
  const selecting = ['selectionCards', 'restoring', 'permDeleting'].includes(state);
  const entries = state === 'onlyDecks' ? D.trash.filter((e) => e.type === 'deck')
    : state === 'noDecks' || state === 'selectionCards' || state === 'restoring' || state === 'permDeleting' ? D.trash.filter((e) => e.type === 'card')
      : D.trash;

  let body;
  if (state === 'loading') body =
    <>{[0, 1, 2].map((i) =>
      <div key={i} className="card" style={{ padding: 14, marginBottom: 8, display: 'grid', gridTemplateColumns: '28px 1fr', gap: 10 }}>
        <Skeleton w={28} h={28} r={8} op={0.5} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <Skeleton w={`${45 + i * 10}%`} h={13} op={0.5} /><Skeleton w="72%" h={10} op={0.35} /><Skeleton w="40%" h={10} op={0.3} />
        </div>
      </div>)}</>;
  else if (state === 'empty') body =
    <EmptyState icon="trash-2" title={t('Trash is empty', 'Thùng rác trống')}
      body={t('Anything you delete lands here for 30 days, then goes for good. Nothing is waiting right now.', 'Mọi thứ bạn xoá sẽ ở đây 30 ngày rồi biến mất hẳn. Hiện chưa có gì.')} />;
  else if (state === 'noDecks') body =
    <>
      <Note style={{ marginBottom: 12 }}>{t('No deleted decks — only cards are in Trash right now.', 'Không có bộ thẻ nào bị xoá — hiện trong Thùng rác chỉ có thẻ.')}</Note>
      {entries.map((e) => <Entry key={e.id} e={e} />)}
    </>;
  else if (state === 'loadFailed') body =
    <ErrorState title={t("Couldn't open Trash", 'Không mở được Thùng rác')} body={t('Nothing was purged. Try again.', 'Chưa xoá vĩnh viễn gì cả. Hãy thử lại.')} />;
  else body =
    <>
      <Note icon="clock" style={{ marginBottom: 12 }}>
        {t('Items stay here for 30 days after deletion, then they are removed for good. Restoring always asks where to put them back.', 'Các mục ở đây 30 ngày sau khi xoá, rồi bị xoá hẳn. Khi phục hồi, bạn luôn được hỏi đặt lại vào đâu.')}
      </Note>
      {entries.map((e, i) => <Entry key={e.id} e={e} selecting={selecting} selected={selecting && i < 2} />)}
      {state === 'refused' &&
        <Note icon="alert-circle" tone="warning" style={{ marginTop: 4 }}>
          {t('“물” could not be restored: the deck it came from is in Trash too. Restore that deck first, or pick another deck for the card.', 'Không phục hồi được “물”: bộ thẻ gốc cũng đang trong Thùng rác. Hãy phục hồi bộ đó trước, hoặc chọn bộ khác cho thẻ.')}
        </Note>}
    </>;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      {selecting ?
        <div className="appbar" style={{ background: 'var(--memox-primary-soft)' }}>
          <button className="icon-btn" aria-label={t('Clear selection', 'Bỏ chọn')}><Ic name="x" size="md" /></button>
          <div className="title" style={{ fontVariantNumeric: 'tabular-nums' }}>{t('2 cards selected', 'Đã chọn 2 thẻ')}</div>
        </div> :
        <div className="appbar">
          <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="md" /></button>
          <div className="title">{t('Trash', 'Thùng rác')}</div>
          {!['loading', 'empty', 'loadFailed'].includes(state) &&
            <button className="icon-btn" aria-label={t('Select items', 'Chọn mục')}><Ic name="check-square" size="md" /></button>}
        </div>}

      {!selecting && !['loading', 'empty', 'loadFailed'].includes(state) &&
        <ChipRow>
          <Chip label={t('All', 'Tất cả')} count={4} active={state === 'list' || state === 'refused'} />
          <Chip label={t('Cards', 'Thẻ')} count={2} active={state === 'noDecks'} />
          <Chip label={t('Decks', 'Bộ thẻ')} count={2} active={state === 'onlyDecks'} />
        </ChipRow>}

      <ScreenScroll>{body}</ScreenScroll>

      {selecting &&
        <BottomBar style={{ flexDirection: 'row', gap: 8 }}>
          <button className="pill-btn" style={{ flex: 1, background: 'var(--memox-surface-container)', color: 'var(--memox-text-primary)', fontWeight: 700, gap: 6 }}>
            {state === 'restoring' ? <Spinner /> : <Ic name="undo-2" size="xs" color="var(--memox-text-primary)" />}
            {state === 'restoring' ? t('Restoring…', 'Đang phục hồi…') : t('Restore', 'Phục hồi')}
          </button>
          <button className="pill-btn" style={{ flex: 1, background: 'transparent', border: '1px solid var(--memox-danger-border)', color: 'var(--memox-error)', fontWeight: 700, gap: 6 }}>
            {state === 'permDeleting' ? <Spinner color="var(--memox-error)" /> : <Ic name="trash-2" size="xs" color="var(--memox-error)" />}
            {t('Delete for good', 'Xoá vĩnh viễn')}
          </button>
        </BottomBar>}

      {['restoreTargets', 'noValidTarget'].includes(state) &&
        <BottomSheet maxHeight="none">
          <SheetHead title={t('Restore “반짝반짝”', 'Phục hồi “반짝반짝”')}
            sub={t('Choose the deck it goes into', 'Chọn bộ thẻ để đưa thẻ vào')} />
          {state === 'noValidTarget' ?
            <div style={{ padding: '0 16px 16px' }}>
              <Note icon="folder-tree">
                {t('No deck in this tree can hold cards right now — every one of them holds sub-decks. Create a deck for cards first, then restore.', 'Hiện không bộ nào trong cây này nhận được thẻ — tất cả đều đang chứa bộ con. Hãy tạo một bộ chứa thẻ trước, rồi phục hồi.')}
              </Note>
              <button className="pill-btn outline" style={{ width: '100%', marginTop: 12 }}>{t('Go to the Library', 'Mở Thư viện')}</button>
            </div> :
            <div style={{ padding: '0 8px 8px' }}>
              {[
                { name: 'Động từ · 동사', parent: '한국어 TOPIK I · Từ vựng', note: { en: 'where it was', vi: 'nơi trước đây' } },
                { name: 'Ngữ pháp sơ cấp', parent: '한국어 TOPIK I · Từ vựng' },
                { name: 'Tính từ · 형용사', parent: '한국어 TOPIK I · Từ vựng', note: { en: 'empty deck', vi: 'bộ đang trống' } }
              ].map((g) =>
                <button key={g.name} style={{
                  width: '100%', minHeight: 48, display: 'grid', gridTemplateColumns: '28px 1fr 18px', gap: 10, alignItems: 'center',
                  padding: '8px', background: 'transparent', border: 'none', borderRadius: 'var(--memox-radius-md)', textAlign: 'left',
                  fontFamily: 'inherit', color: 'var(--memox-on-surface)', cursor: 'pointer'
                }}>
                  <span style={{ width: 28, height: 28, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Ic name="layers" size="xs" color="var(--memox-primary)" />
                  </span>
                  <span style={{ minWidth: 0 }}>
                    <span style={{ display: 'block', fontSize: 13.5, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{g.name}</span>
                    <span style={{ display: 'block', fontSize: 11.5, color: 'var(--memox-text-secondary)', marginTop: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {g.parent}{g.note ? ` · ${t(g.note.en, g.note.vi)}` : ''}
                    </span>
                  </span>
                  <Ic name="chevron-right" size="xs" color="var(--memox-text-secondary)" />
                </button>)}
            </div>}
          <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
        </BottomSheet>}

      {state === 'permDeleteConfirm' &&
        <ConfirmDialog tone="danger" title={t('Delete 2 cards for good?', 'Xoá vĩnh viễn 2 thẻ?')} confirm={t('Delete for good', 'Xoá vĩnh viễn')} cancel={t('Keep them', 'Giữ lại')}>
          {t('This cannot be undone. The 2 cards and their whole review history are removed from this device, and they disappear from past progress days.', 'Không thể hoàn tác. 2 thẻ và toàn bộ lịch sử học của chúng sẽ bị xoá khỏi máy này, và biến mất khỏi các ngày tiến độ đã qua.')}
        </ConfirmDialog>}

      {state === 'purgeBlocked' &&
        <ConfirmDialog tone="danger" title={t('Delete “Mandarin HSK 1–3” for good?', 'Xoá vĩnh viễn “Mandarin HSK 1–3”?')} confirm={t('Delete for good', 'Xoá vĩnh viễn')} cancel={t('Keep it', 'Giữ lại')}>
          {t('One of its sub-decks was deleted separately and is still in Trash with its own 12 days left. That entry has to go first — restore or delete it, then try again.', 'Một bộ con của nó đã bị xoá riêng và vẫn còn trong Thùng rác với 12 ngày. Cần xử lý mục đó trước — phục hồi hoặc xoá nó, rồi thử lại.')}
        </ConfirmDialog>}

      {state === 'restored' && <Snackbar icon="check">{t('“반짝반짝” restored to Động từ · 동사.', 'Đã phục hồi “반짝반짝” vào Động từ · 동사.')}</Snackbar>}
      {state === 'permDeleted' && <Snackbar icon="check">{t('2 cards deleted for good.', 'Đã xoá vĩnh viễn 2 thẻ.')}</Snackbar>}
      {!selecting && <NavBar active="library" />}
    </div>);
}

Object.assign(window, { Trash });
})();
