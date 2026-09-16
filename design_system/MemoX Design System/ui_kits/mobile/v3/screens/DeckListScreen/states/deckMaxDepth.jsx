/* DeckDetail · state: maxDepth — level 10, the deepest allowed: the breadcrumb collapses and no sub-deck creation is offered (BR-55). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.deckMaxDepth = function (ctx) {
  const { DeckRow, Note } = ctx;
  const deep = [
    { n: 'Nhóm A', type: 'card', cards: 24, due: 3, overdue: 0, fresh: 6, pct: 0.4 },
    { n: 'Nhóm B', type: 'card', cards: 18, due: 0, overdue: 0, fresh: 0, pct: 0.9 },
    { n: 'Nhóm C', type: 'unset', cards: 0, due: 0, overdue: 0, fresh: 0, pct: 0 }
  ];
  const body = (
    <>
      <Note icon="layers" style={{ marginBottom: 12 }}>This is level 10, the deepest a deck can go. Sub-decks here can hold cards but no further sub-decks.</Note>
      {deep.map((d) => <DeckRow key={d.n} d={d} />)}
    </>);
  return { body };
};
})();
