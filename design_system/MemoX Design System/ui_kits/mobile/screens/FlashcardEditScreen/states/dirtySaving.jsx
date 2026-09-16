/* FlashcardEdit · state: dirtySaving — save in progress. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardEdit = R.FlashcardEdit || {});
D.dirtySaving = function () { return { loading: false, loadError: false, validationErr: false, saving: true, saveFailed: false, delConfirm: false }; };
})();
