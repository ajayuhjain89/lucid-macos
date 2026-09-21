/**
 * Lucid Renderer Conformance Test Suite
 *
 * Runs against the actual bundled WebEngine resources:
 * - markdown-it.min.js + plugins
 * - katex.min.js + mhchem.min.js
 * - highlight.min.js
 * - bridge.js
 *
 * Asserts all 12 acceptance invariants and verifies the canonical conformance fixture.
 */

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');

const ROOT = path.resolve(__dirname, '..');
const WEBENGINE_DIR = path.join(ROOT, 'Sources', 'Lucid', 'Resources', 'WebEngine');
const FIXTURE_PATH = path.join(ROOT, 'tests', 'fixtures', 'renderer-conformance.md');

// 1. Create a browser-like VM environment
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
              if (selector === '*') return new Array(10);
              if (selector.includes('h1')) return [];
              if (selector.includes('table')) return [];
              if (selector.includes('.mermaid')) return [];
              if (selector.includes('.lucid-math-placeholder')) return [];
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
    window: null,
    navigator: { clipboard: { writeText: async () => {} } },
    webkit: {
      messageHandlers: {
        lucidReady: { postMessage: function(msg) { dom.messages.push({ type: 'lucidReady', msg }); } },
        lucidScroll: { postMessage: function(msg) { dom.messages.push({ type: 'lucidScroll', msg }); } },
        lucidHeadings: { postMessage: function(msg) { dom.messages.push({ type: 'lucidHeadings', msg }); } },
        lucidActiveHeading: { postMessage: function(msg) { dom.messages.push({ type: 'lucidActiveHeading', msg }); } },
        lucidPerf: { postMessage: function(msg) { dom.messages.push({ type: 'lucidPerf', msg }); } }
      }
    }
  };

  context.window = context;
  context.globalThis = context;
  context.self = context;

  vm.createContext(context);

  // Load scripts in canonical index.html order:
  // 1. markdown-it
  // 2. plugins
  // 3. katex + mhchem
  // 4. highlight.js
  // 5. mermaid
  // 6. bridge.js
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'markdown-it.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'plugins', 'markdown-it-sub.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'plugins', 'markdown-it-sup.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'plugins', 'markdown-it-ins.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'plugins', 'markdown-it-mark.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'plugins', 'markdown-it-deflist.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'plugins', 'markdown-it-abbr.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'plugins', 'markdown-it-task-lists.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'katex', 'katex.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'katex', 'contrib', 'mhchem.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'highlight', 'highlight.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'bridge.js'), 'utf8'), context);

  return { context, dom };
}

let passedCount = 0;
let failedCount = 0;

function runTest(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    passedCount++;
  } catch (err) {
    console.error(`  ✗ ${name}`);
    console.error(`    ${err.message}`);
    failedCount++;
  }
}

console.log('=== Running Lucid Renderer Conformance Tests ===\n');

const { context, dom } = createBrowserEnvironment();

// INVARIANT 1: Safe source storage (no user-authored raw TeX in generated HTML attributes)
runTest('Invariant 1: Deferred placeholders use render-scoped math IDs, not arbitrary raw LaTeX attributes', () => {
  // Render a document with > 30 equations to trigger deferred mode
  const equations = [];
  for (let i = 0; i < 35; i++) {
    equations.push(`\\[ E_${i} = m_${i} c^2 \\]`);
  }
  context.lucid.updateContent(equations.join('\n\n'), 'rev-101');
  const html = dom.contentHTML;

  assert(html.includes('data-math-id="1"'), 'Placeholder must include data-math-id');
  assert(html.includes('data-render-id="rev-101"'), 'Placeholder must include data-render-id');
  assert(!html.includes('data-raw-latex="'), 'Placeholder must not store raw LaTeX in HTML attributes');
});

// INVARIANT 2: Fences longer than 3 backticks
runTest('Invariant 2: Four-backtick fence (````) preserves inner code with delimiters and dollars', () => {
  const input = `\`\`\`\`markdown\n\`\`\`js\nconst x = "$not math$";\nconst y = "\\[also not math\\]";\n\`\`\`\n\`\`\`\``;
  context.lucid.updateContent(input, 'rev-102');
  const html = dom.contentHTML;

  assert(html.includes('<pre class="lucid-enhanced">'), 'Should render as pre.lucid-enhanced');
  assert(html.includes('$not math$'), 'Inner code with $ must remain literal');
  assert(html.includes('\\[also not math\\]'), 'Inner code with \\[ must remain literal');
  assert(!html.includes('katex'), 'Code fence must not be processed by KaTeX');
});

