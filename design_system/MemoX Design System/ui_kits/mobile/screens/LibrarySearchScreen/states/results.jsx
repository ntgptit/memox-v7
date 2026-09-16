/* LibrarySearch · state: results
   Grouped results across folders / decks / flashcards / tags. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibrarySearch = R.LibrarySearch || {});

D.results = function (ctx) {
  const { query, Ic, Group, Highlight, Row, T_FOLDER, T_DECK, T_CARD, T_TAG } = ctx;
  return (
    <>
      <div style={{ padding: '2px 4px 8px' }}>
        <span className="ov" style={{ fontVariantNumeric: 'tabular-nums' }}>18 results for "{query}"</span>
      </div>

      <Group title="Folders" ic="folder" color={T_FOLDER} count={1}>
        <Row ic="folder" color={T_FOLDER}
          title={<Highlight text="Korean 연구 — TOPIK roots" q={query} />}
          sub="4 subfolders · 286 cards"
          trailing={<Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />} last />
      </Group>

      <Group title="Decks" ic="layers" color={T_DECK} count={2}>
        <Row ic="layers" color={T_DECK}
          title={<Highlight text="연구 vocabulary" q={query} />}
          sub="62 cards · Korean / TOPIK II"
          trailing={
            <span style={{
              height: 18, padding: '0 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)',
              color: 'var(--memox-primary)', fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', display: 'inline-flex', alignItems: 'center'
            }}>8 due</span>
          } />
        <Row ic="layers" color={T_DECK}
          title={<Highlight text="Academic 연구 terms" q={query} />}
          sub="34 cards · Korean / Advanced"
          trailing={<Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />} last />
      </Group>

      <Group title="Flashcards" ic="copy" color={T_CARD} count={12} more>
        {[
          { front: '연구자', back: 'researcher / nhà nghiên cứu' },
          { front: '연구하다', back: 'to research, to study' },
          { front: '연구실', back: 'lab, research room' }
        ].map((c, i, a) =>
          <Row key={c.front} ic="copy" color={T_CARD}
            title={<Highlight text={c.front} q={query} />}
            sub={c.back}
            trailing={<Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />}
            last={i === a.length - 1} />
        )}
      </Group>

      <Group title="Tags" ic="tag" color={T_TAG} count={3}>
        {[
          { name: 'research', count: 24 },
          { name: 'researcher', count: 8 },
          { name: 'research-lab', count: 5 }
        ].map((t, i, a) =>
          <Row key={t.name} ic="tag" color={T_TAG}
            title={<Highlight text={t.name} q={query} />}
            sub={`${t.count} cards across all decks`}
            trailing={<Ic name="arrow-up-right" size="xs" color="var(--memox-on-surface-variant)" />}
            last={i === a.length - 1} />
        )}
      </Group>

      <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 0 12px' }}>
        Showing top results · matches are case-insensitive
      </div>
    </>);
};
})();
