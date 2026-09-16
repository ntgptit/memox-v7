/* FlashcardCreate · state: deckRejects — the target deck now holds sub-decks (or is a root) and cannot receive a card — a refusal, not a validation error (A9). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardCreate = R.FlashcardCreate || {});
D.deckRejects = () => ({ deckRejects: true, front: '공부하다', back: 'học, học tập' });
})();
