/* AudioSpeech · state: engineErr — TTS engine unavailable; controls disabled. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AudioSpeech = R.AudioSpeech || {});
D.engineErr = function () { return { lang: 'ko', loading: false, empty: false, engineErr: true, playing: false, showSaved: false }; };
})();
