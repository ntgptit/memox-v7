/* MemoX v2 · A6 — Starter library
   Current templates are development fixtures, so the screen says so before it
   offers anything (BR-87). A copy is an ordinary, independent deck (BR-35), and
   adding a template that is already in the library copies nothing unless the
   user asks for a second copy on purpose (BR-37, BR-38). */
(function () {
const { Ic, StatusBar, ScreenScroll, BottomSheet, Skeleton, Spinner, EmptyState, ErrorState } = window;
const { useT, Note, SheetHead, Snackbar, ConfirmDialog } = window;
const D = window.MemoXData;

function TemplateCard({ tpl, busy }) {
  const t = useT();
  return (
    <div className="card" style={{ padding: 16, marginBottom: 10, display: 'flex', flexDirection: 'column', gap: 12 }}>
      <div>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', lineHeight: 1.3, wordBreak: 'break-word' }}>{tpl.title}</div>
        <div style={{ fontSize: 12.5, color: 'var(--memox-text-secondary)', marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>
          {tpl.lang} · {t.n(tpl.cards)} {t('cards', 'thẻ')}
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4, fontSize: 11.5, color: 'var(--memox-text-secondary)' }}>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          <Ic name="file-text" size="xs" color="var(--memox-text-secondary)" />{tpl.source}
        </span>
        <span>{t('suggested schedule', 'lịch gợi ý')}: {tpl.suggested === 'sm2' ? 'SM-2' : t('Eight boxes', 'Tám hộp')}</span>
      </div>
      {tpl.installed ?
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12.5, fontWeight: 600, color: 'var(--memox-text-secondary)' }}>
            <Ic name="check" size="xs" color="var(--memox-status-mastered)" />{t('Already in your library', 'Đã có trong thư viện')}
          </div>
          <button className="pill-btn" style={{ width: '100%', background: 'var(--memox-surface-container)', color: 'var(--memox-text-primary)', fontWeight: 700 }}>
            {t('Add a second copy', 'Thêm bản thứ hai')}
          </button>
        </div> :
        <button className="pill-btn primary" style={{ width: '100%' }} disabled={busy}>
          {busy ? <Spinner color="var(--memox-on-primary)" /> : <Ic name="plus" size="xs" color="var(--memox-on-primary)" />}
          {busy ? t('Adding…', 'Đang thêm…') : t('Add to my library', 'Thêm vào thư viện')}
        </button>}
    </div>);
}

