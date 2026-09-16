/* StudyHome · state: noResume — same workload, no open session today. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyHome = R.StudyHome || {});
D.noResume = (ctx) => <>{ctx.Workload()}{ctx.DeckList()}</>;
})();
