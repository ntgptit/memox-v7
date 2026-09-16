/* MemoX v2 · A18 — Study session
   One shell, six question formats. The answer is saved before any result is
   shown, and a failed save neither shows a result nor advances (BR-157); the
   card being answered stays on screen while its result shows (BR-158). Only
   `browse` records nothing (BR-111). Wrong cards come back in later rounds
   (BR-115, BR-119). */
(function () {
const { Ic, StatusBar, ScreenScroll, BottomBar, Spinner, StudyTopBar } = window;
const { useT, Note, modeLabel, MODE } = window;

const STAGES = ['browse', 'match', 'guess', 'recall', 'fill'];
const RATINGS = [
  { id: 'again', en: 'Again', vi: 'Lại', c: 'var(--memox-rating-again)' },
  { id: 'hard', en: 'Hard', vi: 'Khó', c: 'var(--memox-rating-hard)' },
  { id: 'good', en: 'Good', vi: 'Tốt', c: 'var(--memox-rating-good)' },
  { id: 'easy', en: 'Easy', vi: 'Dễ', c: 'var(--memox-rating-easy)' }
];
const PAIRS = [
  { term: '기억하다', meaning: 'ghi nhớ' },
  { term: '공부', meaning: 'việc học' },
  { term: '눈치', meaning: 'sự nhạy cảm' },
  { term: '물', meaning: 'nước' },
  { term: '선택하다', meaning: 'lựa chọn' }
];

function Shell({ mode, kind, stage, current, total, round, children, footer, banner }) {
  const t = useT();
  const learning = kind === 'learning';
  return (
    <div className="app">
      <StatusBar />
      <StudyTopBar mode={modeLabel(mode, t)} current={current} total={total} />

      {/* V1's centred context line under the top bar. */}
      <div style={{ padding: '0 16px 10px', marginTop: -4 }}>
        <div className="ov" style={{ textAlign: 'center' }}>
          {learning
            ? t('Động từ · 동사 · learning', 'Động từ · 동사 · học mới')
            : t(`Động từ · 동사 · review${round ? ` · round ${round}` : ''}`, `Động từ · 동사 · ôn tập${round ? ` · vòng ${round}` : ''}`)}
        </div>
      </div>

      {learning &&
        <div className="scroll-x" style={{ display: 'flex', gap: 6, padding: '0 16px 10px' }}>
          {STAGES.map((s, i) => {
            const done = STAGES.indexOf(stage) > i;
            const on = s === stage;
            return (
              <span key={s} style={{
                display: 'inline-flex', alignItems: 'center', gap: 4, height: 24, padding: '0 9px', borderRadius: 999, flexShrink: 0,
                fontSize: 12, fontWeight: 700, whiteSpace: 'nowrap',
                background: on ? 'var(--memox-primary)' : 'var(--memox-surface-container)',
                color: on ? 'var(--memox-on-primary)' : 'var(--memox-on-surface-variant)'
              }}>
                {done ? <Ic name="check" size="xs" color="var(--memox-on-surface-variant)" /> : null}
                {modeLabel(s, t)}
              </span>);
          })}
        </div>}

      {banner ? <div style={{ padding: '0 16px 10px' }}>{banner}</div> : null}
      <ScreenScroll>{children}</ScreenScroll>
      {footer ? <BottomBar>{footer}</BottomBar> : null}
    </div>);
}

/* V1's study card — term above, divider, meaning below, each panel labelled. */
function SplitCard({ overline, term, meaningLabel, meaning, footnote, revealed = true }) {
  const t = useT();
  return (
    <div className="card" style={{ padding: 0, display: 'flex', flexDirection: 'column', minHeight: 300 }}>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '44px 20px 20px', position: 'relative' }}>
        <div className="ov" style={{ position: 'absolute', top: 16, left: 20 }}>{overline}</div>
        <div style={{ fontSize: 32, fontWeight: 700, letterSpacing: '-0.5px', textAlign: 'center', lineHeight: 1.15, wordBreak: 'break-word' }}>{term}</div>
      </div>
      <div style={{ height: 1, background: 'var(--memox-outline-variant)', opacity: 0.5, margin: '0 20px' }} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 10, padding: '44px 20px 20px', position: 'relative' }}>
        <div className="ov" style={{ position: 'absolute', top: 16, left: 20 }}>{meaningLabel}</div>
        {revealed ?
          <>
            <div style={{ fontSize: 20, fontWeight: 600, letterSpacing: '-0.3px', textAlign: 'center', lineHeight: 1.45, wordBreak: 'break-word' }}>{meaning}</div>
            {footnote ? <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center' }}>{footnote}</div> : null}
          </> :
          <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', textAlign: 'center' }}>
            {t('Recall it, then check yourself.', 'Hãy nhứ lại, rồi tự kiểm tra.')}
          </div>}
      </div>
    </div>);
}

