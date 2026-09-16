/* FlashcardCreate · state: emptyForm — blank, Save disabled. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardCreate = R.FlashcardCreate || {});
D.emptyForm = function () {
  return { empty: true, valid: false, showDetails: false, validationErr: false, saving: false, saveFailed: false, front: '', back: '' };
};
})();
