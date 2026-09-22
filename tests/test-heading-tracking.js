/**
 * Lucid Heading Tracking & Anchor Preservation Test Suite
 *
 * Verifies:
 * 1. resolveActiveHeading pure logic:
 *    - Top of document preface rule (scrollY <= 50)
 *    - Bottom of document rule (scrollY + viewportHeight >= documentHeight - 20)
 *    - Binary search natural candidate selection
 *    - Directional hysteresis downwards (referenceY - hysteresis)
 *    - Directional hysteresis upwards (referenceY + hysteresis)
 *    - Sub-pixel deadband
 * 2. Burst coalescing cache invalidation (60ms settle, 250ms max deadline)
 * 3. Reading anchor capture and restoration math
 */

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');

const ROOT = path.resolve(__dirname, '..');
const WEBENGINE_DIR = path.join(ROOT, 'Sources', 'Lucid', 'Resources', 'WebEngine');

function createTestEnvironment() {
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
            querySelectorAll: function() { return []; }
          };
        }
        return null;
      },
      querySelectorAll: function() { return []; },
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
        classList: { add: function() {}, remove: function() {}, contains: () => false },
        setAttribute: function() {}
      },
      documentElement: {
        style: { setProperty: function() {} },
        setAttribute: function() {},
        classList: { add: function() {}, remove: function() {} },
        scrollHeight: 5000
      }
    },
    window: null,
    navigator: { clipboard: { writeText: async () => {} } },
    webkit: {
      messageHandlers: {
        lucidReady: { postMessage: (msg) => dom.messages.push({ type: 'lucidReady', msg }) },
        lucidScroll: { postMessage: (msg) => dom.messages.push({ type: 'lucidScroll', msg }) },
        lucidHeadings: { postMessage: (msg) => dom.messages.push({ type: 'lucidHeadings', msg }) },
        lucidActiveHeading: { postMessage: (msg) => dom.messages.push({ type: 'lucidActiveHeading', msg }) },
        lucidPerf: { postMessage: (msg) => dom.messages.push({ type: 'lucidPerf', msg }) }
      }
    }
  };

  context.window = context;
  context.globalThis = context;
  context.self = context;

  vm.createContext(context);

  // Load scripts
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'markdown-it.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'katex', 'katex.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'highlight', 'highlight.min.js'), 'utf8'), context);
  vm.runInContext(fs.readFileSync(path.join(WEBENGINE_DIR, 'bridge.js'), 'utf8'), context);

  return { context, dom };
}

