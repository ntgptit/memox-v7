/* LibrarySearch · state: results — query "học" (SAMPLE_DATA · search[0]): decks first, then cards; a tag match is named on the card row (BR-252). Load more at the end (hasMore). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibrarySearch = R.LibrarySearch || {});
D.results = function (ctx) {
  const { query, Ic, Group, Highlight, Row, T_DECK, T_CARD, T_TAG } = ctx;
  const cards = [
    { front: 'homework', back: 'bài tập về nhà', path: 'Tiếng Anh giao tiếp hằng ngày › Học qua phim', tag: 'Học' },
    { front: '학생', back: 'học sinh', path: '한국어 TOPIK I · Từ vựng › Danh từ · 명사 › Danh từ chỉ người · 사람' },
    { front: '공부하다', back: 'học, học tập', path: '한국어 TOPIK I · Từ vựng › Động từ · 동사' },
    { front: '대학교', back: 'trường đại học', path: '한국어 TOPIK I · Từ vựng › Danh từ · 명사 › Nơi chốn · 장소' }
  ];
  return (
    <>
      <div style={{ padding: '2px 4px 8px' }}>
        <span className="ov" style={{ fontVariantNumeric: 'tabular-nums' }}>Results for “{query}”</span>
      </div>

      <Group title="Decks" ic="layers" color={T_DECK} count={2}>
        <Row ic="copy" color={T_DECK}
          title={<Highlight text="Học qua phim" q={query} />}
          sub="Tiếng Anh giao tiếp hằng ngày · holds cards"
          trailing={<Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />} />
        <Row ic="layers" color={T_DECK}
          title={<Highlight text="Từ vựng học thuật" q={query} />}
          sub="IELTS Academic Word List · holds sub-decks"
          trailing={<Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />} last />
      </Group>

      <Group title="Cards" ic="copy" color={T_CARD} count="20+">
        {cards.map((c, i, a) =>
          <Row key={c.front} ic="copy" color={T_CARD}
            title={<><Highlight text={c.front} q={query} /><span style={{ color: 'var(--memox-on-surface-variant)', fontWeight: 500 }}> · </span><span style={{ fontWeight: 500 }}><Highlight text={c.back} q={query} /></span></>}
            sub={<>
              {c.tag && <span style={{ display: 'inline-flex', alignItems: 'center', gap: 2, color: T_TAG, fontWeight: 600, marginRight: 6 }}><Ic name="tag" size={12} color={T_TAG} />{c.tag}</span>}
              {c.path}
            </>}
            trailing={<Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />}
            last={i === a.length - 1} />
        )}
      </Group>

      <button className="pill-btn" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', border: 'none', marginBottom: 12 }}>
        Load more results
      </button>
      <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '0 0 12px' }}>
        Decks first, then cards · case-insensitive, accents matter
      </div>
    </>);
};
})();
