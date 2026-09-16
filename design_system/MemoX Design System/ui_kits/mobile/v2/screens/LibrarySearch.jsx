/* MemoX v2 · A7 — Library search
   Refined from V1 LibrarySearchScreen. KEPT: the focused in-bar search field,
   the type filter chips with counts, V1's Group (coloured type header · count ·
   See all) wrapping a card list, V1's 26px-tile Row, and the query Highlight.
   REMOVED: the Folders result type (the product has no folders).
   ADDED: which fields are searched, the accent-sensitivity explanation, and the
   paging / failure states. */
(function () {
const { Ic, StatusBar, ScreenScroll, Skeleton, Spinner, ErrorState } = window;
const { useT, Note } = window;

const T_DECK = 'var(--memox-primary)';
const T_CARD = 'var(--memox-mastery)';
const T_TAG = 'var(--memox-streak)';

const Group = ({ title, ic, color, count, more, children }) =>
  <div style={{ marginBottom: 16 }}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, padding: '0 4px 8px' }}>
      <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
        <Ic name={ic} size="xs" color={color} />
        <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase', color }}>{title}</span>
        <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-on-surface-variant)', padding: '0 4px', borderRadius: 999, background: 'var(--memox-surface-container)', fontVariantNumeric: 'tabular-nums' }}>{count}</span>
      </div>
      {more &&
        <button style={{ background: 'transparent', border: 'none', padding: 0, color: 'var(--memox-primary)', fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          {more}<Ic name="chevron-right" size="xs" color="var(--memox-primary)" />
        </button>}
    </div>
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>{children}</div>
  </div>;

const Highlight = ({ text, q }) => {
  if (!q) return <>{text}</>;
  const i = text.toLowerCase().indexOf(q.toLowerCase());
  if (i < 0) return <>{text}</>;
  return (
    <>
      {text.slice(0, i)}
      <mark style={{ background: 'color-mix(in srgb, var(--memox-primary) 18%, transparent)', color: 'var(--memox-primary)', padding: '0 2px', borderRadius: 4, fontWeight: 700 }}>{text.slice(i, i + q.length)}</mark>
      {text.slice(i + q.length)}
    </>);
};

const Row = ({ ic, color, title, sub, trailing, last }) =>
  <div role="button" tabIndex={0} style={{ display: 'grid', gridTemplateColumns: '30px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: last ? 'none' : 'var(--memox-border-ghost)', cursor: 'pointer' }}>
    <div style={{ width: 26, height: 26, borderRadius: 8, background: `color-mix(in srgb, ${color} 12%, transparent)`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Ic name={ic} size="xs" color={color} />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{title}</div>
      {sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{sub}</div>}
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>{trailing}</div>
  </div>;

const DECK_HITS = [
  { name: 'Học qua phim', path: 'Tiếng Anh giao tiếp hằng ngày', holdsCards: true },
  { name: 'Từ vựng học thuật', path: 'IELTS Academic Word List', holdsCards: false }
];
const CARD_HITS = [
  { front: 'homework', back: 'bài tập về nhà', path: 'Học qua phim' },
  { front: '학생', back: 'học sinh', path: 'Danh từ chỉ người · 사람' },
  { front: '공부하다', back: 'học, học tập', path: 'Động từ · 동사' },
  { front: '대학교', back: 'trường đại học', path: 'Nơi chốn · 장소' }
];
const TAG_HITS = [{ name: 'Học', cards: 42 }, { name: 'ghi chú học tập', cards: 6 }];

function LibrarySearch({ state = 'results' }) {
  const t = useT();
  const empty = state === 'initial';
  const noRes = state === 'noResults';
  const query = empty ? '' : noRes ? 'hoc' : 'học';
  const loading = state === 'searching' || state === 'debouncing';

  let body;
  if (empty) body =
    <div style={{ paddingTop: 4 }}>
      <Note icon="search">
        {t('Search looks at deck names, the front and the back of cards, and tag names. Example sentences, hints and pronunciation are not searched.', 'Tìm kiếm xét tên bộ thẻ, mặt trước và mặt sau của thẻ, và tên nhãn. Câu ví dụ, gợi ý và phát âm không được tìm.')}
      </Note>
      <Note icon="languages" style={{ marginTop: 10 }}>
        {t('Capitalisation does not matter. Accents do — “hoc” will not find “học”.', 'Không phân biệt chữ hoa thường. Nhưng có phân biệt dấu — “hoc” sẽ không tìm ra “học”.')}
      </Note>
    </div>;
  else if (loading) body =
    <>
      {state === 'searching' &&
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '0 4px 12px', fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
          <Spinner />{t('Searching…', 'Đang tìm…')}
        </div>}
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {[0, 1, 2, 3].map((i, _, a) =>
          <div key={i} style={{ display: 'grid', gridTemplateColumns: '30px 1fr', gap: 12, padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
            <Skeleton w={26} h={26} r={8} op={0.45} />
            <div><Skeleton w={`${45 + i * 9}%`} h={12} op={0.5} /><Skeleton w="62%" h={9} op={0.35} style={{ marginTop: 6 }} /></div>
          </div>)}
      </div>
    </>;
  else if (noRes) body =
    <div className="card" style={{ padding: '32px 24px', textAlign: 'center' }}>
      <div style={{ width: 52, height: 52, borderRadius: 16, background: 'var(--memox-surface-container)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
        <Ic name="search-x" size="md" color="var(--memox-on-surface-variant)" />
      </div>
      <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>{t('Nothing matches “hoc”', 'Không có gì khớp “hoc”')}</div>
      <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 16 }}>
        {t('Search keeps accents, so “hoc” and “học” are different words. Try typing the accented form.', 'Tìm kiếm có phân biệt dấu, nên “hoc” và “học” là hai từ khác nhau. Hãy thử nhập có dấu.')}
      </div>
      <button className="pill-btn primary" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
        {t('Search “học” instead', 'Tìm “học”')}
      </button>
    </div>;
  else if (state === 'searchFailed') body =
    <ErrorState title={t('The search failed', 'Tìm kiếm thất bại')}
      body={t('Nothing was changed. Try the same query again.', 'Không có gì thay đổi. Hãy thử lại cùng từ khoá.')}
      action={<button className="pill-btn primary"><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />{t('Retry', 'Thử lại')}</button>} />;
  else body =
    <>
      <Group title={t('Decks', 'Bộ thẻ')} ic="layers" color={T_DECK} count={DECK_HITS.length}>
        {DECK_HITS.map((d, i, a) =>
          <Row key={d.name} ic={d.holdsCards ? 'layers' : 'folder-tree'} color={T_DECK}
            title={<Highlight text={d.name} q={query} />} sub={d.path} last={i === a.length - 1}
            trailing={<Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />} />)}
      </Group>

      <Group title={t('Cards', 'Thẻ')} ic="copy" color={T_CARD} count={t('4 of 9', '4/9')} more={t('See all', 'Xem tất cả')}>
        {CARD_HITS.map((c, i, a) =>
          <Row key={c.front} ic="copy" color={T_CARD}
            title={<Highlight text={c.front} q={query} />}
            sub={<><Highlight text={c.back} q={query} /> · {c.path}</>} last={i === a.length - 1}
            trailing={<Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />} />)}
      </Group>

      <Group title={t('Tags', 'Nhãn')} ic="tag" color={T_TAG} count={TAG_HITS.length}>
        {TAG_HITS.map((g, i, a) =>
          <Row key={g.name} ic="tag" color={T_TAG} title={<Highlight text={g.name} q={query} />}
            sub={t(`on ${g.cards} cards`, `trên ${g.cards} thẻ`)} last={i === a.length - 1}
            trailing={<Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />} />)}
      </Group>

      {state === 'loadingMore' ?
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: '4px 0 16px', fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
          <Spinner />{t('Loading more…', 'Đang tải thêm…')}
        </div> :
        state === 'loadMoreFailed' ?
          <>
            <Note icon="alert-circle" tone="danger">{t("Couldn't load more results. The ones above are still valid.", 'Không tải thêm được kết quả. Những kết quả ở trên vẫn đúng.')}</Note>
            <button className="pill-btn outline" style={{ width: '100%', marginTop: 10 }}>{t('Retry', 'Thử lại')}</button>
          </> : null}

      <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 0 12px', lineHeight: 1.5 }}>
        {t('Opening a card here shows it read-only — searching never counts as studying.', 'Mở một thẻ ở đây sẽ ở chế độ chỉ đọc — tìm kiếm không tính là học.')}
      </div>
    </>;

  return (
    <div className="app">
      <StatusBar />

      {/* V1's focused search app bar. */}
      <div className="appbar" style={{ justifyContent: 'flex-start', gap: 8 }}>
        <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="md" /></button>
        <div role="search" style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8, height: 38, padding: '0 12px', background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-primary)', borderRadius: 'var(--memox-radius-md)' }}>
          <Ic name="search" size="xs" color="var(--memox-primary)" />
          <span style={{ flex: 1, minWidth: 0, fontSize: 14, color: empty ? 'var(--memox-on-surface-variant)' : 'var(--memox-on-surface)', fontWeight: empty ? 500 : 600, display: 'inline-flex', alignItems: 'center', whiteSpace: 'nowrap', overflow: 'hidden' }}>
            {empty ? t('Search decks, cards, tags', 'Tìm bộ thẻ, thẻ, nhãn') : query}
            <span style={{ display: 'inline-block', width: 2, height: 16, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite', marginLeft: empty ? 4 : 2 }} />
          </span>
          {!empty &&
            <button className="icon-btn" style={{ width: 24, height: 24 }} aria-label={t('Clear', 'Xoá')}>
              <Ic name="x-circle" size="xs" color="var(--memox-on-surface-variant)" />
            </button>}
        </div>
      </div>

      {/* Type filter chips — decks, cards, tags: the three things search covers. */}
      {!empty && state !== 'searchFailed' &&
        <div style={{ padding: '0 16px 8px' }}>
          <div className="scroll-x" style={{ display: 'flex', gap: 4 }}>
            {[
              { label: t('All', 'Tất cả'), active: true, count: noRes ? 0 : 13 },
              { label: t('Decks', 'Bộ thẻ'), ic: 'layers', count: noRes ? 0 : 2, c: T_DECK },
              { label: t('Cards', 'Thẻ'), ic: 'copy', count: noRes ? 0 : 9, c: T_CARD },
              { label: t('Tags', 'Nhãn'), ic: 'tag', count: noRes ? 0 : 2, c: T_TAG }
            ].map((f) =>
              <button key={f.label} style={{
                height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, whiteSpace: 'nowrap',
                background: f.active ? 'var(--memox-primary)' : 'var(--memox-surface-container-lowest)',
                color: f.active ? 'var(--memox-on-primary)' : 'var(--memox-on-surface)',
                border: f.active ? 'none' : 'var(--memox-border-ghost)',
                display: 'inline-flex', alignItems: 'center', gap: 4, fontFamily: 'inherit', fontWeight: 600, flexShrink: 0, cursor: 'pointer'
              }}>
                {f.ic && !f.active && <Ic name={f.ic} size="xs" color={f.c} />}
                {f.label}
                <span style={{ fontSize: 12, fontWeight: 700, opacity: f.active ? 0.75 : 0.6, fontVariantNumeric: 'tabular-nums' }}>{f.count}</span>
              </button>)}
          </div>
        </div>}

      <ScreenScroll>{body}</ScreenScroll>
    </div>);
}

Object.assign(window, { LibrarySearch });
})();
