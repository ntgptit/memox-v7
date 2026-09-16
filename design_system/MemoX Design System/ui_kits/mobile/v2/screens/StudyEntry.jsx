/* MemoX v2 · A16 — Study entry for a deck
   Learning and reviewing are two separate offers, never one button (BR-142,
   BR-150). Review needs something due — there is no early review (BR-145).
   What the review schedule cannot ask is stated as a fact about this deck and
   never as something Reset would unlock (BR-100). */
(function () {
const { Ic, StatusBar, ScreenScroll, Skeleton, Spinner, Badge } = window;
const { useT, Note, schedLabel, modeLabel, MODE } = window;
const D = window.MemoXData;

const DIRECTIONS = [
  { id: 'termFirst', en: 'Term first', vi: 'Từ trước', sen: 'See the term, recall the meaning', svi: 'Thấy từ, nhớ nghĩa' },
  { id: 'meaningFirst', en: 'Meaning first', vi: 'Nghĩa trước', sen: 'See the meaning, recall the term', svi: 'Thấy nghĩa, nhớ từ' },
  { id: 'mixed', en: 'Mixed', vi: 'Trộn', sen: 'Both, split evenly across the session', svi: 'Cả hai, chia đều trong phiên' }
];
const UNAVAILABLE = {
  needsFiveMeanings: { en: 'Needs 5 different meanings among the due cards', vi: 'Cần 5 nghĩa khác nhau trong số thẻ đến hạn' },
  needsTwoPairs: { en: 'Needs at least 2 pairs', vi: 'Cần ít nhất 2 cặp' },
  needsExample: { en: 'Only cards that have an example can be filled in', vi: 'Chỉ thẻ có câu ví dụ mới dùng được' }
};

function Block({ overline, children, style }) {
  return (
    <div className="card" style={{ padding: 16, marginBottom: 12, display: 'flex', flexDirection: 'column', gap: 12, ...style }}>
      {overline ? <div className="ov">{overline}</div> : null}
      {children}
    </div>);
}

/* V1's stat voice: one 24px number with a quiet caption beside it. */
function Stat({ value, caption }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, flexWrap: 'wrap' }}>
      <span style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px', fontVariantNumeric: 'tabular-nums' }}>{value}</span>
      <span style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)' }}>{caption}</span>
    </div>);
}

function OptionRow({ selected, disabled, title, sub, right, icon }) {
  return (
    <button type="button" disabled={disabled} style={{
      width: '100%', minHeight: 56, display: 'grid', gridTemplateColumns: '20px 1fr auto', gap: 12, alignItems: 'center',
      padding: '10px 12px', textAlign: 'left', fontFamily: 'inherit', cursor: disabled ? 'default' : 'pointer',
      borderRadius: 'var(--memox-radius-md)', background: selected ? 'var(--memox-primary-soft)' : 'var(--memox-surface-container-low)',
      border: selected ? '1px solid var(--memox-primary-border)' : '1px solid transparent',
      opacity: disabled ? 'var(--memox-op-disabled)' : 1, color: 'var(--memox-on-surface)'
    }}>
      <span style={{
        width: 18, height: 18, borderRadius: 999, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
        border: selected ? '5px solid var(--memox-primary)' : '2px solid var(--memox-outline)'
      }} />
      <span style={{ minWidth: 0 }}>
        <span style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 14, fontWeight: 700 }}>
          {icon ? <Ic name={icon} size="xs" color="var(--memox-text-secondary)" /> : null}{title}
        </span>
        {sub ? <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 3, lineHeight: 1.45 }}>{sub}</span> : null}
      </span>
      {right ? <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-text-secondary)', fontVariantNumeric: 'tabular-nums', whiteSpace: 'nowrap' }}>{right}</span> : <span />}
    </button>);
}

