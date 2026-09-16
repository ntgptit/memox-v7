/* MemoX v2 · A10 — Card detail and review history
   Refined from V1 FlashcardHistoryScreen. KEPT: the card preview, the
   current-progress card, and V1's vertical timeline — dot marker, event card,
   uppercase kind badge, relative + absolute time pair, one-line note, and the
   meta row carrying the box move and the mode. REMOVED: recall rate, answer
   duration, the audio-added event kind (no audio, no timings in the product).
   ADDED: the learning-cycle headers, so events recorded under an earlier
   schedule keep the values they were written with. Read-only: opening a card is
   not studying. */
(function () {
const { Ic, StatusBar, ScreenScroll, Skeleton, Spinner, ErrorState, Breadcrumb } = window;
const { useT, Note, modeLabel, schedLabel } = window;
const D = window.MemoXData;

const KINDS = {
  remembered: { en: 'Remembered', vi: 'Nhớ được', color: 'var(--memox-mastery)', ic: 'check' },
  forgotten: { en: 'Forgotten', vi: 'Quên', color: 'var(--memox-error)', ic: 'rotate-ccw' },
  again: { en: 'Again', vi: 'Lại', color: 'var(--memox-rating-again)', ic: 'rotate-ccw' },
  hard: { en: 'Hard', vi: 'Khó', color: 'var(--memox-rating-hard)', ic: 'corner-up-right' },
  good: { en: 'Good', vi: 'Tốt', color: 'var(--memox-rating-good)', ic: 'check' },
  easy: { en: 'Easy', vi: 'Dễ', color: 'var(--memox-rating-easy)', ic: 'check' }
};
const SESSION_KIND = {
  learning: { en: 'while learning', vi: 'khi học mới' },
  scheduled: { en: 'in a review', vi: 'khi ôn tập' },
  relearning: { en: 'repeated in session', vi: 'nhắc lại trong phiên' }
};

function BoxMove({ e, color }) {
  const t = useT();
  const b = e.before, a = e.after;
  if (!b && !a) return <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontStyle: 'italic' }}>{t('no schedule change', 'không đổi lịch')}</span>;
  const fmt = (v) => v ? (v.box !== undefined ? `B${v.box}` : `${v.interval}d`) : t('new', 'mới');
  return (
    <span style={{ fontSize: 12, fontWeight: 700, color, fontVariantNumeric: 'tabular-nums', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
      <span style={{ opacity: 0.6, fontWeight: 600 }}>{fmt(b)}</span>
      <Ic name="arrow-right" size="xs" color={color} />
      <span>{fmt(a)}</span>
    </span>);
}

function Event({ e }) {
  const t = useT();
  const k = KINDS[e.action] || KINDS.remembered;
  return (
    <div style={{ position: 'relative', marginBottom: 12 }}>
      <span style={{ position: 'absolute', left: -19, top: 8, width: 14, height: 14, borderRadius: 999, background: 'var(--memox-surface)', border: `3px solid ${k.color}`, boxSizing: 'border-box' }} />
      <div style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 12, padding: '12px 16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, marginBottom: 8 }}>
          <span style={{ height: 22, padding: '0 8px', borderRadius: 999, background: `color-mix(in srgb, ${k.color} 12%, transparent)`, color: k.color, fontSize: 12, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase', display: 'inline-flex', alignItems: 'center', gap: 4, flexShrink: 0 }}>
            <Ic name={k.ic} size="xs" color={k.color} />{t(k.en, k.vi)}
          </span>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', textAlign: 'right' }}>
            <div style={{ fontWeight: 600, color: 'var(--memox-on-surface)' }}>{e.rel}</div>
            <div style={{ fontSize: 12, opacity: 0.7, marginTop: 1 }}>{e.at.slice(0, 16)}</div>
          </div>
        </div>
        <div style={{ fontSize: 14, lineHeight: 1.45, marginBottom: 8 }}>
          {t(`${modeLabel(e.mode, t)} · ${SESSION_KIND[e.kind].en}`, `${modeLabel(e.mode, t)} · ${SESSION_KIND[e.kind].vi}`)}
        </div>
        <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '4px 8px', fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
          <BoxMove e={e} color={k.color} />
          {e.nextDue &&
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontVariantNumeric: 'tabular-nums' }}>
              <Ic name="calendar-clock" size="xs" color="var(--memox-on-surface-variant)" />
              {t('next', 'kế tiếp')} {e.nextDue.slice(0, 10)}
            </span>}
          {e.timeout &&
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <Ic name="timer" size="xs" color="var(--memox-on-surface-variant)" />{t('ran out of time', 'hết thời gian')}
            </span>}
          {e.hintUsed &&
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <Ic name="lightbulb" size="xs" color="var(--memox-on-surface-variant)" />{t('hint used', 'đã dùng gợi ý')}
            </span>}
        </div>
      </div>
    </div>);
}

const REL = ['2h ago', '2h ago', '2 days ago', '2 days ago', '7 months ago', '7 months ago'];

function CycleHeader({ current, sched }) {
  const t = useT();
  return (
    <div className="ov" style={{ padding: '4px 4px 8px', display: 'flex', alignItems: 'center', gap: 6 }}>
      <Ic name={current ? 'play' : 'rotate-ccw'} size="xs" color="var(--memox-on-surface-variant)" />
      {current
        ? t(`Since the last reset · ${schedLabel(sched, t)}`, `Từ lần đặt lại gần nhất · ${schedLabel(sched, t)}`)
        : t(`Before the reset · ${schedLabel(sched, t)}`, `Trước khi đặt lại · ${schedLabel(sched, t)}`)}
    </div>);
}

function CardDetail({ state = 'loaded' }) {
  const t = useT();
  const c = D.cardDetail;
  const loading = state === 'loading';
  const noHistory = state === 'noHistory';
  const events = (noHistory ? [] : D.history).map((e, i) => ({ ...e, rel: REL[i] || '' }));
  const gen2 = events.filter((e) => e.gen === 2);
  const gen1 = events.filter((e) => e.gen === 1);

  if (state === 'notFound') return (
    <div className="app">
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn"><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>{t('Card', 'Thẻ')}</div>
      </div>
      <ScreenScroll>
        <ErrorState icon="file-question" title={t('This card is gone', 'Thẻ này không còn')}
          body={t('It was moved to Trash elsewhere in the app. Its history goes with it and comes back if you restore it.', 'Thẻ đã được chuyển vào Thùng rác ở nơi khác. Lịch sử đi theo thẻ và sẽ trở lại nếu bạn phục hồi.')}
          action={<button className="pill-btn primary">{t('Back to the deck', 'Về bộ thẻ')}</button>} />
      </ScreenScroll>
    </div>);

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>{t('Card', 'Thẻ')}</div>
        <button className="pill-btn primary" style={{ height: 32, padding: '0 16px', borderRadius: 8, fontSize: 12, gap: 4 }}>
          <Ic name="pencil" size="xs" color="var(--memox-on-primary)" />{t('Edit', 'Sửa')}
        </button>
      </div>
      <Breadcrumb segments={[{ label: t('Library', 'Thư viện') }, { label: '한국어 TOPIK I · Từ vựng' }, { label: 'Động từ · 동사' }]} />

      <ScreenScroll>
        {/* Card preview */}
        <div className="card" style={{ padding: 16, marginBottom: 16, background: 'var(--memox-surface-container-lowest)' }}>
          {loading ?
            <><Skeleton w={110} h={24} /><div style={{ height: 8 }} /><Skeleton w="80%" h={13} op={0.4} /></> :
            <>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
                <div style={{ flex: 1, minWidth: 0, fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px', lineHeight: 1.25, wordBreak: 'break-word' }}>{c.front}</div>
                {c.flagged &&
                  <span style={{ flexShrink: 0, display: 'inline-flex', alignItems: 'center', gap: 4, height: 22, padding: '0 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)', color: 'var(--memox-streak)', fontSize: 12, fontWeight: 700 }}>
                    <Ic name="flag" size="xs" color="var(--memox-streak)" />{t('Flagged', 'Gắn cờ')}
                  </span>}
              </div>
              <div style={{ fontSize: 16, fontWeight: 500, lineHeight: 1.45, marginTop: 8, wordBreak: 'break-word' }}>{c.back}</div>
              {[
                { ic: 'type', v: c.pron }, { ic: 'message-square', v: c.example }, { ic: 'lightbulb', v: c.hint }
              ].filter((r) => r.v).map((r) =>
                <div key={r.ic} style={{ display: 'flex', gap: 6, alignItems: 'flex-start', marginTop: 8, fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>
                  <span style={{ flexShrink: 0, marginTop: 2 }}><Ic name={r.ic} size="xs" color="var(--memox-on-surface-variant)" /></span>
                  <span style={{ minWidth: 0 }}>{r.v}</span>
                </div>)}
              {c.tags && c.tags.length ?
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginTop: 12 }}>
                  {c.tags.map((g) =>
                    <span key={g} style={{ height: 26, padding: '0 8px', display: 'inline-flex', alignItems: 'center', gap: 4, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', borderRadius: 999, fontSize: 12, fontWeight: 600 }}>
                      <Ic name="tag" size="xs" color="var(--memox-primary)" />{g}
                    </span>)}
                </div> : null}
            </>}
        </div>

        {/* Current progress */}
        <div className="ov" style={{ padding: '0 4px 8px' }}>{t('Current progress', 'Tiến trình hiện tại')}</div>
        <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
          {[
            { ic: 'box', label: t('Box', 'Hộp'), value: t(`${c.box} of 8 · 2-day interval`, `${c.box}/8 · nhịp 2 ngày`) },
            { ic: 'calendar-clock', label: t('Due', 'Đến hạn'), value: c.dueAt },
            { ic: 'check-circle-2', label: t('Finished learning', 'Học xong'), value: c.learnedAt },
            { ic: 'history', label: t('Answers', 'Số lần trả lời'), value: t(`${c.answers} · ${c.lapses} forgotten after learning`, `${c.answers} · ${c.lapses} lần quên sau khi học`) }
          ].map((r, i, a) =>
            <div key={r.label} style={{ display: 'grid', gridTemplateColumns: '32px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'var(--memox-surface-container)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name={r.ic} size="xs" color="var(--memox-on-surface-variant)" />
              </div>
              <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{r.label}</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', textAlign: 'right', maxWidth: 160 }}>{r.value}</div>
            </div>)}
        </div>

        {/* Timeline */}
        <div className="ov" style={{ padding: '0 4px 8px' }}>{t('Review history', 'Lịch sử học')}</div>
        {loading ?
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {[0, 1, 2].map((i) =>
              <div key={i} style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 12, padding: '12px 16px' }}>
                <Skeleton w={90} h={18} r={999} op={0.4} /><div style={{ height: 8 }} /><Skeleton w="65%" h={12} />
              </div>)}
          </div> :
          noHistory ?
            <Note icon="history">
              {t('Nothing yet. This card has not been answered — history starts with its first study session.', 'Chưa có gì. Thẻ này chưa được trả lời — lịch sử bắt đầu từ phiên học đầu tiên.')}
            </Note> :
            <>
              <CycleHeader current sched="eight_box" />
              <div style={{ position: 'relative', paddingLeft: 24 }}>
                <div style={{ position: 'absolute', left: 11, top: 8, bottom: 8, width: 2, background: 'var(--memox-surface-container)', borderRadius: 999 }} />
                {gen2.map((e) => <Event key={e.id} e={e} />)}
              </div>

              {gen1.length ?
                <>
                  <CycleHeader sched="sm2" />
                  <Note icon="rotate-ccw" style={{ marginBottom: 12 }}>
                    {t('Learning progress was reset on 14 Sep 2026 and the review schedule changed from SM-2 to Eight boxes. These events keep the values they were recorded with.', 'Tiến trình học đã được đặt lại ngày 14/09/2026 và lịch ôn đổi từ SM-2 sang Tám hộp. Các mục dưới đây giữ nguyên giá trị lúc được ghi.')}
                  </Note>
                  <div style={{ position: 'relative', paddingLeft: 24 }}>
                    <div style={{ position: 'absolute', left: 11, top: 8, bottom: 8, width: 2, background: 'var(--memox-surface-container)', borderRadius: 999 }} />
                    {gen1.map((e) => <Event key={e.id} e={e} />)}
                    {state === 'allLoaded' &&
                      <div style={{ position: 'relative', marginTop: 4 }}>
                        <span style={{ position: 'absolute', left: -19, top: 4, width: 14, height: 14, borderRadius: 999, background: 'var(--memox-surface-container)', border: '2px solid var(--memox-outline-variant)', boxSizing: 'border-box' }} />
                        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', paddingTop: 4, fontStyle: 'italic' }}>
                          {t('Beginning of history', 'Điểm đầu của lịch sử')}
                        </div>
                      </div>}
                  </div>
                </> : null}

              {state === 'loadingMore' &&
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: '4px 0 12px', fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
                  <Spinner />{t('Loading more…', 'Đang tải thêm…')}
                </div>}
              {state === 'loadMoreFailed' &&
                <>
                  <Note icon="alert-circle" tone="danger">{t("Couldn't load older events. What is shown above is complete and correct.", 'Không tải được các mục cũ hơn. Phần hiển thị ở trên vẫn đầy đủ và chính xác.')}</Note>
                  <button className="pill-btn outline" style={{ width: '100%', marginTop: 10 }}>{t('Retry', 'Thử lại')}</button>
                </>}
              {state === 'loaded' &&
                <button className="pill-btn" style={{ width: '100%', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', color: 'var(--memox-on-surface)', fontWeight: 600 }}>
                  {t('Load 50 older events', 'Tải 50 mục cũ hơn')}
                </button>}
            </>}
        <div style={{ height: 12 }} />
      </ScreenScroll>
    </div>);
}

Object.assign(window, { CardDetail });
})();
