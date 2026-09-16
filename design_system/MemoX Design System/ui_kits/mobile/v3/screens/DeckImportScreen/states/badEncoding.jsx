/* DeckImport · state: badEncoding — file saved as UTF-16 — refused with guidance (BR-173, SAMPLE_DATA ParseCardTransfer). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.badEncoding = () => ({ kind: 'flow', fileChosen: true, fileProblem: { title: 'This file is not UTF-8', body: 'Save it again as UTF-8 (CSV UTF-8 in Excel or Sheets) and choose it once more. Nothing was read.', file: 'tu-vung.csv · UTF-16' } });
})();
