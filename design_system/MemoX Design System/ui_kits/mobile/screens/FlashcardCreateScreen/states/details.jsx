/* FlashcardCreate · state: details — valid form with the optional details section open. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardCreate = R.FlashcardCreate || {});
D.details = function () {
  return { empty: false, valid: true, showDetails: true, validationErr: false, saving: false, saveFailed: false, front: '연구자', back: 'Researcher / Nhà nghiên cứu' };
};
})();
