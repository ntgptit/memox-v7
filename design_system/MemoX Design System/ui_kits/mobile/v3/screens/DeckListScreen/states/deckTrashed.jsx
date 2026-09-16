/* DeckDetail · state: trashed — just after moving a sub-deck to Trash: list updates live, snackbar offers Undo (BR-263). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.deckTrashed = function (ctx) {
  const { Snackbar, DeckRow, children } = ctx;
  const body = <>{children.filter((d) => d.n !== 'Danh từ · 명사').map((d) => <DeckRow key={d.n} d={d} />)}</>;
  return { body, overlay: <Snackbar action="Undo">“Danh từ · 명사” moved to Trash · 4 sub-decks, 800 cards</Snackbar> };
};
})();