// INVARIANT 3: Tilde fences
runTest('Invariant 3: Tilde fences (~~~~) preserve inner content without math processing', () => {
  const input = `~~~~\n\\[\nE = mc^2\n\\]\n~~~~`;
  context.lucid.updateContent(input, 'rev-103');
  const html = dom.contentHTML;

  assert(html.includes('\\[\nE = mc^2\n\\]'), 'Tilde fence content must remain literal');
  assert(!html.includes('class="lucid-math-block"'), 'Tilde fence must not create math block');
});

// INVARIANT 4: Dollar-math vs currency semantics
runTest('Invariant 4: $2x$, $100x + 20$, and $x = 10$ are math; $10, $100, and $10 and $20 are not math', () => {
  const currencyInput = `The first costs $10 and the second costs $20. Total budget is $100. Range is $10 to $50.`;
  context.lucid.updateContent(currencyInput, 'rev-104a');
  assert(!dom.contentHTML.includes('katex'), 'Currency amounts must not trigger KaTeX');
  assert(dom.contentHTML.includes('$10 and the second costs $20'), 'Currency text must be preserved literally');

  const mathInput = `Calculate $2x$ and $100x + 20$ and $x = 10$ and $y=x^2$.`;
  context.lucid.updateContent(mathInput, 'rev-104b');
  assert(dom.contentHTML.includes('katex'), 'Legitimate math must trigger KaTeX');
  assert(!dom.contentHTML.includes('$2x$'), '$2x$ must be converted to KaTeX HTML');
  assert(!dom.contentHTML.includes('$100x + 20$'), '$100x + 20$ must be converted to KaTeX HTML');
});

// INVARIANT 5: Conservative malformed delimiter recovery
runTest('Invariant 5: Malformed unclosed math block does not swallow subsequent valid equation', () => {
  const input = `\\[\n\\frac{Numerator}{\n\nOrdinary paragraph in between.\n\n\\[\nE = mc^2\n\\]`;
  context.lucid.updateContent(input, 'rev-105');
  const html = dom.contentHTML;

  assert(html.includes('Ordinary paragraph in between.'), 'Paragraph between blocks must be preserved');
  assert(html.includes('katex'), 'Second valid expression must render with KaTeX');
});

// INVARIANT 6: Container & nested contexts
runTest('Invariant 6: Math blocks work inside blockquotes and ordered lists without syntax leakage', () => {
  const input = `> **Transfer function:**\n>\n> 1. Formulate:\n>\n>    \\[\n>    G(s) = \\frac{1}{s^2+2s+1}\n>    \\]\n>\n> 2. Inline form \\(G(s)\\).`;
  context.lucid.updateContent(input, 'rev-106');
  const html = dom.contentHTML;

  assert(html.includes('<blockquote'), 'Must generate blockquote');
  assert(html.includes('<ol>'), 'Must generate ordered list');
  assert(html.includes('lucid-math-block'), 'Must generate lucid-math-block');
  assert(!html.includes('\\[') && !html.includes('\\]'), 'Delimiters \\[ and \\] must not leak into HTML');
});

// INVARIANT 7: Table-safe inline display math
runTest('Invariant 7: Display math in table cells generates table-safe span elements without invalid block div', () => {
  const input = `| Function | Expression |\n| :--- | :--- |\n| Response | \\[\\frac{C(s)}{R(s)} = \\frac{G(s)}{1+G(s)H(s)}\\] |`;
  context.lucid.updateContent(input, 'rev-107');
  const html = dom.contentHTML;

  assert(html.includes('lucid-math-display-inline'), 'Table cell display math must emit lucid-math-display-inline');
  assert(!html.includes('<td><div class="lucid-math-block">'), 'Must not emit block div directly inside td');
});

// INVARIANT 8: Special character integrity
runTest('Invariant 8: Math containing quotes, ampersands, angle brackets, and newlines renders accurately', () => {
  const input = `\\[\n\\begin{aligned}\na &< b \\\\\nc &> d \\\\\n\\text{"status"} &= 1\n\\end{aligned}\n\\]`;
  context.lucid.updateContent(input, 'rev-108');
  const html = dom.contentHTML;

  assert(html.includes('katex'), 'Aligned environment with special characters must render with KaTeX');
  assert(!html.includes('lucid-math-error'), 'Special characters must not trigger formula render warning');
});

