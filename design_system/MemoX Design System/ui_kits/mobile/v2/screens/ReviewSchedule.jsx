/* MemoX v2 · A5 — Review schedule and reset (root deck)
   Two different actions, deliberately kept apart on one screen: switching the
   schedule is only possible while the deck is unlocked (BR-12, BR-13), while
   Reset is always possible and always says what is kept and what is lost
   (BR-50). Neither is worded as a deletion (BR-266). */
(function () {
const { Ic, StatusBar, ScreenScroll, Dialog, Spinner } = window;
const { useT, Note, schedLabel, Snackbar } = window;

const SCHEDULES = [
  { id: 'eight_box', en: 'Eight boxes', vi: 'Tám hộp', sen: 'Remembered moves a card up one box, forgotten sends it back to the first. Intervals: 1, 2, 4, 8, 16, 32, 64, 128 days.', svi: 'Nhớ được thì lên một hộp, quên thì về hộp đầu. Nhịp: 1, 2, 4, 8, 16, 32, 64, 128 ngày.' },
  { id: 'sm2', en: 'SM-2', vi: 'SM-2', sen: 'You grade yourself and the interval adapts per card: Again, Hard, Good, Easy.', svi: 'Bạn tự đánh giá và nhịp ôn thay đổi theo từng thẻ: Lại, Khó, Tốt, Dễ.' }
];

function Row({ selected, disabled, s, t }) {
  return (
    <button type="button" disabled={disabled} style={{
      width: '100%', display: 'grid', gridTemplateColumns: '20px 1fr', gap: 10, alignItems: 'start', textAlign: 'left',
      padding: 12, borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', color: 'var(--memox-on-surface)',
      background: selected ? 'var(--memox-primary-soft)' : 'var(--memox-surface-container-low)',
      border: selected ? '1px solid var(--memox-primary-border)' : '1px solid transparent',
      opacity: disabled && !selected ? 'var(--memox-op-disabled)' : 1, cursor: disabled ? 'default' : 'pointer'
    }}>
      <span style={{ width: 18, height: 18, borderRadius: 999, marginTop: 2, border: selected ? '5px solid var(--memox-primary)' : '2px solid var(--memox-outline)' }} />
      <span style={{ minWidth: 0 }}>
        <span style={{ display: 'block', fontSize: 14, fontWeight: 700 }}>{t(s.en, s.vi)}</span>
        <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 3, lineHeight: 1.45 }}>{t(s.sen, s.svi)}</span>
      </span>
    </button>);
}

