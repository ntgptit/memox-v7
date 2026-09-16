/* FlashcardCreate · state: validationErr — tried to save with empty back; inline error. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardCreate = R.FlashcardCreate || {});
D.validationErr = function () {
  return { empty: false, valid: false, showDetails: false, validationErr: true, saving: false, saveFailed: false, front: '연구자', back: '' };
};
})();
