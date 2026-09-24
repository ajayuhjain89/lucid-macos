/**
 * Lucid Security & Engine Regression Suite
 *
 * Guards the P1/P2 audit fixes that harden the renderer:
 *   - AUDIT-001: raw HTML from a document is inert (markdown-it html:false) and
 *                Mermaid runs with securityLevel:'strict'.
 *   - AUDIT-003: the STEM & Math engine toggles actually gate rendering.
 *   - AUDIT-004: heading ids are Unicode-preserving and deduplicated so they
 *                match the native MarkdownOutlineParser slugifier.
 *
 * Runs the ACTUAL bundled WebEngine (markdown-it + plugins + KaTeX + hljs +
 * mermaid + bridge.js) in a Node VM. Note: a VM/fake-DOM cannot prove browser
 * *execution* safety (inline handlers never fire here); it proves the source
 * fix — that html:false emits escaped text and no raw executable tags. Full
 * browser-execution protection is covered by configuration + code inspection,
 * not by this harness.
 */

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');

const ROOT = path.resolve(__dirname, '..');
const WEBENGINE_DIR = path.join(ROOT, 'Sources', 'Lucid', 'Resources', 'WebEngine');

function createEnv() {
  const dom = { contentHTML: '', messages: [] };
  const ctx = {
    console, setTimeout, clearTimeout,
    requestAnimationFrame: (cb) => setTimeout(cb, 0),
    cancelAnimationFrame: (id) => clearTimeout(id),
    addEventListener() {}, removeEventListener() {},
    atob: (s) => Buffer.from(s, 'base64').toString('binary'),
    btoa: (s) => Buffer.from(s, 'binary').toString('base64'),
    performance: { now: () => Date.now() },
    encodeURIComponent, decodeURIComponent, parseInt, parseFloat, isNaN,
    Math, Map, Set, Array, Object, String, RegExp, Date,
    document: {
      readyState: 'complete',
      addEventListener() {}, removeEventListener() {},
      getElementById(id) {
        if (id === 'lucid-content') {
          return {
            id,
            set innerHTML(v) { dom.contentHTML = v; },
            get innerHTML() { return dom.contentHTML; },
            querySelectorAll(sel) { return sel === '*' ? new Array(10) : []; }
          };
        }
        return null;
      },
      querySelectorAll() { return []; },
      createElement(tag) {
        return {
          tagName: tag.toUpperCase(), style: {},
          classList: { add() {}, remove() {}, contains() { return false; } },
          setAttribute() {}, getAttribute() { return null; }, appendChild() {}
        };
      },
      head: { appendChild() {} },
      body: { classList: { add() {}, remove() {}, contains() { return false; } }, setAttribute() {} },
      documentElement: { style: { setProperty() {} }, setAttribute() {}, classList: { add() {}, remove() {} } }
    },
    window: null,
    navigator: { clipboard: { writeText: async () => {} } },
    webkit: {
      messageHandlers: {
        lucidReady: { postMessage() {} },
        lucidScroll: { postMessage() {} },
        lucidHeadings: { postMessage(m) { dom.messages.push(m); } },
        lucidActiveHeading: { postMessage() {} },
        lucidPerf: { postMessage() {} }
      }
    }
  };
  ctx.window = ctx; ctx.globalThis = ctx; ctx.self = ctx;
  vm.createContext(ctx);
  [
    'markdown-it.min.js',
    'plugins/markdown-it-sub.min.js', 'plugins/markdown-it-sup.min.js',
    'plugins/markdown-it-ins.min.js', 'plugins/markdown-it-mark.min.js',
    'plugins/markdown-it-deflist.min.js', 'plugins/markdown-it-abbr.min.js',
    'katex/katex.min.js', 'katex/contrib/mhchem.min.js',
    'highlight/highlight.min.js', 'mermaid/mermaid.min.js', 'bridge.js'
  ].forEach((f) => vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, f), 'utf8'), ctx));
  return { ctx, dom };
}

let passed = 0, failed = 0;
function runTest(name, fn) {
  try { fn(); console.log('  ✓ ' + name); passed++; }
  catch (e) { console.error('  ✗ ' + name); console.error('    ' + e.message); failed++; }
}

console.log('=== Running Lucid Security & Engine Regression Suite ===\n');

const { ctx, dom } = createEnv();

// ---- AUDIT-001: raw HTML is inert ----------------------------------------
runTest('AUDIT-001: raw <img onerror>/<iframe>/<script> are escaped, not live DOM', () => {
  ctx.lucid.updateContent(
    '# H\n\n<img src="x" onerror="window.__p=1">\n\n<iframe src="https://example.com"></iframe>\n\n<script>window.__p=1<\/script>',
    'sec-1'
  );
  const h = dom.contentHTML;
  // No raw executable tags reach the DOM (they are the XSS vectors); the
  // remaining "onerror=" text is inert escaped content, not a live attribute.
  assert(!/<img\b/i.test(h), 'must not emit a raw <img> tag');
  assert(!/<iframe\b/i.test(h), 'must not emit a raw <iframe> tag');
  assert(!/<script\b/i.test(h), 'must not emit a raw <script> tag');
  assert(/&lt;img[^>]*onerror/i.test(h), 'the <img onerror> vector is present only as escaped text');
});

