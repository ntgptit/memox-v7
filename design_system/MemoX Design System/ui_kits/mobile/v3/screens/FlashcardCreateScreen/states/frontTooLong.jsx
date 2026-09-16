/* FlashcardCreate · state: frontTooLong — the term runs past 60 characters (validation belongs to the field). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardCreate = R.FlashcardCreate || {});
D.frontTooLong = () => ({ frontTooLong: true, front: '-(으)ㄹ 뿐만 아니라: không những … mà còn … (ngữ pháp trung cấp, bài 12)', back: 'Nối hai mệnh đề, nhấn mạnh rằng ngoài điều thứ nhất còn có thêm điều thứ hai.' });
})();
