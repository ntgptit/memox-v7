/* FlashcardCreate · state: saveFailed — inline retry banner above the save bar. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardCreate = R.FlashcardCreate || {});
D.saveFailed = function () {
  return { empty: false, valid: true, showDetails: false, validationErr: false, saving: false, saveFailed: true, front: '연구자', back: 'Researcher / Nhà nghiên cứu' };
};
})();
