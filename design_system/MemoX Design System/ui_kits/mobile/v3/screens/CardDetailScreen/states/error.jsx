/* CardDetail · state: error — read failed, retryable (v1). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.CardDetail = R.CardDetail || {});
D.error = () => {
  const { ErrorState } = window;
  return <ErrorState title="Couldn't load this card" body="Your data is safe on this device. Try again in a moment." />;
};
})();
