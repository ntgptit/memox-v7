/* FlashcardEdit · state: validationErr — tried to save with the meaning empty. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardEdit = R.FlashcardEdit || {});
D.validationErr = function () { return { loading: false, loadError: false, validationErr: true, saving: false, saveFailed: false, delConfirm: false }; };
})();
