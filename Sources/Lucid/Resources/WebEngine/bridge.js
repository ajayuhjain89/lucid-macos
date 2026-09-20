(function() {
  const ALERT_ICONS = {
    note: '<svg viewBox="0 0 16 16"><path d="M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8Zm8-6.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13ZM6.5 7.75A.75.75 0 0 1 7.25 7h1a.75.75 0 0 1 .75.75v2.75h.25a.75.75 0 0 1 0 1.5h-2.5a.75.75 0 0 1 0-1.5h.25v-2h-.25a.75.75 0 0 1-.75-.75ZM8 6a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"></path></svg>',
    tip: '<svg viewBox="0 0 16 16"><path d="M8 1.5c-2.363 0-4 1.69-4 3.75 0 .984.424 1.625.984 2.304l.214.253c.223.264.47.556.673.848.284.411.537.896.621 1.49a.75.75 0 0 1-1.484.211c-.04-.282-.163-.547-.37-.847a8.456 8.456 0 0 0-.542-.68c-.09-.106-.188-.22-.294-.346C3.12 7.677 2.5 6.75 2.5 5.25 2.5 2.31 4.97 0 8 0s5.5 2.31 5.5 5.25c0 1.5-.62 2.427-1.306 3.238-.106.126-.204.24-.294.346-.176.208-.356.42-.542.68-.207.3-.33.565-.37.847a.75.75 0 0 1-1.485-.212c.084-.593.337-1.078.621-1.489.203-.292.45-.584.673-.848.075-.088.147-.173.213-.253.561-.679.985-1.32.985-2.304 0-2.06-1.637-3.75-4-3.75ZM5.75 12h4.5a.75.75 0 0 1 0 1.5h-4.5a.75.75 0 0 1 0-1.5Zm1 3h2.5a.75.75 0 0 1 0 1.5h-2.5a.75.75 0 0 1 0-1.5Z"></path></svg>',
    important: '<svg viewBox="0 0 16 16"><path d="M0 1.75C0 .784.784 0 1.75 0h12.5C15.216 0 16 .784 16 1.75v9.5A1.75 1.75 0 0 1 14.25 13H9.06l-2.573 2.573A1.458 1.458 0 0 1 4 14.543V13H1.75A1.75 1.75 0 0 1 0 11.25Zm1.75-.25a.25.25 0 0 0-.25.25v9.5c0 .138.112.25.25.25h2.5a.75.75 0 0 1 .75.75v2.19l2.72-2.72a.749.749 0 0 1 .53-.22h6.5a.25.25 0 0 0 .25-.25v-9.5a.25.25 0 0 0-.25-.25Zm7 2.25v2.5a.75.75 0 0 1-1.5 0v-2.5a.75.75 0 0 1 1.5 0ZM9 9a1 1 0 1 1-2 0 1 1 0 0 1 2 0Z"></path></svg>',
    warning: '<svg viewBox="0 0 16 16"><path d="M6.457 1.047c.659-1.234 2.427-1.234 3.086 0l6.082 11.378A1.75 1.75 0 0 1 14.082 15H1.918a1.75 1.75 0 0 1-1.543-2.575Zm1.763.707a.25.25 0 0 0-.44 0L1.698 13.132a.25.25 0 0 0 .22.368h12.164a.25.25 0 0 0 .22-.368Zm.53 3.996v2.5a.75.75 0 0 1-1.5 0v-2.5a.75.75 0 0 1 1.5 0ZM9 11a1 1 0 1 1-2 0 1 1 0 0 1 2 0Z"></path></svg>',
    caution: '<svg viewBox="0 0 16 16"><path d="M4.47.22A.749.749 0 0 1 5 0h6c.199 0 .389.079.53.22l4.25 4.25c.141.14.22.331.22.53v6a.749.749 0 0 1-.22.53l-4.25 4.25A.749.749 0 0 1 11 16H5a.749.749 0 0 1-.53-.22L.22 11.53A.749.749 0 0 1 0 11V5c0-.199.079-.389.22-.53Zm.84 1.28L1.5 5.31v5.38l3.81 3.81h5.38l3.81-3.81V5.31L10.69 1.5ZM8 4a.75.75 0 0 1 .75.75v3.5a.75.75 0 0 1-1.5 0v-3.5A.75.75 0 0 1 8 4Zm0 8a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"></path></svg>',
    example: '<svg viewBox="0 0 16 16"><path d="M1.5 1.75a.25.25 0 0 1 .25-.25h12.5a.25.25 0 0 1 .25.25v12.5a.25.25 0 0 1-.25.25H1.75a.25.25 0 0 1-.25-.25ZM1.75 0A1.75 1.75 0 0 0 0 1.75v12.5C0 15.216.784 16 1.75 16h12.5A1.75 1.75 0 0 0 16 14.25V1.75A1.75 1.75 0 0 0 14.25 0Zm9.28 10.28a.75.75 0 0 0-1.06-1.06L7 12.19l-1.72-1.72a.75.75 0 0 0-1.06 1.06l2.25 2.25a.75.75 0 0 0 1.06 0Z"></path></svg>',
    question: '<svg viewBox="0 0 16 16"><path d="M8 0a8 8 0 1 0 0 16A8 8 0 0 0 8 0Zm.93 11.588H7.07v-1.636h1.86v1.636Zm.03-3.053H7.062c.004-.848.243-1.464.717-1.848.475-.383 1.15-.79 2.025-1.22.614-.3.993-.728.993-1.282 0-.616-.484-1.082-1.242-1.082-.72 0-1.24.436-1.332 1.144L6.46 3.99C6.67 2.477 7.79 1.5 9.54 1.5c1.71 0 2.87.973 2.87 2.378 0 1.047-.63 1.766-1.57 2.274-.63.34-.95.666-.98 1.026v.357Z"></path></svg>',
    quote: '<svg viewBox="0 0 16 16"><path d="M1.75 2.5a.75.75 0 0 0 0 1.5h12.5a.75.75 0 0 0 0-1.5H1.75Zm0 5a.75.75 0 0 0 0 1.5h8.5a.75.75 0 0 0 0-1.5H1.75Zm0 5a.75.75 0 0 0 0 1.5h12.5a.75.75 0 0 0 0-1.5H1.75Z"></path></svg>',
    abstract: '<svg viewBox="0 0 16 16"><path d="M2 3.75C2 2.784 2.784 2 3.75 2h8.5c.966 0 1.75.784 1.75 1.75v8.5A1.75 1.75 0 0 1 12.25 14h-8.5A1.75 1.75 0 0 1 2 12.25Zm1.75-.25a.25.25 0 0 0-.25.25v8.5c0 .138.112.25.25.25h8.5a.25.25 0 0 0 .25-.25v-8.5a.25.25 0 0 0-.25-.25Z"></path></svg>',
    bug: '<svg viewBox="0 0 16 16"><path d="M4.72 3.22a.75.75 0 0 1 1.06 1.06L4.81 5.25h6.38l-.97-.97a.75.75 0 0 1 1.06-1.06l2.25 2.25a.75.75 0 0 1 0 1.06l-2.25 2.25a.75.75 0 1 1-1.06-1.06l.97-.97H4.81l.97.97a.75.75 0 0 1-1.06 1.06L2.47 6.53a.75.75 0 0 1 0-1.06l2.25-2.25Z"></path></svg>',
    info: '<svg viewBox="0 0 16 16"><path d="M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8Zm8-6.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13ZM6.5 7.75A.75.75 0 0 1 7.25 7h1a.75.75 0 0 1 .75.75v2.75h.25a.75.75 0 0 1 0 1.5h-2.5a.75.75 0 0 1 0-1.5h.25v-2h-.25a.75.75 0 0 1-.75-.75ZM8 6a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"></path></svg>',
    success: '<svg viewBox="0 0 16 16"><path d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.751.751 0 0 1 .018-1.042.751.751 0 0 1 1.042-.018L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0Z"></path></svg>',
    failure: '<svg viewBox="0 0 16 16"><path d="M3.72 3.72a.75.75 0 0 1 1.06 0L8 6.94l3.22-3.22a.749.749 0 0 1 1.275.326.749.749 0 0 1-.215.734L9.06 8l3.22 3.22a.749.749 0 0 1-.326 1.275.749.749 0 0 1-.734-.215L8 9.06l-3.22 3.22a.751.751 0 0 1-1.042-.018.751.751 0 0 1-.018-1.042L6.94 8 3.72 4.78a.75.75 0 0 1 0-1.06Z"></path></svg>'
  };

  // Performance instrumentation
  const LucidPerf = {
    enabled: true,
    mark: function(renderId, phase, data) {
      if (!this.enabled) return;
      const t = performance.now();
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidPerf) {
        window.webkit.messageHandlers.lucidPerf.postMessage({
          renderId: String(renderId || '0'),
          phase: phase,
          t: t,
          data: data || {}
        });
      }
    }
  };
  window.LucidPerf = LucidPerf;

  // Initialize Markdown-it
  const md = window.markdownit({
    html: true,
    linkify: true,
    typographer: true,
    highlight: function(str, lang) {
      if (lang === 'mermaid') {
        const escapedRaw = encodeURIComponent(str);
        return '<div class="mermaid-container" data-raw-mermaid="' + escapedRaw + '">' +
               '<div class="mermaid-toolbar">' +
               '<button class="lucid-mermaid-btn lucid-btn-pan" title="Pan Tool" onclick="window.lucid.togglePan(this)"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 11V6a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v0M14 10V4a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v2M10 10.5V6a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v8M6 14v-1.5a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v4a8 8 0 0 0 8 8h2a8 8 0 0 0 8-8v-3a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2"/></svg></button>' +
               '<button class="lucid-mermaid-btn" title="Zoom In" onclick="window.lucid.zoomDiagram(this, 1.15)">+</button>' +
               '<button class="lucid-mermaid-btn" title="Zoom Out" onclick="window.lucid.zoomDiagram(this, 0.87)">−</button>' +
               '<button class="lucid-mermaid-btn" title="Fit to Viewport" onclick="window.lucid.fitDiagram(this)">Fit</button>' +
               '<button class="lucid-mermaid-btn" title="Reset to Initial View" onclick="window.lucid.resetDiagram(this)">Reset</button>' +
               '<button class="lucid-mermaid-btn lucid-btn-expand" title="Expand Fullscreen" onclick="window.lucid.expandDiagram(this)"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/></svg></button>' +
               '<span class="mermaid-toolbar-sep"></span>' +
               '<button class="lucid-mermaid-btn" title="Copy SVG" onclick="window.lucid.copySvg(this)">Copy SVG</button>' +
               '<button class="lucid-mermaid-btn" title="Export SVG…" onclick="window.lucid.saveSvg(this)">Export SVG…</button>' +
               '</div>' +
               '<div class="mermaid-viewport" onmousedown="window.lucid.handleDiagramMouseDown(event, this)">' +
               '<div class="mermaid-canvas">' +
               '<div class="mermaid">' + md.utils.escapeHtml(str) + '</div>' +
               '</div>' +
               '</div>' +
               '</div>';
      }

      let highlighted = '';
      if (lang && typeof hljs !== 'undefined' && hljs.getLanguage(lang)) {
        try {
          highlighted = hljs.highlight(str, { language: lang, ignoreIllegals: true }).value;
        } catch (__) {
          highlighted = md.utils.escapeHtml(str);
        }
      } else {
        highlighted = md.utils.escapeHtml(str);
      }

      const isPlainText = !lang || lang.toLowerCase() === 'text' || lang.toLowerCase() === 'plain';
      const langLabel = isPlainText ? '' : lang.toUpperCase();

      // ASCII Diagram detection
      const isAsciiDiagram = isPlainText && /[\u2500-\u257F\u2580-\u259F\u2190-\u2193\+\-\|]{4,}/.test(str);
      const lines = str.split('\n');
      const maxLineLen = lines.reduce((max, l) => Math.max(max, l.length), 0);
      const isWide = maxLineLen > 68;

      let classes = ['lucid-enhanced'];
      if (isAsciiDiagram) classes.push('lucid-ascii-diagram');
      if (isWide) classes.push('lucid-wide');

      return '<pre class="' + classes.join(' ') + '">' +
             '<div class="lucid-codebar">' +
             (langLabel ? '<span class="lucid-lang">' + langLabel + '</span>' : '<span></span>') +
             '<button class="lucid-copy" type="button" onclick="window.lucid.copyCode(this)">Copy</button>' +
             '</div>' +
             '<code class="hljs language-' + md.utils.escapeHtml(lang || '') + '">' + highlighted + '</code>' +
             '</pre>';
    }
  });

  if (window.markdownitSub) md.use(window.markdownitSub);
  if (window.markdownitSup) md.use(window.markdownitSup);
  if (window.markdownitIns) md.use(window.markdownitIns);
  if (window.markdownitMark) md.use(window.markdownitMark);
  if (window.markdownitDeflist) md.use(window.markdownitDeflist);
  if (window.markdownitAbbr) md.use(window.markdownitAbbr);
  if (window.markdownitTaskList) md.use(window.markdownitTaskList, { enabled: true });

  function slugify(text) {
    return text.toLowerCase().trim()
      .replace(/[^\w\s-]/g, '')
      .replace(/[\s_-]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  md.core.ruler.push('lucid-heading-ids', function(state) {
    for (let i = 0; i < state.tokens.length; i++) {
      if (state.tokens[i].type === 'heading_open') {
        const next = state.tokens[i + 1];
        if (next && next.type === 'inline') {
          const id = slugify(next.content);
          state.tokens[i].attrSet('id', id);
        }
      }
    }
  });

  function parseAlerts(html) {
    const alertRegex = /<blockquote>\s*<p>\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION|EXAMPLE|QUESTION|QUOTE|ABSTRACT|BUG|INFO|SUCCESS|FAILURE)\]([+-]?)(?:\s*([^\n<]*))?(?:\s*<br\s*\/?>)?([\s\S]*?)<\/p>\s*([\s\S]*?)<\/blockquote>/gi;
    return html.replace(alertRegex, function(match, type, collapseFlag, customTitle, firstLine, rest) {
      const alertType = type.toLowerCase();
      const icon = ALERT_ICONS[alertType] || ALERT_ICONS.note;
      const titleText = customTitle && customTitle.trim() ? customTitle.trim() : alertType;
      const content = (firstLine && firstLine.trim() ? '<p>' + firstLine.trim() + '</p>' : '') + rest;
      const titleHtml = '<div class="markdown-alert-title"><span class="markdown-alert-icon">' + icon + '</span>' + titleText + '</div>';

      if (collapseFlag === '-' || collapseFlag === '+') {
        const isOpen = collapseFlag === '+' ? ' open' : '';
        return '<details class="markdown-alert markdown-alert-' + alertType + '"' + isOpen + '>' +
               '<summary>' + titleHtml + '</summary>' +
               '<div class="markdown-alert-content">' + content + '</div>' +
               '</details>';
      }

      return '<blockquote class="markdown-alert markdown-alert-' + alertType + '">' +
             titleHtml +
             '<div class="markdown-alert-content">' + content + '</div>' +
             '</blockquote>';
    });
  }

  // Simple Bounded LRU Cache
  function SimpleLRU(maxEntries) {
    this.max = maxEntries || 60;
    this.cache = new Map();
  }
  SimpleLRU.prototype.get = function(key) {
    if (!this.cache.has(key)) return null;
    const val = this.cache.get(key);
    this.cache.delete(key);
    this.cache.set(key, val);
    return val;
  };
  SimpleLRU.prototype.set = function(key, val) {
    if (this.cache.has(key)) this.cache.delete(key);
    else if (this.cache.size >= this.max) {
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }
    this.cache.set(key, val);
  };
  SimpleLRU.prototype.clear = function() {
    this.cache.clear();
  };

  let currentRenderRevision = '0';
  const katexLRU = new SimpleLRU(500);
  const mermaidLRU = new SimpleLRU(50);
  let currentMermaidTheme = 'neutral';

  function ensureMermaidInitialized() {
    if (typeof mermaid !== 'undefined' && !mermaid._lucidInitialized) {
      try {
        mermaid.initialize({
          startOnLoad: false,
          theme: currentMermaidTheme || 'neutral',
          securityLevel: 'loose',
          layout: 'dagre',
          flowchart: { defaultRenderer: 'dagre' }
        });
        mermaid._lucidInitialized = true;
      } catch (e) {
        console.warn('Failed to initialize Mermaid:', e);
      }
    }
  }

  function countMathExpressions(text) {
    if (!text || typeof katex === 'undefined' || text.indexOf('$') === -1) return 0;
    const codeRegex = /(```[\s\S]*?```|~~~[\s\S]*?~~~|`+[^`\n]+?`+)/g;
    const stripped = text.replace(codeRegex, '');
    const dispMatches = stripped.match(/\$\$[\s\S]+?\$\$/g);
    const inlineMatches = stripped.match(/(^|[^\\])\$[^\$\n]+?\$/g);
    return (dispMatches ? dispMatches.length : 0) + (inlineMatches ? inlineMatches.length : 0);
  }

  function renderKaTeXBlock(trimmed) {
    const cacheKey = 'disp:' + trimmed;
    const cached = katexLRU.get(cacheKey);
    if (cached) return cached;
    try {
      const rendered = katex.renderToString(trimmed, { displayMode: true, throwOnError: false });
      const escapedRaw = encodeURIComponent(trimmed);
      const res = '<div class="lucid-math-block" data-raw-latex="' + escapedRaw + '">' +
             rendered +
             '<button class="lucid-btn-copy-latex" onclick="window.lucid.copyLatex(this)">Copy LaTeX</button>' +
             '</div>';
      katexLRU.set(cacheKey, res);
      return res;
    } catch (e) {
      return '<div class="lucid-math-error"><span class="lucid-error-msg">Formula render warning: ' + md.utils.escapeHtml(e.message || 'Syntax error') + '</span><pre>' + md.utils.escapeHtml(trimmed) + '</pre></div>';
    }
  }

  function renderKaTeXInline(trimmed) {
    const cacheKey = 'inline:' + trimmed;
    const cached = katexLRU.get(cacheKey);
    if (cached) return cached;
    try {
      const rendered = katex.renderToString(trimmed, { displayMode: false, throwOnError: false });
      katexLRU.set(cacheKey, rendered);
      return rendered;
    } catch (e) {
      return '$' + md.utils.escapeHtml(trimmed) + '$';
    }
  }

  function enhancePlaceholder(ph) {
    if (!ph || !ph.parentNode) return;
    const isDisplay = ph.classList.contains('lucid-math-display');
    let rawLatex = '';
    try {
      const attr = ph.getAttribute('data-raw-latex') || (ph.dataset && ph.dataset.rawLatex) || '';
      if (attr) {
        try {
          rawLatex = decodeURIComponent(attr);
        } catch (_) {
          rawLatex = attr;
        }
      }
      if (rawLatex) {
        if (isDisplay) {
          ph.outerHTML = renderKaTeXBlock(rawLatex);
        } else {
          ph.outerHTML = renderKaTeXInline(rawLatex);
        }
      } else {
        ph.remove();
      }
    } catch (e) {
      console.warn('KaTeX placeholder enhance error:', e);
      try { ph.remove(); } catch (_) {}
    }
  }

  function parseKaTeX(text, isDeferred) {
    if (typeof katex === 'undefined' || text.indexOf('$') === -1) return text;

    const codeBlocks = [];
    const codeRegex = /(```[\s\S]*?```|~~~[\s\S]*?~~~|`+[^`\n]+?`+)/g;
    text = text.replace(codeRegex, function(match) {
      codeBlocks.push(match);
      return '@@LUCID_CODE_' + (codeBlocks.length - 1) + '@@';
    });

    text = text.replace(/\$\$([\s\S]+?)\$\$/g, function(match, math) {
      const trimmed = math.trim();
      if (isDeferred) {
        const escapedRaw = encodeURIComponent(trimmed);
        return '<div class="lucid-math-placeholder lucid-math-display" data-raw-latex="' + escapedRaw + '"><div class="lucid-math-raw">' + md.utils.escapeHtml(trimmed) + '</div></div>';
      }
      return renderKaTeXBlock(trimmed);
    });
    text = text.replace(/(^|[^\\])\$([^\$\n]+?)\$/g, function(match, prefix, math) {
      const trimmed = math.trim();
      if (isDeferred) {
        const escapedRaw = encodeURIComponent(trimmed);
        return prefix + '<span class="lucid-math-placeholder lucid-math-inline" data-raw-latex="' + escapedRaw + '"><span class="lucid-math-raw">' + md.utils.escapeHtml(trimmed) + '</span></span>';
      }
      return prefix + renderKaTeXInline(trimmed);
    });

    text = text.replace(/@@LUCID_CODE_(\d+)@@/g, function(match, idx) {
      return codeBlocks[parseInt(idx, 10)];
    });

    return text;
  }

  function formatMermaidContainer(c) {
    if (!c) return;
    const svg = c.querySelector('.mermaid-canvas svg') || c.querySelector('.mermaid svg');
    if (!svg) return;
    const viewBox = svg.viewBox && svg.viewBox.baseVal;
    if (viewBox && viewBox.width > 0) {
      svg.style.maxWidth = 'none';
      svg.style.width = viewBox.width + 'px';
      svg.style.height = viewBox.height + 'px';

      const viewport = c.querySelector('.mermaid-viewport');
      const canvas = c.querySelector('.mermaid-canvas');
      if (viewport && canvas) {
        const availWidth = Math.max(100, viewport.clientWidth - 48);

        // 1. Inspect real SVG label typography geometry
        let baseFontSize = 14;
        const labelEl = svg.querySelector('.nodeLabel, .label, text, span');
        if (labelEl) {
          const fs = parseFloat(window.getComputedStyle(labelEl).fontSize);
          if (!isNaN(fs) && fs > 0) baseFontSize = fs;
        }

        // 2. Readability-first scale: target ~13.5px effective label size
        const readabilityFloor = Math.min(1.0, 13.5 / baseFontSize);
        const widthFitScale = availWidth / viewBox.width;

        let initialScale = 1.0;
        if (viewBox.width > availWidth) {
          // Diagram is wider than viewport: do NOT aggressively shrink to fit!
          // Prioritize readability so labels are readable without immediate zooming
          initialScale = Math.min(1.0, Math.max(widthFitScale, readabilityFloor));
        } else {
          // Small or medium diagram: keep at natural readable size (~1.0x)
          initialScale = 1.0;
        }

        // 3. Dynamic bounded viewport height based on diagram aspect ratio
        const scaledHeight = viewBox.height * initialScale;
        const targetHeight = Math.round(Math.min(640, Math.max(180, scaledHeight + 64)));
        viewport.style.height = targetHeight + 'px';

        // 4. Meaningful centering translation
        let contentOffsetX = 0;
        let contentOffsetY = 0;
        try {
          const bbox = svg.getBBox();
          if (bbox && bbox.width > 0) {
            const contentCenterX = bbox.x + bbox.width / 2;
            const contentCenterY = bbox.y + bbox.height / 2;
            const vbCenterX = (viewBox.x || 0) + viewBox.width / 2;
            const vbCenterY = (viewBox.y || 0) + viewBox.height / 2;
            contentOffsetX = vbCenterX - contentCenterX;
            contentOffsetY = vbCenterY - contentCenterY;
          }
        } catch (e) {}

        const initialTx = Math.round(contentOffsetX * initialScale);
        const initialTy = Math.round(contentOffsetY * initialScale);

        // 5. Store initial transform & apply
        canvas.dataset.initialScale = initialScale;
        canvas.dataset.initialTx = initialTx;
        canvas.dataset.initialTy = initialTy;
        canvas.dataset.contentOffsetX = contentOffsetX;
        canvas.dataset.contentOffsetY = contentOffsetY;
        canvas.dataset.scale = initialScale;
        canvas.dataset.tx = initialTx;
        canvas.dataset.ty = initialTy;
        canvas.style.transform = 'translate(' + initialTx + 'px, ' + initialTy + 'px) scale(' + initialScale + ')';

        viewport.onwheel = function(e) { window.lucid.handleDiagramWheel(e, viewport); };
        viewport.onmousemove = function(e) {
          viewport._lastClientX = e.clientX;
          viewport._lastClientY = e.clientY;
        };
        viewport.onmouseleave = function() {
          viewport._lastClientX = null;
          viewport._lastClientY = null;
        };
      }
    }
  }



  function extractHeadings() {
    const headings = [];
    const elements = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
    elements.forEach(function(el) {
      let text = '';
      const anchor = el.querySelector('.lucid-anchor');
      if (anchor) {
        const clone = el.cloneNode(true);
        const cloneAnchor = clone.querySelector('.lucid-anchor');
        if (cloneAnchor) cloneAnchor.remove();
        text = clone.textContent.trim();
      } else {
        text = el.textContent.trim();
      }
      headings.push({
        id: el.id,
        level: parseInt(el.tagName.substring(1), 10),
        text: text
      });
    });
    return headings;
  }

  // Focus Mode & Typewriter Mode Handler.
  // These react to the reader's text selection/caret within the read-only
  // preview to gently emphasize or center the block being looked at.
  let isFocusModeEnabled = false;
  let isTypewriterModeEnabled = false;

  function updateCaretPosition() {
    const selection = window.getSelection();
    if (!selection.rangeCount) return;
    const range = selection.getRangeAt(0);
    const rect = range.getBoundingClientRect();

    // 1. Focus Mode
    if (isFocusModeEnabled) {
      let node = range.startContainer;
      while (node && node.parentNode && node.parentNode.id !== 'lucid-content') {
        node = node.parentNode;
      }
      if (node && node.parentNode && node.parentNode.id === 'lucid-content') {
        const prev = document.querySelector('.lucid-active-block');
        if (prev && prev !== node) prev.classList.remove('lucid-active-block');
        node.classList.add('lucid-active-block');
      }
    }

    // 2. Typewriter Mode
    if (isTypewriterModeEnabled && rect.top > 0) {
      const targetY = window.innerHeight * 0.45;
      const deltaY = rect.top - targetY;
      if (Math.abs(deltaY) > 20) {
        window.scrollBy({ top: deltaY, behavior: 'smooth' });
      }
    }
  }

  document.addEventListener('keyup', updateCaretPosition);
  document.addEventListener('mouseup', updateCaretPosition);

  // Link handling: keep in-page anchors smooth, and hand every other link
  // (external URLs and relative references to sibling documents) to the native
  // app so the webview never navigates away from the render surface.
  document.addEventListener('click', function(e) {
    const a = e.target && e.target.closest ? e.target.closest('a') : null;
    if (!a) return;
    const container = document.getElementById('lucid-content');
    if (!container || !container.contains(a)) return;
    const href = a.getAttribute('href');
    if (!href) return;

    if (href.charAt(0) === '#') {
      e.preventDefault();
      const id = decodeURIComponent(href.slice(1));
      const el = document.getElementById(id) || document.querySelector('[name="' + CSS.escape(id) + '"]');
      if (el) {
        isProgrammaticScroll = true;
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
        setTimeout(function() { isProgrammaticScroll = false; }, 400);
      }
      return;
    }

    e.preventDefault();
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidLinkClicked) {
      window.webkit.messageHandlers.lucidLinkClicked.postMessage(href);
    }
  });

  // Scroll Spy
  let isProgrammaticScroll = false;
  let activeHeadingTimer = null;
  window.addEventListener('scroll', function() {
    if (isProgrammaticScroll) return;

    const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
    const fraction = maxScroll > 0 ? window.scrollY / maxScroll : 0;
    // Graduated 0..1 intensity so the chrome can fade its glass and fade out document
    // metadata smoothly over the first ~28px of travel.
    const intensity = Math.max(0, Math.min(1, window.scrollY / 28));
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidScroll) {
      window.webkit.messageHandlers.lucidScroll.postMessage({ fraction: fraction, scrolled: window.scrollY > 6, intensity: intensity });
    }

    clearTimeout(activeHeadingTimer);
    activeHeadingTimer = setTimeout(function() {
      const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
      let currentHeading = null;
      for (let i = 0; i < headings.length; i++) {
        const rect = headings[i].getBoundingClientRect();
        if (rect.top <= 120) {
          currentHeading = headings[i];
        } else {
          break;
        }
      }
      if (currentHeading && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidActiveHeading) {
        window.webkit.messageHandlers.lucidActiveHeading.postMessage({
          id: currentHeading.id,
          text: currentHeading.textContent.trim(),
          level: parseInt(currentHeading.tagName.substring(1), 10)
        });
      }
    }, 100);
  }, { passive: true });

  // Public API
  window.lucid = {
    updateContent: function(rawMarkdown, renderId) {
      renderId = String(renderId || '0');
      currentRenderRevision = renderId;
      LucidPerf.mark(renderId, 't4_js_received', { length: rawMarkdown ? rawMarkdown.length : 0 });
      const container = document.getElementById('lucid-content');
      if (!container) return;

      LucidPerf.mark(renderId, 't5_katex_pre_begin');
      const mathCount = countMathExpressions(rawMarkdown);
      const isDeferredMath = (mathCount > 30);
      const preprocessed = parseKaTeX(rawMarkdown, isDeferredMath);
      LucidPerf.mark(renderId, 't5_katex_pre_end', { count: mathCount, deferred: isDeferredMath });

      LucidPerf.mark(renderId, 't6_md_render_begin');
      let html = md.render(preprocessed);
      LucidPerf.mark(renderId, 't6_md_render_end');

      LucidPerf.mark(renderId, 't7_alerts_begin');
      html = parseAlerts(html);
      LucidPerf.mark(renderId, 't7_alerts_end', { htmlLength: html.length });

      LucidPerf.mark(renderId, 't8_dom_insert_begin');
      container.innerHTML = html;
      const domNodeCount = container.querySelectorAll('*').length;
      LucidPerf.mark(renderId, 't9_dom_insert_end', { nodeCount: domNodeCount });

      // First Readable Frame Proxy: 2 RAFs ensure layout & paint stabilization
      let firstReadableFrameDone = false;
      function markFrpDone() {
        if (firstReadableFrameDone || currentRenderRevision !== renderId) return;
        firstReadableFrameDone = true;
        LucidPerf.mark(renderId, 't11_first_readable_frame_proxy');
        checkFullEnhancement();
      }

      requestAnimationFrame(function() {
        LucidPerf.mark(renderId, 't10_first_raf_layout');
        requestAnimationFrame(function() {
          markFrpDone();
        });
      });
      setTimeout(function() {
        markFrpDone();
      }, 50);

      // Heading Anchors (Quiet hover reveal)
      const hs = container.querySelectorAll('h1, h2, h3, h4, h5, h6');
      hs.forEach(function(h) {
        if (!h.querySelector('.lucid-anchor') && h.id) {
          const a = document.createElement('a');
          a.className = 'lucid-anchor';
          a.href = '#' + h.id;
          a.textContent = '#';
          a.title = 'Link to this section';
          a.setAttribute('aria-hidden', 'true');
          h.appendChild(a);
        }
      });

      // Dynamic Content-Aware Table Layout & TOC Detection (Batched to prevent layout thrashing)
      const tables = container.querySelectorAll('table');
      LucidPerf.mark(renderId, 't10_table_layout_begin', { tableCount: tables.length });

      if (tables.length > 0) {
        const readerWidth = Math.min(1024, window.innerWidth * 0.86);
        const tableData = [];

        // Phase 1: Structure & TOC detection (pure DOM, no geometry reads)
        for (let i = 0; i < tables.length; i++) {
          const table = tables[i];
          let wrapper = table.parentElement;
          if (!wrapper || !wrapper.classList.contains('lucid-table-wrapper')) {
            wrapper = document.createElement('div');
            wrapper.className = 'lucid-table-wrapper';
            table.parentNode.insertBefore(wrapper, table);
            wrapper.appendChild(table);
          }

          // Detect Table of Contents
          let isToc = false;
          let prev = wrapper.previousElementSibling;
          while (prev && prev.tagName !== 'H1' && prev.tagName !== 'H2' && prev.tagName !== 'H3') {
            prev = prev.previousElementSibling;
          }
          if (prev && /contents|toc|index/i.test(prev.textContent)) {
            isToc = true;
          } else {
            const ths = table.querySelectorAll('th');
            if (ths.length >= 2) {
              const h0 = ths[0].textContent.trim().toLowerCase();
              const h1 = ths[1].textContent.trim().toLowerCase();
              if ((h0 === '#' || h0 === 'no' || h0 === 'index' || h0 === 'no.') &&
                  (h1 === 'section' || h1 === 'topic' || h1 === 'title' || h1 === 'chapter')) {
                isToc = true;
              }
            }
          }
          if (isToc) {
            table.classList.add('lucid-toc-table');
          }

          tableData.push({ table: table, wrapper: wrapper });
        }

        // Phase 2: Batch ALL writes before any geometry reads
        for (let i = 0; i < tableData.length; i++) {
          tableData[i].table.style.width = 'max-content';
        }

        // Phase 3: Batch ALL geometry reads in a single browser layout pass
        for (let i = 0; i < tableData.length; i++) {
          tableData[i].naturalWidth = tableData[i].table.scrollWidth;
        }

        // Phase 4: Batch ALL final writes (clean up width & apply breakout classes)
        for (let i = 0; i < tableData.length; i++) {
          const item = tableData[i];
          item.table.style.width = '';
          if (item.naturalWidth > readerWidth + 15) {
            item.wrapper.classList.add('lucid-wide');
          }
        }
      }
      LucidPerf.mark(renderId, 't10_table_layout_end');

      const headings = extractHeadings();
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidHeadings) {
        // Tag with the render revision so the native side can drop a stale echo
        // from an older revision (dual-writer safety with DocumentAnalyzer).
        window.webkit.messageHandlers.lucidHeadings.postMessage({ renderId: renderId, headings: headings });
      }

      // Asynchronous Enhancements (Math & Mermaid)
      let mathDone = !isDeferredMath;
      const mermaidNodes = (typeof mermaid !== 'undefined') ? container.querySelectorAll('.mermaid') : [];
      let mermaidDone = (mermaidNodes.length === 0);

      function checkFullEnhancement() {
        if (currentRenderRevision !== renderId) return;
        if (firstReadableFrameDone && mathDone && mermaidDone) {
          LucidPerf.mark(renderId, 't17_full_enhancement_complete');
        }
      }

      // 1. Deferred Math Enhancement
      if (isDeferredMath) {
        const mathPlaceholders = container.querySelectorAll('.lucid-math-placeholder');
        if (mathPlaceholders.length === 0) {
          mathDone = true;
          checkFullEnhancement();
        } else {
          let activeMathObserver = null;
          if (window.IntersectionObserver) {
            activeMathObserver = new IntersectionObserver(function(entries) {
              if (currentRenderRevision !== renderId) return;
              for (let i = 0; i < entries.length; i++) {
                if (entries[i].isIntersecting) {
                  const target = entries[i].target;
                  activeMathObserver.unobserve(target);
                  enhancePlaceholder(target);
                }
              }
            }, { rootMargin: '1200px 0px' });
            for (let i = 0; i < mathPlaceholders.length; i++) {
              activeMathObserver.observe(mathPlaceholders[i]);
            }
          }

          function processMathChunk() {
            if (currentRenderRevision !== renderId) {
              if (activeMathObserver) { activeMathObserver.disconnect(); activeMathObserver = null; }
              return;
            }
            try {
              const remaining = container.querySelectorAll('.lucid-math-placeholder');
              if (remaining.length === 0) {
                if (activeMathObserver) { activeMathObserver.disconnect(); activeMathObserver = null; }
                mathDone = true;
                checkFullEnhancement();
                return;
              }
              const limit = Math.min(150, remaining.length);
              for (let i = 0; i < limit; i++) {
                const ph = remaining[i];
                if (activeMathObserver) activeMathObserver.unobserve(ph);
                enhancePlaceholder(ph);
              }
              const nextRemaining = container.querySelectorAll('.lucid-math-placeholder');
              if (nextRemaining.length > 0) {
                setTimeout(processMathChunk, 0);
              } else {
                if (activeMathObserver) { activeMathObserver.disconnect(); activeMathObserver = null; }
                mathDone = true;
                checkFullEnhancement();
              }
            } catch (err) {
              console.warn('processMathChunk error:', err);
              if (activeMathObserver) { activeMathObserver.disconnect(); activeMathObserver = null; }
              mathDone = true;
              checkFullEnhancement();
            }
          }

          setTimeout(processMathChunk, 0);
        }
      }

      // 2. Mermaid Enhancement
      if (!mermaidDone) {
        ensureMermaidInitialized();
        const mermaidCount = mermaidNodes.length;
        LucidPerf.mark(renderId, 't15_mermaid_begin', { count: mermaidCount });

        if (mermaidCount <= 6) {
          try {
            mermaid.run({ nodes: mermaidNodes, suppressErrors: true }).then(function() {
              if (currentRenderRevision !== renderId) return;
              for (let i = 0; i < mermaidNodes.length; i++) {
                const c = mermaidNodes[i].closest('.mermaid-container');
                if (c) formatMermaidContainer(c);
              }
              LucidPerf.mark(renderId, 't16_mermaid_end', { count: mermaidCount });
              mermaidDone = true;
              checkFullEnhancement();
            }).catch(function(err) {
              console.warn('Mermaid batch render error:', err);
              if (currentRenderRevision !== renderId) return;
              for (let i = 0; i < mermaidNodes.length; i++) {
                const c = mermaidNodes[i].closest('.mermaid-container');
                if (c) formatMermaidContainer(c);
              }
              LucidPerf.mark(renderId, 't16_mermaid_end', { count: mermaidCount });
              mermaidDone = true;
              checkFullEnhancement();
            });
          } catch (e) {
            console.warn('Mermaid synchronous error:', e);
            if (currentRenderRevision !== renderId) return;
            mermaidDone = true;
            checkFullEnhancement();
          }
        } else {
          const allNodes = Array.prototype.slice.call(mermaidNodes);
          let chunkIndex = 0;
          const chunkSize = 6;

          function processMermaidChunk() {
            if (currentRenderRevision !== renderId) return;
            if (chunkIndex >= allNodes.length) {
              LucidPerf.mark(renderId, 't16_mermaid_end', { count: mermaidCount });
              mermaidDone = true;
              checkFullEnhancement();
              return;
            }

            const currentChunk = allNodes.slice(chunkIndex, chunkIndex + chunkSize);
            chunkIndex += chunkSize;

            try {
              mermaid.run({ nodes: currentChunk, suppressErrors: true }).then(function() {
                if (currentRenderRevision !== renderId) return;
                for (let i = 0; i < currentChunk.length; i++) {
                  const c = currentChunk[i].closest('.mermaid-container');
                  if (c) formatMermaidContainer(c);
                }
                setTimeout(processMermaidChunk, 0);
              }).catch(function(err) {
                console.warn('Mermaid chunk render error:', err);
                if (currentRenderRevision !== renderId) return;
                for (let i = 0; i < currentChunk.length; i++) {
                  const c = currentChunk[i].closest('.mermaid-container');
                  if (c) formatMermaidContainer(c);
                }
                setTimeout(processMermaidChunk, 0);
              });
            } catch (e) {
              console.warn('Mermaid synchronous chunk error:', e);
              if (currentRenderRevision !== renderId) return;
              setTimeout(processMermaidChunk, 0);
            }
          }

          processMermaidChunk();
        }
      }

      // 3. Immediate completion check if nothing is deferred
      checkFullEnhancement();
    },

    updatePreferences: function(prefs) {
      const root = document.documentElement;
      const body = document.body;

      if (prefs.theme) {
        body.setAttribute('data-theme', prefs.theme);
        body.className = 'vscode-body ' + (prefs.theme === 'dark' ? 'vscode-dark' : (prefs.theme === 'light' ? 'vscode-light' : 'vscode-sepia'));
        const newMermaidTheme = (prefs.theme === 'light' ? 'default' : (prefs.theme === 'sepia' ? 'neutral' : 'dark'));
        if (typeof mermaid !== 'undefined' && currentMermaidTheme !== newMermaidTheme) {
          currentMermaidTheme = newMermaidTheme;
          try {
            mermaid.initialize({
              startOnLoad: false,
              theme: currentMermaidTheme,
              securityLevel: 'loose',
              layout: 'dagre',
              flowchart: { defaultRenderer: 'dagre' }
            });
          } catch (e) {}
        }
      }
      if (prefs.fontFamily) root.style.setProperty('--lucid-font-family', prefs.fontFamily);
      if (prefs.fontSize) root.style.setProperty('--lucid-font-size', prefs.fontSize + 'px');
      if (prefs.lineHeight) root.style.setProperty('--lucid-line-height', prefs.lineHeight);
      if (prefs.contentWidth) root.style.setProperty('--lucid-content-width', prefs.contentWidth);
      if (prefs.accentColor) root.style.setProperty('--lucid-accent', prefs.accentColor);
      if (prefs.topInset) root.style.setProperty('--lucid-top-inset', prefs.topInset + 'px');
      if (typeof prefs.breakout !== 'undefined') {
        if (prefs.breakout) body.classList.remove('no-breakout');
        else body.classList.add('no-breakout');
      }
      // Focus Mode
      if (typeof prefs.focusMode !== 'undefined') {
        isFocusModeEnabled = prefs.focusMode;
        if (prefs.focusMode) body.classList.add('lucid-focus-mode');
        else body.classList.remove('lucid-focus-mode');
      }

      // Typewriter Mode
      if (typeof prefs.typewriterMode !== 'undefined') {
        isTypewriterModeEnabled = prefs.typewriterMode;
        if (prefs.typewriterMode) body.classList.add('lucid-typewriter-mode');
        else body.classList.remove('lucid-typewriter-mode');
      }

      // Custom User CSS Injection
      if (typeof prefs.customCSS !== 'undefined') {
        let styleTag = document.getElementById('lucid-user-custom-css');
        if (!styleTag) {
          styleTag = document.createElement('style');
          styleTag.id = 'lucid-user-custom-css';
          document.head.appendChild(styleTag);
        }
        styleTag.textContent = prefs.customCSS;
      }

      // Math & Mermaid Scaling & Table Density
      if (prefs.mathScale) root.style.setProperty('--lucid-math-scale', prefs.mathScale);
      if (prefs.mermaidScale) root.style.setProperty('--lucid-mermaid-scale', prefs.mermaidScale);
      if (prefs.tableDensity) body.setAttribute('data-table-density', prefs.tableDensity);
    },

    handleMessage: function(msg) {
      if (!msg || !msg.type) return;
      if (msg.type === 'updateContent' && typeof msg.markdown === 'string') {
        window.lucid.updateContent(msg.markdown, msg.renderId || msg.revision);
      } else if (msg.type === 'updatePreferences' && msg.preferences) {
        window.lucid.updatePreferences(msg.preferences);
      } else if (msg.type === 'ping') {
        LucidPerf.mark(msg.renderId || 'ping', 't4_js_ping_received', { length: (msg.payload || '').length });
      }
    },

    togglePan: function(btn) {
      const container = btn.closest('.mermaid-container') || btn.closest('.lucid-mermaid-modal-content');
      if (!container) return;
      const viewport = container.querySelector('.mermaid-viewport') || container.querySelector('.lucid-mermaid-modal-body');
      if (!viewport) return;
      btn.classList.toggle('active');
      const isPanning = btn.classList.contains('active');
      viewport.classList.toggle('is-panning', isPanning);
    },

    handleDiagramMouseDown: function(e, viewport) {
      const isPanActive = viewport.classList.contains('is-panning') || e.spaceKey || e.button === 1;
      if (!isPanActive) return;
      e.preventDefault();
      viewport.classList.add('is-dragging');
      const canvas = viewport.querySelector('.mermaid-canvas');
      if (!canvas) return;

      let tx = parseFloat(canvas.dataset.tx || '0');
      let ty = parseFloat(canvas.dataset.ty || '0');
      let scale = parseFloat(canvas.dataset.scale || '1.0');
      const startX = e.clientX;
      const startY = e.clientY;

      function onMouseMove(moveEvent) {
        const dx = moveEvent.clientX - startX;
        const dy = moveEvent.clientY - startY;
        const currentTx = tx + dx;
        const currentTy = ty + dy;
        canvas.style.transform = 'translate(' + currentTx + 'px, ' + currentTy + 'px) scale(' + scale + ')';
        canvas.dataset.tempTx = currentTx;
        canvas.dataset.tempTy = currentTy;
      }

      function onMouseUp() {
        viewport.classList.remove('is-dragging');
        window.removeEventListener('mousemove', onMouseMove);
        window.removeEventListener('mouseup', onMouseUp);
        if (canvas.dataset.tempTx) {
          canvas.dataset.tx = canvas.dataset.tempTx;
          canvas.dataset.ty = canvas.dataset.tempTy;
          delete canvas.dataset.tempTx;
          delete canvas.dataset.tempTy;
        }
      }

      window.addEventListener('mousemove', onMouseMove);
      window.addEventListener('mouseup', onMouseUp);
    },

    zoomDiagramAtPoint: function(targetEl, factor, clientX, clientY) {
      if (!targetEl) return;
      const viewport = targetEl.classList && (targetEl.classList.contains('mermaid-viewport') || targetEl.classList.contains('lucid-mermaid-modal-body'))
        ? targetEl
        : (targetEl.querySelector ? (targetEl.querySelector('.mermaid-viewport') || targetEl.querySelector('.lucid-mermaid-modal-body')) : null)
          || (targetEl.closest ? (targetEl.closest('.mermaid-viewport') || targetEl.closest('.lucid-mermaid-modal-body')) : null);
      if (!viewport) return;
      const canvas = viewport.querySelector('.mermaid-canvas') || (viewport.parentElement ? viewport.parentElement.querySelector('.mermaid-canvas') : null);
      if (!canvas) return;

      const currentScale = parseFloat(canvas.dataset.scale || '1.0');
      const tx = parseFloat(canvas.dataset.tx || '0');
      const ty = parseFloat(canvas.dataset.ty || '0');

      const newScale = Math.max(0.3, Math.min(4.0, currentScale * factor));
      if (Math.abs(newScale - currentScale) < 0.001) return;

      const viewportRect = viewport.getBoundingClientRect();
      const centerX = viewportRect.left + viewport.clientWidth / 2;
      const centerY = viewportRect.top + viewport.clientHeight / 2;

      const targetX = (typeof clientX === 'number' && clientX >= viewportRect.left && clientX <= viewportRect.right) ? clientX : centerX;
      const targetY = (typeof clientY === 'number' && clientY >= viewportRect.top && clientY <= viewportRect.bottom) ? clientY : centerY;

      const px = targetX - centerX;
      const py = targetY - centerY;

      const ratio = newScale / currentScale;
      const newTx = px - (px - tx) * ratio;
      const newTy = py - (py - ty) * ratio;

      canvas.dataset.scale = newScale;
      canvas.dataset.tx = newTx;
      canvas.dataset.ty = newTy;
      canvas.style.transform = 'translate(' + newTx + 'px, ' + newTy + 'px) scale(' + newScale + ')';
    },

    zoomDiagram: function(btn, factor) {
      const container = btn.closest('.mermaid-container') || btn.closest('.lucid-mermaid-modal-content') || btn.closest('.test-container') || btn.parentElement;
      if (!container) return;
      const viewport = container.querySelector('.mermaid-viewport') || container.querySelector('.lucid-mermaid-modal-body');
      const lastX = viewport ? viewport._lastClientX : null;
      const lastY = viewport ? viewport._lastClientY : null;
      window.lucid.zoomDiagramAtPoint(container, factor, lastX, lastY);
    },

    handleDiagramWheel: function(e, viewport) {
      if (e.ctrlKey || e.metaKey) {
        e.preventDefault();
        const factor = e.deltaY < 0 ? 1.08 : 0.92;
        window.lucid.zoomDiagramAtPoint(viewport, factor, e.clientX, e.clientY);
      }
      // Normal vertical mouse/trackpad scrolling is intentionally untouched so page scrolls naturally
    },

    resetDiagram: function(btn) {
      const container = btn.closest('.mermaid-container') || btn.closest('.lucid-mermaid-modal-content') || btn.closest('.test-container') || btn.parentElement;
      const canvas = container ? container.querySelector('.mermaid-canvas') : null;
      if (!canvas) return;

      const initialScale = parseFloat(canvas.dataset.initialScale || '1.0');
      const initialTx = parseFloat(canvas.dataset.initialTx || '0');
      const initialTy = parseFloat(canvas.dataset.initialTy || '0');

      canvas.dataset.scale = initialScale;
      canvas.dataset.tx = initialTx;
      canvas.dataset.ty = initialTy;
      canvas.style.transform = 'translate(' + initialTx + 'px, ' + initialTy + 'px) scale(' + initialScale + ')';
    },

    fitDiagram: function(btn) {
      const container = btn.closest('.mermaid-container') || btn.closest('.lucid-mermaid-modal-content') || btn.closest('.test-container') || btn.parentElement;
      const viewport = container ? (container.querySelector('.mermaid-viewport') || container.querySelector('.lucid-mermaid-modal-body')) : null;
      const canvas = container ? container.querySelector('.mermaid-canvas') : null;
      const svg = canvas ? canvas.querySelector('svg') : null;
      if (!viewport || !canvas || !svg) return;

      const viewBox = svg.viewBox && svg.viewBox.baseVal;
      const unscaledWidth = (viewBox && viewBox.width > 0) ? viewBox.width : (svg.clientWidth || 300);
      const unscaledHeight = (viewBox && viewBox.height > 0) ? viewBox.height : (svg.clientHeight || 200);

      const availWidth = Math.max(100, viewport.clientWidth - 48);
      const availHeight = Math.max(100, viewport.clientHeight - 48);

      const fitScale = Math.min(availWidth / unscaledWidth, availHeight / unscaledHeight, 1.5);
      const contentOffsetX = parseFloat(canvas.dataset.contentOffsetX || '0');
      const contentOffsetY = parseFloat(canvas.dataset.contentOffsetY || '0');
      const fitTx = Math.round(contentOffsetX * fitScale);
      const fitTy = Math.round(contentOffsetY * fitScale);

      canvas.dataset.scale = fitScale;
      canvas.dataset.tx = fitTx;
      canvas.dataset.ty = fitTy;
      canvas.style.transform = 'translate(' + fitTx + 'px, ' + fitTy + 'px) scale(' + fitScale + ')';
    },

    expandDiagram: function(btn) {
      const container = btn.closest('.mermaid-container');
      const svg = container ? (container.querySelector('.mermaid-canvas svg') || container.querySelector('.mermaid svg')) : null;
      if (!svg) return;

      let modal = document.getElementById('lucid-mermaid-modal');
      if (!modal) {
        modal = document.createElement('div');
        modal.id = 'lucid-mermaid-modal';
        modal.className = 'lucid-mermaid-modal';
        modal.innerHTML =
          '<div class="lucid-mermaid-modal-content">' +
            '<div class="lucid-mermaid-modal-header">' +
              '<span class="lucid-mermaid-modal-title">Diagram Preview</span>' +
              '<div class="mermaid-toolbar" style="position:static; opacity:1; box-shadow:none; border:none; background:transparent;">' +
                '<button class="lucid-mermaid-btn lucid-btn-pan" title="Pan Tool" onclick="window.lucid.togglePan(this)"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 11V6a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v0M14 10V4a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v2M10 10.5V6a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v8M6 14v-1.5a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v4a8 8 0 0 0 8 8h2a8 8 0 0 0 8-8v-3a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2"/></svg></button>' +
                '<button class="lucid-mermaid-btn" title="Zoom In" onclick="window.lucid.zoomDiagram(this, 1.15)">+</button>' +
                '<button class="lucid-mermaid-btn" title="Zoom Out" onclick="window.lucid.zoomDiagram(this, 0.87)">−</button>' +
                '<button class="lucid-mermaid-btn" title="Fit to Viewport" onclick="window.lucid.fitDiagram(this)">Fit</button>' +
                '<button class="lucid-mermaid-btn" title="Reset to Initial View" onclick="window.lucid.resetDiagram(this)">Reset</button>' +
                '<span class="mermaid-toolbar-sep"></span>' +
                '<button class="lucid-mermaid-btn" title="Copy SVG" onclick="window.lucid.copySvg(this)">Copy SVG</button>' +
                '<button class="lucid-mermaid-btn" title="Export SVG…" onclick="window.lucid.saveSvg(this)">Export SVG…</button>' +
                '<span class="mermaid-toolbar-sep"></span>' +
                '<button class="lucid-mermaid-btn" title="Close (Esc)" onclick="window.lucid.closeDiagramModal()">✕</button>' +
              '</div>' +
            '</div>' +
            '<div class="lucid-mermaid-modal-body" onmousedown="window.lucid.handleDiagramMouseDown(event, this)">' +
              '<div class="mermaid-canvas" id="lucid-modal-canvas"></div>' +
            '</div>' +
          '</div>';
        modal.onclick = function(e) {
          if (e.target === modal) window.lucid.closeDiagramModal();
        };
        document.body.appendChild(modal);

        const modalBody = modal.querySelector('.lucid-mermaid-modal-body');
        if (modalBody) {
          modalBody.onwheel = function(e) { window.lucid.handleDiagramWheel(e, modalBody); };
          modalBody.onmousemove = function(e) {
            modalBody._lastClientX = e.clientX;
            modalBody._lastClientY = e.clientY;
          };
          modalBody.onmouseleave = function() {
            modalBody._lastClientX = null;
            modalBody._lastClientY = null;
          };
        }

        window.addEventListener('keydown', function(e) {
          if (e.key === 'Escape' && modal.classList.contains('is-open')) {
            window.lucid.closeDiagramModal();
          }
        });
      }

      const modalCanvas = document.getElementById('lucid-modal-canvas');
      const modalViewport = modal.querySelector('.lucid-mermaid-modal-body');
      modalCanvas.innerHTML = svg.outerHTML;
      const modalSvg = modalCanvas.querySelector('svg');
      let modalInitialScale = 1.0;
      let modalTx = 0;
      let modalTy = 0;
      if (modalSvg) {
        modalSvg.style.maxWidth = 'none';
        modalSvg.style.display = 'block';
        const viewBox = modalSvg.viewBox && modalSvg.viewBox.baseVal;
        if (viewBox && viewBox.width > 0) {
          modalSvg.style.width = viewBox.width + 'px';
          modalSvg.style.height = viewBox.height + 'px';
          const availWidth = Math.max(100, (modalViewport ? modalViewport.clientWidth : 800) - 64);
          const availHeight = Math.max(100, (modalViewport ? modalViewport.clientHeight : 600) - 80);
          const fitScale = Math.min(availWidth / viewBox.width, availHeight / viewBox.height);

          let baseFontSize = 14;
          const labelEl = modalSvg.querySelector('.nodeLabel, .label, text, span');
          if (labelEl) {
            const fs = parseFloat(window.getComputedStyle(labelEl).fontSize);
            if (!isNaN(fs) && fs > 0) baseFontSize = fs;
          }
          const readabilityFloor = Math.min(1.0, 13.5 / baseFontSize);

          if (fitScale >= readabilityFloor) {
            modalInitialScale = Math.min(1.2, fitScale);
          } else {
            modalInitialScale = Math.min(1.0, Math.max(fitScale, readabilityFloor));
          }

          let contentOffsetX = 0;
          let contentOffsetY = 0;
          try {
            const bbox = modalSvg.getBBox();
            if (bbox && bbox.width > 0) {
              const contentCenterX = bbox.x + bbox.width / 2;
              const contentCenterY = bbox.y + bbox.height / 2;
              const vbCenterX = (viewBox.x || 0) + viewBox.width / 2;
              const vbCenterY = (viewBox.y || 0) + viewBox.height / 2;
              contentOffsetX = vbCenterX - contentCenterX;
              contentOffsetY = vbCenterY - contentCenterY;
            }
          } catch (e) {}
          modalTx = Math.round(contentOffsetX * modalInitialScale);
          modalTy = Math.round(contentOffsetY * modalInitialScale);
        }
      }
      modalCanvas.dataset.initialScale = modalInitialScale;
      modalCanvas.dataset.initialTx = modalTx;
      modalCanvas.dataset.initialTy = modalTy;
      modalCanvas.dataset.scale = modalInitialScale;
      modalCanvas.dataset.tx = modalTx;
      modalCanvas.dataset.ty = modalTy;
      modalCanvas.style.transform = 'translate(' + modalTx + 'px, ' + modalTy + 'px) scale(' + modalInitialScale + ')';

      modal.classList.add('is-open');
    },

    closeDiagramModal: function() {
      const modal = document.getElementById('lucid-mermaid-modal');
      if (modal) modal.classList.remove('is-open');
    },

    scrollToHeading: function(id) {
      const el = document.getElementById(id);
      if (el) {
        isProgrammaticScroll = true;
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
        setTimeout(function() { isProgrammaticScroll = false; }, 400);
      }
    },

    setScrollFraction: function(fraction) {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
      if (maxScroll > 0) {
        isProgrammaticScroll = true;
        window.scrollTo({ top: fraction * maxScroll, behavior: 'instant' });
        setTimeout(function() { isProgrammaticScroll = false; }, 50);
      }
    },


    copyCode: function(btn) {
      const pre = btn.closest('pre.lucid-enhanced');
      const code = pre ? pre.querySelector('code') : null;
      if (code) {
        navigator.clipboard.writeText(code.innerText).then(function() {
          const original = btn.innerText;
          btn.innerText = 'Copied!';
          btn.classList.add('lucid-copied');
          setTimeout(function() {
            btn.innerText = original;
            btn.classList.remove('lucid-copied');
          }, 1800);
        });
      }
    },

    copyLatex: function(btn) {
      const container = btn.closest('.lucid-math-block');
      if (container && container.dataset.rawLatex) {
        const latex = decodeURIComponent(container.dataset.rawLatex);
        navigator.clipboard.writeText(latex).then(function() {
          const original = btn.innerText;
          btn.innerText = 'Copied!';
          setTimeout(function() { btn.innerText = original; }, 1800);
        });
      }
    },

    copySvg: function(btn) {
      const container = btn.closest('.mermaid-container') || btn.closest('.lucid-mermaid-modal-content') || btn.closest('.mermaid-wrapper');
      const svg = container ? (container.querySelector('.mermaid-canvas svg') || container.querySelector('.mermaid svg') || container.querySelector('svg')) : null;
      if (svg) {
        navigator.clipboard.writeText(svg.outerHTML).then(function() {
          const original = btn.innerText;
          btn.innerText = 'Copied!';
          setTimeout(function() { btn.innerText = original; }, 1800);
        });
      }
    },

    saveSvg: function(btn) {
      const container = btn.closest('.mermaid-container') || btn.closest('.lucid-mermaid-modal-content') || btn.closest('.mermaid-wrapper');
      const svg = container ? (container.querySelector('.mermaid-canvas svg') || container.querySelector('.mermaid svg') || container.querySelector('svg')) : null;
      if (svg) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidSaveSvg) {
          window.webkit.messageHandlers.lucidSaveSvg.postMessage({ svg: svg.outerHTML });
        } else {
          const blob = new Blob([svg.outerHTML], { type: 'image/svg+xml;charset=utf-8' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'diagram.svg';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        }
      }
    },

    // In-Page Find Implementation
    findMatches: [],
    findCurrentIndex: 0,

    find: function(query) {
      window.lucid.clearFind();
      if (!query || !query.trim()) return;

      const container = document.getElementById('lucid-content');
      if (!container) return;

      const walker = document.createTreeWalker(container, NodeFilter.SHOW_TEXT, null, false);
      const textNodes = [];
      let node;
      while (node = walker.nextNode()) {
        if (node.parentElement && !['SCRIPT', 'STYLE', 'BUTTON'].includes(node.parentElement.tagName)) {
          textNodes.push(node);
        }
      }

      const regex = new RegExp('(' + query.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&') + ')', 'gi');
      window.lucid.findMatches = [];

      textNodes.forEach(function(textNode) {
        const val = textNode.nodeValue;
        if (regex.test(val)) {
          const frag = document.createDocumentFragment();
          let lastIdx = 0;
          val.replace(regex, function(match, p1, offset) {
            if (offset > lastIdx) {
              frag.appendChild(document.createTextNode(val.substring(lastIdx, offset)));
            }
            const mark = document.createElement('mark');
            mark.className = 'lucid-find-match';
            mark.textContent = match;
            frag.appendChild(mark);
            window.lucid.findMatches.push(mark);
            lastIdx = offset + match.length;
          });
          if (lastIdx < val.length) {
            frag.appendChild(document.createTextNode(val.substring(lastIdx)));
          }
          textNode.parentNode.replaceChild(frag, textNode);
        }
      });

      window.lucid.findCurrentIndex = 0;
      if (window.lucid.findMatches.length > 0) {
        window.lucid.highlightActiveFindMatch();
      }

      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidFindMatches) {
        window.webkit.messageHandlers.lucidFindMatches.postMessage({
          count: window.lucid.findMatches.length,
          index: window.lucid.findMatches.length > 0 ? 1 : 0
        });
      }
    },

    highlightActiveFindMatch: function() {
      window.lucid.findMatches.forEach(function(m) { m.classList.remove('lucid-find-active'); });
      if (window.lucid.findMatches.length === 0) return;
      const idx = window.lucid.findCurrentIndex;
      const active = window.lucid.findMatches[idx];
      if (active) {
        active.classList.add('lucid-find-active');
        active.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    },

    findNext: function() {
      if (window.lucid.findMatches.length === 0) return;
      window.lucid.findCurrentIndex = (window.lucid.findCurrentIndex + 1) % window.lucid.findMatches.length;
      window.lucid.highlightActiveFindMatch();
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidFindMatches) {
        window.webkit.messageHandlers.lucidFindMatches.postMessage({
          count: window.lucid.findMatches.length,
          index: window.lucid.findCurrentIndex + 1
        });
      }
    },

    findPrev: function() {
      if (window.lucid.findMatches.length === 0) return;
      window.lucid.findCurrentIndex = (window.lucid.findCurrentIndex - 1 + window.lucid.findMatches.length) % window.lucid.findMatches.length;
      window.lucid.highlightActiveFindMatch();
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidFindMatches) {
        window.webkit.messageHandlers.lucidFindMatches.postMessage({
          count: window.lucid.findMatches.length,
          index: window.lucid.findCurrentIndex + 1
        });
      }
    },

    clearFind: function() {
      const marks = document.querySelectorAll('mark.lucid-find-match');
      marks.forEach(function(mark) {
        const parent = mark.parentNode;
        parent.replaceChild(document.createTextNode(mark.textContent), mark);
        parent.normalize();
      });
      window.lucid.findMatches = [];
      window.lucid.findCurrentIndex = 0;
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidFindMatches) {
        window.webkit.messageHandlers.lucidFindMatches.postMessage({
          count: 0,
          index: 0
        });
      }
    },

    getStandaloneHTML: function() {
      return document.documentElement.outerHTML;
    }
  };

  function notifyBridgeReady() {
    ensureMermaidInitialized();
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidReady) {
      window.webkit.messageHandlers.lucidReady.postMessage({ status: 'ready' });
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', notifyBridgeReady);
  } else {
    notifyBridgeReady();
  }
})();
