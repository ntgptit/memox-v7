/* MemoX v2 · A20 + A21 — Progress
   Refined from V1 ProgressScreen. KEPT: the large-title bar, the range
   segmented control, V1's Card(title · value · sub · chart) rhythm, the
   per-chart dashed empty treatment, the streak tile pair, the row list, and
   the read-only footer line. REMOVED: accuracy, box distribution, suspended /
   buried rows and the "All time" range — none exist in the product.
   ADDED: the learning/reviewing split inside V1's bars, and per-deck activity. */
(function () {
const { Ic, StatusBar, ScreenScroll, Skeleton, EmptyState, ErrorState } = window;
const { useT, NavBar } = window;
const D = window.MemoXData;

const Card = ({ title, value, sub, children, right }) =>
  <div className="card" style={{ padding: 16, marginBottom: 12 }}>
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8, marginBottom: 12 }}>
      <div style={{ minWidth: 0 }}>
        <div className="ov">{title}</div>
        {value != null && <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px', lineHeight: 1.1, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{value}</div>}
        {sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4 }}>{sub}</div>}
      </div>
      {right}
    </div>
    {children}
  </div>;

const ChartEmpty = ({ line }) =>
  <div style={{ padding: '24px 16px', textAlign: 'center', background: 'var(--memox-surface-container-lowest)', borderRadius: 'var(--memox-radius-md)', border: '1px dashed var(--memox-outline-variant)', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>{line}</div>;

function DayBars({ days }) {
  const t = useT();
  const max = Math.max(...days.map((d) => d.total), 1);
  return (
    <>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 78, padding: '0 2px' }}>
        {days.map((d, i) => {
          const today = i === days.length - 1;
          const pct = d.total / max;
          return (
            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-end', height: '100%' }}>
              {d.total === 0 ?
                <div style={{ width: '100%', height: 2, borderRadius: 4, background: 'var(--memox-surface-container-high)' }} /> :
                <div style={{ width: '100%', height: `${Math.max(pct * 100, 6)}%`, borderRadius: 4, overflow: 'hidden', display: 'flex', flexDirection: 'column', opacity: today ? 1 : 0.62 }}>
                  <div style={{ flex: d.reviewing, background: 'var(--memox-primary)' }} />
                  <div style={{ flex: d.learning, background: 'var(--memox-status-learning)' }} />
                </div>}
            </div>);
        })}
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 4, padding: '0 2px', fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
        {days.map((d, i) => <span key={i} style={{ flex: 1, textAlign: 'center' }}>{t(d.day[0], d.vi)}</span>)}
      </div>
      <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap', marginTop: 10 }}>
        {[
          { c: 'var(--memox-primary)', en: 'Reviewing', vi: 'Ôn tập' },
          { c: 'var(--memox-status-learning)', en: 'Learning', vi: 'Học mới' }
        ].map((l) =>
          <span key={l.en} style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
            <span className="status-dot" style={{ width: 6, height: 6, background: l.c }} />{t(l.en, l.vi)}
          </span>)}
      </div>
    </>);
}

