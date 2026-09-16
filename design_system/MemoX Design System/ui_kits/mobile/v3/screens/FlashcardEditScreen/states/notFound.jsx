/* FlashcardEdit · state: notFound — the card was moved to Trash from another area while open (SAMPLE_DATA · UpdateCard "meanwhile deleted"). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardEdit = R.FlashcardEdit || {});
D.notFound = () => ({ notFound: true });
})();