function StarterLibrary({ state = 'list' }) {
  const t = useT();

  let body;
  if (state === 'loading') body =
    <>{[0, 1].map((i) =>
      <div key={i} className="card" style={{ padding: 16, marginBottom: 10, display: 'flex', flexDirection: 'column', gap: 12 }}>
        <Skeleton w="70%" h={15} op={0.5} /><Skeleton w="45%" h={11} op={0.4} /><Skeleton w="100%" h={44} r={12} op={0.3} />
      </div>)}</>;
  else if (state === 'noTemplates') body =
    <EmptyState icon="package-open" title={t('No starter decks in this build', 'Bản này chưa có bộ có sẵn')}
      body={t('Ready-made content is not published yet. You can still build a deck yourself, or import a list you already have.', 'Nội dung sẵn chưa được phát hành. Bạn vẫn có thể tự tạo bộ thẻ, hoặc nhập danh sách có sẵn.')}
      action={<button className="pill-btn primary">{t('Create a deck', 'Tạo bộ thẻ')}</button>} />;
  else if (state === 'loadFailed') body =
    <ErrorState title={t("Couldn't load the starter decks", 'Không tải được bộ có sẵn')}
      body={t('Nothing was added to your library.', 'Chưa có gì được thêm vào thư viện.')} />;
  else body =
    <>
      <Note icon="flask-conical" style={{ marginBottom: 14 }}>
        {t('These decks are practice fixtures used for development and testing — not published course material. Treat the content as examples.', 'Các bộ này là dữ liệu mẫu dùng để phát triển và kiểm thử — không phải tài liệu khoá học chính thức. Hãy xem nội dung như ví dụ.')}
      </Note>
      {state === 'addFailed' &&
        <Note icon="alert-circle" tone="danger" style={{ marginBottom: 12 }}>
          {t('Adding failed and nothing was copied. Your library is unchanged.', 'Thêm không thành công và chưa sao chép gì. Thư viện của bạn không thay đổi.')}
        </Note>}
      {D.templates.map((tpl) => <TemplateCard key={tpl.id} tpl={tpl} busy={state === 'adding' && !tpl.installed} />)}
      <div style={{ padding: '6px 4px 0', fontSize: 11.5, color: 'var(--memox-text-secondary)', lineHeight: 1.5 }}>
        {t('A copy becomes an ordinary deck of yours. Later versions of a starter deck never change the copy you already have.', 'Bản sao trở thành bộ thẻ bình thường của bạn. Các phiên bản sau của bộ có sẵn không bao giờ thay đổi bản bạn đã có.')}
      </div>
    </>;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="md" /></button>
        <div className="title">{t('Starter decks', 'Bộ có sẵn')}</div>
      </div>
      <ScreenScroll>{body}</ScreenScroll>

      {state === 'addSheet' &&
        <BottomSheet maxHeight="none">
          <SheetHead title={t('Add “한글 기초 · Hangul basics”', 'Thêm “한글 기초 · Hangul basics”')} sub={t('24 cards · Korean → romanisation', '24 thẻ · Hàn → phiên âm')} />
          <div style={{ padding: '0 16px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-text-secondary)' }}>{t('Review schedule for this deck', 'Lịch ôn cho bộ này')}</div>
            {[{ id: 'sm2', en: 'SM-2', vi: 'SM-2', note: t('suggested for this deck', 'gợi ý cho bộ này') }, { id: 'eight_box', en: 'Eight boxes', vi: 'Tám hộp' }].map((s) =>
              <button key={s.id} style={{
                width: '100%', minHeight: 48, display: 'grid', gridTemplateColumns: '20px 1fr', gap: 10, alignItems: 'center',
                padding: 12, borderRadius: 'var(--memox-radius-md)', textAlign: 'left', fontFamily: 'inherit', cursor: 'pointer',
                background: s.id === 'sm2' ? 'var(--memox-primary-soft)' : 'var(--memox-surface-container-low)',
                border: s.id === 'sm2' ? '1px solid var(--memox-primary-border)' : '1px solid transparent', color: 'var(--memox-on-surface)'
              }}>
                <span style={{ width: 18, height: 18, borderRadius: 999, border: s.id === 'sm2' ? '5px solid var(--memox-primary)' : '2px solid var(--memox-outline)' }} />
                <span style={{ fontSize: 14, fontWeight: 600 }}>
                  {t(s.en, s.vi)}
                  {s.note ? <span style={{ fontWeight: 500, color: 'var(--memox-text-secondary)' }}> · {s.note}</span> : null}
                </span>
              </button>)}
            <button className="pill-btn primary" style={{ width: '100%', marginTop: 4 }}>{t('Add deck', 'Thêm bộ thẻ')}</button>
          </div>
          <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
        </BottomSheet>}

      {state === 'secondCopy' &&
        <ConfirmDialog title={t('Add a second copy?', 'Thêm bản thứ hai?')} confirm={t('Add a copy', 'Thêm bản sao')}>
          {t('“Everyday English → Tiếng Việt” is already in your library. A second copy is a separate deck with its own progress — nothing is merged.', '“Everyday English → Tiếng Việt” đã có trong thư viện. Bản thứ hai là một bộ riêng với tiến trình riêng — không gộp vào bản cũ.')}
        </ConfirmDialog>}

      {state === 'added' && <Snackbar icon="check" action={t('Open', 'Mở')}>{t('“한글 기초 · Hangul basics” added — 24 new cards.', 'Đã thêm “한글 기초 · Hangul basics” — 24 thẻ mới.')}</Snackbar>}
      {state === 'alreadyPresent' && <Snackbar icon="info">{t('Already in your library — nothing was copied.', 'Đã có trong thư viện — không sao chép gì.')}</Snackbar>}
    </div>);
}

Object.assign(window, { StarterLibrary });
})();
