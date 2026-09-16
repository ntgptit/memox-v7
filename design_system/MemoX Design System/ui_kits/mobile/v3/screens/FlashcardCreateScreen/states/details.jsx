/* FlashcardCreate · state: details — valid form with the optional details section open. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardCreate = R.FlashcardCreate || {});
D.details = function () {
  return { empty: false, valid: true, showDetails: true, validationErr: false, saving: false, saveFailed: false, front: '공부하다', back: 'học, học tập' };
};
})();
