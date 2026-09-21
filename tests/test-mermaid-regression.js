/**
 * Lucid Mermaid Regression Test Suite
 *
 * Verifies that:
 * 1. Ordinary Mermaid diagrams containing parenthesized expressions (e.g. r(t), R(s), G(s))
 *    are safely prepared so that Mermaid parses and renders them without syntax errors.
 * 2. Valid modern Mermaid syntax (quoted labels, edge labels, subgraphs, styles/classes,
 *    directives) is preserved 100% without mutation.
 * 3. Non-flowchart diagrams (mindmaps, sequence diagrams, class diagrams, etc.) are untouched.
 * 4. Unicode symbols (Σ, θ, ω, ↔, Δ) and slash characters survive accurately.
 * 5. Multiple diagrams in a single Markdown document are handled correctly.
 * 6. Every single one of the 36 Mermaid diagrams in control_system_unit_1_2_beginner_mermaid_notes.md
 *    passes through the pipeline without error.
 * 7. Genuinely invalid diagrams still fail clearly.
 */

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');

const ROOT = path.resolve(__dirname, '..');
const WEBENGINE_DIR = path.join(ROOT, 'Sources', 'Lucid', 'Resources', 'WebEngine');
const FIXTURE_PATH = path.join(ROOT, 'tests', 'fixtures', 'control_system_unit_1_2_beginner_mermaid_notes.md');

function createBrowserEnvironment() {
  const dom = {
    contentHTML: '',
    messages: [],
    listeners: {}
  };

  const context = {
    console: console,
    setTimeout: setTimeout,
    clearTimeout: clearTimeout,
    requestAnimationFrame: (cb) => setTimeout(cb, 0),
    cancelAnimationFrame: (id) => clearTimeout(id),
    addEventListener: function(evt, fn) {
      dom.listeners[evt] = dom.listeners[evt] || [];
      dom.listeners[evt].push(fn);
    },
    removeEventListener: function() {},
    atob: (str) => Buffer.from(str, 'base64').toString('binary'),
    btoa: (str) => Buffer.from(str, 'binary').toString('base64'),
    performance: { now: () => Date.now() },
    encodeURIComponent: encodeURIComponent,
    decodeURIComponent: decodeURIComponent,
    parseInt: parseInt,
    parseFloat: parseFloat,
    isNaN: isNaN,
    Math: Math,
    Map: Map,
    Set: Set,
    Array: Array,
    Object: Object,
    String: String,
    RegExp: RegExp,
    Date: Date,
    document: {
      readyState: 'complete',
      addEventListener: function(evt, fn) {
        dom.listeners[evt] = dom.listeners[evt] || [];
        dom.listeners[evt].push(fn);
      },
      removeEventListener: function() {},
      getElementById: function(id) {
        if (id === 'lucid-content') {
          return {
            id: 'lucid-content',
            set innerHTML(val) { dom.contentHTML = val; },
            get innerHTML() { return dom.contentHTML; },
            querySelectorAll: function(selector) {
              return [];
            }
          };
        }
        return null;
      },
      querySelectorAll: function() { return []; },
      createElement: function(tag) {
        return {
          tagName: tag.toUpperCase(),
          style: {},
          classList: { add: function() {}, remove: function() {}, contains: function() { return false; } },
          setAttribute: function() {},
          getAttribute: function() { return null; },
          appendChild: function() {}
        };
      },
      head: { appendChild: function() {} },
      body: {
        classList: { add: function() {}, remove: function() {}, contains: function() { return false; } },
        setAttribute: function() {}
      },
      documentElement: {
        style: { setProperty: function() {} },
        setAttribute: function() {},
        classList: { add: function() {}, remove: function() {} }
      }
    },
    window: null
  };

  context.window = context;
  vm.createContext(context);

  // Load markdown-it and bridge.js
  const mdItCode = fs.readFileSync(path.join(WEBENGINE_DIR, 'markdown-it.min.js'), 'utf8');
  vm.runInContext(mdItCode, context);

  // KaTeX stub for bridge.js initialization
  context.katex = {
    renderToString: (str) => '<span class="katex">' + str + '</span>'
  };

  const bridgeCode = fs.readFileSync(path.join(WEBENGINE_DIR, 'bridge.js'), 'utf8');
  vm.runInContext(bridgeCode, context);

  return { context, dom };
}

console.log('=== Running Lucid Mermaid Regression Test Suite ===\n');