runTest('AUDIT-001: benign inline HTML (details/kbd/span/br) is escaped (documented tradeoff)', () => {
  ctx.lucid.updateContent('<details><summary>More</summary>Hidden</details>\n\nPress <kbd>S</kbd>.\n\nA<br>B\n\n<span>x</span>', 'sec-2');
  const h = dom.contentHTML;
  assert(!/<details\b/i.test(h), 'raw <details> intentionally not live');
  assert(!/<kbd\b/i.test(h), 'raw <kbd> intentionally not live');
  assert(/&lt;details|&lt;kbd|&lt;span|&lt;br/i.test(h), 'benign HTML rendered as escaped text');
});

runTest('AUDIT-001: markdown-it configured html:false and Mermaid securityLevel strict (config guard)', () => {
  const src = fs.readFileSync(path.join(WEBENGINE_DIR, 'bridge.js'), 'utf8');
  assert(/\bhtml:\s*false\b/.test(src), 'markdown-it must be html:false');
  assert(/securityLevel:\s*'strict'/.test(src), "Mermaid must be securityLevel:'strict'");
  assert(!/\bhtml:\s*true\b/.test(src), 'markdown-it must not re-enable html:true');
});

runTest('Code-fence info string is escaped in the code bar (no live elements or attributes)', () => {
  ctx.lucid.updateContent(
    '```<MARK>X</MARK>\ncode\n```\n\n```<IMG/SRC=x ONERROR=alert(1)>\ncode\n```\n\n```a"b\'c\ncode\n```',
    'sec-fence'
  );
  const h = dom.contentHTML;
  assert(!/<mark\b/i.test(h), 'fence tag must not create a <mark> element');
  assert(!/<img\b/i.test(h), 'fence tag must not create an <img> element');
  assert(/&lt;MARK&gt;X&lt;\/MARK&gt;/.test(h), 'fence tag rendered as escaped text in the code bar');
  const langs = [...h.matchAll(/<span class="lucid-lang">([^<]*)<\/span>/g)].map((m) => m[1]);
  assert(langs.length === 3, 'expected three language labels, got ' + langs.length);
  langs.forEach((l) => assert(!/[<>"]/.test(l), 'label must not carry raw markup characters: ' + l));
});

runTest('Local image paths are routed through lucid-asset:, remote and data images untouched', () => {
  ctx.lucid.updateContent(
    '![a](shot.png) ![b](<dir with space/my image.png>) ![c](../up/x.png) ![d](/Users/me/p.png) ' +
    '![e](https://example.com/r.png) ![f](data:image/png;base64,AAAA)',
    'img-1'
  );
  const srcs = [...dom.contentHTML.matchAll(/<img src="([^"]*)"/g)].map((m) => m[1]);
  assert.deepStrictEqual(srcs, [
    'lucid-asset://doc/shot.png',
    'lucid-asset://doc/dir%20with%20space%2Fmy%20image.png',
    'lucid-asset://doc/..%2Fup%2Fx.png',
    'lucid-asset://abs/Users%2Fme%2Fp.png',
    'https://example.com/r.png',
    'data:image/png;base64,AAAA'
  ], 'srcs: ' + JSON.stringify(srcs));
});

runTest('Mermaid containers are emitted bare, not inside a <pre><code> code frame', () => {
  ctx.lucid.updatePreferences({ enableMermaid: true });
  ctx.lucid.updateContent('```mermaid\nflowchart TD\nA-->B\n```', 'm-frame');
  const h = dom.contentHTML;
  assert(/^\s*<div class="mermaid-container"/.test(h), 'container must be top-level, got: ' + h.slice(0, 80));
  assert(!/<pre><code[^>]*>\s*<div class="mermaid-container"/.test(h), 'no <pre><code> wrapper');
});

// ---- AUDIT-003: STEM engine toggles gate rendering ------------------------
runTest('AUDIT-003: KaTeX toggle gates math rendering', () => {
  ctx.lucid.updatePreferences({ enableKaTeX: true });
  ctx.lucid.updateContent('Inline $x^2$ end.', 'k-on');
  assert(/class="katex/.test(dom.contentHTML), 'KaTeX ON must typeset math');

  ctx.lucid.updatePreferences({ enableKaTeX: false });
  ctx.lucid.updateContent('Inline $x^2$ end.', 'k-off');
  assert(!/class="katex/.test(dom.contentHTML), 'KaTeX OFF must not typeset');
  assert(/\$x\^2\$/.test(dom.contentHTML), 'KaTeX OFF must leave literal $ math');
  ctx.lucid.updatePreferences({ enableKaTeX: true });
});

runTest('AUDIT-003: Mermaid toggle gates diagram rendering', () => {
  const doc = '```mermaid\nflowchart TD\nA-->B\n```';
  ctx.lucid.updatePreferences({ enableMermaid: true });
  ctx.lucid.updateContent(doc, 'm-on');
  assert(/mermaid-container/.test(dom.contentHTML), 'Mermaid ON must build a diagram container');

  ctx.lucid.updatePreferences({ enableMermaid: false });
  ctx.lucid.updateContent(doc, 'm-off');
  assert(!/mermaid-container/.test(dom.contentHTML), 'Mermaid OFF must not build a diagram');
  assert(/lucid-enhanced/.test(dom.contentHTML), 'Mermaid OFF must fall back to a code block');
  ctx.lucid.updatePreferences({ enableMermaid: true });
});

runTest('AUDIT-003: Syntax-highlighting toggle gates hljs markup', () => {
  const doc = '```javascript\nconst a = 42;\n```';
  ctx.lucid.updatePreferences({ enableSyntaxHighlighting: true });
  ctx.lucid.updateContent(doc, 's-on');
  assert(/class="hljs-/.test(dom.contentHTML), 'Highlighting ON must emit hljs token spans');

  ctx.lucid.updatePreferences({ enableSyntaxHighlighting: false });
  ctx.lucid.updateContent(doc, 's-off');
  assert(!/class="hljs-/.test(dom.contentHTML), 'Highlighting OFF must not emit hljs token spans');
  assert(/const a = 42/.test(dom.contentHTML.replace(/&nbsp;/g, ' ')), 'code text still present, unhighlighted');
  ctx.lucid.updatePreferences({ enableSyntaxHighlighting: true });
});

runTest('AUDIT-003: mhchem toggle gates chemistry rendering', () => {
  const doc = 'Chem: $\\ce{H2O}$ end.';
  ctx.lucid.updatePreferences({ enableKaTeX: true, enableMhchem: true });
  ctx.lucid.updateContent(doc, 'c-on');
  assert(/class="katex/.test(dom.contentHTML), 'mhchem ON must typeset chemistry via KaTeX');

  ctx.lucid.updatePreferences({ enableMhchem: false });
  ctx.lucid.updateContent(doc, 'c-off');
  assert(/mhchem/i.test(dom.contentHTML) || /\\ce\{H2O\}/.test(dom.contentHTML),
    'mhchem OFF must not typeset chemistry (disabled notice or literal source)');
  ctx.lucid.updatePreferences({ enableMhchem: true });
});

runTest('AUDIT-001: preview CSP forbids inline script, and the engine emits no inline handlers', () => {
  const html = fs.readFileSync(path.join(WEBENGINE_DIR, 'index.html'), 'utf8');
  const meta = html.match(/<meta http-equiv="Content-Security-Policy" content="([^"]+)"/);
  assert(meta, 'index.html must declare a Content-Security-Policy');
  const scriptSrc = (meta[1].match(/script-src ([^;]+)/) || [])[1] || '';
  assert(scriptSrc && !/unsafe-inline|unsafe-eval/.test(scriptSrc), 'script-src must not allow inline/eval: ' + scriptSrc);
  assert(/object-src 'none'/.test(meta[1]) && /frame-src 'none'/.test(meta[1]), 'objects and frames must be blocked');
  assert(!/<script>/.test(html), 'index.html must not contain inline <script> blocks');

  const doc = ['```js', 'x()', '```', '', '```mermaid', 'graph TD; A-->B', '```', '', '$$', 'x^2', '$$'].join('\n');
  ctx.lucid.updateContent(doc, 'csp-1');
  assert(/data-lucid-action="copyCode"/.test(dom.contentHTML), 'code copy button must use data-lucid-action');
  assert(!/\son[a-z]+\s*=/i.test(dom.contentHTML), 'rendered HTML must not contain inline on* handlers');
  const bridge = fs.readFileSync(path.join(WEBENGINE_DIR, 'bridge.js'), 'utf8');
  assert(!/\son(click|pointerdown|error|load)="/.test(bridge), 'bridge.js must not emit inline handler attributes');
});

// ---- AUDIT-004: heading id Unicode parity + dedup -------------------------
runTest('AUDIT-004: heading ids preserve Unicode and deduplicate like the native parser', () => {
  const doc = [
    '# Overview', '', '## Overview', '', '## 概要', '', '## Section θ', '',
    '## Overview', '', '## Пример', '', '## 数据', '', '## Café résumé', '', '## !!! ???'
  ].join('\n');
  ctx.lucid.updateContent(doc, 'h-1');
  const ids = [...dom.contentHTML.matchAll(/<h[1-6]\s+id="([^"]*)"/g)].map((m) => m[1]);
  const expected = [
    'overview', 'overview-1', '概要', 'section-θ', 'overview-2',
    'пример', '数据', 'café-résumé', 'heading'
  ];
  assert.deepStrictEqual(ids, expected, 'ids: ' + JSON.stringify(ids));
  // No duplicate ids (would break the SwiftUI outline List identity).
  assert.strictEqual(new Set(ids).size, ids.length, 'heading ids must be unique');
});

console.log(`\n=== Results: ${passed} passed, ${failed} failed ===\n`);
if (failed > 0) { process.exit(1); }
console.log('All security & engine regression assertions PASSED successfully!');
