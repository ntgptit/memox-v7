# -*- coding: utf-8 -*-
"""Graft this branch's screens onto whatever gallery is currently published.

The pinned Artifact URL in CLAUDE.md has one slot and several unmerged branches
publish to it, so a plain republish deletes whichever branch published last.
The generated page is regular enough to merge instead: every screen is one
`<figure data-name="...">`, and the only other branch-dependent things are three
counters and the header stamp.

Usage:
  python splice_screen_gallery.py --base <saved-live.html> --mine <fresh-build.html>
         --prefix "Card detail" --section Card --stamp "<what the header should say>"
         --out build/screen_gallery.html

`--base` is the file WebFetch saves when you read the live artifact; it still
carries the frame-runtime wrapper, which this strips. The arithmetic
(base - replaced + mine == mine's own total) is asserted, not assumed: if a
branch renamed a screen, the count stops matching and this fails instead of
silently publishing a page with a screen listed twice.
"""
import argparse
import io
import re

FIGURE = re.compile(r'<figure class="shot".*?</figure>', re.S)
NAME = re.compile(r'data-name="([^"]*)"')


def page(path):
    """The generator's own output, with the published page's wrapper removed."""
    raw = io.open(path, encoding='utf-8').read()
    if '<!-- /frame-runtime -->' not in raw:
        return raw
    body = raw.index('<body>\n') + len('<body>\n')
    return raw[body:raw.rindex('</body></html>')].rstrip('\n') + '\n'


def figures(doc):
    return [(NAME.search(f).group(1), f) for f in FIGURE.findall(doc)]


def replace_once(doc, old, new):
    if doc.count(old) != 1:
        raise SystemExit(f'expected exactly one {old!r}, found {doc.count(old)}')
    return doc.replace(old, new, 1)


def main():
    ap = argparse.ArgumentParser()
    for flag in ('--base', '--mine', '--prefix', '--section', '--stamp', '--out'):
        ap.add_argument(flag, required=True)
    args = ap.parse_args()

    base, mine = page(args.base), page(args.mine)
    base_figs, mine_figs = figures(base), figures(mine)

    keep = [f for n, f in mine_figs if n.startswith(args.prefix)]
    drop = [f for n, f in base_figs if n.startswith(args.prefix)]
    if not keep:
        raise SystemExit(f'no figure in --mine starts with {args.prefix!r}')

    total = len(base_figs) - len(drop) + len(keep)
    if total != len(mine_figs):
        raise SystemExit(
            f'{len(base_figs)} - {len(drop)} + {len(keep)} = {total}, but --mine '
            f'has {len(mine_figs)}. The two builds disagree about which screens '
            f'exist, so grafting would drop or duplicate one.')

    # the group keeps the slot the first replaced figure held
    out = base.replace(drop[0], ''.join(keep), 1) if drop else base
    for gone in drop[1:]:
        out = out.replace(gone, '', 1)

    old_n = len(drop)
    section = re.search(
        r'<span class="eyebrow">%s</span><span class="count">(\d+)</span>'
        % re.escape(args.section), out)
    if not section:
        raise SystemExit(f'no section named {args.section!r}')
    out = replace_once(out, section.group(0), section.group(0).replace(
        f'>{section.group(1)}<', f'>{int(section.group(1)) - old_n + len(keep)}<'))

    out = replace_once(out, re.search(r'<h1>[^<]*</h1>', out).group(0),
                       f'<h1>MemoX · {total} màn</h1>')
    out = replace_once(out, re.search(r'<title>[^<]*</title>', out).group(0),
                       f'<title>MemoX — {total} màn hình</title>')
    out = replace_once(out, re.search(r'<p>golden suite @[^<]*</p>|<p>ghép tay[^<]*</p>',
                                      out).group(0), f'<p>{args.stamp}</p>')

    io.open(args.out, 'w', encoding='utf-8', newline='\n').write(out)
    names = [n for n, _ in figures(out)]
    print(f'{len(names)} screens | {sum(n.startswith(args.prefix) for n in names)} '
          f'grafted | {len(out.encode()) / 1e6:.1f} MB -> {args.out}')


if __name__ == '__main__':
    main()