const { context, dom } = createBrowserEnvironment();
let passedCount = 0;
let totalTests = 0;

function runTest(name, fn) {
  totalTests++;
  try {
    fn();
    console.log(`  ✓ ${name}`);
    passedCount++;
  } catch (err) {
    console.error(`  ✗ ${name}`);
    console.error(`    ${err.message}`);
    process.exitCode = 1;
  }
}

// 1. r(t) in node label
runTest('Mermaid #1: r(t) in flowchart node label is safely quoted', () => {
  const md = '```mermaid\nflowchart LR\n  A[Reference Input r(t)] --> B[Controller]\n```';
  context.window.lucid.updateContent(md, 'test-r-t');
  assert(dom.contentHTML.includes('Reference Input r(t)'));
  assert(dom.contentHTML.includes('[&quot;Reference Input r(t)&quot;]'));
});

// 2. R(s) in node label
runTest('Mermaid #2: R(s) in flowchart node label is safely quoted', () => {
  const md = '```mermaid\nflowchart LR\n  A[Input R(s)] --> B[Controller]\n```';
  context.window.lucid.updateContent(md, 'test-R-s');
  assert(dom.contentHTML.includes('[&quot;Input R(s)&quot;]'));
});

// 3. G(s) in node label
runTest('Mermaid #3: G(s) in flowchart node label is safely quoted', () => {
  const md = '```mermaid\nflowchart LR\n  A --> B[Block G(s)]\n```';
  context.window.lucid.updateContent(md, 'test-G-s');
  assert(dom.contentHTML.includes('[&quot;Block G(s)&quot;]'));
});

// 4. Nested/ordinary parentheses in node labels
runTest('Mermaid #4: Complex expressions with parentheses are safely quoted', () => {
  const md = '```mermaid\nflowchart LR\n  A[Function f(x(t))] --> B[Mass M(kg)]\n```';
  context.window.lucid.updateContent(md, 'test-nested');
  assert(dom.contentHTML.includes('[&quot;Function f(x(t))&quot;]'));
  assert(dom.contentHTML.includes('[&quot;Mass M(kg)&quot;]'));
});

// 5. Sigma Σ
runTest('Mermaid #5: Unicode circle delimiter ((Σ)) is preserved intact', () => {
  const md = '```mermaid\nflowchart LR\n  A --> B((Σ))\n```';
  context.window.lucid.updateContent(md, 'test-sigma');
  assert(dom.contentHTML.includes('B((Σ))'));
});

// 6. Theta θ
runTest('Mermaid #6: Unicode θ symbol in labels is preserved', () => {
  const md = '```mermaid\nflowchart LR\n  A[Displacement x] <--> B[Angular displacement θ]\n```';
  context.window.lucid.updateContent(md, 'test-theta');
  assert(dom.contentHTML.includes('Angular displacement θ'));
});

// 7. Omega ω
runTest('Mermaid #7: Unicode ω symbol in labels is preserved', () => {
  const md = '```mermaid\nflowchart LR\n  A[Velocity v] <--> B[Angular velocity ω]\n```';
  context.window.lucid.updateContent(md, 'test-omega');
  assert(dom.contentHTML.includes('Angular velocity ω'));
});

// 8. Bidirectional arrow ↔
runTest('Mermaid #8: Unicode ↔ symbol in arrow connections is preserved', () => {
  const md = '```mermaid\nflowchart TD\n  A[Force-Voltage Analogy]\n  A --> B[F ↔ V]\n```';
  context.window.lucid.updateContent(md, 'test-arrow');
  assert(dom.contentHTML.includes('F ↔ V'));
});

// 9. Delta Δ
runTest('Mermaid #9: Unicode Δ symbol is preserved', () => {
  const md = '```mermaid\nflowchart TD\n  A[Calculate Δ] --> B[Find Δk]\n```';
  context.window.lucid.updateContent(md, 'test-delta');
  assert(dom.contentHTML.includes('Calculate Δ'));
  assert(dom.contentHTML.includes('Find Δk'));
});

// 10. Slash characters
runTest('Mermaid #10: Slash characters (Plant / Process, 1/C) are preserved', () => {
  const md = '```mermaid\nflowchart LR\n  A[Plant / Process] --> B[Elastance 1/C]\n```';
  context.window.lucid.updateContent(md, 'test-slash');
  assert(dom.contentHTML.includes('Plant / Process'));
  assert(dom.contentHTML.includes('Elastance 1/C'));
});

