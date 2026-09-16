/* FlashcardEdit · state: saveFailed — save failed banner above the save bar. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardEdit = R.FlashcardEdit || {});
D.saveFailed = function () { return { loading: false, loadError: false, validationErr: false, saving: false, saveFailed: true, delConfirm: false }; };
})();