function ReviewSchedule({ state = 'locked' }) {
  const t = useT();
  const unlocked = ['unlocked', 'switching', 'switched', 'writeFailed'].includes(state);
  const nothingStudied = state === 'resetNothing';
  const current = unlocked || nothingStudied ? 'eight_box' : 'sm2';

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="md" /></button>
        <div className="title">{t('Review schedule', 'Lịch ôn tập')}</div>
      </div>
      <div style={{ padding: '0 16px 14px', fontSize: 12, color: 'var(--memox-text-secondary)', lineHeight: 1.45 }}>
        <strong style={{ fontWeight: 700, color: 'var(--memox-text-primary)' }}>{unlocked || nothingStudied ? 'IT' : '한국어 TOPIK I · Từ vựng'}</strong>
        {' · '}{t('applies to every deck inside it', 'áp dụng cho mọi bộ con bên trong')}
      </div>

      <ScreenScroll>
        <div className="card" style={{ padding: 16, marginBottom: 12, display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
            <span className="ov" style={{ fontSize: 11 }}>{t('In use now', 'Đang dùng')}</span>
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 5, height: 22, padding: '0 8px', borderRadius: 999, fontSize: 11.5, fontWeight: 700,
              background: unlocked ? 'var(--memox-surface-container)' : 'var(--memox-warning-soft)',
              color: unlocked ? 'var(--memox-text-secondary)' : 'var(--memox-warning-ink)'
            }}>
              <Ic name={unlocked ? 'unlock' : 'lock'} size="xs" color={unlocked ? 'var(--memox-text-secondary)' : 'var(--memox-warning)'} />
              {unlocked ? t('Can still be changed', 'Vẫn đổi được') : t('Locked', 'Đã khoá')}
            </span>
          </div>

          {unlocked ?
            <>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {SCHEDULES.map((s) => <Row key={s.id} s={s} t={t} selected={s.id === current} />)}
              </div>
              <Note icon="alert-circle" tone="warning">
                {t('Switching now starts every card in this deck from the beginning of the new schedule, and ends any session that is open. Your cards, tags and history stay.', 'Đổi bây giờ sẽ đưa mọi thẻ trong bộ về đầu lịch mới và kết thúc phiên đang mở. Thẻ, nhãn và lịch sử vẫn giữ nguyên.')}
              </Note>
              {state === 'writeFailed' &&
                <Note icon="alert-circle" tone="danger">{t("Couldn't switch. The deck is still on Eight boxes.", 'Không đổi được. Bộ thẻ vẫn đang dùng Tám hộp.')}</Note>}
              <button className="pill-btn primary" style={{ width: '100%' }} disabled={state === 'switching'}>
                {state === 'switching' ? <Spinner color="var(--memox-on-primary)" /> : null}
                {state === 'switching' ? t('Switching…', 'Đang đổi…') : t('Switch to SM-2', 'Đổi sang SM-2')}
              </button>
            </> :
            <>
              <div style={{ fontSize: 16, fontWeight: 700 }}>{schedLabel(current, t)}</div>
              <div style={{ fontSize: 13, lineHeight: 1.5, color: 'var(--memox-text-secondary)' }}>
                {t(SCHEDULES.find((s) => s.id === current).sen, SCHEDULES.find((s) => s.id === current).svi)}
              </div>
              <Note icon="lock">
                {t('A card in this deck has already finished learning, so the schedule is fixed. Resetting the learning progress below starts a new cycle and lets you choose again.', 'Đã có thẻ trong bộ học xong nên lịch ôn được cố định. Đặt lại tiến trình học ở dưới sẽ mở một vòng mới và cho bạn chọn lại.')}
              </Note>
            </>}
        </div>

        <div className="card" style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 12 }}>
          <span className="ov" style={{ fontSize: 11 }}>{t('Reset learning progress', 'Đặt lại tiến trình học')}</span>
          {nothingStudied ?
            <div style={{ fontSize: 13, lineHeight: 1.5, color: 'var(--memox-text-secondary)' }}>
              {t('Nothing has been studied in this deck yet, so a reset has nothing to undo. It would only let you pick the review schedule again.', 'Bộ này chưa học gì nên đặt lại không làm mất gì. Việc này chỉ cho bạn chọn lại lịch ôn.')}
            </div> :
            <>
              <div style={{ fontSize: 13, lineHeight: 1.5, color: 'var(--memox-text-secondary)' }}>
                {t('Start this deck over: every card becomes new again and waits to be learned from scratch.', 'Học lại bộ này từ đầu: mọi thẻ trở lại trạng thái mới và chờ được học lại.')}
              </div>
              <div style={{ display: 'grid', gap: 8 }}>
                {[
                  { ic: 'check', head: t('Kept', 'Giữ lại'), body: t('Every deck, sub-deck, card, tag and note — and all past review history, labelled by cycle.', 'Mọi bộ, bộ con, thẻ, nhãn và ghi chú — cùng toàn bộ lịch sử học trước đây, được ghi theo từng vòng.') },
                  { ic: 'minus', head: t('Lost', 'Mất đi'), body: t("Every card's schedule, due date and progress, and any session that is open. 204 mastered cards go back to new.", 'Lịch ôn, ngày đến hạn và tiến trình của mọi thẻ, cùng phiên đang mở. 204 thẻ thành thạo trở về thẻ mới.') }
                ].map((b) =>
                  <div key={b.head} style={{ display: 'grid', gridTemplateColumns: '20px 1fr', gap: 8, padding: '10px 12px', borderRadius: 'var(--memox-radius-md)', background: 'var(--memox-surface-container-low)' }}>
                    <Ic name={b.ic} size="xs" color="var(--memox-text-secondary)" />
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontSize: 12.5, fontWeight: 700 }}>{b.head}</div>
                      <div style={{ fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 2, lineHeight: 1.45 }}>{b.body}</div>
                    </div>
                  </div>)}
              </div>
            </>}
          <button className="pill-btn outline" style={{ width: '100%' }}>
            <Ic name="rotate-ccw" size="xs" color="var(--memox-primary)" />{t('Reset learning progress', 'Đặt lại tiến trình học')}
          </button>
        </div>
      </ScreenScroll>

      {(state === 'resetConfirm' || state === 'applying') &&
        <Dialog>
          <div style={{ padding: '20px 20px 4px' }}>
            <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: '-0.3px', marginBottom: 8 }}>{t('Reset “한국어 TOPIK I · Từ vựng”?', 'Đặt lại “한국어 TOPIK I · Từ vựng”?')}</div>
            <div style={{ fontSize: 13.5, lineHeight: 1.55, color: 'var(--memox-text-secondary)' }}>
              {t('All 1,248 cards become new again. Your cards, tags and past history stay; schedules, due dates and the open session do not.', 'Cả 1.248 thẻ sẽ trở lại thẻ mới. Thẻ, nhãn và lịch sử cũ vẫn giữ; lịch ôn, ngày đến hạn và phiên đang mở thì không.')}
            </div>
            <div style={{ marginTop: 16 }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-text-secondary)', marginBottom: 8 }}>{t('Review schedule for the new cycle', 'Lịch ôn cho vòng mới')}</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {SCHEDULES.map((s) => <Row key={s.id} s={s} t={t} selected={s.id === 'sm2'} />)}
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8, padding: '14px 16px 16px', justifyContent: 'flex-end' }}>
            <button className="pill-btn" style={{ background: 'transparent', color: 'var(--memox-text-secondary)', fontWeight: 700 }}>{t('Cancel', 'Huỷ')}</button>
            <button className="pill-btn primary" style={{ gap: 6 }}>
              {state === 'applying' ? <Spinner color="var(--memox-on-primary)" /> : null}
              {state === 'applying' ? t('Resetting…', 'Đang đặt lại…') : t('Reset', 'Đặt lại')}
            </button>
          </div>
        </Dialog>}

      {state === 'applied' && <Snackbar icon="check">{t('Progress reset. 1,248 cards are new again — cycle 2.', 'Đã đặt lại tiến trình. 1.248 thẻ trở lại thẻ mới — vòng 2.')}</Snackbar>}
      {state === 'switched' && <Snackbar icon="check">{t('This deck now uses SM-2.', 'Bộ thẻ này giờ dùng SM-2.')}</Snackbar>}
      {state === 'refused' && <Snackbar icon="lock">{t("Couldn't switch — a card finished learning a moment ago, so the schedule just locked.", 'Không đổi được — vừa có thẻ học xong nên lịch ôn đã khoá.')}</Snackbar>}
    </div>);
}

Object.assign(window, { ReviewSchedule });
})();
