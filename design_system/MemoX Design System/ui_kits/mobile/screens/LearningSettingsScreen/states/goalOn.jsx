/* LearningSettings · state: goalOn — goal on, reminder off. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LearningSettings = R.LearningSettings || {});
D.goalOn = function () { return { goalEnabled: true, reminderOn: false, permDenied: false, showSaved: false }; };
})();
