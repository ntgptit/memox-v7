/* FlashcardEdit · state: loaded — normal pre-filled edit form. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardEdit = R.FlashcardEdit || {});
D.loaded = function () { return { loading: false, loadError: false, validationErr: false, saving: false, saveFailed: false, delConfirm: false }; };
})();
