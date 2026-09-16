/* LearningSettings · state: permDenied — reminder requested but OS permission denied. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LearningSettings = R.LearningSettings || {});
D.permDenied = function () { return { goalEnabled: true, reminderOn: true, permDenied: true, showSaved: false }; };
})();