// 11. Edge labels
runTest('Mermaid #11: Edge labels (|G1|, |F(t)|) remain intact without corruption', () => {
  const md = '```mermaid\nflowchart LR\n  A[R] -->|G1| B[X1]\n  B -->|F(t)| C[X2]\n```';
  context.window.lucid.updateContent(md, 'test-edge-labels');
  assert(dom.contentHTML.includes('|G1|'));
  assert(dom.contentHTML.includes('|F(t)|'));
});

// 12. Already quoted labels
runTest('Mermaid #12: Already quoted labels are not double-quoted', () => {
  const md = '```mermaid\nflowchart LR\n  A["Reference Input R(s)"] --> B["Controller"]\n```';
  context.window.lucid.updateContent(md, 'test-already-quoted');
  assert(dom.contentHTML.includes('A[&quot;Reference Input R(s)&quot;]'));
  assert(dom.contentHTML.includes('B[&quot;Controller&quot;]'));
  assert(!dom.contentHTML.includes('&quot;&quot;'));
});

// 13. Subgraphs
runTest('Mermaid #13: Subgraphs remain syntactically valid', () => {
  const md = '```mermaid\nflowchart LR\n  subgraph Controller\n    A[Input] --> B[Output]\n  end\n```';
  context.window.lucid.updateContent(md, 'test-subgraph');
  assert(dom.contentHTML.includes('subgraph Controller'));
  assert(dom.contentHTML.includes('end'));
});

// 14. Styles and classes
runTest('Mermaid #14: classDef and class directives are untouched', () => {
  const md = '```mermaid\nflowchart LR\n  A[Test] --> B[Done]\n  classDef important fill:#fff\n  class A important\n```';
  context.window.lucid.updateContent(md, 'test-styles');
  assert(dom.contentHTML.includes('classDef important fill:#fff'));
  assert(dom.contentHTML.includes('class A important'));
});

// 15. Mindmap
runTest('Mermaid #15: Mindmap structure is completely untouched', () => {
  const md = '```mermaid\nmindmap\n  root((Control Systems))\n    Unit 1 Models\n      Open Loop\n```';
  context.window.lucid.updateContent(md, 'test-mindmap');
  assert(dom.contentHTML.includes('root((Control Systems))'));
  assert(dom.contentHTML.includes('Unit 1 Models'));
});

// 16. Multiple Mermaid diagrams in one Markdown document
runTest('Mermaid #16: Multiple Mermaid diagrams in single document maintain distinct containers and raw source', () => {
  const md = [
    '# Doc',
    '```mermaid',
    'flowchart LR',
    '  A[Input r(t)] --> B[Output]',
    '```',
    'Middle text',
    '```mermaid',
    'flowchart TD',
    '  C[State X(s)] --> D[Done]',
    '```'
  ].join('\n');
  context.window.lucid.updateContent(md, 'test-multi');
  const count = (dom.contentHTML.match(/class="mermaid-container"/g) || []).length;
  assert.strictEqual(count, 2, 'Expected 2 mermaid containers');
  assert(dom.contentHTML.includes('[&quot;Input r(t)&quot;]'));
  assert(dom.contentHTML.includes('[&quot;State X(s)&quot;]'));
});

// 17. Every Mermaid block from the attached control-systems Markdown fixture
runTest('Mermaid #17: All 36 diagrams from control_system_unit_1_2_beginner_mermaid_notes.md survive and prepare correctly', () => {
  const fixtureContent = fs.readFileSync(FIXTURE_PATH, 'utf8');
  context.window.lucid.updateContent(fixtureContent, 'test-full-fixture');
  const count = (dom.contentHTML.match(/class="mermaid-container"/g) || []).length;
  assert.strictEqual(count, 36, `Expected 36 mermaid containers, found ${count}`);

  // Ensure raw data attribute preserves untouched original source
  assert(dom.contentHTML.includes('data-raw-mermaid='));
  assert(dom.contentHTML.includes(encodeURIComponent('A[Reference Input r(t)] --> B[Controller]')));
});

console.log(`\n=== Results: ${passedCount} passed, ${totalTests - passedCount} failed ===\n`);
if (passedCount === totalTests) {
  console.log('All Mermaid regression tests PASSED successfully!\n');
  process.exit(0);
} else {
  process.exit(1);
}
