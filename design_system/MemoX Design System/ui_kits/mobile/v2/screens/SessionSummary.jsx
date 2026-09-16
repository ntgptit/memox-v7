/* MemoX v2 · A19 — Session summary
   Refined from V1 StudyResultScreen. KEPT: the calm hero card (tile · headline
   · one sentence · three-stat row), V1's neutral "ended early" treatment for
   abnormal endings, and the footer action bar with its caption line.
   REMOVED: accuracy, duration, box changes, streak/goal, tough cards and the
   share action — none of those exist in the product.
   ADDED: what was kept when a session ended abnormally. */
(function () {
const { Ic, StatusBar, ScreenScroll, Skeleton } = window;
const { useT } = window;

const CASES = {
  completedLearning: { kind: 'learning', finished: 20, answered: 20, wrong: 7, turns: 87, tone: 'ok' },
  completedReview: { kind: 'reviewing', finished: 30, answered: 30, wrong: 4, turns: 34, tone: 'ok' },
  largeReview: { kind: 'reviewing', finished: 200, answered: 200, wrong: 57, turns: 257, tone: 'ok' },
  leftEarly: { kind: 'reviewing', finished: 6, answered: 8, wrong: 3, turns: 11, tone: 'calm' },
  interrupted: { kind: 'learning', finished: 0, answered: 12, wrong: 2, turns: 26, tone: 'calm' },
  reset: { kind: 'reviewing', finished: 2, answered: 2, wrong: 0, turns: 2, tone: 'calm' },
  schedulerChanged: { kind: 'reviewing', finished: 3, answered: 3, wrong: 1, turns: 3, tone: 'calm' },
  contentDeleted: { kind: 'learning', finished: 1, answered: 4, wrong: 1, turns: 9, tone: 'calm' },
  saveError: { kind: 'reviewing', finished: 5, answered: 5, wrong: 2, turns: 6, tone: 'warn' }
};

function SessionSummary({ state = 'completedReview' }) {
  const t = useT();
  const loading = state === 'loading';
  const c = CASES[state] || CASES.completedReview;
  const learning = c.kind === 'learning';
  const calm = c.tone !== 'ok';

  const headline = {
    completedLearning: t('Learning session finished', 'Đã học xong phiên này'),
    completedReview: t('Review finished', 'Đã ôn xong'),
    largeReview: t('Review finished', 'Đã ôn xong'),
    leftEarly: t('You left the review', 'Bạn đã dừng phiên ôn'),
    interrupted: t('The session was interrupted', 'Phiên học bị ngắt'),
    reset: t('Ended by a progress reset', 'Kết thúc vì đặt lại tiến trình'),
    schedulerChanged: t('The review schedule changed', 'Lịch ôn đã thay đổi'),
    contentDeleted: t('The material went to Trash', 'Nội dung đã vào Thùng rác'),
    saveError: t('The session stopped', 'Phiên học đã dừng')
  }[state] || '';

  const explain = {
    completedLearning: t('Every card in this session went through all five stages. They are learned now and come back tomorrow.', 'Mọi thẻ trong phiên đã đi qua cả năm bước. Chúng đã học xong và sẽ quay lại vào ngày mai.'),
    completedReview: t('Every due card in this session was answered and rescheduled.', 'Mọi thẻ đến hạn trong phiên đã được trả lời và xếp lại lịch.'),
    largeReview: t('All 200 cards of this session were answered and rescheduled.', 'Cả 200 thẻ của phiên đã được trả lời và xếp lại lịch.'),
    leftEarly: t('The 6 cards you answered were rescheduled. The rest are still due and will be waiting next time.', '6 thẻ bạn đã trả lời được xếp lại lịch. Số còn lại vẫn đến hạn và sẽ chờ bạn lần sau.'),
    interrupted: t('The app closed before the session finished, and it was not resumed the same day. Your 12 answers were kept, but no card finished learning — those cards are still new.', 'Ứng dụng bị đóng trước khi phiên kết thúc và không được tiếp tục trong ngày. 12 câu trả lời vẫn được giữ, nhưng chưa thẻ nào học xong — các thẻ đó vẫn là thẻ mới.'),
    reset: t("The deck's learning progress was reset while this session was open, so no further answer could be written. The 2 answers given before that were kept.", 'Tiến trình học của bộ thẻ được đặt lại khi phiên còn mở, nên không thể ghi thêm câu trả lời. 2 câu trước đó vẫn được giữ.'),
    schedulerChanged: t('The review schedule of this deck was changed while the session was open, so the session ended. The 3 answers given before that were kept.', 'Lịch ôn của bộ thẻ bị thay đổi khi phiên còn mở nên phiên đã kết thúc. 3 câu trước đó vẫn được giữ.'),
    contentDeleted: t('The deck or some of its cards were moved to Trash, so the session ended. What you answered first was kept.', 'Bộ thẻ hoặc một số thẻ đã vào Thùng rác nên phiên kết thúc. Những câu bạn trả lời trước đó vẫn được giữ.'),
    saveError: t('An answer could not be saved, so the session stopped instead of continuing without recording. The 5 answers already saved are safe.', 'Có câu trả lời không lưu được nên phiên dừng lại thay vì tiếp tục mà không ghi. 5 câu đã lưu vẫn an toàn.')
  }[state] || '';

  const accent = c.tone === 'warn' ? 'var(--memox-warning)' : 'var(--memox-mastery)';
  const icon = c.tone === 'ok' ? 'check-circle-2' : c.tone === 'warn' ? 'alert-circle' : 'pause-circle';

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      {/* V1: no back button — the summary must not be re-enterable after Done. */}
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <div className="title" style={{ fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface-variant)' }}>
          {t('Session complete', 'Phiên học đã xong')}
        </div>
      </div>

      <ScreenScroll>
        {loading ?
          <>
            <div className="card" style={{ padding: '28px 24px', textAlign: 'center', marginBottom: 16 }}>
              <Skeleton w={56} h={56} r={16} />
              <div style={{ height: 14 }} />
              <Skeleton w={180} h={20} r={6} />
              <div style={{ height: 6 }} />
              <Skeleton w={120} h={11} op={0.4} />
              <div style={{ height: 18 }} />
              <Skeleton w="100%" h={50} r={11} />
            </div>
            <div className="card" style={{ padding: 16 }}>
              <Skeleton w={80} h={10} />
              <div style={{ height: 12 }} />
              <Skeleton w="100%" h={40} r={10} />
            </div>
          </> :
          <>
            <div className="card" style={{
              padding: '24px 24px 20px', textAlign: 'center', marginBottom: 16,
              background: calm ? 'var(--memox-surface-container-lowest)' : `color-mix(in srgb, ${accent} 8%, var(--memox-surface-bright))`,
              border: calm ? '1px solid var(--memox-outline-variant)' : `1px solid color-mix(in srgb, ${accent} 22%, transparent)`
            }}>
              <div style={{
                width: 60, height: 60, borderRadius: 20, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16,
                background: calm ? 'var(--memox-surface-container)' : `color-mix(in srgb, ${accent} 16%, transparent)`
              }}>
                <Ic name={icon} size="lg" color={calm ? 'var(--memox-on-surface-variant)' : accent} />
              </div>
              <div style={{ fontSize: calm ? 18 : 22, fontWeight: 700, letterSpacing: '-0.4px', marginBottom: 6, lineHeight: 1.2 }}>{headline}</div>
              <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 16 }}>{explain}</div>
              <div style={{ display: 'flex', gap: 8, padding: '0 4px', fontVariantNumeric: 'tabular-nums' }}>
                {[
                  { v: t.n(c.finished), l: learning ? t('Learned', 'Đã học xong') : t('Rescheduled', 'Đã xếp lịch') },
                  { v: t.n(c.answered), l: t('Answered', 'Đã trả lời') },
                  { v: `${t.n(c.wrong)}/${t.n(c.turns)}`, l: t('Wrong turns', 'Lượt sai') }
                ].map((s) =>
                  <div key={s.l} style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px' }}>{s.v}</div>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 700, lineHeight: 1.35 }}>{s.l}</div>
                  </div>)}
              </div>
            </div>

            <div className="ov" style={{ padding: '0 4px 8px' }}>{t('This session', 'Phiên này')}</div>
            <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
              {[
                { ic: 'layers', label: t('Deck', 'Bộ thẻ'), value: 'Động từ · 동사' },
                { ic: learning ? 'sparkles' : 'play', label: t('Kind', 'Loại'), value: learning ? t('Learning', 'Học mới') : t('Review', 'Ôn tập') },
                { ic: 'calendar-clock', label: t('Review schedule', 'Lịch ôn tập'), value: t('Eight boxes', 'Tám hộp') }
              ].map((r, i, a) =>
                <div key={r.label} style={{ display: 'grid', gridTemplateColumns: '32px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
                  <div style={{ width: 30, height: 30, borderRadius: 8, background: 'var(--memox-surface-container)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Ic name={r.ic} size="xs" color="var(--memox-on-surface-variant)" />
                  </div>
                  <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{r.label}</div>
                  <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', maxWidth: 150, textAlign: 'right', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.value}</div>
                </div>)}
            </div>
          </>}
      </ScreenScroll>

      {/* V1's final action bar — Done always available, with a caption line. */}
      <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', gap: 8 }}>
        <div style={{ display: 'flex', gap: 8 }}>
          {!loading && state !== 'saveError' &&
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8 }}>
              <Ic name="play" size="xs" color="var(--memox-primary)" />{t('Study more', 'Học thêm')}
            </button>}
          {state === 'saveError' &&
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8 }}>
              <Ic name="refresh-cw" size="xs" color="var(--memox-primary)" />{t('Try this deck again', 'Thử lại bộ thẻ này')}
            </button>}
          <button className="pill-btn primary" disabled={loading} style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: loading ? 0.45 : 1 }}>
            <Ic name="check" size="xs" color="var(--memox-on-primary)" />{t('Done', 'Xong')}
          </button>
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center', opacity: 0.8 }}>
          {loading ? t('Saving your session…', 'Đang lưu phiên học…')
            : calm ? t('Everything you answered was already saved.', 'Mọi câu bạn đã trả lời đều đã được lưu.')
              : t('Done returns you to where you started.', 'Xong sẽ đưa bạn về nơi bắt đầu.')}
        </div>
      </div>
    </div>);
}

Object.assign(window, { SessionSummary });
})();
