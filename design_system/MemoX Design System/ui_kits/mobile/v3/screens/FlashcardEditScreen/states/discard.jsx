/* FlashcardEdit · state: discard — leaving with unsaved edits asks for confirmation (A9). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardEdit = R.FlashcardEdit || {});
D.discard = () => ({ discard: true });
})();
