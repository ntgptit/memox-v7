/* DeckImport · state: emptySheet — spreadsheet whose first sheet is empty (SAMPLE_DATA). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.emptySheet = () => ({ kind: 'flow', fileChosen: true, fileProblem: { title: 'The first sheet is empty', body: 'Only the first sheet of a workbook is read. Move your rows there, or export that sheet as CSV.', file: 'workbook.xlsx · sheet 1 of 3' } });
})();