function Prompt({ children, small, style }) {
  return (
    <div style={{
      fontSize: small ? 22 : 34, fontWeight: 700, letterSpacing: '-0.6px', lineHeight: 1.2, textAlign: 'center',
      wordBreak: 'break-word', padding: '28px 8px 8px', ...style
    }}>{children}</div>);
}
function Answer({ children }) {
  return <div style={{ fontSize: 17, lineHeight: 1.5, textAlign: 'center', color: 'var(--memox-text-secondary)', padding: '0 8px', wordBreak: 'break-word' }}>{children}</div>;
}
function Tile({ children, tone, selected, style }) {
  const border = tone === 'wrong' ? 'var(--memox-error)' : tone === 'right' ? 'var(--memox-status-mastered)' : selected ? 'var(--memox-primary)' : 'transparent';
  return (
    <button style={{
      width: '100%', minHeight: 52, padding: '10px 12px', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit',
      fontSize: 14, fontWeight: 600, lineHeight: 1.35, textAlign: 'center', cursor: 'pointer', color: 'var(--memox-on-surface)',
      background: tone === 'wrong' ? 'var(--memox-danger-soft)' : tone === 'right' ? 'var(--memox-success-soft)' : selected ? 'var(--memox-primary-soft)' : 'var(--memox-surface-container-low)',
      border: `1.5px solid ${border}`, ...style
    }}>{children}</button>);
}

