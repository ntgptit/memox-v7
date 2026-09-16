/*
 * find-unused.cjs — quarantine files no HTML page reaches.
 *
 * CommonJS + .cjs on purpose: this is a Node maintenance script, not design-system
 * source, and the .cjs extension keeps it out of the compiled browser bundle.
 *
 *   node tools/find-unused.cjs           # dry run: print the report, touch nothing
 *   node tools/find-unused.cjs --apply   # move unreachable files into backup/202609/
 *   node tools/find-unused.cjs --undo    # put everything in backup/202609/ back
 *
 * How reachability is decided
 *   Roots        every *.html outside the backup folder (each one is a real page).
 *   Edges        HTML  src= href= srcset= poster= data-src= and url(...) in <style>
 *                CSS   @import and url(...)
 *                JS    import/require/fetch + any string literal that looks like a
 *                      project-relative path with a known extension
 *   Closure      followed transitively, so a .jsx pulled in by a page keeps whatever
 *                it references alive too.
 *
 * Files that are never quarantined even when no HTML points at them (KEEP below):
 * design-system build output, the token/component sources the compiler reads,
 * .dc.html templates and their ds-base.js, .d.ts type files paired with a component,
 * project docs, and this script.
 */
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const BACKUP = path.join('backup', '202609');
const MANIFEST = path.join(BACKUP, 'MANIFEST.tsv');

const SKIP_DIRS = new Set(['node_modules', '.git', '.vscode', 'backup', 'uploads', 'screenshots', 'scraps']);
const FOLLOW_EXT = new Set(['.html', '.htm', '.css', '.js', '.jsx', '.mjs', '.ts', '.tsx']);
const PATHLIKE = /\.(html?|css|m?js|jsx|tsx?|json|png|jpe?g|gif|svg|webp|avif|woff2?|ttf|otf|eot|mp4|webm|mp3|wav|md|csv)$/i;

/* Never move these, whatever the graph says. */
const KEEP = [
  /^_ds_/, /^_adherence\./,                    // compiler output
  /^styles\.css$/, /^colors_and_type\.css$/, /^components\.css$/,
  /^tokens\//, /^components\//,                 // compiler reads these directly
  /^templates\//,                               // .dc.html templates + ds-base.js
  /\.dc\.html$/, /(^|\/)support\.js$/, /(^|\/)ds-base\.js$/,
  /(^|\/)(readme|README|CLAUDE|SKILL|github)\.md$/i, /\.md$/,
  /(^|\/)thumbnail\.html$/,
  /^tools\//,
  /^assets\/(logo|icon)/i,
  /(^|\/)\./,                                   // dotfiles
];

const rel = (p) => path.relative(ROOT, p).split(path.sep).join('/');
const isKept = (r) => KEEP.some((re) => re.test(r));

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name.startsWith('.')) continue;
    const full = path.join(dir, e.name);
    if (e.isDirectory()) { if (!SKIP_DIRS.has(e.name)) walk(full, out); }
    else out.push(full);
  }
  return out;
}

