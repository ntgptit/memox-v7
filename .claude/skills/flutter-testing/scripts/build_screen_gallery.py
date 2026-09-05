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
import re
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


def _escape(text):
    return (text.replace('&', '&amp;').replace('<', '&lt;')
            .replace('>', '&gt;').replace('"', '&quot;'))


def _stamp():
    """The commit the sheet was printed from, so a stale tab is recognisable.

    Returned split rather than joined: the sha is set in the mono face and the
    subject is the part allowed to be clipped when the header runs out of room,
    and one pre-joined string cannot be styled in two ways.
    """
    try:
        out = subprocess.check_output(
            ['git', 'log', '-1', '--format=%h\x1f%s'],
            cwd=ROOT,
            text=True,
            encoding='utf-8',
        ).strip()
        sha, _, subject = out.partition('\x1f')

        return sha, subject
    except Exception:
        return 'unknown', 'revision không đọc được'


SCREENS = [
    ('Library & Deck', 'deck_list_root', 'Deck list — root', 'Hero hôm nay, chip workload, path một target'),
    # High contrast: the theme pair had no picture until A20.1 P1-08. The
    # densest border surface and the screen with disabled controls.
    ('Library & Deck', 'deck_list_root_hc', 'Deck list — high contrast', 'Mọi viền, chip và hairline dưới cặp theme HC'),
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
    ('Card', 'card_editor_create', 'Card editor — tạo mới', 'Form rỗng, autofocus mặt trước; khác edit về chrome (SC-C1-02)'),
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
    ('Study', 'study_entry', 'Study entry — vào một deck', 'Đếm new/due, hai lối vào, nút tuỳ chọn (UC-14)'),
    ('Study', 'study_options', 'Study options', 'Giới hạn thẻ, thứ tự thẻ mới; override theo deck (BR-212)'),
    ('Study', 'study_browse', 'Browse', 'Giai đoạn đọc của learning'),
    ('Study', 'study_match', 'Match', 'Ghép cặp'),
    ('Study', 'study_guess', 'Guess', 'Chọn nghĩa'),
    ('Study', 'study_recall', 'Recall', 'Đếm ngược + tự chấm'),
    ('Study', 'study_fill', 'Fill', 'Gõ đáp án'),
    ('Progress', 'progress_overview', 'Progress — tổng quan', 'Streak, 7 ngày, tổng đời (UC-12)'),
    ('Progress', 'progress_deck', 'Progress — theo deck', 'Card-day, Learning/Reviewing (UC-13)'),
    ('Settings & Reminder', 'settings', 'Settings', 'Mặc định học, theme, ngôn ngữ (UC-16)'),
    ('Settings & Reminder', 'settings_save_failed', 'Settings — lưu thất bại',
     'Band lỗi nằm trong card của chính nhóm đó (BR-216)'),
    ('Settings & Reminder', 'reminder_settings', 'Daily reminder', 'Opt-in, giờ địa phương (UC-17)'),
    ('Reminder', 'reminder_settings_hc', 'Reminder — high contrast', 'Hàng giờ và workload inert dưới cặp theme HC'),
    ('Search', 'library_search', 'Global search', 'Deck + thẻ + nhãn, keyset (UC-20)'),
    ('Trash', 'trash', 'Trash', 'Soft delete, 30 ngày, restore/purge (UC-21)'),
    ('App', 'route_not_found', 'Route not found', 'errorBuilder của router — màn duy nhất không thuộc feature nào'),
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
    # The slug line sits *above* the frame it names: a caption under a
    # phone-shaped image reads as belonging to the next card down, because the
    # gap above it is the frame's own edge and the gap below is only the grid's.
    # The frame number is filled in by script, in DOM order, so it is the same
    # address the lightbox's arrow keys use.
    card = (
        '<figure class="shot" tabindex="0" data-name="{name}"{dark}>'
        '<figcaption><span class="slug"><b class="num"></b>'
        '<strong>{name}</strong>{tag}</span><span class="note">{note}</span>'
        '</figcaption>'
        '<div class="frame"><img loading="lazy" src="{light}" alt="{name}"></div>'
        '</figure>'
    ).format(name=_escape(name), dark=dark_attr, light=light, tag=tag,
             note=_escape(note))
    groups.setdefault(group, []).append(card)


def _slug(text):
    """A stable anchor id for a group name, so the rail can link to it."""
    return 'g-' + re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')


sections, rail = [], []
for group, items in groups.items():
    gid = _slug(group)
    label = _escape(group)
    rail.append(
        '<a href="#{id}"><span>{g}</span><b>{n}</b></a>'.format(
            id=gid, g=label, n=len(items)))
    sections.append(
        '<section id="{id}"><h2><span class="eyebrow">{g}</span>'
        '<span class="count">{n} màn</span></h2>'
        '<div class="grid">{cards}</div></section>'.format(
            id=gid, g=label, n=len(items), cards=''.join(items)))

# **The tab title stopped counting** (M100.34). It used to read
# "MemoX — 59 màn hình", and the number had drifted once already — a literal 29
# against a manifest of 44, which is why it was generated in the first place
# (#364 reached the same fix independently). Generating it fixed the drift and
# left a worse problem: the artifact's title is its identity in the owner's
# gallery, and one that changes every time a screen is added is a page that
# looks new each time. The count moved into the header, beside the two numbers
# that qualify it — how many have a dark capture, and at what size.
html = """<meta charset="utf-8">
<title>MemoX Proof Sheet</title>
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap">
<style>
/* A proof sheet's own colours stay out of the way of the frames on it. The
   accent is a darkroom china-marker red — deliberately far from the app's
   indigo, so nothing in the chrome can be mistaken for something in a
   screenshot, and so a screen's own brand colour is the only brand colour on
   the page. */
:root{
  --paper:#EFEFEC; --card:#FFFFFF; --ink:#17171A; --muted:#6E6E73;
  --rule:#D9D9D3; --accent:#B4341F; --bezel:#101014; --chip:#E4E4DE;
  --lift:0 1px 2px rgba(20,18,14,.10), 0 8px 20px rgba(20,18,14,.10);
}
@media (prefers-color-scheme: dark){
  :root:not([data-theme="light"]){
    --paper:#131316; --card:#1B1B1F; --ink:#EDEDE8; --muted:#9A9A9F;
    --rule:#2C2C31; --accent:#E4654C; --bezel:#000000; --chip:#26262B;
    --lift:0 1px 2px rgba(0,0,0,.5), 0 10px 26px rgba(0,0,0,.45);
  }
}
:root[data-theme="dark"]{
  --paper:#131316; --card:#1B1B1F; --ink:#EDEDE8; --muted:#9A9A9F;
  --rule:#2C2C31; --accent:#E4654C; --bezel:#000000; --chip:#26262B;
  --lift:0 1px 2px rgba(0,0,0,.5), 0 10px 26px rgba(0,0,0,.45);
}
*{box-sizing:border-box}
body{background:var(--paper); color:var(--ink); margin:0; padding:0 0 5rem;
  font:400 16px/1.5 Archivo,"Segoe UI",Roboto,system-ui,sans-serif;
  -webkit-font-smoothing:antialiased}
.mono{font-family:"JetBrains Mono",ui-monospace,"Cascadia Mono",Consolas,
  monospace; font-variant-numeric:tabular-nums}

/* ---- edge stamp -------------------------------------------------------- */
header{position:sticky; top:0; z-index:6; background:var(--paper);
  border-bottom:1px solid var(--rule); transition:transform .22s ease}
header.hidden{transform:translateY(-100%)}
@media (prefers-reduced-motion: reduce){ header{transition:none} }
.bar{display:flex; align-items:center; gap:1rem; flex-wrap:nowrap;
  max-width:1320px; margin:0 auto; padding:.55rem 1.4rem}
.mark{display:flex; align-items:baseline; gap:.5rem; flex:none}
.mark b{font-size:1rem; font-weight:700; letter-spacing:-.015em}
.mark span{font-size:.72rem; font-weight:600; letter-spacing:.16em;
  text-transform:uppercase; color:var(--accent)}
.stamp{flex:1; min-width:0; display:flex; align-items:center; gap:.55rem;
  font-size:.74rem; color:var(--muted); white-space:nowrap; overflow:hidden}
.stamp .sha{color:var(--ink); font-weight:500}
.stamp .subj{overflow:hidden; text-overflow:ellipsis; min-width:0}
.stamp i{font-style:normal; opacity:.45}
@media (max-width:820px){ .stamp .subj{display:none} }
@media (max-width:560px){ .stamp{display:none} }

/* The segmented control picks which *capture* is shown, not the page's own
   theme — the label says so, because a bare Light/Dark pair on a page that
   also follows the reader's theme is read as a page toggle every time. */
.pick{display:flex; align-items:center; gap:.5rem; flex:none}
.pick > span{font-size:.74rem; color:var(--muted)}
.seg{display:flex; border:1px solid var(--rule); border-radius:7px;
  overflow:hidden; background:var(--card)}
.seg button{border:0; background:transparent; color:var(--muted); font:inherit;
  font-size:.78rem; font-weight:500; padding:.24rem .8rem; cursor:pointer;
  line-height:1.5}
.seg button + button{border-left:1px solid var(--rule)}
.seg button[aria-pressed="true"]{background:var(--accent); color:#FFF8F4}
.seg button:disabled{opacity:.4; cursor:not-allowed}
.seg button:focus-visible{outline:2px solid var(--accent); outline-offset:-3px}

/* ---- section rail ------------------------------------------------------ */
nav{border-top:1px solid var(--rule); overflow-x:auto;
  scrollbar-width:thin}
nav ol{list-style:none; display:flex; gap:0; margin:0 auto; padding:0 1.4rem;
  max-width:1320px}
nav a{display:flex; align-items:center; gap:.4rem; padding:.4rem .7rem;
  color:var(--muted); text-decoration:none; font-size:.78rem;
  white-space:nowrap; border-bottom:2px solid transparent}
nav a:hover{color:var(--ink)}
nav a b{font-weight:500; font-size:.7rem; color:var(--muted);
  font-family:"JetBrains Mono",ui-monospace,monospace;
  background:var(--chip); border-radius:4px; padding:0 .3rem}
nav a:focus-visible{outline:2px solid var(--accent); outline-offset:-2px}

/* ---- the sheet --------------------------------------------------------- */
main{max-width:1320px; margin:0 auto; padding:0 1.4rem}
section{scroll-margin-top:6.5rem}
section h2{display:flex; align-items:baseline; gap:.7rem; margin:2.6rem 0 1.2rem;
  padding-bottom:.5rem; border-bottom:1px solid var(--rule)}
.eyebrow{font-size:.78rem; font-weight:700; letter-spacing:.15em;
  text-transform:uppercase; color:var(--accent)}
.count{font-size:.74rem; color:var(--muted);
  font-family:"JetBrains Mono",ui-monospace,monospace;
  font-variant-numeric:tabular-nums}
.grid{display:grid; column-gap:1.5rem; row-gap:2.1rem;
  grid-template-columns:repeat(auto-fill,minmax(208px,1fr))}
.shot{margin:0; cursor:zoom-in}
.shot:focus-visible{outline:2px solid var(--accent); outline-offset:4px;
  border-radius:4px}
figcaption{padding:0 .1rem .55rem}
.slug{display:flex; align-items:baseline; gap:.45rem}
.num{font-family:"JetBrains Mono",ui-monospace,monospace; font-size:.72rem;
  font-weight:500; color:var(--accent); font-variant-numeric:tabular-nums;
  flex:none}
.slug strong{font-size:.87rem; font-weight:600; letter-spacing:-.005em;
  color:var(--ink); overflow:hidden; text-overflow:ellipsis;
  white-space:nowrap; min-width:0}
.note{display:block; margin-top:.1rem; padding-left:1.55rem; font-size:.79rem;
  color:var(--muted); line-height:1.35}
.chip{flex:none; background:var(--chip); color:var(--muted); border-radius:4px;
  padding:.05rem .35rem; font-size:.65rem; font-weight:500;
  letter-spacing:.04em; text-transform:uppercase}
/* A printed edge, not a floating mockup: a tight bezel and a crisp seat, so
   fifty-nine of them read as one sheet rather than as fifty-nine stickers. */
.frame{background:var(--bezel); border-radius:15px; padding:5px;
  box-shadow:var(--lift)}
.frame img{display:block; width:100%; height:auto; border-radius:11px;
  background:#FFF}
@media (prefers-reduced-motion: no-preference){
  .shot{transition:transform .16s ease}
  .shot:hover{transform:translateY(-2px)}
}

/* ---- loupe ------------------------------------------------------------- */
dialog{border:0; border-radius:12px; padding:0; background:var(--card);
  color:var(--ink); max-width:min(94vw,980px); width:max-content;
  box-shadow:0 30px 90px rgba(0,0,0,.5)}
dialog::backdrop{background:rgba(12,11,10,.8)}
.loupebar{display:flex; align-items:center; gap:.9rem; padding:.6rem .9rem;
  border-bottom:1px solid var(--rule)}
.loupebar .n{font-family:"JetBrains Mono",ui-monospace,monospace;
  font-size:.75rem; color:var(--accent); font-variant-numeric:tabular-nums}
.loupebar strong{font-size:.92rem; font-weight:600}
.loupebar .keys{color:var(--muted); font-size:.74rem}
@media (max-width:620px){ .loupebar .keys{display:none} }
.loupebar .seg{margin-left:auto}
.loupebar .x{border:1px solid var(--rule); background:transparent;
  color:var(--ink); border-radius:7px; font:inherit; font-size:.8rem;
  padding:.24rem .7rem; cursor:pointer}
.loupebar .x:focus-visible{outline:2px solid var(--accent); outline-offset:1px}
.plates{display:flex; gap:.9rem; padding:.9rem; align-items:flex-start;
  overflow:auto; max-height:78vh}
.plate{flex:0 0 auto; display:flex; flex-direction:column; gap:.4rem}
.plate figcaption{padding:0; font-size:.72rem; color:var(--muted);
  letter-spacing:.1em; text-transform:uppercase; font-weight:600}
.plate img{display:block; width:min(393px,42vw); height:auto;
  border-radius:9px; background:#FFF; border:1px solid var(--rule)}
.plates.solo .plate img{width:min(393px,84vw)}
@media (max-width:620px){
  .plates{flex-direction:column}
  .plate img{width:min(393px,80vw)}
}
</style>
<header id="hdr">
  <div class="bar">
    <div class="mark"><b>MemoX</b><span>Proof sheet</span></div>
    <div class="stamp">
      <span class="mono sha">__SHA__</span><i>·</i>
      <span class="subj">__SUBJ__</span><i>·</i>
      <span class="mono">__TOTAL__ màn</span><i>·</i>
      <span class="mono">__DARKN__ có dark</span><i>·</i>
      <span class="mono">__SURFACE__</span>
    </div>
    <div class="pick">
      <span>Chụp ở</span>
      <div class="seg" role="group" aria-label="Chế độ app trong ảnh chụp">
        <button id="btnLight" aria-pressed="true">Light</button>
        <button id="btnDark" aria-pressed="false">Dark</button>
      </div>
    </div>
  </div>
  <nav aria-label="Nhóm màn hình"><ol>__RAIL__</ol></nav>
</header>
<main>__SECTIONS__</main>
<dialog id="box" aria-label="Xem màn hình">
  <div class="loupebar">
    <span class="n" id="boxNum"></span>
    <strong id="boxName"></strong>
    <span class="keys">&larr; &rarr; chuyển màn · Esc đóng</span>
    <div class="seg" role="group" aria-label="Bản chụp hiển thị">
      <button id="pvLight" aria-pressed="true">Light</button>
      <button id="pvDark" aria-pressed="false">Dark</button>
      <button id="pvBoth" aria-pressed="false">Cả hai</button>
    </div>
    <button class="x" id="boxClose">Đóng</button>
  </div>
  <div class="plates" id="boxPlates"></div>
</dialog>
<script>
(function(){
  var shots = Array.prototype.slice.call(document.querySelectorAll('.shot'));
  shots.forEach(function(s, i){
    var img = s.querySelector('img');
    img.dataset.light = img.src;
    s.querySelector('.num').textContent = String(i + 1).padStart(2, '0');
    s.dataset.index = i;
  });

  /* ---- which capture the sheet shows ---- */
  var dark = false;
  function sheetSrc(s){
    return (dark && s.dataset.dark) ? s.dataset.dark
      : s.querySelector('img').dataset.light;
  }
  function applySheet(){
    shots.forEach(function(s){ s.querySelector('img').src = sheetSrc(s); });
    document.getElementById('btnLight').setAttribute('aria-pressed', String(!dark));
    document.getElementById('btnDark').setAttribute('aria-pressed', String(dark));
  }
  document.getElementById('btnLight').onclick = function(){ dark = false; applySheet(); };
  document.getElementById('btnDark').onclick = function(){ dark = true; applySheet(); };

  /* ---- the loupe ----
     Light, dark and both, because comparing the two is the review this
     project keeps running: a role that resolves differently per brightness
     is invisible in either picture alone. */
  var box = document.getElementById('box');
  var plates = document.getElementById('boxPlates');
  var view = 'light', cur = -1;

  function plate(label, src, name){
    return '<figure class="plate"><figcaption>' + label + '</figcaption>'
      + '<img src="' + src + '" alt="' + name + ' — ' + label + '"></figure>';
  }
  function render(){
    var s = shots[cur];
    var lightSrc = s.querySelector('img').dataset.light;
    var darkSrc = s.dataset.dark || '';
    var name = s.dataset.name;
    var both = view === 'both' && darkSrc;
    var html = '';
    if(view === 'dark' && darkSrc) html = plate('Dark', darkSrc, name);
    else if(both) html = plate('Light', lightSrc, name) + plate('Dark', darkSrc, name);
    else html = plate('Light', lightSrc, name);
    plates.innerHTML = html;
    plates.classList.toggle('solo', !both);
    document.getElementById('boxNum').textContent = String(cur + 1).padStart(2, '0');
    document.getElementById('boxName').textContent = name;
    document.getElementById('pvDark').disabled = !darkSrc;
    document.getElementById('pvBoth').disabled = !darkSrc;
    [['pvLight','light'],['pvDark','dark'],['pvBoth','both']].forEach(function(p){
      document.getElementById(p[0]).setAttribute('aria-pressed', String(view === p[1]));
    });
  }
  function show(i){
    cur = (i + shots.length) % shots.length;
    if(!shots[cur].dataset.dark && view !== 'light') view = 'light';
    render();
    if(!box.open) box.showModal();
  }
  [['pvLight','light'],['pvDark','dark'],['pvBoth','both']].forEach(function(p){
    document.getElementById(p[0]).onclick = function(){ view = p[1]; render(); };
  });
  shots.forEach(function(s, i){
    s.addEventListener('click', function(){
      view = dark && s.dataset.dark ? 'dark' : 'light';
      show(i);
    });
    s.addEventListener('keydown', function(e){
      if(e.key === 'Enter' || e.key === ' '){ e.preventDefault(); show(i); }
    });
  });
  document.getElementById('boxClose').onclick = function(){ box.close(); };
  box.addEventListener('click', function(e){ if(e.target === box) box.close(); });
  document.addEventListener('keydown', function(e){
    if(!box.open) return;
    if(e.key === 'ArrowRight') show(cur + 1);
    if(e.key === 'ArrowLeft') show(cur - 1);
  });

  /* The stamp gets out of the way while reviewing: hidden on scroll down,
     back on the first scroll up. */
  var hdr = document.getElementById('hdr'), lastY = 0;
  window.addEventListener('scroll', function(){
    var y = window.scrollY;
    if(y > lastY + 6 && y > 90) hdr.classList.add('hidden');
    else if(y < lastY - 6) hdr.classList.remove('hidden');
    lastY = y;
  }, {passive:true});

  applySheet();
})();
</script>
"""
sha, subject = _stamp()
html = html.replace('__SECTIONS__', ''.join(sections))
html = html.replace('__RAIL__', ''.join('<li>%s</li>' % a for a in rail))
html = html.replace('__TOTAL__', str(total))
html = html.replace('__DARKN__', str(dark_count))
html = html.replace('__SHA__', sha)
html = html.replace('__SUBJ__', _escape(subject))
html = html.replace(
    '__SURFACE__', '%d×%d' % (SURFACE[0] // DPR, SURFACE[1] // DPR)
)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
io.open(OUT, 'w', encoding='utf-8').write(html)
print('screens:', total, '| with dark:', dark_count,
      '| size: %.1f MB' % (os.path.getsize(OUT) / 1048576))
print('wrote', OUT)