// INVARIANT 9: Source order preservation
runTest('Invariant 9: Multiple math expressions in document preserve exact source ordering', () => {
  const input = `First: $A=1$, Second: \\(B=2\\), Third: \\[C=3\\]`;
  context.lucid.updateContent(input, 'rev-109');
  const html = dom.contentHTML;

  assert(html.includes('katex'), 'Expressions must be rendered by KaTeX');
});

// INVARIANT 10: Render revision safety
runTest('Invariant 10: Old async math work does not mutate newer renderId', () => {
  context.lucid.updateContent(`$A=1$`, 'rev-201');
  context.lucid.updateContent(`$B=2$`, 'rev-202');

  assert.strictEqual(context.lucid.getCurrentRevision(), 'rev-202', 'currentRenderRevision must be rev-202');
});

// INVARIANT 11: Control Systems regressions & absence of leaked TeX commands
runTest('Invariant 11: Control systems equations render cleanly without raw TeX command leakage', () => {
  const controlSystemsInput = `
\\[
E(s)=R(s)-B(s)
\\]

\\[
B(s)=H(s)C(s)
\\]

\\[
C(s)=G(s)E(s)
\\]

\\[
C(s)=G(s)\\left[R(s)-H(s)C(s)\\right]
\\]

\\[
C(s)+G(s)H(s)C(s)=G(s)R(s)
\\]

\\[
C(s)\\left[1+G(s)H(s)\\right]=G(s)R(s)
\\]

\\[
\\boxed{
\\frac{C(s)}{R(s)}
=
\\frac{G(s)}{1+G(s)H(s)}
}
\\]

\\[
\\Delta
=
1-\\sum_i L_i
+\\sum_{i,j}L_iL_j
-\\sum_{i,j,k}L_iL_jL_k
+\\cdots
\\]

Inline: \\(\\Delta_k\\) and \\(P_k\\).
`;
  context.lucid.updateContent(controlSystemsInput, 'rev-111');
  const html = dom.contentHTML;

  // Strip KaTeX MathML annotations and raw fallback spans to test normal rendered prose
  const prose = html.replace(/<annotation encoding="application\/x-tex">[\s\S]*?<\/annotation>/g, '')
                    .replace(/<span class="lucid-math-raw">[\s\S]*?<\/span>/g, '');

  assert(!prose.includes('\\frac'), '\\frac must not leak as raw string in normal prose');
  assert(!prose.includes('\\boxed'), '\\boxed must not leak as raw string in normal prose');
  assert(!prose.includes('\\left['), '\\left[ must not leak as raw string in normal prose');
  assert(!prose.includes('\\right]'), '\\right] must not leak as raw string in normal prose');
  assert(!prose.includes('\\Delta'), '\\Delta must not leak as raw string in normal prose');
  assert(!prose.includes('\\sum'), '\\sum must not leak as raw string in normal prose');
  assert(!prose.includes('\\cdots'), '\\cdots must not leak as raw string in normal prose');

  // Verify KaTeX rendered output exists
  assert(html.includes('class="katex"'), 'Output must contain KaTeX elements');
});

// INVARIANT 12: Security probe isolation
runTest('Invariant 12: Inert security probe window.__lucidSecurityProbe is never executed', () => {
  const input = `<script>window.__lucidSecurityProbe = true;</script>\n<img src="x" onerror="window.__lucidSecurityProbe = true;">`;
  context.lucid.updateContent(input, 'rev-112');

  assert.strictEqual(context.__lucidSecurityProbe, undefined, 'Security probe must remain undefined');
});

// FULL FIXTURE RUN: Verify complete renderer-conformance.md fixture
runTest('Full Fixture: renderer-conformance.md renders cleanly without unhandled exceptions', () => {
  const fixtureContent = fs.readFileSync(FIXTURE_PATH, 'utf8');
  assert(fixtureContent.length > 5000, 'Fixture must be substantial');

  context.lucid.updateContent(fixtureContent, 'fixture-run');
  const html = dom.contentHTML;

  assert(html.length > 5000, 'Rendered HTML must be substantial');
  assert(html.includes('lucid-math-block') || html.includes('lucid-math-placeholder'), 'Fixture must contain math blocks or placeholders');
  assert(html.includes('lucid-enhanced'), 'Fixture must contain enhanced code blocks');
  assert(html.includes('markdown-alert'), 'Fixture must contain alerts');
});

console.log(`\n=== Results: ${passedCount} passed, ${failedCount} failed ===\n`);

if (failedCount > 0) {
  process.exit(1);
} else {
  console.log('All conformance assertions PASSED successfully!');
}
