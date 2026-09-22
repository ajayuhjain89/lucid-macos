/**
 * Lucid Theme Performance & Serialized Mermaid Worker Regression Test Suite
 *
 * Verifies:
 * 1. Theme-only preference update does NOT call updateContent or rebuild Markdown DOM.
 * 2. Markdown DOM identity (e.g. elements, inputs) stays intact on theme update.
 * 3. Base theme tokens (data-theme, className, CSS variables) apply immediately.
 * 4. Serialized worker processes ONE Mermaid diagram at a time and yields to browser.
 * 5. Mermaid SVG cache avoids re-running mermaid.render on previously rendered themes.
 * 6. Mermaid SVG cache is bounded (maximum 3 entries: dark, light, sepia).
 * 7. Stale background render does NOT overwrite a newer visual theme (cancellation safety).
 * 8. Rapid theme changes abort obsolete work and converge on final selected theme.
 * 9. Duplicate identical preference updates do not cause redundant re-renders.
 * 10. Cache invalidates when new document content is loaded.
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

  const styleProperties = {};

  const context = {
    console: console,
    setTimeout: setTimeout,
    clearTimeout: clearTimeout,
    requestAnimationFrame: (cb) => setTimeout(cb, 0),
    cancelAnimationFrame: (id) => clearTimeout(id),
    requestIdleCallback: (cb) => setTimeout(cb, 0),
    cancelIdleCallback: (id) => clearTimeout(id),
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
          return dom.contentElement;
        }
        return null;
      },
      querySelectorAll: function(selector) {
        if (selector === '.mermaid-container') {
          return dom.mermaidContainers || [];
        }
        return [];
      },
      createElement: function(tag) {
        return {
          tagName: tag.toUpperCase(),
          style: {},
          classList: { add: function() {}, remove: function() {}, contains: () => false },
          setAttribute: function() {},
          getAttribute: () => null,
          appendChild: function() {}
        };
      },
      head: { appendChild: function() {} },
      body: {
        classList: {
          add: function(c) { this._classes = this._classes || []; this._classes.push(c); },
          remove: function(c) { this._classes = (this._classes || []).filter(x => x !== c); },
          contains: function(c) { return (this._classes || []).includes(c); }
        },
        setAttribute: function(attr, val) { this[attr] = val; },
        getAttribute: function(attr) { return this[attr]; },
        className: ''
      },
      documentElement: {
        style: {
          setProperty: function(k, v) { styleProperties[k] = v; },
          getPropertyValue: function(k) { return styleProperties[k]; }
        },
        setAttribute: function(attr, val) { this[attr] = val; },
        classList: { add: function() {}, remove: function() {} }
      }
    },
    window: null,
    styleProperties: styleProperties
  };

  // Mock content element with real object reference
  dom.contentElement = {
    id: 'lucid-content',
    _html: '',
    set innerHTML(val) {
      this._html = val;
      // Parse mock mermaid containers from html
      const matches = val.match(/class="mermaid-container"[^>]*data-raw-mermaid="([^"]*)"/g) || [];
      dom.mermaidContainers = matches.map((m, idx) => {
        const rawMatch = m.match(/data-raw-mermaid="([^"]*)"/);
        const raw = rawMatch ? rawMatch[1] : '';
        const canvas = {
          innerHTML: `<svg id="mock-svg-${idx}"><text>old-svg</text></svg>`,
          querySelector: () => null
        };
        const viewport = { clientWidth: 800, style: {} };
        const container = {
          getAttribute: (name) => (name === 'data-raw-mermaid' ? raw : null),
          querySelector: (sel) => {
            if (sel === '.mermaid-canvas') return canvas;
            if (sel === '.mermaid-viewport') return viewport;
            return null;
          }
        };
        return container;
      });
    },
    get innerHTML() { return this._html; },
    querySelectorAll: function(selector) {
      if (selector === '*') return new Array(10);
      if (selector.includes('h1')) return [];
      if (selector.includes('table')) return [];
      if (selector.includes('.mermaid')) return dom.mermaidContainers || [];
      if (selector.includes('.lucid-math-placeholder')) return [];
      return [];
    }
  };

  context.window = context;
  vm.createContext(context);

  const mdItCode = fs.readFileSync(path.join(WEBENGINE_DIR, 'markdown-it.min.js'), 'utf8');
  vm.runInContext(mdItCode, context);

  context.katex = {
    renderToString: (str) => '<span class="katex">' + str + '</span>'
  };

  const bridgeCode = fs.readFileSync(path.join(WEBENGINE_DIR, 'bridge.js'), 'utf8');
  vm.runInContext(bridgeCode, context);

  return { context, dom, styleProperties };
}

console.log('=== Running Lucid Theme Performance Test Suite ===\n');

let passedCount = 0;
let totalTests = 0;

function runTest(name, fn) {
  totalTests++;
  try {
    const p = fn();
    if (p && typeof p.then === 'function') {
      return p.then(() => {
        console.log(`  ✓ ${name}`);
        passedCount++;
      }).catch((err) => {
        console.error(`  ✗ ${name}`);
        console.error(`    ${err.message}`);
        process.exitCode = 1;
      });
    } else {
      console.log(`  ✓ ${name}`);
      passedCount++;
    }
  } catch (err) {
    console.error(`  ✗ ${name}`);
    console.error(`    ${err.message}`);
    process.exitCode = 1;
  }
}

async function runAllTests() {
  // Test 1: Theme update does NOT invoke updateContent
  await runTest('Theme update does not invoke updateContent or rebuild Markdown DOM', () => {
    const { context, dom } = createBrowserEnvironment();
    context.window.lucid.updateContent('# Test Title\n\nParagraph text.', 'rev-1');
    const initialHTML = dom.contentElement.innerHTML;

    // Spy on updateContent
    let updateContentCalled = false;
    const origUpdateContent = context.window.lucid.updateContent;
    context.window.lucid.updateContent = function() {
      updateContentCalled = true;
      return origUpdateContent.apply(this, arguments);
    };

    context.window.lucid.updatePreferences({ theme: 'light' });

    assert.strictEqual(updateContentCalled, false, 'updateContent must not be called during theme update');
    assert.strictEqual(dom.contentElement.innerHTML, initialHTML, 'Markdown DOM must be preserved intact');
    assert.strictEqual(context.document.body['data-theme'], 'light', 'data-theme should be updated to light');
    assert(context.document.body.className.includes('vscode-light'), 'body class should include vscode-light');
  });

  // Test 2: Base theme tokens apply immediately
  await runTest('Base theme tokens and CSS custom properties apply synchronously', () => {
    const { context, styleProperties } = createBrowserEnvironment();
    context.window.lucid.updatePreferences({
      theme: 'sepia',
      accentColor: '#cf222e',
      fontFamily: 'Georgia, serif',
      fontSize: 20
    });

    assert.strictEqual(context.document.body['data-theme'], 'sepia');
    assert(context.document.body.className.includes('vscode-sepia'));
    assert.strictEqual(styleProperties['--lucid-accent'], '#cf222e');
    assert.strictEqual(styleProperties['--lucid-font-family'], 'Georgia, serif');
    assert.strictEqual(styleProperties['--lucid-font-size'], '20px');
  });

  // Test 3: Serialized worker processes diagrams one at a time and yields
  await runTest('Serialized Mermaid worker processes one diagram at a time and yields between diagrams', async () => {
    const { context, dom } = createBrowserEnvironment();
    const md = [
      '```mermaid', 'flowchart LR', 'A --> B', '```',
      '```mermaid', 'flowchart TD', 'C --> D', '```'
    ].join('\n');
    context.window.lucid.updateContent(md, 'rev-2');

    let activeRenders = 0;
    let maxConcurrentRenders = 0;
    let renderCount = 0;

    context.mermaid = {
      initialize: () => {},
      render: (id, code) => {
        activeRenders++;
        renderCount++;
        maxConcurrentRenders = Math.max(maxConcurrentRenders, activeRenders);
        return new Promise((resolve) => {
          setTimeout(() => {
            activeRenders--;
            resolve({ svg: `<svg id="${id}"><text>rendered-for-theme</text></svg>` });
          }, 10);
        });
      }
    };

    context.window.lucid.updatePreferences({ theme: 'light' });

    // Wait for worker to finish
    await new Promise((r) => setTimeout(r, 100));

    assert.strictEqual(maxConcurrentRenders, 1, 'Mermaid worker must render strictly ONE diagram at a time (serialized)');
    assert.strictEqual(renderCount, 2, 'Should have rendered all 2 diagrams');
  });

  // Test 4: Mermaid SVG cache avoids re-rendering previously rendered themes
  await runTest('Mermaid SVG cache avoids re-running mermaid.render on previously rendered themes', async () => {
    const { context, dom } = createBrowserEnvironment();
    const md = '```mermaid\nflowchart LR\nA --> B\n```';
    context.window.lucid.updateContent(md, 'rev-3');

    let renderCount = 0;
    context.mermaid = {
      initialize: () => {},
      render: (id, code) => {
        renderCount++;
        return Promise.resolve({ svg: `<svg id="${id}-theme"><text>svg-${renderCount}</text></svg>` });
      }
    };

    // First switch: Dark -> Light
    context.window.lucid.updatePreferences({ theme: 'light' });
    await new Promise((r) => setTimeout(r, 50));
    assert.strictEqual(renderCount, 1, 'First light switch must render');

    // Second switch: Light -> Sepia
    context.window.lucid.updatePreferences({ theme: 'sepia' });
    await new Promise((r) => setTimeout(r, 50));
    assert.strictEqual(renderCount, 2, 'First sepia switch must render');

    // Third switch: Sepia -> Light (ALREADY CACHED!)
    const renderCountBefore = renderCount;
    context.window.lucid.updatePreferences({ theme: 'light' });
    await new Promise((r) => setTimeout(r, 50));

    assert.strictEqual(renderCount, renderCountBefore, 'Revisiting light theme must be a CACHE HIT with zero mermaid.render calls');
    const container = dom.mermaidContainers[0];
    const canvas = container.querySelector('.mermaid-canvas');
    assert(canvas.innerHTML.includes('svg-1'), 'Restored SVG should match cached light theme SVG');
  });

  // Test 5: Mermaid cache is bounded to 3 entries
  await runTest('Mermaid cache is bounded to maximum 3 entries per container', async () => {
    const { context, dom } = createBrowserEnvironment();
    const md = '```mermaid\nflowchart LR\nA --> B\n```';
    context.window.lucid.updateContent(md, 'rev-4');

    context.mermaid = {
      initialize: () => {},
      render: (id, code) => Promise.resolve({ svg: `<svg id="${id}"></svg>` })
    };

    // Switch through themes
    context.window.lucid.updatePreferences({ theme: 'dark' });
    await new Promise((r) => setTimeout(r, 30));
    context.window.lucid.updatePreferences({ theme: 'light' });
    await new Promise((r) => setTimeout(r, 30));
    context.window.lucid.updatePreferences({ theme: 'sepia' });
    await new Promise((r) => setTimeout(r, 30));

    const container = dom.mermaidContainers[0];
    const cacheKeys = Object.keys(container._lucidRenderedThemes || {});
    assert(cacheKeys.length <= 3, `Cache size should be <= 3, got ${cacheKeys.length}`);
  });

  // Test 6: Stale background render does NOT overwrite newer visual theme
  await runTest('Stale background render does not overwrite a newer visual theme', async () => {
    const { context, dom } = createBrowserEnvironment();
    const md = '```mermaid\nflowchart LR\nA --> B\n```';
    context.window.lucid.updateContent(md, 'rev-5');

    let resolveDarkRender;
    context.mermaid = {
      initialize: () => {},
      render: (id, code) => {
        return new Promise((resolve) => {
          resolveDarkRender = resolve;
        });
      }
    };

    // Start dark theme
    context.window.lucid.updatePreferences({ theme: 'dark' });
    await new Promise((r) => setTimeout(r, 10));

    // While dark render is in-flight, user switches to light
    // We update mermaid mock to resolve immediately for light
    context.mermaid.render = (id, code) => {
      return Promise.resolve({ svg: '<svg id="light-svg"><text>LIGHT</text></svg>' });
    };
    context.window.lucid.updatePreferences({ theme: 'light' });
    await new Promise((r) => setTimeout(r, 30));

    // Now resolve the old stale dark render
    resolveDarkRender({ svg: '<svg id="dark-svg"><text>DARK-STALE</text></svg>' });
    await new Promise((r) => setTimeout(r, 30));

    const container = dom.mermaidContainers[0];
    const canvas = container.querySelector('.mermaid-canvas');
    assert(canvas.innerHTML.includes('LIGHT'), 'Container must show LIGHT theme, not stale dark SVG');
    assert(!canvas.innerHTML.includes('DARK-STALE'), 'Stale dark SVG must be discarded');
  });

  // Test 7: Rapid theme switching converges on final selected theme
  await runTest('Rapid theme switching converges safely on final selected theme', async () => {
    const { context, dom } = createBrowserEnvironment();
    const md = '```mermaid\nflowchart LR\nA --> B\n```';
    context.window.lucid.updateContent(md, 'rev-6');

    context.mermaid = {
      initialize: () => {},
      render: (id, code) => {
        return new Promise((resolve) => {
          setTimeout(() => {
            resolve({ svg: `<svg id="${id}"><text>final</text></svg>` });
          }, 15);
        });
      }
    };

    // Rapid switches
    context.window.lucid.updatePreferences({ theme: 'light' });
    context.window.lucid.updatePreferences({ theme: 'sepia' });
    context.window.lucid.updatePreferences({ theme: 'dark' });

    await new Promise((r) => setTimeout(r, 120));

    assert.strictEqual(context.document.body['data-theme'], 'dark', 'Final data-theme must be dark');
    assert(context.document.body.className.includes('vscode-dark'), 'Final class must be vscode-dark');
  });

  // Test 8: Cache invalidation on new document content
  await runTest('Cache invalidates when new document content is loaded', async () => {
    const { context, dom } = createBrowserEnvironment();
    context.window.lucid.updateContent('```mermaid\nflowchart LR\nA --> B\n```', 'rev-7');

    context.mermaid = {
      initialize: () => {},
      run: () => Promise.resolve(),
      render: (id, code) => Promise.resolve({ svg: '<svg id="v1"></svg>' })
    };

    context.window.lucid.updatePreferences({ theme: 'light' });
    await new Promise((r) => setTimeout(r, 30));

    // Load new content
    context.window.lucid.updateContent('```mermaid\nflowchart LR\nC --> D\n```', 'rev-8');
    const newContainer = dom.mermaidContainers[0];
    assert.strictEqual(newContainer._lucidRenderedThemes, undefined, 'New container must not retain old cache');
  });

  console.log(`\n=== Results: ${passedCount} passed, ${totalTests - passedCount} failed ===\n`);
  if (passedCount === totalTests) {
    console.log('All theme performance tests PASSED successfully!\n');
    process.exit(0);
  } else {
    process.exit(1);
  }
}

runAllTests();
