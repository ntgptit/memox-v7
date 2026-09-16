/* FlashcardCreate · state: valid — both required fields filled, Save enabled. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardCreate = R.FlashcardCreate || {});
D.valid = function () {
  return { empty: false, valid: true, showDetails: false, validationErr: false, saving: false, saveFailed: false, front: '연구자', back: 'Researcher / Nhà nghiên cứu' };
};
})();
