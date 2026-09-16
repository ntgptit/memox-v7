/* Settings · state: loading — subtitles render as skeletons. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Settings = R.Settings || {});
D.loading = function (ctx) {
  const { Skel } = ctx;
  return { loading: true, account: { icon: 'user-circle', iconBg: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', iconColor: 'var(--memox-primary)', label: 'Account & sync', subtitle: <Skel w={160} />, chip: null } };
};
})();
