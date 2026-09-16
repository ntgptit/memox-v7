/* CardDetail · state: notFound — the card was moved to Trash from another area while open (BR-245). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.CardDetail = R.CardDetail || {});
D.notFound = () => {
  const { EmptyState } = window;
  return <EmptyState icon="search-x" title="This card is no longer here" body="It was moved to Trash while you were away. It can still be restored from Trash, with its history." action={<div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}><button className="pill-btn primary" style={{ fontSize: 14 }}>Back to deck</button><button className="pill-btn outline" style={{ fontSize: 14 }}>Open Trash</button></div>} />;
};
})();
