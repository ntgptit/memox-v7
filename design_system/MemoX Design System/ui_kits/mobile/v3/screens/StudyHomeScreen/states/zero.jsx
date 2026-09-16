/* StudyHome · state: zero — decks with cards but zero workload everywhere — normal, neither error nor achievement (BR-202). Replaces v1 goalOff / streakBroken. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyHome = R.StudyHome || {});
D.zero = (ctx) => <>{ctx.Workload({ zero: true })}{ctx.DeckList({ zero: true })}</>;
})();
