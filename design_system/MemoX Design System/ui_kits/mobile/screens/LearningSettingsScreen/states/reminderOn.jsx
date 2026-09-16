/* LearningSettings · state: reminderOn — goal on, daily reminder on (permission granted). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LearningSettings = R.LearningSettings || {});
D.reminderOn = function () { return { goalEnabled: true, reminderOn: true, permDenied: false, showSaved: false }; };
})();
