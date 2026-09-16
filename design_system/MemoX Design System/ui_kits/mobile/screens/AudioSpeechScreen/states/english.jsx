/* AudioSpeech · state: english — English tab active (independent from Korean). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AudioSpeech = R.AudioSpeech || {});
D.english = function () { return { lang: 'en', loading: false, empty: false, engineErr: false, playing: false, showSaved: false }; };
})();
