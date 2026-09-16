/* StudyHome · state: loaded — decks with workload and a session from today to resume. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyHome = R.StudyHome || {});
D.loaded = (ctx) => <>{ctx.ContinueStudying()}{ctx.Workload()}{ctx.DeckList()}</>;
})();
