/* FlashcardCreate · state: tagLimit — ten tags on the card; "Add tag" is withdrawn and the limit is stated (BR-93). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardCreate = R.FlashcardCreate || {});
D.tagLimit = () => ({ valid: true, tagLimit: true, front: '-(으)ㄹ 뿐만 아니라', back: 'không những … mà còn …' });
})();
