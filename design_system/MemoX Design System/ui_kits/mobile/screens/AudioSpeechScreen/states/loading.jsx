/* AudioSpeech · state: loading — voice list spinner for the selected language. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AudioSpeech = R.AudioSpeech || {});
D.loading = function () { return { lang: 'ko', loading: true, empty: false, engineErr: false, playing: false, showSaved: false }; };
})();
