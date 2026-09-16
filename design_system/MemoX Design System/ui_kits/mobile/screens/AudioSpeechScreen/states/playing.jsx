/* AudioSpeech · state: playing — preview audio playing (visualizer + Stop). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AudioSpeech = R.AudioSpeech || {});
D.playing = function () { return { lang: 'ko', loading: false, empty: false, engineErr: false, playing: true, showSaved: false }; };
})();
