# -*- coding: utf-8 -*-
"""Build the screen gallery: one HTML page of every demo golden.

**What it is for.** `test/demo/` renders the real screens on a real device
size and commits the result; those PNGs are the only picture the project has
of itself. Opening 110 files one at a time is not review, so this collects
them into a page a person can scan: light and dark of the same screen behind
one toggle, click to enlarge, arrows to walk the set.

**One surface only: 393 × 852 dp.** Every row is the same phone, so a
difference between two cards is a difference in the app rather than in the
frame it was shot at. A 320dp or 412dp render is worth having — it is where
layout breaks — but it belongs in the test that measures it, not here: side by
side with the others it reads as a screen that got narrower, and the header's
one `393×852` stamp becomes a lie for part of the page. `_check_surface`
enforces this, so a row whose golden was shot elsewhere fails the build instead
of quietly widening the set.

**It reads the committed goldens; it does not render.** So run
`flutter test --tags golden` first if the code has moved — a gallery built
from stale PNGs is worse than none, because it looks current.

    python .claude/skills/flutter-testing/scripts/build_screen_gallery.py

Writes `build/screen_gallery.html` (gitignored — 7MB of embedded PNGs has no
business in git). Pass a path as the first argument to write elsewhere.

Needs Pillow for the resize: `python -m pip install Pillow`.
"""
import base64
import io
import os
import subprocess
import sys

from PIL import Image

# .claude/skills/flutter-testing/scripts/ -> the repo root.
ROOT = os.path.abspath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), *[os.pardir] * 4)
)
G = os.path.join(ROOT, 'test', 'demo', 'goldens')
OUT = (
    os.path.abspath(sys.argv[1])
    if len(sys.argv) > 1
    else os.path.join(ROOT, 'build', 'screen_gallery.html')
)


def _stamp():
    """What the reader is looking at, so a stale tab is recognisable."""
    try:
        return subprocess.check_output(
            ['git', 'log', '-1', '--format=%h · %s'],
            cwd=ROOT,
            text=True,
            encoding='utf-8',
        ).strip()
    except Exception:
        return 'unknown revision'


