/* FlashcardCreate · state: saving — save in progress (app-bar + CTA spinner). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardCreate = R.FlashcardCreate || {});
D.saving = function () {
  return { empty: false, valid: true, showDetails: false, validationErr: false, saving: true, saveFailed: false, front: '연구자', back: 'Researcher / Nhà nghiên cứu' };
};
})();
