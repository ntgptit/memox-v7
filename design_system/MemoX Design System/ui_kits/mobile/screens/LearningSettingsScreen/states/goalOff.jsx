/* LearningSettings · state: goalOff — goal off, slider locked, streak frozen (not reset). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LearningSettings = R.LearningSettings || {});
D.goalOff = function () { return { goalEnabled: false, reminderOn: false, permDenied: false, showSaved: false }; };
})();