SCREENS = [
    ('Library & Deck', 'deck_list_root', 'Deck list — root', 'Hero hôm nay, chip workload, path một target'),
    ('Library & Deck', 'deck_list_level', 'Deck list — trong deck', 'Cấp con: breadcrumb, sub-decks, chip trên tile'),
    ('Library & Deck', 'deck_list_empty', 'Deck list — rỗng', 'Hai lối vào: starter catalog / deck mới'),
    ('Library & Deck', 'deck_list_new_only', 'Deck chỉ có thẻ mới', 'BR-150: Study vẫn mở'),
    # Deck's overlays. They are surfaces, not screens, and they had no picture
    # at all until #346 — which is how eleven of them, including both
    # destructive actions, went unreviewed while the same list screen was
    # scored four times.
    ('Deck — overlay', 'deck_actions_root', 'Deck actions — root', 'Rename, study mode, reset, delete'),
    ('Deck — overlay', 'deck_actions_child', 'Deck actions — sub-deck', 'Chỉ sub-deck mới có Move (BR-06)'),
    ('Deck — overlay', 'deck_library_menu', 'Library menu', 'Tag catalog, Trash, lọc due-only'),
    ('Deck — overlay', 'deck_sort_sheet', 'Sort sheet', 'Các thứ tự một danh sách có thể nhận'),
    ('Deck — overlay', 'deck_create_root', 'New deck', 'Tên + chọn scheduler, khoá sau review đầu'),
    ('Deck — overlay', 'deck_create_child_kind', 'Thêm gì vào deck unset', 'BR-61/62: cả sub-deck lẫn card'),
    ('Deck — overlay', 'deck_rename_form', 'Rename', 'Cùng form, tên đã điền sẵn'),
    ('Deck — overlay', 'deck_move_picker', 'Move picker', 'Mục bị chặn nêu lý do (BR-69/70)'),
    ('Deck — overlay', 'deck_ancestors', 'Breadcrumb — Go to', 'Chỉ mở bằng long press'),
    ('Deck — overlay', 'deck_delete_confirm', 'Delete — confirm', 'Nút xuống 2 dòng: C1, MxButtonPair'),
    ('Deck — overlay', 'deck_delete_empty', 'Delete — deck rỗng', 'Câu mở đầu bằng chữ thường (O1)'),
    ('Deck — overlay', 'deck_delete_confirm_vi', 'Delete — tiếng Việt', 'Cùng nút vỡ ở ngôn ngữ dài hơn'),
    ('Deck — overlay', 'deck_reset_progress', 'Reset learning progress', 'Hai heading liền nhau (O3)'),
    ('Deck — overlay', 'deck_scheduler_change', 'Change study mode', '"Study mode" xuất hiện hai lần (O4)'),
    ('Deck — overlay', 'deck_starter_library', 'Starter library', 'UC-01; in mã locale thô (O5)'),
    ('Card', 'card_list', 'Card list', 'Toolbar lọc + pill trạng thái'),
    ('Card', 'card_list_search_empty', 'Card list — search rỗng', 'Term giữ nguyên, pill vẫn tới được (M99.93)'),
    ('Card', 'card_list_filter_empty', 'Card list — pill rỗng', 'D3: pill khác All vẫn đó, không action'),
    # M99.63: bốn PopupMenuButton tồn tại và không cái nào từng có ảnh —
    # menu vẽ cùng giấy với card nó mở đè lên, nổi 0.00 L*, và mọi assertion
    # về nó vẫn xanh. Hai mode vì độ nổi được dựng khác nhau ở mỗi mode.
    ('Card', 'card_overflow_menu', 'Overflow menu', 'Import / Export / Manage tags, mở đè lên list'),
    ('Card', 'card_editor_edit', 'Card editor', 'Sửa nội dung, tag, cờ; danger zone'),
    ('Card', 'card_detail', 'Card detail', 'Ba bề mặt: hero, panel lịch, timeline (M99.60)'),
    ('Card', 'card_detail_sm2', 'Card detail — sm2', 'Ba vắng mặt: divider, chip cờ, accent'),
    ('Card', 'card_detail_long_content', 'Card detail — nội dung dài', 'Hero giữ được một đoạn văn'),
    ('Card', 'card_detail_load_more', 'Card detail — Load more', 'Đuôi trên mép band + ranh generation'),
    ('Card', 'card_detail_history_loading', 'Card detail — đang tải lịch sử', 'Mặt duy nhất chưa ai từng nhìn'),
    ('Card', 'card_detail_no_history', 'Card detail — chưa có lịch sử', 'Timeline card giữ hình cả khi rỗng'),
    ('Card', 'card_detail_not_found', 'Card detail — thẻ đã bị xoá', 'delete_outline, không phải search_off'),
    ('Card', 'card_detail_page_error', 'Card detail — lỗi trang sau', 'Band D24: giữ những gì đã đọc, kèm Retry'),
    # The compact and large-text frames. They are the widths G8 and the state
    # `Wrap` are actually governed at, and they were reachable only by opening a
    # PNG — so the one part of this screen that changes shape was the one part
    # the review page never showed.
    ('Card', 'card_detail_loading_more', 'Card detail — trang kế đang tới', 'G6: nút đổi thành spinner tại chỗ'),
    ('Card', 'card_detail_loading', 'Card detail — đang tải thẻ', 'W3 mặt 1: chưa có gì để sửa'),
    ('Card', 'card_detail_read_error', 'Card detail — không đọc được thẻ', 'W3 mặt 7: app bar bỏ Edit'),
    ('Card', 'card_import_source', 'Import — nguồn', 'Bước 1 của wizard'),
    ('Card', 'card_import_parsing', 'Import — đang phân tích', 'Phase chưa từng có ảnh: panel giữ chỗ'),
    ('Card', 'card_import_preview', 'Import — preview', 'Bước 2: hàng lỗi được khoanh'),
    ('Card', 'card_import_submitting', 'Import — đang ghi', 'Panel submit thế chỗ confirm, cùng rect'),
    ('Card', 'card_import_result_complete', 'Import — kết quả', 'Bước 3: đếm đủ, không lệch'),
    ('Card', 'card_export_sheet', 'Export sheet', 'Ba format, share qua OS'),
    ('Card', 'card_bulk_delete_dialog', 'Bulk delete — confirm', 'Variant cautious: vào Trash 30 ngày'),
    ('Card', 'card_move_picker', 'Move picker', 'Chỉ deck hợp lệ được chào'),
    ('Tag', 'tag_catalog', 'Tag catalog', 'Nhãn toàn thư viện tại /tags'),
    ('Tag', 'tag_filter_sheet', 'Tag filter', 'Lọc OR nhiều nhãn (BR-231)'),
    ('Tag', 'tag_rename_merge', 'Tag rename/gộp', 'Đổi tên trùng = gộp, nói trước'),
    ('Study', 'study_home', 'Study Home', 'Resume + workload thật (UC-14)'),
    ('Study', 'study_browse', 'Browse', 'Giai đoạn đọc của learning'),
    ('Study', 'study_match', 'Match', 'Ghép cặp'),
    ('Study', 'study_guess', 'Guess', 'Chọn nghĩa'),
    ('Study', 'study_recall', 'Recall', 'Đếm ngược + tự chấm'),
    ('Study', 'study_fill', 'Fill', 'Gõ đáp án'),
    ('Progress', 'progress_overview', 'Progress — tổng quan', 'Streak, 7 ngày, tổng đời (UC-12)'),
    ('Progress', 'progress_deck', 'Progress — theo deck', 'Card-day, Learning/Reviewing (UC-13)'),
    ('Settings & Reminder', 'settings', 'Settings', 'Mặc định học, theme, ngôn ngữ (UC-16)'),
    ('Settings & Reminder', 'reminder_settings', 'Daily reminder', 'Opt-in, giờ địa phương (UC-17)'),
    ('Search', 'library_search', 'Global search', 'Deck + thẻ + nhãn, keyset (UC-20)'),
    ('Trash', 'trash', 'Trash', 'Soft delete, 30 ngày, restore/purge (UC-21)'),
]