/* ── reference extraction ─────────────────────────────────────────────── */
function refsFromHtml(src) {
  const out = [];
  const attr = /(?:src|href|poster|data-src|srcset)\s*=\s*["']([^"']+)["']/gi;
  for (let m; (m = attr.exec(src));) out.push(...m[1].split(',').map((s) => s.trim().split(/\s+/)[0]));
  out.push(...refsFromCss(src));
  out.push(...refsFromJs(src));
  return out;
}
function refsFromCss(src) {
  const out = [];
  for (let m, re = /url\(\s*["']?([^"')]+)["']?\s*\)/gi; (m = re.exec(src));) out.push(m[1]);
  for (let m, re = /@import\s+(?:url\(\s*)?["']([^"']+)["']/gi; (m = re.exec(src));) out.push(m[1]);
  return out;
}
function refsFromJs(src) {
  const out = [];
  for (let m, re = /["'`]([^"'`\s{}<>]+?)["'`]/g; (m = re.exec(src));) if (PATHLIKE.test(m[1])) out.push(m[1]);
  return out;
}
const extract = (file, src) => {
  const ext = path.extname(file).toLowerCase();
  if (ext === '.html' || ext === '.htm') return refsFromHtml(src);
  if (ext === '.css') return refsFromCss(src);
  return refsFromJs(src);
};

function resolveRef(fromFile, ref) {
  if (/^(https?:|data:|mailto:|tel:|blob:|#|\/\/)/i.test(ref)) return null;
  const clean = ref.split('#')[0].split('?')[0];
  if (!clean) return null;
  const base = clean.startsWith('/')
    ? path.join(ROOT, clean.slice(1))
    : path.resolve(path.dirname(fromFile), clean);
  const r = rel(base);
  if (r.startsWith('..')) return null;               // escapes the project
  return fs.existsSync(base) && fs.statSync(base).isFile() ? base : null;
}

/* ── reachability ─────────────────────────────────────────────────────── */
function reachable(all) {
  const seen = new Set();
  const queue = all.filter((f) => /\.html?$/i.test(f) && !rel(f).startsWith('backup/'));
  for (const f of queue) seen.add(f);
  while (queue.length) {
    const file = queue.shift();
    if (!FOLLOW_EXT.has(path.extname(file).toLowerCase())) continue;
    let src;
    try { src = fs.readFileSync(file, 'utf8'); } catch { continue; }
    for (const ref of extract(file, src)) {
      const target = resolveRef(file, ref);
      if (target && !seen.has(target)) { seen.add(target); queue.push(target); }
    }
  }
  return seen;
}

/* ── report / apply / undo ────────────────────────────────────────────── */
/* Every .html is a root, so a page nothing links to still counts as reachable.
 * Those are the real dead-page candidates: no incoming link AND no @dsCard
 * marker (a carded page is shown by the Design System tab, so it IS used).
 * Reported separately; --apply does not touch them without --include-orphan-html. */
function orphanHtml(all) {
  const linked = new Set();
  for (const f of all) {
    if (!FOLLOW.has(path.extname(f).toLowerCase())) continue;
    let src; try { src = fs.readFileSync(f, 'utf8'); } catch { continue; }
    for (const ref of extract(f, src)) {
      const t = resolveRef(f, ref);
      if (t && /\.html?$/i.test(t) && t !== f) linked.add(t);
    }
  }
  return all.filter((f) => {
    const r = rel(f);
    if (!/\.html?$/i.test(r) || r.startsWith('backup/') || isKept(r)) return false;
    if (linked.has(f)) return false;
    return !/@dsCard|@template/.test(fs.readFileSync(f, 'utf8').slice(0, 4000));
  }).map(rel).sort();
}

function report() {
  const all = walk(ROOT);
  const live = reachable(all);
  const groups = { unused: [], kept: [] };
  for (const f of all) {
    const r = rel(f);
    if (live.has(f) || r.startsWith('backup/')) continue;
    (isKept(r) ? groups.kept : groups.unused).push(r);
  }
  groups.unused.sort(); groups.kept.sort();
  return { all, live, orphans: orphanHtml(all), ...groups };
}

function fmt(bytes) {
  return bytes > 1e6 ? (bytes / 1e6).toFixed(1) + ' MB'
    : bytes > 1e3 ? Math.round(bytes / 1e3) + ' kB' : bytes + ' B';
}

function main() {
  const mode = process.argv.includes('--apply') ? 'apply'
    : process.argv.includes('--undo') ? 'undo' : 'dry';

  if (mode === 'undo') {
    if (!fs.existsSync(path.join(ROOT, MANIFEST))) return console.error('No ' + MANIFEST + ' — nothing to undo.');
    const lines = fs.readFileSync(path.join(ROOT, MANIFEST), 'utf8').trim().split('\n').slice(1);
    let n = 0;
    for (const line of lines) {
      const [from, to] = line.split('\t');
      const src = path.join(ROOT, to), dest = path.join(ROOT, from);
      if (!fs.existsSync(src)) continue;
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.renameSync(src, dest); n++;
    }
    fs.unlinkSync(path.join(ROOT, MANIFEST));
    return console.log('Restored ' + n + ' file(s).');
  }

  const withOrphans = process.argv.includes('--include-orphan-html');
  const rpt = report();
  const { all, live, kept, orphans } = rpt;
  const unused = withOrphans ? [...rpt.unused, ...orphans].sort() : rpt.unused;
  const total = unused.reduce((s, r) => s + fs.statSync(path.join(ROOT, r)).size, 0);

  console.log('\nScanned ' + all.length + ' files · ' + live.size + ' reachable from HTML\n');
  if (kept.length) {
    console.log('Unreferenced but PROTECTED (' + kept.length + ') — design-system sources, templates, docs:');
    for (const r of kept) console.log('  · ' + r);
    console.log('');
  }
  if (orphans.length && !withOrphans) {
    console.log('Orphan HTML pages (' + orphans.length + ') — nothing links to them and they carry no @dsCard;\nlikely stale copies. Add --include-orphan-html to quarantine these too:');
    for (const r of orphans) console.log('  ? ' + r);
    console.log('');
  }
  if (!unused.length) return console.log('No unused files. Nothing to move.\n');

  console.log('Unused (' + unused.length + ' files, ' + fmt(total) + '):');
  for (const r of unused) console.log('  ✗ ' + r);

  if (mode === 'dry') return console.log('\nDry run. Re-run with --apply to move these into ' + BACKUP + '/\n');

  const rows = [];
  for (const r of unused) {
    const dest = path.join(ROOT, BACKUP, r);
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.renameSync(path.join(ROOT, r), dest);
    rows.push(r + '\t' + BACKUP.split(path.sep).join('/') + '/' + r);
  }
  fs.mkdirSync(path.join(ROOT, BACKUP), { recursive: true });
  fs.writeFileSync(path.join(ROOT, MANIFEST),
    ['original\tmoved_to', ...rows].join('\n') + '\n');
  console.log('\nMoved ' + rows.length + ' file(s) into ' + BACKUP + '/');
  console.log('Manifest: ' + MANIFEST + ' — run with --undo to restore.\n');
}

main();