function StudyEntry({ state = 'sm2' }) {
  const t = useT();
  const eight = ['eightBox', 'refused'].includes(state);
  const e = eight ? D.entryEightBox : D.entrySm2;
  const onlyNew = state === 'onlyNew';
  const nothing = state === 'nothing';
  const newCount = nothing ? 0 : onlyNew ? 312 : e.new;
  const due = nothing || onlyNew ? 0 : e.due;
  const overdue = nothing || onlyNew ? 0 : e.overdue;
  const dueToday = nothing || onlyNew ? 0 : e.dueToday;
  const limit = e.limit;
  const learnBatch = Math.min(newCount, limit);
  const reviewBatch = Math.min(due, limit);

  const optionsLine = t(
    `${limit} cards per session · new cards ${e.order === 'random' ? 'shuffled' : 'in the order you added them'}${e.isOverride ? ' · set on this deck' : ' · app default'}`,
    `${limit} thẻ mỗi phiên · thẻ mới ${e.order === 'random' ? 'xếp ngẫu nhiên' : 'theo thứ tự bạn đã thêm'}${e.isOverride ? ' · đặt riêng cho bộ này' : ' · mặc định của ứng dụng'}`);

  if (state === 'loading') return (
    <div className="app">
      <StatusBar />
      <div className="appbar"><button className="icon-btn"><Ic name="arrow-left" size="md" /></button><Skeleton w="55%" h={14} /></div>
      <ScreenScroll>
        <Skeleton w="42%" h={10} op={0.4} style={{ margin: '6px 0 14px' }} />
        {[0, 1].map((i) =>
          <div key={i} className="card" style={{ padding: 16, marginBottom: 12, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <Skeleton w="28%" h={10} op={0.45} />
            <Skeleton w="60%" h={22} op={0.5} />
            <Skeleton w="100%" h={48} r={12} op={0.32} />
          </div>)}
      </ScreenScroll>
    </div>);

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{
          display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden', lineHeight: 1.25, fontSize: 15
        }}>{e.deckName}</div>
        <button className="icon-btn" aria-label={t('Study options', 'Tuỳ chọn học')}><Ic name="sliders-horizontal" size="md" /></button>
      </div>
      <div style={{ padding: '0 16px 12px', fontSize: 12, color: 'var(--memox-text-secondary)' }}>
        {t('Review schedule', 'Lịch ôn tập')} · <strong style={{ fontWeight: 700, color: 'var(--memox-text-primary)' }}>{schedLabel(e.sched, t)}</strong>
      </div>

      <ScreenScroll>
        {state === 'resume' &&
          <Block overline={t('In progress today', 'Đang học hôm nay')} style={{ background: 'color-mix(in srgb, var(--memox-primary) 6%, var(--memox-surface-bright))', border: 'none' }}>
            <div style={{ fontSize: 14, fontWeight: 700 }}>{t('Review · Self-assess', 'Ôn tập · Tự đánh giá')}</div>
            <div style={{ fontSize: 12.5, color: 'var(--memox-text-secondary)', fontVariantNumeric: 'tabular-nums' }}>
              {t('18 of 30 cards left', 'còn 18/30 thẻ')}
            </div>
            <button className="pill-btn primary" style={{ width: '100%' }}>
              <Ic name="play" size="xs" color="var(--memox-on-primary)" />{t('Continue this session', 'Tiếp tục phiên này')}
            </button>
            <Note icon="info">{t('Starting new learning or a new review below will end this session and keep everything you have already answered.', 'Bắt đầu học mới hoặc ôn mới ở dưới sẽ kết thúc phiên này và giữ lại mọi câu bạn đã trả lời.')}</Note>
          </Block>}

        {/* ── Learn ── */}
        <Block overline={t('Learn new cards', 'Học thẻ mới')}>
          {newCount > 0 ?
            <>
              <Stat value={t.n(newCount)} caption={t('cards never studied', 'thẻ chưa từng học')} />
              <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14 }} disabled={state === 'starting'}>
                {state === 'starting' ? <Spinner color="var(--memox-on-primary)" /> : <Ic name="sparkles" size="xs" color="var(--memox-on-primary)" />}
                {state === 'starting' ? t('Starting…', 'Đang bắt đầu…') : t(`Learn ${learnBatch} cards`, `Học ${learnBatch} thẻ`)}
              </button>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.45 }}>
                {e.sched === 'sm2'
                  ? t('Each card goes through Browse, then Self-assess.', 'Mỗi thẻ đi qua Xem trước rồi Tự đánh giá.')
                  : t('Each card goes through Browse, Match, Guess, Recall and Fill.', 'Mỗi thẻ đi qua Xem trước, Ghép cặp, Chọn nghĩa, Nhớ lại và Điền từ.')}
              </div>
            </> :
            <div style={{ fontSize: 13, color: 'var(--memox-text-secondary)', lineHeight: 1.5 }}>
              {t('No new cards left in this deck. Add or import more to keep learning.', 'Bộ này không còn thẻ mới. Thêm hoặc nhập thẻ để học tiếp.')}
            </div>}
        </Block>

        {/* ── Review ── */}
        <Block overline={t('Review due cards', 'Ôn thẻ đến hạn')}>
          {due > 0 ?
            <>
              <Stat value={t.n(due)} caption={t('cards due', 'thẻ đến hạn')} />
              <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: 8, fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>
                {overdue > 0 &&
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--memox-warning-ink)', fontWeight: 600 }}>
                    <span className="status-dot" style={{ background: 'var(--memox-warning)', width: 6, height: 6 }} />
                    {t.n(overdue)} {t('overdue', 'quá hạn')}
                  </span>}
                {dueToday > 0 &&
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                    <span className="status-dot" style={{ background: 'var(--memox-primary)', width: 6, height: 6 }} />
                    {t.n(dueToday)} {t('due today', 'đến hạn hôm nay')}
                  </span>}
              </div>
              {overdue > 0 &&
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
                  {t(`Oldest card has been due for ${e.overdueDays || 3} days.`, `Thẻ cũ nhất đã quá hạn ${e.overdueDays || 3} ngày.`)}
                </div>}

              {eight ?
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-text-secondary)', marginTop: 2 }}>
                    {t('Study mode', 'Chế độ học')}
                  </div>
                  {D.reviewModes.map((m, i) =>
                    <OptionRow key={m.mode} selected={i === 0} disabled={m.capacity === 0} icon={MODE[m.mode].icon}
                      title={modeLabel(m.mode, t)}
                      sub={m.capacity === 0
                        ? t(UNAVAILABLE[m.reason].en, UNAVAILABLE[m.reason].vi)
                        : m.capacity < due ? t(`${m.capacity} of the due cards can take this mode`, `${m.capacity} thẻ đến hạn dùng được chế độ này`) : undefined}
                      right={m.capacity > 0 ? t(`${m.capacity} cards`, `${m.capacity} thẻ`) : t('Unavailable', 'Không dùng được')} />)}
                </div> :
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-text-secondary)', marginTop: 2 }}>
                    {t('Question direction', 'Chiều câu hỏi')}
                  </div>
                  {DIRECTIONS.map((dir, i) =>
                    <OptionRow key={dir.id} selected={i === 0} title={t(dir.en, dir.vi)} sub={t(dir.sen, dir.svi)} />)}
                  <Note icon="lock">{t('The direction stays the same for the whole session. Self-assess is the only way this deck asks — that is what its SM-2 schedule uses.', 'Chiều câu hỏi giữ nguyên trong cả phiên. Bộ này chỉ hỏi bằng Tự đánh giá — đó là cách lịch SM-2 hoạt động.')}</Note>
                </div>}

              {state === 'refused' &&
                <Note icon="alert-circle" tone="warning">
                  {t('These cards are no longer due — they were reviewed somewhere else. Nothing was started.', 'Các thẻ này không còn đến hạn — chúng đã được ôn ở nơi khác. Chưa có phiên nào được bắt đầu.')}
                </Note>}
              {state === 'startFailed' &&
                <Note icon="alert-circle" tone="danger">
                  {t("The session couldn't be opened. Nothing was written — try again.", 'Không mở được phiên học. Chưa ghi gì cả — hãy thử lại.')}
                </Note>}
              <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14 }} disabled={state === 'refused'}>
                <Ic name="play" size="xs" color="var(--memox-on-primary)" />
                {state === 'startFailed' ? t('Try again', 'Thử lại') : t(`Review ${reviewBatch} cards`, `Ôn ${reviewBatch} thẻ`)}
              </button>
            </> :
            <>
              <div style={{ fontSize: 13, color: 'var(--memox-text-secondary)', lineHeight: 1.5 }}>
                {nothing
                  ? t('Nothing is due right now, and there are no new cards left. This deck is simply resting.', 'Hiện không có thẻ nào đến hạn và cũng không còn thẻ mới. Bộ thẻ đang nghỉ.')
                  : t('Nothing is due right now. Cards come back when their schedule says so — reviewing early is not possible.', 'Hiện không có thẻ nào đến hạn. Thẻ sẽ quay lại theo lịch — không thể ôn sớm.')}
              </div>
              {nothing &&
                <div style={{ fontSize: 12, color: 'var(--memox-text-secondary)', fontVariantNumeric: 'tabular-nums' }}>
                  {t('Next card is due tomorrow, 00:00', 'Thẻ tiếp theo đến hạn 00:00 ngày mai')}
                </div>}
            </>}
        </Block>

        <button className="card" style={{
          width: '100%', padding: 14, display: 'grid', gridTemplateColumns: '1fr 20px', gap: 10, alignItems: 'center',
          textAlign: 'left', border: 'none', cursor: 'pointer'
        }}>
          <span style={{ minWidth: 0 }}>
            <span style={{ display: 'block', fontSize: 14, fontWeight: 700 }}>{t('Study options', 'Tuỳ chọn học')}</span>
            <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 3, lineHeight: 1.45 }}>{optionsLine}</span>
          </span>
          <Ic name="chevron-right" size="sm" color="var(--memox-text-secondary)" />
        </button>
      </ScreenScroll>
    </div>);
}

Object.assign(window, { StudyEntry });
})();
