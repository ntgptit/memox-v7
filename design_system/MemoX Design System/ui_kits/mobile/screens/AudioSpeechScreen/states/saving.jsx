/* AudioSpeech · state: saving — transient autosave "Saved" chip in the app bar. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AudioSpeech = R.AudioSpeech || {});
D.saving = function () { return { lang: 'ko', loading: false, empty: false, engineErr: false, playing: false, showSaved: true }; };
})();
