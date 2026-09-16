/* StudyResult · state: loading
   Skeletons while the session finalizes. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});

D.loading = function (ctx) {
  return ctx.LoadingBody();
};
})();
