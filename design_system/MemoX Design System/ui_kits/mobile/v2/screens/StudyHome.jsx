/* MemoX v2 · A15 — Study home
   The only question this screen answers: what should I study now. Root decks
   only, ordered by workload (BR-201); decks with nothing waiting stay in the
   list, last, and read as normal rather than as a problem (BR-202). Nothing
   here starts a session (BR-200). */
(function () {
const { Ic, StatusBar, ScreenScroll, Skeleton, EmptyState, ErrorState, Badge } = window;
const { useT, NavBar, Note, schedLabel, modeLabel } = window;
const D = window.MemoXData;

function DeckRow({ d, first }) {
  const t = useT();
  const due = d.overdue + d.dueToday;
  const idle = !due && !d.new;
  return (
    <div className="card" role="button" tabIndex={0} style={{
      padding: 16, marginBottom: 8, display: 'grid', gridTemplateColumns: '1fr 24px', gap: 12, alignItems: 'center',
      cursor: 'pointer', opacity: idle ? 0.86 : 1,
      border: first ? '1px solid var(--memox-primary-border)' : undefined
    }}>
      <div style={{ minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8 }}>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', lineHeight: 1.3, minWidth: 0, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{d.name}</div>
          {due > 0 && <Badge tone="primary">{t(`${t.n(due)} due`, `${t.n(due)} đến hạn`)}</Badge>}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: 8, marginTop: 8, fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>
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
          {idle && <span>{d.total === 0 ? t('no cards yet', 'chưa có thẻ nào') : t('nothing waiting', 'không có gì đang chờ')}</span>}
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            <Ic name="copy" size="xs" color="var(--memox-on-surface-variant)" />
            {t.n(d.total)} {t('cards', 'thẻ')} · {schedLabel(d.sched, t)}
          </span>
        </div>
      </div>
      <Ic name="chevron-right" size="sm" color="var(--memox-on-surface-variant)" />
    </div>);
}

function ResumeCard({ r }) {
  const t = useT();
  return (
    <div className="card" style={{ padding: 16, marginBottom: 12, background: 'color-mix(in srgb, var(--memox-primary) 6%, var(--memox-surface-bright))', border: 'none' }}>
      <div className="ov" style={{ marginBottom: 8 }}>{t('In progress today', 'Đang học hôm nay')}</div>
      <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', lineHeight: 1.3, wordBreak: 'break-word' }}>{r.deckName}</div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, marginBottom: 12, fontVariantNumeric: 'tabular-nums' }}>
        {r.kind === 'learning' ? t('Learning', 'Học mới') : t('Review', 'Ôn tập')} · {modeLabel(r.mode, t)} · {t(`${r.remaining} of ${r.of} cards left`, `còn ${r.remaining}/${r.of} thẻ`)}
      </div>
      <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14 }}>
        <Ic name="play" size="xs" color="var(--memox-on-primary)" />{t('Continue', 'Tiếp tục')}
      </button>
    </div>);
}

function StudyHome({ state = 'loaded' }) {
  const t = useT();
  const decks = D.studyHome;
  const idle = decks.map((d) => ({ ...d, overdue: 0, dueToday: 0, new: 0 }));

  let body;
  if (state === 'loading') body =
    <>{[0, 1, 2].map((i) =>
      <div key={i} className="card" style={{ padding: 14, marginBottom: 8, display: 'flex', flexDirection: 'column', gap: 8 }}>
        <Skeleton w={`${60 + i * 8}%`} h={13} op={0.55} />
        <Skeleton w="70%" h={20} r={999} op={0.32} />
        <Skeleton w="34%" h={10} op={0.4} />
      </div>)}</>;
  else if (state === 'noDecks') body =
    <EmptyState icon="graduation-cap" title={t('Nothing to study yet', 'Chưa có gì để học')}
      body={t('Studying needs a deck with cards. Copy a ready-made deck, or build your own in the Library.', 'Muốn học thì cần một bộ thẻ có thẻ bên trong. Sao chép bộ có sẵn, hoặc tự tạo trong Thư viện.')}
      action={
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <button className="pill-btn primary">{t('Browse starter decks', 'Xem bộ có sẵn')}</button>
          <button className="pill-btn outline">{t('Go to Library', 'Mở Thư viện')}</button>
        </div>}
      footnote={t('Starter decks are practice fixtures for development and testing, not published course content.', 'Bộ có sẵn hiện là dữ liệu mẫu để phát triển và kiểm thử, không phải nội dung khoá học chính thức.')} />;
  else if (state === 'noCards') body =
    <EmptyState icon="layers" title={t('Your decks have no cards', 'Các bộ thẻ chưa có thẻ nào')}
      body={t('You have 6 decks, but none holds a card yet. Add or import cards in the Library, then come back.', 'Bạn có 6 bộ thẻ nhưng chưa bộ nào có thẻ. Hãy thêm hoặc nhập thẻ trong Thư viện rồi quay lại.')}
      action={<button className="pill-btn primary">{t('Go to Library', 'Mở Thư viện')}</button>} />;
  else if (state === 'error') body =
    <ErrorState title={t("Couldn't read your workload", 'Không đọc được khối lượng học')}
      body={t('Your study history is safe on this device.', 'Lịch sử học của bạn vẫn an toàn trên máy này.')}
      action={<button className="pill-btn primary"><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />{t('Try again', 'Thử lại')}</button>} />;
  else {
    const zero = state === 'allClear';
    const list = zero ? idle : decks;
    body =
      <>
        {state === 'resume' && <ResumeCard r={D.resume} />}
        {zero &&
          <Note icon="check" style={{ marginBottom: 12 }}>
            {t('Nothing is due today across your decks. Cards come back on their own schedule — the next one is due tomorrow.', 'Hôm nay không có thẻ nào đến hạn. Các thẻ sẽ tự quay lại theo lịch — thẻ tiếp theo đến hạn vào ngày mai.')}
          </Note>}
        <div className="ov" style={{ padding: '2px 4px 8px' }}>
          {zero ? t('Your decks', 'Bộ thẻ của bạn') : t('Needs work first', 'Cần học trước')}
        </div>
        {list.map((d, i) => <DeckRow key={d.id} d={d} first={!zero && i === 0} />)}
      </>;
  }

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar appbar-lg">
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>{t('Study', 'Học')}</div>
      </div>
      <ScreenScroll>{body}</ScreenScroll>
      <NavBar active="study" />
    </div>);
}

Object.assign(window, { StudyHome });
})();
