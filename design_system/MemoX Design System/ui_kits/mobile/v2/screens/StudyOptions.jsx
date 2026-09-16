/* MemoX v2 · A17 — Study options (per root deck)
   Options live on the root deck; sub-decks follow it (BR-147). "Use app
   defaults" belongs here, not in Settings (BR-212), and every state says that
   a change only affects sessions started afterwards (BR-213). */
(function () {
const { Ic, StatusBar, ScreenScroll, BottomBar, Skeleton, Spinner } = window;
const { useT, Note } = window;

const ORDERS = [
  { id: 'created', en: 'In the order you added them', vi: 'Theo thứ tự bạn đã thêm' },
  { id: 'random', en: 'Shuffled', vi: 'Xếp ngẫu nhiên' }
];

function StudyOptions({ state = 'override' }) {
  const t = useT();
  const invalid = state === 'invalid';
  const following = state === 'defaults';
  const limit = invalid ? 250 : following ? 20 : 50;
  const order = following ? 'created' : 'random';

  if (state === 'loading') return (
    <div className="app">
      <StatusBar />
      <div className="appbar"><button className="icon-btn"><Ic name="arrow-left" size="md" /></button><div className="title">{t('Study options', 'Tuỳ chọn học')}</div></div>
      <ScreenScroll>
        {[0, 1].map((i) =>
          <div key={i} className="card" style={{ padding: 16, marginBottom: 12, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <Skeleton w="40%" h={11} op={0.45} /><Skeleton w="55%" h={28} op={0.5} /><Skeleton w="100%" h={32} r={999} op={0.3} />
          </div>)}
      </ScreenScroll>
    </div>);

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="md" /></button>
        <div className="title">{t('Study options', 'Tuỳ chọn học')}</div>
      </div>
      <div style={{ padding: '0 16px 12px', fontSize: 12, color: 'var(--memox-text-secondary)', lineHeight: 1.45 }}>
        <strong style={{ fontWeight: 700, color: 'var(--memox-text-primary)' }}>한국어 TOPIK I · Từ vựng</strong>
        {' · '}{following
          ? t('following the app defaults', 'đang theo mặc định của ứng dụng')
          : t('set on this deck', 'đặt riêng cho bộ này')}
        {' · '}{t('applies to every deck inside it', 'áp dụng cho mọi bộ con bên trong')}
      </div>

      <ScreenScroll>
        <div className="card" style={{ padding: 16, marginBottom: 12, display: 'flex', flexDirection: 'column', gap: 14 }}>
          <span className="ov">{t('Cards per session', 'Số thẻ mỗi phiên')}</span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <button className="icon-btn" aria-label={t('Fewer', 'Giảm')} style={{ background: 'var(--memox-surface-container)', width: 40, height: 40 }}>
              <Ic name="minus" size="sm" />
            </button>
            <div style={{ flex: 1, textAlign: 'center' }}>
              <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px', fontVariantNumeric: 'tabular-nums', color: invalid ? 'var(--memox-error)' : undefined }}>{limit}</div>
              <div style={{ fontSize: 11.5, color: 'var(--memox-text-secondary)' }}>{t('1 – 200 cards', '1 – 200 thẻ')}</div>
            </div>
            <button className="icon-btn" aria-label={t('More', 'Tăng')} style={{ background: 'var(--memox-surface-container)', width: 40, height: 40 }}>
              <Ic name="plus" size="sm" />
            </button>
          </div>
          {invalid &&
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--memox-error)' }}>
              <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
              {t('Use a number between 1 and 200.', 'Hãy nhập số từ 1 đến 200.')}
            </div>}
          <div style={{ display: 'flex', gap: 8 }}>
            {[10, 20, 50, 100].map((n) =>
              <button key={n} className="pill-btn" style={{
                flex: 1, height: 34, padding: 0, borderRadius: 999, fontSize: 13, fontWeight: 700,
                background: n === limit ? 'var(--memox-primary)' : 'var(--memox-surface-container)',
                color: n === limit ? 'var(--memox-on-primary)' : 'var(--memox-text-primary)'
              }}>{n}</button>)}
          </div>
        </div>

        <div className="card" style={{ padding: 16, marginBottom: 12, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <span className="ov">{t('New cards arrive', 'Thẻ mới xuất hiện')}</span>
          {ORDERS.map((o) =>
            <button key={o.id} style={{
              width: '100%', minHeight: 48, display: 'grid', gridTemplateColumns: '20px 1fr', gap: 12, alignItems: 'center',
              padding: '10px 12px', borderRadius: 'var(--memox-radius-md)', textAlign: 'left', fontFamily: 'inherit', cursor: 'pointer',
              background: o.id === order ? 'var(--memox-primary-soft)' : 'var(--memox-surface-container-low)',
              border: o.id === order ? '1px solid var(--memox-primary-border)' : '1px solid transparent', color: 'var(--memox-on-surface)'
            }}>
              <span style={{ width: 18, height: 18, borderRadius: 999, border: o.id === order ? '5px solid var(--memox-primary)' : '2px solid var(--memox-outline)' }} />
              <span style={{ fontSize: 14, fontWeight: 600 }}>{t(o.en, o.vi)}</span>
            </button>)}
        </div>

        <Note icon="info">{t('A change applies to sessions you start from now on. A session already open keeps the size it opened with.', 'Thay đổi chỉ áp dụng cho các phiên bắt đầu từ giờ. Phiên đang mở giữ nguyên số thẻ lúc mở.')}</Note>

        {state === 'saved' &&
          <Note icon="check" style={{ marginTop: 10 }}>{t('Saved for this deck.', 'Đã lưu cho bộ thẻ này.')}</Note>}
        {state === 'writeFailed' &&
          <Note icon="alert-circle" tone="danger" style={{ marginTop: 10 }}>
            {t("Couldn't save. The deck is still using its previous options.", 'Không lưu được. Bộ thẻ vẫn dùng tuỳ chọn trước đó.')}
          </Note>}
      </ScreenScroll>

      <BottomBar>
        <button className="pill-btn primary" style={{ width: '100%' }} disabled={invalid || state === 'saving'}>
          {state === 'saving' ? <Spinner color="var(--memox-on-primary)" /> : null}
          {state === 'saving' ? t('Saving…', 'Đang lưu…') : state === 'writeFailed' ? t('Try again', 'Thử lại') : t('Save', 'Lưu')}
        </button>
        {!following &&
          <button className="pill-btn" style={{ width: '100%', background: 'transparent', color: 'var(--memox-primary)', fontWeight: 700 }}>
            {t('Use app defaults instead', 'Dùng mặc định của ứng dụng')}
          </button>}
      </BottomBar>
    </div>);
}

Object.assign(window, { StudyOptions });
})();
