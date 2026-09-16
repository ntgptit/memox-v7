/* AudioSpeech · state: empty — no voices installed for the selected language. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AudioSpeech = R.AudioSpeech || {});
D.empty = function () { return { lang: 'ko', loading: false, empty: true, engineErr: false, playing: false, showSaved: false }; };
})();
