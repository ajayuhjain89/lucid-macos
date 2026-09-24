/**
 * Outline parity: the headings (ids, levels, text) the real renderer produces
 * for tests/fixtures/outline-parity.md must equal tests/fixtures/outline-parity.json.
 * The Swift suite checks MarkdownOutlineParser against the same JSON, so the
 * native sidebar outline and the preview can't drift apart (AUDIT-025).
 * Regenerate after an intended change: node tests/test-outline-parity.js --write
 */
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');

const ROOT = path.resolve(__dirname, '..');
const WEBENGINE_DIR = path.join(ROOT, 'Sources', 'Lucid', 'Resources', 'WebEngine');
const FIXTURE = path.join(__dirname, 'fixtures', 'outline-parity.md');
const EXPECTED = path.join(__dirname, 'fixtures', 'outline-parity.json');

const dom = { contentHTML: '' };
const ctx = {
  console, setTimeout, clearTimeout,
  requestAnimationFrame: (cb) => setTimeout(cb, 0), cancelAnimationFrame: (id) => clearTimeout(id),
  addEventListener() {}, removeEventListener() {},
  performance: { now: () => Date.now() },
  atob: (s) => Buffer.from(s, 'base64').toString('binary'),
  btoa: (s) => Buffer.from(s, 'binary').toString('base64'),
  encodeURIComponent, decodeURIComponent, parseInt, parseFloat, isNaN,
  Math, Map, Set, Array, Object, String, RegExp, Date,
  document: {
    readyState: 'complete', addEventListener() {}, removeEventListener() {},
    getElementById(id) {
      if (id !== 'lucid-content') return null;
      return { set innerHTML(v) { dom.contentHTML = v; }, get innerHTML() { return dom.contentHTML; }, querySelectorAll() { return []; } };
    },
    querySelectorAll() { return []; }, querySelector() { return null; },
    createElement() { return { style: {}, classList: { add() {}, remove() {} }, setAttribute() {}, appendChild() {} }; },
    documentElement: { style: { setProperty() {} }, setAttribute() {}, classList: { add() {}, remove() {} } },
    body: { classList: { add() {}, remove() {}, contains() { return false; } }, setAttribute() {}, style: {} },
    head: { appendChild() {} }
  },
  navigator: { clipboard: { writeText: () => Promise.resolve() } },
  window: {}
};
ctx.window = ctx;
vm.createContext(ctx);
['markdown-it.min.js',
 'plugins/markdown-it-sub.min.js', 'plugins/markdown-it-sup.min.js', 'plugins/markdown-it-ins.min.js',
 'plugins/markdown-it-mark.min.js', 'plugins/markdown-it-deflist.min.js', 'plugins/markdown-it-abbr.min.js',
 'plugins/markdown-it-task-lists.min.js', 'plugins/markdown-it-footnote.min.js',
 'katex/katex.min.js', 'katex/contrib/mhchem.min.js', 'highlight/highlight.min.js', 'bridge.js'
].forEach((f) => vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, f), 'utf8'), ctx));

ctx.lucid.updateContent(fs.readFileSync(FIXTURE, 'utf8'), 'outline');
const decode = (s) => s.replace(/<[^>]+>/g, '').replace(/&amp;/g, '&').replace(/&lt;/g, '<')
  .replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&#39;/g, "'").trim();
const headings = [...dom.contentHTML.matchAll(/<h([1-6])\s+id="([^"]*)"[^>]*>([\s\S]*?)<\/h\1>/g)]
  .map((m) => ({ id: m[2], level: Number(m[1]), text: decode(m[3]) }));

if (process.argv.includes('--write')) {
  fs.writeFileSync(EXPECTED, JSON.stringify(headings, null, 2) + '\n');
  console.log('Wrote ' + EXPECTED);
  process.exit(0);
}
const expected = JSON.parse(fs.readFileSync(EXPECTED, 'utf8'));
try {
  assert.deepStrictEqual(headings, expected);
  console.log('=== Results: 1 passed, 0 failed ===');
  console.log('Renderer outline matches outline-parity.json (' + headings.length + ' headings).');
} catch (e) {
  console.error('Renderer outline differs from outline-parity.json:\n' + JSON.stringify(headings, null, 2));
  process.exit(1);
}
