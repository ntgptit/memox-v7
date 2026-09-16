/* MemoX v2 · A12 — Card export
   A sheet over the card list: scope, format, and exactly what the file will
   contain. The app hands the file to the system and never claims it was saved;
   closing the share sheet is a cancel, not an error (BR-181). */
(function () {
const { Ic, BottomSheet, Spinner } = window;
const { useT, Note, SheetHead, Snackbar } = window;

const FORMATS = [
  { id: 'csv', label: 'CSV', sen: 'Opens in any spreadsheet app', svi: 'Mở được bằng mọi phần mềm bảng tính' },
  { id: 'tsv', label: 'TSV', sen: 'Tab separated', svi: 'Phân cách bằng tab' },
  { id: 'xlsx', label: 'XLSX', sen: 'Excel workbook', svi: 'Sổ tính Excel' }
];

function CardExport({ state = 'choosing' }) {
  const t = useT();
  const selection = ['selection', 'stale'].includes(state);
  const Bg = window.CardList;

  const problem = {
    failed: { ic: 'alert-circle', tone: 'danger', body: t("The file couldn't be created. Nothing left the app — try again.", 'Không tạo được tệp. Không có gì rời khỏi ứng dụng — hãy thử lại.') },
    unavailable: { ic: 'share-2', tone: 'warning', body: t('This device has nowhere to share a file. Export needs a share target — a files app, mail or a cloud app.', 'Máy này không có nơi nào để chia sẻ tệp. Xuất cần một đích chia sẻ — ứng dụng tệp, thư hoặc ứng dụng lưu trữ.') },
    stale: { ic: 'alert-circle', tone: 'warning', body: t('One of the 3 selected cards was deleted or moved somewhere else, so the whole export was refused. Nothing partial was produced — clear the selection and pick again.', 'Một trong 3 thẻ đã chọn bị xoá hoặc chuyển đi nơi khác nên cả lần xuất bị từ chối. Không tạo ra tệp một phần nào — hãy bỏ chọn và chọn lại.') },
    empty: { ic: 'info', tone: 'neutral', body: t('This deck has no cards, so there is nothing to export yet.', 'Bộ này chưa có thẻ nào nên chưa có gì để xuất.') }
  }[state];

  const overlay = ['shared', 'dismissed'].includes(state) ?
    <Snackbar icon={state === 'shared' ? 'share-2' : 'info'}>
      {state === 'shared'
        ? t('“Động từ · 동사 — 2026-09-16.csv” handed to your device to share or save.', 'Đã chuyển “Động từ · 동사 — 2026-09-16.csv” cho máy của bạn để chia sẻ hoặc lưu.')
        : t('Export cancelled. Your selection is still here.', 'Đã huỷ xuất. Lựa chọn của bạn vẫn còn.')}
    </Snackbar> :
    <BottomSheet maxHeight="none">
      <SheetHead title={selection ? t('Export 3 selected cards', 'Xuất 3 thẻ đã chọn') : t('Export all 420 cards', 'Xuất cả 420 thẻ')}
        sub={selection ? t('Động từ · 동사', 'Động từ · 동사') : t('The whole deck, ignoring the current filter and search', 'Toàn bộ bộ thẻ, bỏ qua bộ lọc và tìm kiếm hiện tại')} />
      <div style={{ padding: '0 16px 16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {problem ? <Note icon={problem.ic} tone={problem.tone}>{problem.body}</Note> : null}

        {!problem &&
          <div style={{ display: 'flex', gap: 8 }}>
            {FORMATS.map((f) =>
              <button key={f.id} style={{
                flex: 1, minHeight: 64, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 3,
                padding: 8, borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', color: 'var(--memox-on-surface)',
                background: f.id === 'csv' ? 'var(--memox-primary-soft)' : 'var(--memox-surface-container-low)',
                border: f.id === 'csv' ? '1px solid var(--memox-primary-border)' : '1px solid transparent'
              }}>
                <span style={{ fontSize: 14, fontWeight: 800, letterSpacing: 0.4 }}>{f.label}</span>
                <span style={{ fontSize: 10.5, lineHeight: 1.3, textAlign: 'center', color: 'var(--memox-text-secondary)' }}>{t(f.sen, f.svi)}</span>
              </button>)}
          </div>}

        <div style={{ padding: '12px 14px', borderRadius: 'var(--memox-radius-md)', background: 'var(--memox-surface-container-low)' }}>
          <div style={{ fontSize: 12, fontWeight: 700, marginBottom: 6 }}>{t('The file contains six columns', 'Tệp gồm sáu cột')}</div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 5 }}>
            {['front', 'back', 'example', 'hint', 'pronunciation', 'tags'].map((h) =>
              <span key={h} style={{ height: 22, padding: '0 8px', borderRadius: 6, display: 'inline-flex', alignItems: 'center', background: 'var(--memox-surface-container-high)', fontSize: 11, fontWeight: 600, fontFamily: 'ui-monospace, monospace' }}>{h}</span>)}
          </div>
          <div style={{ fontSize: 11.5, color: 'var(--memox-text-secondary)', marginTop: 8, lineHeight: 1.5 }}>
            {t('Card content only — no schedule, no review history, no flags. This is not a backup of your progress.', 'Chỉ nội dung thẻ — không có lịch ôn, lịch sử học hay cờ. Đây không phải bản sao lưu tiến trình.')}
          </div>
        </div>

        {!['empty', 'stale', 'unavailable'].includes(state) &&
          <button className="pill-btn primary" style={{ width: '100%' }} disabled={state === 'generating'}>
            {state === 'generating' ? <Spinner color="var(--memox-on-primary)" /> : <Ic name="share-2" size="xs" color="var(--memox-on-primary)" />}
            {state === 'generating' ? t('Preparing the file…', 'Đang tạo tệp…') : state === 'failed' ? t('Try again', 'Thử lại') : t('Export and share', 'Xuất và chia sẻ')}
          </button>}
        {!problem &&
          <div style={{ fontSize: 11, color: 'var(--memox-text-secondary)', textAlign: 'center', lineHeight: 1.45 }}>
            {t('MemoX hands the file to your device. Where it ends up is up to the app you pick.', 'MemoX chuyển tệp cho máy của bạn. Tệp nằm ở đâu là do ứng dụng bạn chọn.')}
          </div>}
      </div>
      <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
    </BottomSheet>;

  return (
    <div style={{ position: 'relative', height: '100%', width: '100%' }}>
      <Bg state={selection ? 'selection' : 'loaded'} />
      {overlay}
    </div>);
}

Object.assign(window, { CardExport });
})();