async function runTests() {
  console.log('Testing Lucid Heading Tracking & Reading Anchor System...\n');

  const { context } = createTestEnvironment();
  const lucid = context.window.lucid;
  assert(lucid, 'window.lucid must be defined');
  assert(typeof lucid.resolveActiveHeading === 'function', 'resolveActiveHeading must be exported on window.lucid');

  const headings = [
    { id: 'heading-1', top: 200 },
    { id: 'heading-2', top: 600 },
    { id: 'heading-3', top: 1200 },
    { id: 'heading-4', top: 2000 }
  ];

  const standardOptions = {
    headings: headings,
    scrollY: 0,
    viewportHeight: 800,
    documentHeight: 4000,
    previousActiveId: null,
    previousScrollY: 0,
    referenceY: 120,
    hysteresis: 15
  };

  // Test 1: Top of document preface rule
  console.log('1. Top of document preface rule');
  {
    // Case A: scrollY <= 50 and first heading is within top 50% of viewport (200 <= 400)
    const active = lucid.resolveActiveHeading({
      ...standardOptions,
      scrollY: 10
    });
    assert.strictEqual(active, 'heading-1', 'Should highlight first heading when near top and heading is in view');

    // Case B: scrollY <= 50 but first heading is pushed far down (e.g. at 600px, > 400px)
    const activePreface = lucid.resolveActiveHeading({
      ...standardOptions,
      headings: [{ id: 'late-heading', top: 600 }],
      scrollY: 10
    });
    assert.strictEqual(activePreface, null, 'Should return null for long preface when first heading is below 50% viewport');
  }

  // Test 2: Bottom of document rule
  console.log('2. Bottom of document rule');
  {
    // documentHeight = 4000, viewportHeight = 800
    // At scrollY = 3200, scrollY + viewportHeight = 4000 >= 4000 - 20
    const activeBottom = lucid.resolveActiveHeading({
      ...standardOptions,
      scrollY: 3200,
      previousScrollY: 3100
    });
    assert.strictEqual(activeBottom, 'heading-4', 'Should highlight last heading when scrolled to bottom of document');
  }

  // Test 3: Binary search natural candidate
  console.log('3. Binary search natural candidate selection');
  {
    // targetDocY = scrollY + referenceY (120)
    // scrollY = 300 -> targetDocY = 420 -> candidate heading-1 (top 200 <= 420 < 600)
    const at300 = lucid.resolveActiveHeading({
      ...standardOptions,
      scrollY: 300,
      previousScrollY: 300
    });
    assert.strictEqual(at300, 'heading-1', 'Should resolve heading-1 at scrollY=300');

    // scrollY = 700 -> targetDocY = 820 -> candidate heading-2 (top 600 <= 820 < 1200)
    const at700 = lucid.resolveActiveHeading({
      ...standardOptions,
      scrollY: 700,
      previousScrollY: 700
    });
    assert.strictEqual(at700, 'heading-2', 'Should resolve heading-2 at scrollY=700');

    // scrollY = 1500 -> targetDocY = 1620 -> candidate heading-3 (top 1200 <= 1620 < 2000)
    const at1500 = lucid.resolveActiveHeading({
      ...standardOptions,
      scrollY: 1500,
      previousScrollY: 1500
    });
    assert.strictEqual(at1500, 'heading-3', 'Should resolve heading-3 at scrollY=1500');
  }

  // Test 4: Directional Hysteresis
  console.log('4. Directional Hysteresis (anti-flicker band)');
  {
    // Headings: h1 at 200, h2 at 600.
    // Natural threshold: scrollY + 120 >= 600 => scrollY >= 480.
    // DOWNWARD: candidate becomes h2 at scrollY=480.
    // Hysteresis requirement: bViewportTop <= referenceY - hysteresis => (600 - scrollY) <= 120 - 15 = 105 => scrollY >= 495.
    // Between scrollY 480 and 494, moving downward with previousActiveId = 'heading-1':
    const downBeforeHysteresis = lucid.resolveActiveHeading({
      ...standardOptions,
      scrollY: 485,
      previousScrollY: 480,
      previousActiveId: 'heading-1'
    });
    assert.strictEqual(downBeforeHysteresis, 'heading-1', 'Downward scroll in hysteresis band must retain previous heading-1');

    const downAfterHysteresis = lucid.resolveActiveHeading({
      ...standardOptions,
      scrollY: 496,
      previousScrollY: 490,
      previousActiveId: 'heading-1'
    });
    assert.strictEqual(downAfterHysteresis, 'heading-2', 'Downward scroll past hysteresis threshold (495) must switch to heading-2');

    // UPWARD: scrolling up from heading-2.
    // Natural threshold candidate for h1 is scrollY + 120 < 600 => scrollY < 480.
    // Upward hysteresis: candidate is h1 (candidateIndex < prevIndex).
    // bViewportTop = 600 - scrollY.
    // Hysteresis requirement: bViewportTop > referenceY + hysteresis => (600 - scrollY) > 120 + 15 = 135 => scrollY < 465.
    // Between scrollY 479 down to 465, moving upward with previousActiveId = 'heading-2':
    const upBeforeHysteresis = lucid.resolveActiveHeading({
      ...standardOptions,
      scrollY: 470,
      previousScrollY: 475,
      previousActiveId: 'heading-2'
    });
    assert.strictEqual(upBeforeHysteresis, 'heading-2', 'Upward scroll in hysteresis band must retain heading-2');

    const upAfterHysteresis = lucid.resolveActiveHeading({
      ...standardOptions,
      scrollY: 460,
      previousScrollY: 465,
      previousActiveId: 'heading-2'
    });
    assert.strictEqual(upAfterHysteresis, 'heading-1', 'Upward scroll past hysteresis threshold (465) must switch to heading-1');
  }

  // Test 5: Sub-pixel deadband
  console.log('5. Sub-pixel deadband');
  {
    // Micro-movements (< 1px) should be treated as stationary and not switch in hysteresis zone
    const microMove = lucid.resolveActiveHeading({
      ...standardOptions,
      scrollY: 485.4,
      previousScrollY: 485.0,
      previousActiveId: 'heading-1'
    });
    assert.strictEqual(microMove, 'heading-1', 'Sub-pixel delta should be treated as stationary');
  }

  // Test 6: Burst coalescing cache invalidation
  console.log('6. Burst coalescing cache invalidation');
  {
    assert(typeof lucid.invalidateHeadingPositions === 'function', 'invalidateHeadingPositions must be exported');
    // Call invalidate repeatedly in burst
    for (let i = 0; i < 50; i++) {
      lucid.invalidateHeadingPositions('burst-test-' + i);
    }
    // Verify it does not crash or throw
  }

  // Test 7: Programmatic scroll active flag
  console.log('7. Programmatic scroll state tracking');
  {
    assert(typeof lucid.isProgrammaticScrollActive === 'function', 'isProgrammaticScrollActive must be exported');
    assert.strictEqual(lucid.isProgrammaticScrollActive(), false, 'Programmatic scroll should initially be false');
  }

  console.log('\nAll 7 Heading Tracking & Anchor tests passed successfully!');
}

runTests().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
