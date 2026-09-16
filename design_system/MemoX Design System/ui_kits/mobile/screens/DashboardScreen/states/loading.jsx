/* Dashboard · state: loading
   Section-level skeletons while today's summary resolves. App-bar greeting
   also renders as a skeleton (handled by the shell when state === 'loading'). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Dashboard = R.Dashboard || {});

D.loading = function (ctx) {
  return ctx.LoadingBody();
};
})();
