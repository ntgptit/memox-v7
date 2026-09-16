/* LibraryOverview · state: trashed — a deck was just moved to Trash; the list updates live and a snackbar offers Undo (BR-256, BR-263). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.rootTrashed = function (ctx) {
  const { Snackbar, decks, DeckCard } = ctx;
  const body = <>{decks.filter((d) => d.name !== 'IT').map((f) => <DeckCard key={f.name} f={f} />)}</>;
  const overlay = <Snackbar aboveNav action="Undo">“IT” moved to Trash · 1 sub-deck, 5 cards</Snackbar>;
  return { body, overlay };
};
})();
