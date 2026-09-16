/* TagManagement · state: tagGone — the tag was deleted meanwhile (not found) — the list has already updated; a toast explains. ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});
D.tagGone = function (ctx) {
  const { Ic, tags, TagRow } = ctx;
  const { Snackbar } = window;
  const body = (
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
      {tags.filter((t) => t.name !== 'tạm').map((t, i, a) => <TagRow key={t.name} tag={t} last={i === a.length - 1} />)}
    </div>);
  return { body, toast: <Snackbar>“tạm” no longer exists — it was removed a moment ago.</Snackbar> };
};
})();