function StudySession({ state = 'browse' }) {
  const t = useT();

  if (state === 'starting') return (
    <Shell mode="browse" kind="learning" stage="browse" current={0} total={20}>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12, padding: '120px 0' }}>
        <Spinner size="md" />
        <div style={{ fontSize: 13.5, color: 'var(--memox-text-secondary)' }}>{t('Opening the session…', 'Đang mở phiên học…')}</div>
      </div>
    </Shell>);

  if (state === 'invalidated') return (
    <Shell mode="self_assess" kind="reviewing" current={12} total={30}>
      <div className="card" style={{ padding: 20, marginTop: 20, display: 'flex', flexDirection: 'column', gap: 14, textAlign: 'center' }}>
        <span style={{ alignSelf: 'center', width: 48, height: 48, borderRadius: 16, background: 'var(--memox-warning-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Ic name="rotate-ccw" size="md" color="var(--memox-warning)" />
        </span>
        <div style={{ fontSize: 17, fontWeight: 700 }}>{t('This session has ended', 'Phiên học đã kết thúc')}</div>
        <div style={{ fontSize: 13.5, lineHeight: 1.55, color: 'var(--memox-text-secondary)' }}>
          {t("The deck's learning progress was reset while you were studying, so no further answer can be recorded. The 11 answers you already gave were kept.", 'Tiến trình học của bộ thẻ đã được đặt lại trong lúc bạn học, nên không thể ghi thêm câu trả lời. 11 câu bạn đã trả lời vẫn được giữ.')}
        </div>
        <button className="pill-btn primary" style={{ width: '100%' }}>{t('See what was saved', 'Xem phần đã lưu')}</button>
      </div>
    </Shell>);

  /* ── browse: front and back together, nothing recorded ── */
  if (state === 'browse') return (
    <Shell mode="browse" kind="learning" stage="browse" current={4} total={20}
      footer={
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="pill-btn" style={{ flex: '0 0 96px', background: 'var(--memox-surface-container)', color: 'var(--memox-text-primary)' }}>
            <Ic name="chevron-left" size="xs" color="var(--memox-text-primary)" />{t('Back', 'Trước')}
          </button>
          <button className="pill-btn primary" style={{ flex: 1 }}>{t('Next card', 'Thẻ tiếp')}</button>
        </div>}>
      <SplitCard overline={t('Term', 'Từ')} term="기억하다"
        meaningLabel={t('Meaning', 'Nghĩa')} meaning="ghi nhớ, nhớ được"
        footnote="매일 한국어 공부를 합니다." />
      <div style={{ marginTop: 12 }}>
        <Note icon="eye">{t('First look. Nothing is graded or recorded in this stage — read both sides, then move on.', 'Lần xem đầu. Bước này không tính điểm và không ghi lại gì — đọc cả hai mặt rồi đi tiếp.')}</Note>
      </div>
    </Shell>);

  /* ── self_assess ── */
  if (state === 'selfAssessPrompt' || state === 'selfAssessRevealed' || state === 'saving' || state === 'saveFailed') {
    const revealed = state !== 'selfAssessPrompt';
    return (
      <Shell mode="self_assess" kind="reviewing" current={12} total={30}
        banner={state === 'saveFailed'
          ? <Note icon="alert-circle" tone="danger">{t("Your answer couldn't be saved, so it doesn't count yet. The card stays here until it is saved.", 'Không lưu được câu trả lời nên chưa được tính. Thẻ vẫn ở đây cho tới khi lưu xong.')}</Note>
          : null}
        footer={revealed
          ? <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {state === 'saveFailed' &&
                <button className="pill-btn primary" style={{ width: '100%' }}><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />{t('Retry saving “Good”', 'Lưu lại “Tốt”')}</button>}
              <div style={{ display: 'flex', gap: 6 }}>
                {RATINGS.map((r) =>
                  <button key={r.id} className="pill-btn" style={{
                    flex: 1, flexDirection: 'column', gap: 2, height: 56, padding: 0, fontSize: 12.5, fontWeight: 700,
                    background: `color-mix(in srgb, ${r.c} 14%, transparent)`, color: r.c,
                    opacity: state === 'saving' ? 0.6 : 1
                  }}>
                    {state === 'saving' && r.id === 'good' ? <Spinner color={r.c} /> : null}
                    {t(r.en, r.vi)}
                  </button>)}
              </div>
            </div>
          : <button className="pill-btn primary" style={{ width: '100%' }}>{t('Show the meaning', 'Hiện nghĩa')}</button>}>
        <SplitCard overline={t('Term', 'Từ')} term="눈치" revealed={revealed}
          meaningLabel={t('Meaning', 'Nghĩa')}
          meaning="sự nhạy cảm trong giao tiếp — khả năng đọc không khí và cảm xúc của người khác mà không cần ai nói ra"
          footnote="그는 눈치가 빠르다." />
      </Shell>);
  }

  /* ── match ── */
  if (state === 'match' || state === 'matchWrong') {
    const wrong = state === 'matchWrong';
    return (
      <Shell mode="match" kind="reviewing" current={6} total={12} round={wrong ? 2 : 1}
        banner={wrong
          ? <Note icon="alert-circle" tone="warning">{t('눈치 ↔ nước was not a pair. It stays on the board and comes back in the next round.', '눈치 ↔ nước không phải một cặp. Thẻ ở lại bảng và sẽ quay lại vòng sau.')}</Note>
          : null}>
        <div style={{ fontSize: 12.5, color: 'var(--memox-text-secondary)', textAlign: 'center', padding: '4px 0 14px' }}>
          {t('Pair each term with its meaning — start from either side.', 'Ghép mỗi từ với nghĩa của nó — bắt đầu từ bên nào cũng được.')}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {PAIRS.map((p, i) =>
              <Tile key={p.term} selected={wrong && i === 2} tone={wrong && i === 2 ? 'wrong' : i < 2 && !wrong ? 'right' : undefined}>
                {p.term}
              </Tile>)}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {['nước', 'việc học', 'lựa chọn', 'ghi nhớ', 'sự nhạy cảm'].map((m, i) =>
              <Tile key={m} tone={wrong && i === 0 ? 'wrong' : !wrong && i > 2 ? 'right' : undefined}>{m}</Tile>)}
          </div>
        </div>
        <div style={{ textAlign: 'center', fontSize: 11.5, color: 'var(--memox-text-secondary)', paddingTop: 14, fontVariantNumeric: 'tabular-nums' }}>
          {t('5 pairs at a time · 12 cards in this round', 'Mỗi lần 5 cặp · 12 thẻ trong vòng này')}
        </div>
      </Shell>);
  }

  /* ── guess ── */
  if (state === 'guess' || state === 'guessAnswered') {
    const answered = state === 'guessAnswered';
    const options = ['nước', 'sự nhạy cảm trong giao tiếp', 'việc học', 'lựa chọn', 'ghi nhớ'];
    return (
      <Shell mode="guess" kind="reviewing" current={8} total={12} round={1}
        footer={answered ? <button className="pill-btn primary" style={{ width: '100%' }}>{t('Next card', 'Thẻ tiếp')}</button> : null}>
        <Prompt small>눈치</Prompt>
        <div style={{ fontSize: 12.5, color: 'var(--memox-text-secondary)', textAlign: 'center', padding: '4px 0 16px' }}>
          {answered ? t('Only your first choice counts.', 'Chỉ lựa chọn đầu tiên được tính.') : t('Choose the meaning.', 'Chọn nghĩa đúng.')}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {options.map((o, i) =>
            <Tile key={o} tone={answered ? (i === 0 ? 'wrong' : i === 1 ? 'right' : undefined) : undefined}
              style={{ textAlign: 'left', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
              <span>{o}</span>
              {answered && i === 0 ? <Ic name="x" size="sm" color="var(--memox-error)" /> : null}
              {answered && i === 1 ? <Ic name="check" size="sm" color="var(--memox-status-mastered)" /> : null}
            </Tile>)}
        </div>
      </Shell>);
  }

  /* ── recall ── */
  if (state === 'recallCounting' || state === 'recallRevealed' || state === 'recallTimeout') {
    const left = state === 'recallCounting' ? 12 : 0;
    const timeout = state === 'recallTimeout';
    return (
      <Shell mode="recall" kind="reviewing" current={9} total={12} round={1}
        footer={
          state === 'recallRevealed'
            ? <div style={{ display: 'flex', gap: 8 }}>
                <button className="pill-btn" style={{ flex: 1, background: 'color-mix(in srgb, var(--memox-self-missed) 14%, transparent)', color: 'var(--memox-self-missed)', fontWeight: 700 }}>{t('I forgot', 'Tôi quên')}</button>
                <button className="pill-btn" style={{ flex: 1, background: 'color-mix(in srgb, var(--memox-self-gotit) 16%, transparent)', color: 'var(--memox-self-gotit)', fontWeight: 700 }}>{t('I remembered', 'Tôi nhớ được')}</button>
              </div>
            : timeout
              ? <button className="pill-btn primary" style={{ width: '100%' }}>{t('Continue', 'Tiếp tục')}</button>
              : <button className="pill-btn primary" style={{ width: '100%' }}>{t('Show the meaning', 'Hiện nghĩa')}</button>}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, padding: '8px 0 0' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: 12, fontWeight: 700, color: timeout ? 'var(--memox-warning-ink)' : 'var(--memox-text-secondary)', fontVariantNumeric: 'tabular-nums' }}>
            <span>{timeout ? t('Time is up', 'Hết thời gian') : t('Time to recall', 'Thời gian nhớ lại')}</span>
            <span>{left}s / 20s</span>
          </div>
          <div style={{ height: 6, borderRadius: 999, background: 'var(--memox-surface-container)', overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${(left / 20) * 100}%`, background: timeout ? 'var(--memox-warning)' : 'var(--memox-primary)', borderRadius: 999 }} />
          </div>
        </div>
        <SplitCard overline={t('Term', 'Từ')} term="기억하다" revealed={state !== 'recallCounting'}
          meaningLabel={t('Meaning', 'Nghĩa')} meaning="ghi nhớ, nhớ được" />
        {state === 'recallCounting' &&
          <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 12 }}>
            {t('The timer pauses if you leave the app.', 'Bộ đếm tạm dừng nếu bạn rời ứng dụng.')}
          </div>}
        {timeout &&
          <div style={{ marginTop: 12 }}>
            <Note icon="alert-circle" tone="warning">
              {t('Running out of time counts as forgotten. The card comes back in the next round.', 'Hết thời gian được tính là quên. Thẻ sẽ quay lại vòng sau.')}
            </Note>
          </div>}
      </Shell>);
  }

  /* ── fill ── */
  const wrongFill = state === 'fillWrong';
  const hint = state === 'fillHint';
  return (
    <Shell mode="fill" kind="reviewing" current={3} total={3} round={1}
      banner={wrongFill
        ? <Note icon="alert-circle" tone="warning">{t('Not quite. The term is 기억하다 — the card comes back in the next round.', 'Chưa đúng. Từ cần điền là 기억하다 — thẻ sẽ quay lại vòng sau.')}</Note>
        : null}
      footer={
        <div style={{ display: 'flex', gap: 8 }}>
          {!wrongFill &&
            <button className="pill-btn" style={{ flex: '0 0 110px', background: 'var(--memox-surface-container)', color: 'var(--memox-text-primary)', gap: 6 }}>
              <Ic name="lightbulb" size="xs" color="var(--memox-text-primary)" />{hint ? t('Hint shown', 'Đã hiện gợi ý') : t('Hint', 'Gợi ý')}
            </button>}
          <button className="pill-btn primary" style={{ flex: 1 }}>{wrongFill ? t('Next card', 'Thẻ tiếp') : t('Check', 'Kiểm tra')}</button>
        </div>}>
      <div style={{ fontSize: 11.5, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase', color: 'var(--memox-text-secondary)', textAlign: 'center', paddingTop: 6 }}>
        {t('Type the term for this meaning', 'Điền từ ứng với nghĩa này')}
      </div>
      <Prompt small>ghi nhớ, nhớ được</Prompt>
      <div style={{ padding: '14px 0 0' }}>
        <window.TextField value={wrongFill ? '기역하다' : '기'} focused={!wrongFill}
          error={wrongFill ? t('Correct term: 기억하다', 'Từ đúng: 기억하다') : undefined}
          style={{ minHeight: 56, fontSize: 18, justifyContent: 'center', textAlign: 'center' }} />
      </div>
      {hint &&
        <div style={{ marginTop: 14 }}>
          <Note icon="lightbulb">{t('Hint: đọc không khí — using the hint is recorded, but it does not change your result.', 'Gợi ý: đọc không khí — việc dùng gợi ý được ghi lại nhưng không ảnh hưởng kết quả.')}</Note>
        </div>}
      <div style={{ textAlign: 'center', fontSize: 11.5, color: 'var(--memox-text-secondary)', paddingTop: 16, lineHeight: 1.5 }}>
        {t('Capitalisation and outer spaces are ignored. Accents are not.', 'Không phân biệt chữ hoa và khoảng trắng ở hai đầu. Dấu thì có phân biệt.')}
      </div>
    </Shell>);
}

Object.assign(window, { StudySession });
})();
