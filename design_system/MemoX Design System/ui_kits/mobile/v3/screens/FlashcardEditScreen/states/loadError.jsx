/* FlashcardEdit · state: loadError — couldn't load the card (full-screen layout). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardEdit = R.FlashcardEdit || {});
D.loadError = function () { return { loading: false, loadError: true, validationErr: false, saving: false, saveFailed: false, delConfirm: false }; };
})();
