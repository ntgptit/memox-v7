/* AudioSpeech · state: loaded — Korean voices loaded, default selection. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AudioSpeech = R.AudioSpeech || {});
D.loaded = function () { return { lang: 'ko', loading: false, empty: false, engineErr: false, playing: false, showSaved: false }; };
})();
