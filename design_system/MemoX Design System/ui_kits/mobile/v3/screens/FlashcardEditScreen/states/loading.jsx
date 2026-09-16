/* FlashcardEdit · state: loading — skeleton fields while the card fetches. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardEdit = R.FlashcardEdit || {});
D.loading = function () { return { loading: true, loadError: false, validationErr: false, saving: false, saveFailed: false, delConfirm: false }; };
})();