function Progress({ state = 'loaded' }) {
  const t = useT();
  const p = D.progress;
  const month = state === 'month';
  const deckScope = state === 'deckScope';
  const noActivity = state === 'rangeNoActivity';
  const held = state === 'heldStreak';
  const lost = state === 'lostStreak';
  const never = state === 'never';
  const loading = state === 'loading';

  const days = held || lost || noActivity
    ? p.week.map((d, i) => (i === p.week.length - 1 || noActivity ? { ...d, total: 0, learning: 0, reviewing: 0 } : d))
    : p.week;
  const totalStudied = days.reduce((a, d) => a + d.total, 0);
  const scope = month ? D.deckActivity.scope30 : D.deckActivity.scope7;
  const children = noActivity
    ? D.deckActivity.children7.map((c) => ({ ...c, activeCards: 0, activeDays: 0, learning: 0, reviewing: 0 }))
    : D.deckActivity.children7;
  const rangeLabel = month ? t('last 30 days', '30 ngày qua') : t('last 7 days', '7 ngày qua');

  if (state === 'error') return (
    <div className="app">
      <StatusBar />
      <div className="appbar appbar-lg"><div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>{t('Progress', 'Tiến độ')}</div></div>
      <ScreenScroll>
        <ErrorState title={t("Couldn't summarise your progress", 'Không tổng hợp được tiến độ')}
          body={t('Your study history is safe on this device. Try again in a moment.', 'Lịch sử học của bạn vẫn an toàn trên máy này. Hãy thử lại sau giây lát.')}
          action={<button className="pill-btn primary"><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />{t('Retry', 'Thử lại')}</button>} />
      </ScreenScroll>
      <NavBar active="progress" />
    </div>);

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar appbar-lg" style={{ justifyContent: 'space-between' }}>
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>{t('Progress', 'Tiến độ')}</div>
        <button className="icon-btn" aria-label={t('About these numbers', 'Về các con số này')}>
          <Ic name="help-circle" size="sm" color="var(--memox-on-surface-variant)" />
        </button>
      </div>

      <ScreenScroll>
        <div style={{ display: 'inline-flex', padding: 4, gap: 2, background: 'var(--memox-surface-container)', borderRadius: 'var(--memox-radius-md)', marginBottom: 16 }}>
          {[{ id: 'week', en: '7 days', vi: '7 ngày' }, { id: 'month', en: '30 days', vi: '30 ngày' }].map((r) => {
            const active = (r.id === 'month') === month;
            return (
              <button key={r.id} style={{
                height: 32, padding: '0 16px', borderRadius: 8, border: 'none', fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer',
                background: active ? 'var(--memox-surface-container-lowest)' : 'transparent',
                color: active ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)',
                boxShadow: active ? 'var(--memox-shadow-soft)' : 'none'
              }}>{t(r.en, r.vi)}</button>);
          })}
        </div>

        {loading &&
          <>{[0, 1, 2].map((i) =>
            <div key={i} className="card" style={{ padding: 16, marginBottom: 12 }}>
              <Skeleton w={80} h={9} op={0.4} />
              <div style={{ height: 8 }} />
              <Skeleton w={120} h={20} />
              <div style={{ height: 14 }} />
              <Skeleton w="100%" h={70} r={10} />
            </div>)}</>}

        {never && !loading &&
          <EmptyState icon="trending-up" title={t('Nothing studied yet', 'Chưa học gì')}
            body={t('This is where your recent effort shows up: your streak, today, and the last seven days. Finish one session and it starts filling in.', 'Đây là nơi hiện lại nỗ lực gần đây: chuỗi ngày, hôm nay và bảy ngày vừa qua. Học xong một phiên là bắt đầu có dữ liệu.')}
            action={<button className="pill-btn primary" style={{ fontSize: 14 }}>{t('Go to Study', 'Mở trang Học')}</button>} />}

        {!loading && !never &&
          <>
            <Card title={t('Cards studied', 'Số thẻ đã học')}
              value={noActivity ? null : totalStudied}
              sub={noActivity ? null : t(`over the ${rangeLabel}`, `trong ${rangeLabel}`)}>
              {noActivity
                ? <ChartEmpty line={t('No study sessions in this range yet. Any deck in Study starts the count.', 'Chưa có phiên học nào trong khoảng này. Học bất kỳ bộ nào là bắt đầu tính.')} />
                : <DayBars days={days} />}
            </Card>

            <Card title={t('Streak', 'Chuỗi ngày')}>
              <div style={{ display: 'flex', gap: 8 }}>
                {[
                  { l: t('Current', 'Hiện tại'), v: t(`${lost ? 0 : held ? 4 : p.streak} days`, `${lost ? 0 : held ? 4 : p.streak} ngày`), ic: 'flame', c: lost ? 'var(--memox-on-surface-variant)' : 'var(--memox-streak)' },
                  { l: t('Today', 'Hôm nay'), v: t(`${held || lost ? 0 : p.today.total} cards`, `${held || lost ? 0 : p.today.total} thẻ`), ic: 'calendar-check', c: 'var(--memox-primary)' }
                ].map((s) =>
                  <div key={s.l} style={{ flex: 1, padding: 12, background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 8 }}>
                    <div style={{ width: 32, height: 32, borderRadius: 8, background: `color-mix(in srgb, ${s.c} 12%, transparent)`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <Ic name={s.ic} size="xs" color={s.c} />
                    </div>
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 700 }}>{s.l}</div>
                      <div style={{ fontSize: 14, fontWeight: 700, marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>{s.v}</div>
                    </div>
                  </div>)}
              </div>
              {(held || lost) &&
                <div style={{ marginTop: 10, padding: '8px 12px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', fontSize: 12, lineHeight: 1.5, color: 'var(--memox-on-surface-variant)', display: 'flex', gap: 8 }}>
                  <Ic name="info" size="xs" color="var(--memox-on-surface-variant)" />
                  <span>{held
                    ? t('Nothing studied today yet, so the streak is held from yesterday. One card keeps it going.', 'Hôm nay chưa học gì nên chuỗi ngày vẫn giữ theo hôm qua. Chỉ cần một thẻ là chuỗi tiếp tục.')
                    : t('Neither today nor yesterday had any activity, so the streak is back to zero. Your next session starts a new one.', 'Hôm nay và hôm qua đều không có hoạt động nên chuỗi ngày về 0. Phiên học tới sẽ bắt đầu chuỗi mới.')}</span>
                </div>}
            </Card>

            {/* A21 — by deck, in V1's row-list language. */}
            <Card title={deckScope ? t('Inside 한국어 TOPIK I · Từ vựng', 'Trong 한국어 TOPIK I · Từ vựng') : t('By deck', 'Theo bộ thẻ')}
              value={noActivity ? null : t.n(deckScope ? 82 : scope.activeCards)}
              sub={noActivity ? null : t(`cards studied · ${deckScope ? 5 : scope.activeDays} active days · ${t.n(deckScope ? 24 : scope.learning)} learning · ${t.n(deckScope ? 88 : scope.reviewing)} reviewing`,
                `thẻ đã học · ${deckScope ? 5 : scope.activeDays} ngày có học · ${t.n(deckScope ? 24 : scope.learning)} lượt học mới · ${t.n(deckScope ? 88 : scope.reviewing)} lượt ôn tập`)}>
              {noActivity && <ChartEmpty line={t('No deck was studied in this range. Your decks are still listed below, so you can see which went untouched.', 'Không bộ nào được học trong khoảng này. Các bộ vẫn liệt kê bên dưới để bạn thấy bộ nào chưa học.')} />}
              <div style={{ marginTop: noActivity ? 12 : 0 }}>
                {children.map((c, i, a) =>
                  <div key={c.name} role="button" tabIndex={0} style={{
                    display: 'grid', gridTemplateColumns: '1fr auto auto', gap: 12, alignItems: 'center', padding: '12px 0',
                    borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', cursor: 'pointer', opacity: c.activeCards ? 1 : 0.75
                  }}>
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.name}</div>
                      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1, lineHeight: 1.4, fontVariantNumeric: 'tabular-nums' }}>
                        {c.activeCards
                          ? t(`${c.activeDays} days · ${c.learning} learning · ${c.reviewing} reviewing`, `${c.activeDays} ngày · ${c.learning} học mới · ${c.reviewing} ôn tập`)
                          : t('not studied in this range', 'không học trong khoảng này')}
                      </div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>{t.n(c.activeCards)}</div>
                      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>{t('cards', 'thẻ')}</div>
                    </div>
                    <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
                  </div>)}
              </div>
            </Card>

            <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 0 12px', lineHeight: 1.5 }}>
              {t(`Read-only summary · ${rangeLabel}`, `Bản tổng hợp chỉ đọc · ${rangeLabel}`)}
              <br />
              {t('One card studied on one day counts once. The first look at a new card is not counted.', 'Một thẻ học trong một ngày chỉ tính một lần. Lần xem đầu của thẻ mới không được tính.')}
            </div>
          </>}
      </ScreenScroll>
      <NavBar active="progress" />
    </div>);
}

Object.assign(window, { Progress });
})();