# The one surface the gallery shows, in device pixels. `test/demo/` renders at
# DPR 3, so 393 × 852 dp lands here; see the module docstring for why the set is
# not allowed to mix.
SURFACE = (1179, 2556)
DPR = 3


def _check_surface(path, im):
    if (im.width, im.height) == SURFACE:
        return
    raise SystemExit(
        '{}: {}×{} px = {}×{} dp, but the gallery shows one surface only '
        '({}×{} dp). Either render this screen at the gallery surface, or drop '
        'its row from SCREENS and leave the golden to the test that needs that '
        'width.'.format(
            os.path.basename(path), im.width, im.height,
            round(im.width / DPR), round(im.height / DPR),
            SURFACE[0] // DPR, SURFACE[1] // DPR))


def encode(path, width=560):
    """A screen at review width, embedded — the page has to open offline."""
    im = Image.open(path)
    _check_surface(path, im)
    if im.width > width:
        im = im.resize((width, round(im.height * width / im.width)),
                       Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, format='PNG', optimize=True)

    return 'data:image/png;base64,' + base64.b64encode(buf.getvalue()).decode()


cards, total, dark_count = [], 0, 0
groups = {}
for group, base, name, note in SCREENS:
    light_p = os.path.join(G, base + '_light.png')
    if not os.path.exists(light_p):
        light_p = os.path.join(G, base + '.png')  # card_editor_edit
    dark_p = os.path.join(G, base + '_dark.png')
    light = encode(light_p)
    dark = encode(dark_p) if os.path.exists(dark_p) else None
    if dark:
        dark_count += 1
    total += 1
    dark_attr = (' data-dark="%s"' % dark) if dark else ''
    tag = '' if dark else '<span class="chip">light only</span>'
    card = (
        '<figure class="shot" tabindex="0" data-name="{name}"{dark}>'
        '<figcaption><strong>{name}</strong>{tag}<span>{note}</span></figcaption>'
        '<div class="frame"><img loading="lazy" src="{light}" alt="{name}"></div>'
        '</figure>'
    ).format(name=name, dark=dark_attr, light=light, tag=tag, note=note)
    groups.setdefault(group, []).append(card)

sections = []
for group, items in groups.items():
    sections.append(
        '<section><h2><span class="eyebrow">{g}</span>'
        '<span class="count">{n}</span></h2>'
        '<div class="grid">{cards}</div></section>'.format(
            g=group, n=len(items), cards=''.join(items)))

# The tab title counts the same list the header does. It used to carry a
# literal 29 while the manifest had grown to 44 — the one number the owner
# sees without opening the page, and the only one nothing regenerated.
# #364 reached the same fix independently; this comment is why it was made.
html = """<title>MemoX — __TOTAL__ màn hình</title>
<style>
:root{
  --ground:#F6F6F9; --surface:#FFFFFF; --ink:#1B1B22; --muted:#5D5D6E;
  --accent:#4F5BD5; --line:#E3E3EC; --frame:#23232B; --chip:#EEEEF6;
}
:root:not([data-theme="light"]){}
@media (prefers-color-scheme: dark){
  :root:not([data-theme="light"]){
    --ground:#131318; --surface:#1D1D25; --ink:#ECECF3; --muted:#9C9CAF;
    --accent:#8B95F2; --line:#2A2A36; --frame:#000000; --chip:#26262F;
  }
}
:root[data-theme="dark"]{
  --ground:#131318; --surface:#1D1D25; --ink:#ECECF3; --muted:#9C9CAF;
  --accent:#8B95F2; --line:#2A2A36; --frame:#000000; --chip:#26262F;
}
*{box-sizing:border-box}
body{background:var(--ground); color:var(--ink);
  font:16px/1.5 "Segoe UI",Roboto,system-ui,sans-serif; margin:0;
  padding:0 0 4rem}
header{position:sticky; top:0; z-index:5; background:var(--ground);
  border-bottom:1px solid var(--line); padding:.45rem 1rem;
  display:flex; align-items:center; gap:.8rem; flex-wrap:nowrap;
  transition:transform .22s ease}
header.hidden{transform:translateY(-100%)}
@media (prefers-reduced-motion: reduce){
  header{transition:none}
}
header h1{font-size:.95rem; font-weight:700; letter-spacing:-.01em;
  margin:0; white-space:nowrap; overflow:hidden; text-overflow:ellipsis}
header p{margin:0; color:var(--muted); font-size:.78rem;
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis}
@media (max-width:640px){ header p{display:none} }
.spacer{flex:1; min-width:0}
.toggle{display:flex; border:1px solid var(--line); border-radius:999px;
  overflow:hidden; flex:none}
.toggle button{border:0; background:transparent; color:var(--muted);
  font:inherit; font-size:.8rem; padding:.25rem .75rem; cursor:pointer}
.toggle button[aria-pressed="true"]{background:var(--accent); color:#fff}
.toggle button:focus-visible{outline:2px solid var(--accent);
  outline-offset:-2px}
main{max-width:1240px; margin:0 auto; padding:0 1.4rem}
section h2{display:flex; align-items:baseline; gap:.6rem;
  margin:2.2rem 0 1rem}
.eyebrow{font-size:.78rem; font-weight:700; letter-spacing:.14em;
  text-transform:uppercase; color:var(--accent)}
.count{font-size:.78rem; color:var(--muted);
  font-variant-numeric:tabular-nums}
.grid{display:grid; gap:1.1rem;
  grid-template-columns:repeat(auto-fill,minmax(200px,1fr))}
.shot{margin:0; cursor:zoom-in; border-radius:14px}
.shot:focus-visible{outline:2px solid var(--accent); outline-offset:3px}
.frame{background:var(--frame); border-radius:18px; padding:7px;
  box-shadow:0 6px 22px rgba(20,20,40,.16)}
.frame img{display:block; width:100%; height:auto; border-radius:12px;
  background:#fff}
/* Above the screen it names: a caption under a phone-shaped image reads as
   part of the next card down, because the gap to the image above it is the
   frame's shadow and the gap below is only the grid's. */
figcaption{padding:0 .15rem .5rem; font-size:.83rem; color:var(--muted)}
figcaption strong{display:inline; color:var(--ink); font-size:.88rem;
  margin-right:.4rem}
figcaption span{display:block; margin-top:.05rem}
.chip{display:inline-block; background:var(--chip); color:var(--muted);
  border-radius:999px; padding:.05rem .5rem; font-size:.7rem;
  vertical-align:middle}
dialog{border:0; border-radius:16px; padding:0; background:var(--surface);
  color:var(--ink); max-width:min(92vw,460px);
  box-shadow:0 24px 80px rgba(0,0,0,.45)}
dialog::backdrop{background:rgba(10,10,16,.72)}
dialog img{display:block; width:100%; height:auto;
  border-radius:0 0 16px 16px}
dialog .bar{display:flex; align-items:center; gap:.8rem;
  padding:.7rem 1rem}
dialog .bar strong{font-size:.95rem}
dialog .bar span{color:var(--muted); font-size:.8rem}
dialog .bar button{margin-left:auto; border:1px solid var(--line);
  background:transparent; color:var(--ink); border-radius:8px;
  font:inherit; font-size:.85rem; padding:.3rem .8rem; cursor:pointer}
@media (prefers-reduced-motion: no-preference){
  .shot{transition:transform .18s ease}
  .shot:hover{transform:translateY(-3px)}
}
</style>
<header id="hdr">
  <h1>MemoX · __TOTAL__ màn</h1>
  <div class="spacer"><p>golden suite @ __STAMP__ · __SURFACE__</p></div>
  <div class="toggle" role="group" aria-label="Chế độ render">
    <button id="btnLight" aria-pressed="true">Light</button>
    <button id="btnDark" aria-pressed="false">Dark</button>
  </div>
</header>
<main>__SECTIONS__</main>
<dialog id="box">
  <div class="bar"><strong id="boxName"></strong>
    <span>&larr; &rarr; chuyển màn</span>
    <button id="boxClose">Đóng</button></div>
  <img id="boxImg" alt="">
</dialog>
<script>
(function(){
  var dark = false;
  var shots = Array.prototype.slice.call(document.querySelectorAll('.shot'));
  function srcFor(shot){
    return (dark && shot.dataset.dark) ? shot.dataset.dark
      : shot.querySelector('img').dataset.light;
  }
  shots.forEach(function(s){
    var img = s.querySelector('img');
    img.dataset.light = img.src;
  });
  function apply(){
    shots.forEach(function(s){ s.querySelector('img').src = srcFor(s); });
    document.getElementById('btnLight').setAttribute('aria-pressed', String(!dark));
    document.getElementById('btnDark').setAttribute('aria-pressed', String(dark));
  }
  document.getElementById('btnLight').onclick = function(){ dark=false; apply(); };
  document.getElementById('btnDark').onclick = function(){ dark=true; apply(); };

  var box = document.getElementById('box'), cur = -1;
  function show(i){
    cur = (i + shots.length) % shots.length;
    var s = shots[cur];
    document.getElementById('boxImg').src = srcFor(s);
    document.getElementById('boxImg').alt = s.dataset.name;
    document.getElementById('boxName').textContent = s.dataset.name;
    if(!box.open) box.showModal();
  }
  shots.forEach(function(s, i){
    s.addEventListener('click', function(){ show(i); });
    s.addEventListener('keydown', function(e){
      if(e.key === 'Enter' || e.key === ' '){ e.preventDefault(); show(i); }
    });
  });
  document.getElementById('boxClose').onclick = function(){ box.close(); };
  box.addEventListener('click', function(e){ if(e.target === box) box.close(); });
  document.addEventListener('keydown', function(e){
    if(!box.open) return;
    if(e.key === 'ArrowRight') show(cur+1);
    if(e.key === 'ArrowLeft') show(cur-1);
  });

  // The header gets out of the way while reviewing: hidden on scroll down,
  // back on the first scroll up.
  var hdr = document.getElementById('hdr'), lastY = 0;
  window.addEventListener('scroll', function(){
    var y = window.scrollY;
    if(y > lastY + 6 && y > 60) hdr.classList.add('hidden');
    else if(y < lastY - 6) hdr.classList.remove('hidden');
    lastY = y;
  }, {passive:true});
})();
</script>
"""
html = html.replace('__SECTIONS__', ''.join(sections))
html = html.replace('__TOTAL__', str(total))
html = html.replace('__STAMP__', _stamp())
html = html.replace(
    '__SURFACE__', '%d×%d' % (SURFACE[0] // DPR, SURFACE[1] // DPR)
)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
io.open(OUT, 'w', encoding='utf-8').write(html)
print('screens:', total, '| with dark:', dark_count,
      '| size: %.1f MB' % (os.path.getsize(OUT) / 1048576))
print('wrote', OUT)
