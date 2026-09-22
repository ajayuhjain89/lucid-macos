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

  // Preprocess Mermaid flowchart source to ensure unquoted node labels containing parentheses
  // (e.g. A[Reference Input r(t)]) are safely quoted for Mermaid parsing compatibility without
  // mutating valid modern Mermaid, directives, edge labels, or other diagram types.
  function sanitizeMermaidSource(source) {
    if (!source || typeof source !== 'string') return source;

    const clean = source.replace(/%%\{[\s\S]*?\}%%/g, '').replace(/%%.*$/gm, '').trim();
    if (!clean.startsWith('flowchart') && !clean.startsWith('graph')) {
      return source;
    }

    let result = '';
    let i = 0;
    const len = source.length;

    while (i < len) {
      // 1. Skip comments: %% ...
      if (source[i] === '%' && source[i + 1] === '%') {
        if (source[i + 2] === '{') {
          const endDir = source.indexOf('}%%', i + 3);
          if (endDir !== -1) {
            result += source.slice(i, endDir + 3);
            i = endDir + 3;
            continue;
          }
        }
        const endLine = source.indexOf('\n', i);
        if (endLine !== -1) {
          result += source.slice(i, endLine + 1);
          i = endLine + 1;
        } else {
          result += source.slice(i);
          break;
        }
        continue;
      }

      // 2. Skip already quoted strings: " ... "
      if (source[i] === '"') {
        let j = i + 1;
        while (j < len && (source[j] !== '"' || source[j - 1] === '\\')) {
          j++;
        }
        if (j < len) j++;
        result += source.slice(i, j);
        i = j;
        continue;
      }

      // 3. Skip edge labels: | ... |
      if (source[i] === '|') {
        let j = i + 1;
        while (j < len && source[j] !== '|' && source[j] !== '\n') {
          j++;
        }
        if (j < len && source[j] === '|') {
          j++;
          result += source.slice(i, j);
          i = j;
          continue;
        }
      }

      // 4. Check for node shapes starting with bracket: [
      if (source[i] === '[') {
        const prevChar = i > 0 ? source[i - 1] : '';
        const nextChar = i + 1 < len ? source[i + 1] : '';

        // Subroutine [[ ... ]]
        if (nextChar === '[') {
          let j = i + 2;
          while (j < len && !(source[j] === ']' && source[j + 1] === ']') && source[j] !== '\n') {
            j++;
          }
          if (j < len && source[j] === ']' && source[j + 1] === ']') {
            const inner = source.slice(i + 2, j);
            const trimmed = inner.trim();
            if ((inner.includes('(') || inner.includes(')')) && !(trimmed.startsWith('"') && trimmed.endsWith('"'))) {
              const escaped = inner.replace(/\\"/g, '"').replace(/"/g, '\\"');
              result += '[["' + escaped + '"]]';
            } else {
              result += source.slice(i, j + 2);
            }
            i = j + 2;
            continue;
          }
        }

        // Cylinder [( ... )]
        if (nextChar === '(') {
          let j = i + 2;
          while (j < len && !(source[j] === ')' && source[j + 1] === ']') && source[j] !== '\n') {
            j++;
          }
          if (j < len && source[j] === ')' && source[j + 1] === ']') {
            const inner = source.slice(i + 2, j);
            const trimmed = inner.trim();
            if ((inner.includes('(') || inner.includes(')')) && !(trimmed.startsWith('"') && trimmed.endsWith('"'))) {
              const escaped = inner.replace(/\\"/g, '"').replace(/"/g, '\\"');
              result += '[("' + escaped + '")]';
            } else {
              result += source.slice(i, j + 2);
            }
            i = j + 2;
            continue;
          }
        }

        // Parallelogram or trapezoid: [/ or [\
        if (nextChar === '/' || nextChar === '\\') {
          result += source[i];
          i++;
          continue;
        }

        // Stadium: ([ ... ])
        if (prevChar === '(') {
          let j = i + 1;
          while (j < len && !(source[j] === ']' && source[j + 1] === ')') && source[j] !== '\n') {
            j++;
          }
          if (j < len && source[j] === ']' && source[j + 1] === ')') {
            const inner = source.slice(i + 1, j);
            const trimmed = inner.trim();
            if ((inner.includes('(') || inner.includes(')')) && !(trimmed.startsWith('"') && trimmed.endsWith('"'))) {
              const escaped = inner.replace(/\\"/g, '"').replace(/"/g, '\\"');
              result += '["' + escaped + '"])';
            } else {
              result += source.slice(i, j + 2);
            }
            i = j + 2;
            continue;
          }
        }

        // Standard rectangle: [ ... ]
        let j = i + 1;
        while (j < len && source[j] !== ']' && source[j] !== '\n') {
          j++;
        }
        if (j < len && source[j] === ']') {
          const nextAfterClose = j + 1 < len ? source[j + 1] : '';
          if (nextAfterClose !== ')' && nextAfterClose !== ']') {
            const inner = source.slice(i + 1, j);
            const trimmed = inner.trim();
            if ((inner.includes('(') || inner.includes(')')) && !(trimmed.startsWith('"') && trimmed.endsWith('"'))) {
              const escaped = inner.replace(/\\"/g, '"').replace(/"/g, '\\"');
              result += '["' + escaped + '"]';
            } else {
              result += source.slice(i, j + 1);
            }
            i = j + 1;
            continue;
          }
        }
      }

      // 5. Check for curly braces: { ... } or {{ ... }}
      if (source[i] === '{') {
        const nextChar = i + 1 < len ? source[i + 1] : '';

        // Hexagon {{ ... }}
        if (nextChar === '{') {
          let j = i + 2;
          while (j < len && !(source[j] === '}' && source[j + 1] === '}') && source[j] !== '\n') {
            j++;
          }
          if (j < len && source[j] === '}' && source[j + 1] === '}') {
            const inner = source.slice(i + 2, j);
            const trimmed = inner.trim();
            if ((inner.includes('(') || inner.includes(')')) && !(trimmed.startsWith('"') && trimmed.endsWith('"'))) {
              const escaped = inner.replace(/\\"/g, '"').replace(/"/g, '\\"');
              result += '{{"' + escaped + '"}}';
            } else {
              result += source.slice(i, j + 2);
            }
            i = j + 2;
            continue;
          }
        }

        // Rhombus { ... }
        let j = i + 1;
        while (j < len && source[j] !== '}' && source[j] !== '\n') {
          j++;
        }
        if (j < len && source[j] === '}') {
          const nextAfterClose = j + 1 < len ? source[j + 1] : '';
          if (nextAfterClose !== '}') {
            const inner = source.slice(i + 1, j);
            const trimmed = inner.trim();
            if ((inner.includes('(') || inner.includes(')')) && !(trimmed.startsWith('"') && trimmed.endsWith('"'))) {
              const escaped = inner.replace(/\\"/g, '"').replace(/"/g, '\\"');
              result += '{"' + escaped + '"}';
            } else {
              result += source.slice(i, j + 1);
            }
            i = j + 1;
            continue;
          }
        }
      }

      result += source[i];
      i++;
    }

    return result;
  }

  // Initialize Markdown-it
  const md = window.markdownit({
    html: true,
    linkify: true,
    typographer: true,
    highlight: function(str, lang) {
      if (lang === 'mermaid') {
        const preparedStr = sanitizeMermaidSource(str);
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
               '<div class="mermaid-viewport" onpointerdown="window.lucid.handleDiagramPointerDown(event, this)">' +
               '<div class="mermaid-canvas">' +
               '<div class="mermaid">' + md.utils.escapeHtml(preparedStr) + '</div>' +
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

  // Render-scoped Math Registry
  const renderMathRegistries = new Map();

  function getMathRegistry(renderId) {
    renderId = String(renderId || '0');
    if (!renderMathRegistries.has(renderId)) {
      renderMathRegistries.set(renderId, new Map());
    }
    return renderMathRegistries.get(renderId);
  }

  function pruneOldRegistries(currentRenderId) {
    currentRenderId = String(currentRenderId || '0');
    for (const key of renderMathRegistries.keys()) {
      if (key !== currentRenderId) {
        renderMathRegistries.delete(key);
      }
    }
  }

  function lucidMathPlugin(md) {
    function mathInline(state, silent) {
      const start = state.pos;
      const max = state.posMax;
      const src = state.src;

      // Check for preceding unescaped backslash
      if (start > 0 && src.charCodeAt(start - 1) === 0x5C /* \ */) {
        let backslashCount = 0;
        let p = start - 1;
        while (p >= 0 && src.charCodeAt(p) === 0x5C) {
          backslashCount++;
          p--;
        }
        if (backslashCount % 2 === 1) {
          return false;
        }
      }

      let openDelim = null;
      let closeDelim = null;
      let isDisplay = false;

      if (src.charCodeAt(start) === 0x24 /* $ */) {
        if (start + 1 < max && src.charCodeAt(start + 1) === 0x24) {
          openDelim = '$$';
          closeDelim = '$$';
          isDisplay = true;
        } else {
          openDelim = '$';
          closeDelim = '$';
          isDisplay = false;
        }
      } else if (src.charCodeAt(start) === 0x5C /* \ */ && start + 1 < max) {
        const nextChar = src.charCodeAt(start + 1);
        if (nextChar === 0x28 /* ( */) {
          openDelim = '\\(';
          closeDelim = '\\)';
          isDisplay = false;
        } else if (nextChar === 0x5B /* [ */) {
          openDelim = '\\[';
          closeDelim = '\\]';
          isDisplay = true;
        }
      }

      if (!openDelim) return false;

      // Currency / whitespace check for single $
      if (openDelim === '$') {
        // Opening $ must not be followed by whitespace
        if (start + 1 >= max || /\s/.test(src.charAt(start + 1))) return false;
      }

      const contentStart = start + openDelim.length;
      let matchEnd = -1;
      let pos = contentStart;

      while (pos < max) {
        if (src.startsWith(closeDelim, pos)) {
          let backslashCount = 0;
          let p = pos - 1;
          while (p >= contentStart && src.charCodeAt(p) === 0x5C) {
            backslashCount++;
            p--;
          }
          if (backslashCount % 2 === 0) {
            if (closeDelim === '$') {
              // Closing $ must not be preceded by whitespace
              if (/\s/.test(src.charAt(pos - 1))) {
                pos++;
                continue;
              }
              // Closing $ must not be followed immediately by a digit (e.g. $10 and $20)
              if (pos + 1 < max && /\d/.test(src.charAt(pos + 1))) {
                pos++;
                continue;
              }
            }
            matchEnd = pos;
            break;
          }
        }
        // Single $ inline math cannot cross line breaks
        if (openDelim === '$' && src.charCodeAt(pos) === 0x0A /* \n */) {
          break;
        }
        pos++;
      }

      if (matchEnd === -1) return false;

      if (!silent) {
        const content = src.slice(contentStart, matchEnd);
        const token = state.push(isDisplay ? 'math_display_inline' : 'math_inline', 'math', 0);
        token.content = content;
        token.markup = openDelim;
      }

      state.pos = matchEnd + closeDelim.length;
      return true;
    }

    function mathBlock(state, startLine, endLine, silent) {
      let start = state.bMarks[startLine] + state.tShift[startLine];
      let max = state.eMarks[startLine];
      const src = state.src;

      let openDelim = null;
      let closeDelim = null;

      if (src.startsWith('$$', start)) {
        openDelim = '$$';
        closeDelim = '$$';
      } else if (src.startsWith('\\[', start)) {
        openDelim = '\\[';
        closeDelim = '\\]';
      }

      if (!openDelim) return false;

      let pos = start + openDelim.length;
      let haveEnd = false;
      let nextLine = startLine;
      let content = '';

      // Check if closing delimiter is on the same line
      let closePos = src.indexOf(closeDelim, pos);
      if (closePos !== -1 && closePos < max) {
        haveEnd = true;
        content = src.slice(pos, closePos);
      } else {
        const contentLines = [];
        const firstLineRest = src.slice(pos, max);
        if (firstLineRest.trim().length > 0) {
          contentLines.push(firstLineRest);
        }

        while (nextLine < endLine) {
          nextLine++;
          if (nextLine >= endLine) break;

          const lStart = state.bMarks[nextLine] + state.tShift[nextLine];
          const lMax = state.eMarks[nextLine];
          const lineStr = src.slice(lStart, lMax);

          if (lineStr.startsWith(closeDelim)) {
            haveEnd = true;
            break;
          }

          // Conservative recovery: if another opening delimiter appears without closing this one,
          // then this construct was unclosed — abort so we do not greedily consume across independent blocks
          if (lineStr.startsWith('\\[') || lineStr.startsWith('$$')) {
            return false;
          }

          contentLines.push(src.slice(state.bMarks[nextLine], lMax));
        }

        if (haveEnd) {
          content = contentLines.join('\n');
        }
      }

      if (!haveEnd) return false;
      if (silent) return true;

      state.line = nextLine + 1;
      const token = state.push('math_block', 'math', 0);
      token.block = true;
      token.content = content.trim();
      token.markup = openDelim;
      return true;
    }

    md.inline.ruler.before('escape', 'lucid_math_inline', mathInline);
    md.block.ruler.before('fence', 'lucid_math_block', mathBlock, {
      alt: ['paragraph', 'reference', 'blockquote', 'list']
    });

    md.renderer.rules.math_inline = function(tokens, idx, options, env) {
      const content = tokens[idx].content;
      const renderId = env && env.renderId ? String(env.renderId) : currentRenderRevision;
      const registry = getMathRegistry(renderId);
      const mathId = registry.size + 1;
      registry.set(mathId, { tex: content, displayMode: false, isBlock: false });

      if (env && env.isDeferredMath) {
        return '<span class="lucid-math-placeholder lucid-math-inline" data-math-id="' + mathId + '" data-render-id="' + renderId + '"><span class="lucid-math-raw">' + md.utils.escapeHtml(content) + '</span></span>';
      }
      return renderKaTeXInline(content, tokens[idx].markup, mathId, renderId);
    };

    md.renderer.rules.math_display_inline = function(tokens, idx, options, env) {
      const content = tokens[idx].content;
      const renderId = env && env.renderId ? String(env.renderId) : currentRenderRevision;
      const registry = getMathRegistry(renderId);
      const mathId = registry.size + 1;
      registry.set(mathId, { tex: content, displayMode: true, isBlock: false });

      if (env && env.isDeferredMath) {
        return '<span class="lucid-math-placeholder lucid-math-display lucid-math-display-inline" data-math-id="' + mathId + '" data-render-id="' + renderId + '"><span class="lucid-math-raw">' + md.utils.escapeHtml(content) + '</span></span>';
      }
      return renderKaTeXDisplayInline(content, tokens[idx].markup, mathId, renderId);
    };

    md.renderer.rules.math_block = function(tokens, idx, options, env) {
      const content = tokens[idx].content;
      const renderId = env && env.renderId ? String(env.renderId) : currentRenderRevision;
      const registry = getMathRegistry(renderId);
      const mathId = registry.size + 1;
      registry.set(mathId, { tex: content, displayMode: true, isBlock: true });

      if (env && env.isDeferredMath) {
        return '<div class="lucid-math-placeholder lucid-math-display" data-math-id="' + mathId + '" data-render-id="' + renderId + '"><div class="lucid-math-raw">' + md.utils.escapeHtml(content) + '</div></div>\n';
      }
      return renderKaTeXBlock(content, mathId, renderId) + '\n';
    };
  }

  md.use(lucidMathPlugin);

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
  let currentMermaidTheme = 'dark';

  // ============================================================
  // MERMAID BLUE-TINT THEME CONFIGURATION
  // ============================================================
  const LUCID_MERMAID_THEMES = {
    dark: {
      theme: 'base',
      themeVariables: {
        darkMode: true,
        background: '#1a1a1a',
        primaryColor: '#162032',           // Deep navy/slate-blue node surface
        primaryBorderColor: '#3b82f6',     // Clear medium blue border
        primaryTextColor: '#f1f5f9',       // High-contrast cool off-white text
        secondaryColor: '#1e293b',         // Differentiated blue-gray
        secondaryBorderColor: '#475569',
        secondaryTextColor: '#e2e8f0',
        tertiaryColor: '#0f172a',
        tertiaryBorderColor: '#334155',
        tertiaryTextColor: '#cbd5e1',
        lineColor: '#60a5fa',              // Brighter blue edges/arrows
        textColor: '#f1f5f9',
        mainBkg: '#162032',
        nodeBorder: '#3b82f6',
        clusterBkg: '#111827',             // Subtle blue-tint cluster background
        clusterBorder: '#2d3e58',
        defaultLinkColor: '#60a5fa',
        titleColor: '#93c5fd',
        edgeLabelBackground: '#171717',    // Matches reader background
        actorBkg: '#162032',
        actorBorder: '#3b82f6',
        actorTextColor: '#f1f5f9',
        actorLineColor: '#60a5fa',
        signalColor: '#60a5fa',
        signalTextColor: '#f1f5f9',
        labelBoxBkgColor: '#162032',
        labelBoxBorderColor: '#3b82f6',
        labelTextColor: '#f1f5f9',
        classText: '#f1f5f9',
        fillType0: '#162032',
        fillType1: '#1e293b',
        fillType2: '#0f172a',
        fontFamily: 'var(--lucid-font-family, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif)',
        fontSize: '13px'
      },
      themeCSS: `
        .node rect, .node circle, .node ellipse, .node polygon, .node path { stroke-width: 1.5px; }
        .edgePath .path { stroke-width: 1.5px; stroke: #60a5fa; }
        .arrowheadPath { fill: #60a5fa !important; stroke: #60a5fa !important; }
        .marker { fill: #60a5fa !important; stroke: #60a5fa !important; }
        .edgeLabel { background-color: #171717 !important; color: #cbd5e1 !important; }
        .cluster rect { rx: 6px; ry: 6px; }
      `
    },
    light: {
      theme: 'base',
      themeVariables: {
        darkMode: false,
        background: '#f6f8fa',
        primaryColor: '#f0f5ff',           // Very pale cool-blue node surface
        primaryBorderColor: '#2563eb',     // Clean medium blue border
        primaryTextColor: '#0f172a',       // Deep slate text
        secondaryColor: '#e0edff',
        secondaryBorderColor: '#3b82f6',
        secondaryTextColor: '#1e293b',
        tertiaryColor: '#f8faff',
        tertiaryBorderColor: '#93c5fd',
        tertiaryTextColor: '#334155',
        lineColor: '#2563eb',              // Blue edges/arrows
        textColor: '#0f172a',
        mainBkg: '#f0f5ff',
        nodeBorder: '#2563eb',
        clusterBkg: '#f8faff',             // Subtle cool cluster background
        clusterBorder: '#cbd5e1',
        defaultLinkColor: '#2563eb',
        titleColor: '#1d4ed8',
        edgeLabelBackground: '#ffffff',
        actorBkg: '#f0f5ff',
        actorBorder: '#2563eb',
        actorTextColor: '#0f172a',
        actorLineColor: '#2563eb',
        signalColor: '#2563eb',
        signalTextColor: '#0f172a',
        labelBoxBkgColor: '#f0f5ff',
        labelBoxBorderColor: '#2563eb',
        labelTextColor: '#0f172a',
        classText: '#0f172a',
        fillType0: '#f0f5ff',
        fillType1: '#e0edff',
        fillType2: '#f8faff',
        fontFamily: 'var(--lucid-font-family, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif)',
        fontSize: '13px'
      },
      themeCSS: `
        .node rect, .node circle, .node ellipse, .node polygon, .node path { stroke-width: 1.5px; }
        .edgePath .path { stroke-width: 1.5px; stroke: #2563eb; }
        .arrowheadPath { fill: #2563eb !important; stroke: #2563eb !important; }
        .marker { fill: #2563eb !important; stroke: #2563eb !important; }
        .edgeLabel { background-color: #ffffff !important; color: #334155 !important; }
        .cluster rect { rx: 6px; ry: 6px; }
      `
    },
    sepia: {
      theme: 'base',
      themeVariables: {
        darkMode: false,
        background: '#f5efe3',
        primaryColor: '#f0ece3',           // Warm-compatible muted surface
        primaryBorderColor: '#4a627a',     // Desaturated slate-blue border
        primaryTextColor: '#261e16',       // Deep sepia ink
        secondaryColor: '#e8e2d5',
        secondaryBorderColor: '#5c748c',
        secondaryTextColor: '#382d22',
        tertiaryColor: '#faf6ee',
        tertiaryBorderColor: '#8da0b3',
        tertiaryTextColor: '#4a3d31',
        lineColor: '#4a627a',              // Desaturated slate-blue edges
        textColor: '#261e16',
        mainBkg: '#f0ece3',
        nodeBorder: '#4a627a',
        clusterBkg: '#ede6d8',
        clusterBorder: '#c8bba8',
        defaultLinkColor: '#4a627a',
        titleColor: '#2d3f50',
        edgeLabelBackground: '#fcf8f2',
        actorBkg: '#f0ece3',
        actorBorder: '#4a627a',
        actorTextColor: '#261e16',
        actorLineColor: '#4a627a',
        signalColor: '#4a627a',
        signalTextColor: '#261e16',
        labelBoxBkgColor: '#f0ece3',
        labelBoxBorderColor: '#4a627a',
        labelTextColor: '#261e16',
        classText: '#261e16',
        fillType0: '#f0ece3',
        fillType1: '#e8e2d5',
        fillType2: '#faf6ee',
        fontFamily: 'var(--lucid-font-family, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif)',
        fontSize: '13px'
      },
      themeCSS: `
        .node rect, .node circle, .node ellipse, .node polygon, .node path { stroke-width: 1.5px; }
        .edgePath .path { stroke-width: 1.5px; stroke: #4a627a; }
        .arrowheadPath { fill: #4a627a !important; stroke: #4a627a !important; }
        .marker { fill: #4a627a !important; stroke: #4a627a !important; }
        .edgeLabel { background-color: #fcf8f2 !important; color: #4a3d31 !important; }
        .cluster rect { rx: 6px; ry: 6px; }
      `
    }
  };

  function getMermaidConfigForTheme(themeName) {
    const key = (themeName === 'light' || themeName === 'sepia') ? themeName : 'dark';
    const cfg = LUCID_MERMAID_THEMES[key];
    return {
      startOnLoad: false,
      theme: cfg.theme,
      themeVariables: cfg.themeVariables,
      themeCSS: cfg.themeCSS,
      securityLevel: 'loose',
      layout: 'dagre',
      flowchart: { defaultRenderer: 'dagre' }
    };
  }

  function ensureMermaidInitialized() {
    if (typeof mermaid !== 'undefined' && !mermaid._lucidInitialized) {
      try {
        mermaid.initialize(getMermaidConfigForTheme(currentMermaidTheme));
        mermaid._lucidInitialized = true;
      } catch (e) {
        console.warn('Failed to initialize Mermaid:', e);
      }
    }
  }

  function renderKaTeXBlock(trimmed, mathId, renderId) {
    const cacheKey = 'disp:' + trimmed;
    const cached = katexLRU.get(cacheKey);
    const mathAttr = (mathId ? ' data-math-id="' + mathId + '"' : '') +
                     (renderId ? ' data-render-id="' + renderId + '"' : '');
    if (cached) {
      return cached.replace(/^<div class="lucid-math-block"/, '<div class="lucid-math-block"' + mathAttr);
    }
    try {
      const rendered = katex.renderToString(trimmed, { displayMode: true, throwOnError: false });
      const res = '<div class="lucid-math-block"' + mathAttr + '>' +
             rendered +
             '<button class="lucid-btn-copy-latex" onclick="window.lucid.copyLatex(this)">Copy LaTeX</button>' +
             '</div>';
      katexLRU.set(cacheKey, '<div class="lucid-math-block">' + rendered + '<button class="lucid-btn-copy-latex" onclick="window.lucid.copyLatex(this)">Copy LaTeX</button></div>');
      return res;
    } catch (e) {
      return '<div class="lucid-math-error"><span class="lucid-error-msg">Formula render warning: ' + md.utils.escapeHtml(e.message || 'Syntax error') + '</span><pre>' + md.utils.escapeHtml(trimmed) + '</pre></div>';
    }
  }

  function renderKaTeXDisplayInline(trimmed, originalMarkup, mathId, renderId) {
    const cacheKey = 'disp_inline:' + trimmed;
    const cached = katexLRU.get(cacheKey);
    const mathAttr = (mathId ? ' data-math-id="' + mathId + '"' : '') +
                     (renderId ? ' data-render-id="' + renderId + '"' : '');
    if (cached) {
      return cached.replace(/^<span class="lucid-math-inline lucid-math-display-inline"/, '<span class="lucid-math-inline lucid-math-display-inline"' + mathAttr);
    }
    try {
      const rendered = katex.renderToString(trimmed, { displayMode: true, throwOnError: false });
      const res = '<span class="lucid-math-inline lucid-math-display-inline"' + mathAttr + '>' + rendered + '</span>';
      katexLRU.set(cacheKey, '<span class="lucid-math-inline lucid-math-display-inline">' + rendered + '</span>');
      return res;
    } catch (e) {
      const open = originalMarkup || '\\[';
      const close = (open === '\\[' ? '\\]' : '$$');
      return '<span class="lucid-math-error" title="' + md.utils.escapeHtml(e.message || 'Syntax error') + '">' + md.utils.escapeHtml(open + trimmed + close) + '</span>';
    }
  }

  function renderKaTeXInline(trimmed, originalMarkup, mathId, renderId) {
    const cacheKey = 'inline:' + trimmed;
    const cached = katexLRU.get(cacheKey);
    if (cached) return cached;
    try {
      const rendered = katex.renderToString(trimmed, { displayMode: false, throwOnError: false });
      katexLRU.set(cacheKey, rendered);
      return rendered;
    } catch (e) {
      const open = originalMarkup || '$';
      const close = (open === '\\(' ? '\\)' : '$');
      return '<span class="lucid-math-error" title="' + md.utils.escapeHtml(e.message || 'Syntax error') + '">' + md.utils.escapeHtml(open + trimmed + close) + '</span>';
    }
  }

  function enhancePlaceholder(ph) {
    if (!ph || !ph.parentNode) return;
    const isBlock = ph.tagName === 'DIV' || ph.classList.contains('lucid-math-block');
    const isDisplay = ph.classList.contains('lucid-math-display');
    const isDisplayInline = ph.classList.contains('lucid-math-display-inline');
    const mathId = parseInt(ph.getAttribute('data-math-id') || (ph.dataset && ph.dataset.mathId) || '0', 10);
    const renderId = ph.getAttribute('data-render-id') || (ph.dataset && ph.dataset.renderId) || currentRenderRevision;

    let rawLatex = '';
    const registry = renderMathRegistries.get(String(renderId));
    if (registry && registry.has(mathId)) {
      const entry = registry.get(mathId);
      rawLatex = entry.tex;
    } else {
      const attr = ph.getAttribute('data-raw-latex') || (ph.dataset && ph.dataset.rawLatex) || '';
      if (attr) {
        try { rawLatex = decodeURIComponent(attr); } catch (_) { rawLatex = attr; }
      }
    }

    if (rawLatex) {
      try {
        if (isBlock) {
          ph.outerHTML = renderKaTeXBlock(rawLatex, mathId, renderId);
        } else if (isDisplayInline) {
          ph.outerHTML = renderKaTeXDisplayInline(rawLatex, '$$', mathId, renderId);
        } else if (isDisplay) {
          ph.outerHTML = renderKaTeXBlock(rawLatex, mathId, renderId);
        } else {
          ph.outerHTML = renderKaTeXInline(rawLatex, '$', mathId, renderId);
        }
      } catch (e) {
        console.warn('KaTeX placeholder enhance error:', e);
        try { ph.remove(); } catch (_) {}
      }
    } else {
      ph.remove();
    }
  }

  function getRepresentativeFontSize(svg) {
    if (!svg) return 16;
    try {
      const labelEls = svg.querySelectorAll('.nodeLabel, .label, .node text, text, span');
      const fontSizes = [];
      for (let i = 0; i < labelEls.length; i++) {
        const fs = parseFloat(window.getComputedStyle(labelEls[i]).fontSize);
        if (!isNaN(fs) && fs > 0) {
          fontSizes.push(fs);
        }
      }
      if (fontSizes.length > 0) {
        fontSizes.sort(function(a, b) { return a - b; });
        return fontSizes[Math.floor(fontSizes.length / 2)];
      }
    } catch (e) {}
    return 16;
  }

  function computeSmartDiagramLayout(intrinsicWidth, intrinsicHeight, availWidth, maxAvailHeight, representativeFontSize, targetReadableFontSize) {
    const rf = (typeof representativeFontSize === 'number' && representativeFontSize > 0) ? representativeFontSize : 16;
    const tf = (typeof targetReadableFontSize === 'number' && targetReadableFontSize > 0) ? targetReadableFontSize : 13.5;

    if (!intrinsicWidth || intrinsicWidth <= 0 || !intrinsicHeight || intrinsicHeight <= 0 || !availWidth || availWidth <= 0) {
      return {
        scale: 1.0,
        isComplete: false,
        mode: 'fallback',
        targetHeight: 320
      };
    }

    // 1. Readability Floor: Scale required so that rendered label font size does not drop below targetReadableFontSize
    const readableMinimumScale = Math.min(1.0, tf / rf);

    // 2. Width-fitting scale: fit diagram to available reader width (up to 1.0, no upscaling beyond intrinsic)
    const widthFitScale = Math.min(1.0, availWidth / intrinsicWidth);

    // 3. Initial Scale: Priority 1 is readable labels.
    // If widthFitScale >= readableMinimumScale, diagram fits width while maintaining readability.
    // If widthFitScale < readableMinimumScale, clamp to readableMinimumScale to preserve readability.
    let initialScale = 1.0;
    let mode = 'complete';

    if (widthFitScale >= readableMinimumScale) {
      initialScale = widthFitScale;
      mode = 'complete';
    } else {
      initialScale = readableMinimumScale;
      mode = 'readableWorking';
    }

    // 4. Compute natural readable inline height
    const verticalPadding = 48; // 24px top + 24px bottom
    const scaledHeight = intrinsicHeight * initialScale;
    const naturalHeight = Math.round(scaledHeight + verticalPadding);

    // 5. Adaptive safe maximum height:
    // Allow tall diagrams (like ESP32 control flow) to expand inline so users can read them
    // naturally by scrolling the document, without needing Expand.
    // Cap at an adaptive ceiling (1200 - 2400px) to prevent pathological infinite pages.
    const winH = (typeof window !== 'undefined' && window.innerHeight) ? window.innerHeight : 900;
    const adaptiveCeiling = (maxAvailHeight && maxAvailHeight > 0)
      ? maxAvailHeight
      : Math.max(1200, Math.min(2400, Math.round(winH * 2.5)));

    const targetHeight = Math.round(Math.min(adaptiveCeiling, Math.max(180, naturalHeight)));
    const isComplete = (naturalHeight <= adaptiveCeiling) && (widthFitScale >= readableMinimumScale);

    return {
      scale: initialScale,
      isComplete: isComplete,
      mode: isComplete ? 'complete' : mode,
      targetHeight: targetHeight,
      naturalHeight: naturalHeight
    };
  }

  function formatMermaidContainer(c, optErr) {
    if (!c) return;
    const svg = c.querySelector('.mermaid-canvas svg') || c.querySelector('.mermaid svg');
    const isError = !!optErr ||
                    !!c.querySelector('.error-icon') ||
                    !!c.querySelector('.error-text') ||
                    (svg && svg.textContent && svg.textContent.includes('Syntax error'));
    if (isError) {
      const viewport = c.querySelector('.mermaid-viewport');
      const canvas = c.querySelector('.mermaid-canvas');
      if (viewport && canvas) {
        viewport.style.height = 'auto';
        viewport.style.minHeight = '60px';
        canvas.style.transform = 'none';
        let errorMsg = optErr ? (optErr.message || String(optErr)) : 'Syntax error';
        if (!optErr && svg) {
          const errTextEl = svg.querySelector('.error-text') || svg.querySelector('text');
          if (errTextEl && errTextEl.textContent) {
            errorMsg = errTextEl.textContent.trim();
          }
        }
        canvas.innerHTML = '<div class="lucid-mermaid-error" style="padding: 16px; font-family: var(--lucid-font-family, system-ui); color: #e06c75; font-size: 13px;">' +
                           '<div style="font-weight: 600; margin-bottom: 4px;">Mermaid couldn\'t render this diagram.</div>' +
                           '<div style="opacity: 0.85; font-size: 12px; font-family: monospace;">' + md.utils.escapeHtml(errorMsg) + '</div>' +
                           '</div>';
      }
      return;
    }
    if (!svg) return;
    const viewBox = svg.viewBox && svg.viewBox.baseVal;
    if (viewBox && viewBox.width > 0) {
      svg.style.maxWidth = 'none';
      svg.style.width = viewBox.width + 'px';
      svg.style.height = viewBox.height + 'px';

      const viewport = c.querySelector('.mermaid-viewport');
      const canvas = c.querySelector('.mermaid-canvas');
      if (viewport && canvas) {
        // Horizontal padding: 20px left + 20px right = 40px
        const availWidth = Math.max(100, (viewport.clientWidth || 800) - 40);

        // 1. Inspect real SVG label typography geometry
        const baseFontSize = getRepresentativeFontSize(svg);

        // 2. Smart layout: DEFAULT = SMART READABLE COMPLETE VIEW WHEN POSSIBLE
        const layout = computeSmartDiagramLayout(
          viewBox.width,
          viewBox.height,
          availWidth,
          0, // Inline: uses adaptive ceiling
          baseFontSize,
          13.5
        );
        const initialScale = layout.scale;

        // 3. Dynamic bounded viewport height based on diagram aspect ratio & readable scale
        viewport.style.height = layout.targetHeight + 'px';

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
        canvas.dataset.initialHeight = layout.targetHeight;
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
    invalidateHeadingPositions('mermaid');
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
        startProgrammaticScroll(id, el);
      }
      return;
    }

    e.preventDefault();
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidLinkClicked) {
      window.webkit.messageHandlers.lucidLinkClicked.postMessage(href);
    }
  });

  // Scroll Spy, Heading Cache & Anchor Restoration
  let programmaticScrollActive = false;
  let programmaticTargetHeadingId = null;
  let lastProgrammaticScrollEventTime = 0;
  let programmaticSettleTimer = null;
  const supportsScrollEnd = (typeof window !== 'undefined' && 'onscrollend' in window);
  let anchorRestoreActive = false;
  let anchorRestoreSettleTimer = null;
  let lastUserScrollTimestamp = 0;
  let lastResolvedScrollY = 0;
  let lastReportedHeadingId = null;
  let cachedHeadings = null; // Array of { id: string, top: number } sorted ascending
  let headingPositionsDirty = false;
  let headingRefreshTimer = null;
  let headingRefreshMaxTimer = null;
  const HEADING_REFRESH_SETTLE_MS = 60;
  const HEADING_REFRESH_MAX_MS = 250;
  let isScrollSpyPending = false;
  let lastScrollSpyTime = 0;
  const SCROLL_SPY_THROTTLE_MS = 100;
  let scrollSpyTrailingTimer = null;
  let currentActiveAnchor = null;

  function startProgrammaticScroll(id, targetEl) {
    programmaticTargetHeadingId = id;
    programmaticScrollActive = true;
    lastReportedHeadingId = id;
    lastProgrammaticScrollEventTime = (typeof performance !== 'undefined') ? performance.now() : Date.now();

    clearTimeout(programmaticSettleTimer);
    programmaticSettleTimer = setTimeout(onProgrammaticScrollSettled, 120);

    if (supportsScrollEnd) {
      window.addEventListener('scrollend', onScrollEndOnce, { once: true });
    }

    targetEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function onScrollEndOnce() {
    clearTimeout(programmaticSettleTimer);
    onProgrammaticScrollSettled();
  }

  function handleProgrammaticScrollEvent() {
    lastProgrammaticScrollEventTime = (typeof performance !== 'undefined') ? performance.now() : Date.now();
    clearTimeout(programmaticSettleTimer);
    programmaticSettleTimer = setTimeout(onProgrammaticScrollSettled, 120);
  }

  function onProgrammaticScrollSettled() {
    if (supportsScrollEnd) {
      window.removeEventListener('scrollend', onScrollEndOnce);
    }
    clearTimeout(programmaticSettleTimer);
    programmaticScrollActive = false;
    programmaticTargetHeadingId = null;
    evaluateActiveHeading();
  }

  function rebuildHeadingPositionCache() {
    const elements = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
    const list = [];
    const scrollY = window.scrollY || 0;
    for (let i = 0; i < elements.length; i++) {
      const el = elements[i];
      if (!el.id) continue;
      const rect = el.getBoundingClientRect();
      list.push({
        id: el.id,
        top: rect.top + scrollY
      });
    }
    list.sort(function(a, b) { return a.top - b.top; });
    cachedHeadings = list;
  }

  function invalidateHeadingPositions(reason) {
    headingPositionsDirty = true;

    clearTimeout(headingRefreshTimer);
    headingRefreshTimer = setTimeout(function() {
      performHeadingRefreshIfDirty();
    }, HEADING_REFRESH_SETTLE_MS);

    if (!headingRefreshMaxTimer) {
      headingRefreshMaxTimer = setTimeout(function() {
        performHeadingRefreshIfDirty();
      }, HEADING_REFRESH_MAX_MS);
    }
  }

  function performHeadingRefreshIfDirty() {
    clearTimeout(headingRefreshTimer);
    clearTimeout(headingRefreshMaxTimer);
    headingRefreshTimer = null;
    headingRefreshMaxTimer = null;

    if (!headingPositionsDirty) return;
    headingPositionsDirty = false;

    if (typeof requestAnimationFrame !== 'undefined') {
      requestAnimationFrame(function() {
        rebuildHeadingPositionCache();
        evaluateActiveHeading();
      });
    } else {
      rebuildHeadingPositionCache();
      evaluateActiveHeading();
    }
  }

  function resolveActiveHeading(options) {
    const headings = options.headings;
    if (!headings || headings.length === 0) return null;

    const scrollY = options.scrollY;
    const viewportHeight = options.viewportHeight;
    const documentHeight = options.documentHeight;
    const previousActiveId = options.previousActiveId;
    const previousScrollY = options.previousScrollY;
    const referenceY = (options.referenceY !== undefined) ? options.referenceY : 120;
    const hysteresis = (options.hysteresis !== undefined) ? options.hysteresis : 15;

    // 1. Top of document rule
    if (scrollY <= 50) {
      const firstTopViewport = headings[0].top - scrollY;
      if (firstTopViewport <= viewportHeight * 0.5) {
        return headings[0].id;
      }
      return null;
    }

    // 2. Bottom of document rule
    if (scrollY + viewportHeight >= documentHeight - 20) {
      const lastHeading = headings[headings.length - 1];
      const lastTopViewport = lastHeading.top - scrollY;
      if (lastTopViewport <= viewportHeight) {
        return lastHeading.id;
      }
    }

    // 3. Direction determination with deadband for sub-pixel noise
    const deltaY = scrollY - (previousScrollY !== null && previousScrollY !== undefined ? previousScrollY : scrollY);
    const direction = Math.abs(deltaY) < 1 ? 'stationary' : (deltaY > 0 ? 'downward' : 'upward');

    // 4. Binary search for natural candidate where heading.top <= scrollY + referenceY
    const targetDocY = scrollY + referenceY;
    let low = 0;
    let high = headings.length - 1;
    let candidateIndex = -1;

    while (low <= high) {
      const mid = (low + high) >> 1;
      if (headings[mid].top <= targetDocY) {
        candidateIndex = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (candidateIndex < 0) return null;
    const candidate = headings[candidateIndex];

    // 5. Stateful Hysteresis (applied between adjacent headings)
    if (previousActiveId && candidate.id !== previousActiveId) {
      let prevIndex = -1;
      for (let i = 0; i < headings.length; i++) {
        if (headings[i].id === previousActiveId) {
          prevIndex = i;
          break;
        }
      }
      if (prevIndex !== -1 && Math.abs(candidateIndex - prevIndex) === 1) {
        if (candidateIndex > prevIndex && direction !== 'upward') {
          const bViewportTop = candidate.top - scrollY;
          if (bViewportTop > referenceY - hysteresis) {
            return previousActiveId;
          }
        } else if (candidateIndex < prevIndex && direction !== 'downward') {
          const bHeading = headings[prevIndex];
          const bViewportTop = bHeading.top - scrollY;
          if (bViewportTop <= referenceY + hysteresis) {
            return previousActiveId;
          }
        }
      }
    }

    return candidate.id;
  }

  function evaluateActiveHeading() {
    if (programmaticScrollActive && programmaticTargetHeadingId) {
      return;
    }

    if (!cachedHeadings) {
      rebuildHeadingPositionCache();
    }
    if (!cachedHeadings || cachedHeadings.length === 0) return;

    const scrollY = window.scrollY || 0;
    const viewportHeight = window.innerHeight || 800;
    const documentHeight = (document.documentElement && document.documentElement.scrollHeight) || 1000;

    const activeId = resolveActiveHeading({
      headings: cachedHeadings,
      scrollY: scrollY,
      viewportHeight: viewportHeight,
      documentHeight: documentHeight,
      previousActiveId: lastReportedHeadingId,
      previousScrollY: lastResolvedScrollY,
      referenceY: 120,
      hysteresis: 15
    });

    lastResolvedScrollY = scrollY;

    if (activeId !== lastReportedHeadingId) {
      lastReportedHeadingId = activeId;
      if (activeId) {
        const el = document.getElementById(activeId);
        if (el && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidActiveHeading) {
          window.webkit.messageHandlers.lucidActiveHeading.postMessage({
            id: el.id,
            text: el.textContent.trim(),
            level: parseInt(el.tagName.substring(1), 10)
          });
        }
      } else {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidActiveHeading) {
          window.webkit.messageHandlers.lucidActiveHeading.postMessage({
            id: '',
            text: '',
            level: 0
          });
        }
      }
    }
  }

  function captureReadingAnchor() {
    const READING_REFERENCE_Y = 120;
    const hit = document.elementFromPoint ? document.elementFromPoint(window.innerWidth / 2, READING_REFERENCE_Y) : null;
    const block = hit ? hit.closest('h1, h2, h3, h4, h5, h6, p, pre, blockquote, table, .mermaid-container, .lucid-math-block, li') : null;
    const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
    const scrollRatio = maxScroll > 0 ? window.scrollY / maxScroll : 0;

    if (block && block.isConnected) {
      const rect = block.getBoundingClientRect();
      currentActiveAnchor = {
        element: block,
        viewportOffset: rect.top - READING_REFERENCE_Y,
        scrollRatioFallback: scrollRatio
      };
    } else {
      currentActiveAnchor = {
        element: null,
        viewportOffset: 0,
        scrollRatioFallback: scrollRatio
      };
    }
    return currentActiveAnchor;
  }

  function restoreReadingAnchor(anchorToRestore) {
    const anchor = anchorToRestore || currentActiveAnchor;
    if (!anchor) return;
    const READING_REFERENCE_Y = 120;

    const now = (typeof performance !== 'undefined') ? performance.now() : Date.now();
    const isActivelyScrolling = (now - lastUserScrollTimestamp < 150);
    if (isActivelyScrolling) return;

    let delta = 0;
    if (anchor.element && anchor.element.isConnected) {
      const rect = anchor.element.getBoundingClientRect();
      delta = rect.top - (READING_REFERENCE_Y + anchor.viewportOffset);
    } else if (anchor.scrollRatioFallback !== undefined) {
      const newMaxScroll = document.documentElement.scrollHeight - window.innerHeight;
      const targetY = anchor.scrollRatioFallback * newMaxScroll;
      delta = targetY - (window.scrollY || 0);
    }

    if (Math.abs(delta) > 1) {
      anchorRestoreActive = true;
      clearTimeout(anchorRestoreSettleTimer);

      function clearAnchorRestore() {
        clearTimeout(anchorRestoreSettleTimer);
        if (supportsScrollEnd) {
          window.removeEventListener('scrollend', clearAnchorRestore);
        }
        anchorRestoreActive = false;
      }

      if (supportsScrollEnd) {
        window.addEventListener('scrollend', clearAnchorRestore, { once: true });
      }
      anchorRestoreSettleTimer = setTimeout(clearAnchorRestore, 100);

      window.scrollBy(0, delta);
    }
  }

  window.addEventListener('scroll', function() {
    const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
    const fraction = maxScroll > 0 ? window.scrollY / maxScroll : 0;
    const intensity = Math.max(0, Math.min(1, window.scrollY / 28));
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidScroll) {
      window.webkit.messageHandlers.lucidScroll.postMessage({ fraction: fraction, scrolled: window.scrollY > 6, intensity: intensity });
    }

    if (anchorRestoreActive) {
      return;
    }

    if (programmaticScrollActive) {
      handleProgrammaticScrollEvent();
    } else {
      lastUserScrollTimestamp = (typeof performance !== 'undefined') ? performance.now() : Date.now();

      if (!isScrollSpyPending) {
        isScrollSpyPending = true;
        if (typeof requestAnimationFrame !== 'undefined') {
          requestAnimationFrame(function(timestamp) {
            isScrollSpyPending = false;
            const now = (typeof performance !== 'undefined') ? performance.now() : Date.now();
            if (now - lastScrollSpyTime >= SCROLL_SPY_THROTTLE_MS) {
              lastScrollSpyTime = now;
              evaluateActiveHeading();
            } else {
              scheduleTrailingScrollSpy();
            }
          });
        } else {
          isScrollSpyPending = false;
          evaluateActiveHeading();
        }
      }

      scheduleTrailingScrollSpy();
    }
  }, { passive: true });

  function scheduleTrailingScrollSpy() {
    clearTimeout(scrollSpyTrailingTimer);
    scrollSpyTrailingTimer = setTimeout(function() {
      evaluateActiveHeading();
    }, SCROLL_SPY_THROTTLE_MS + 20);
  }

  // Public API
  window.lucid = {
    updateContent: function(rawMarkdown, renderId) {
      renderId = String(renderId || '0');
      currentRenderRevision = renderId;
      pruneOldRegistries(renderId);
      LucidPerf.mark(renderId, 't4_js_received', { length: rawMarkdown ? rawMarkdown.length : 0 });
      const container = document.getElementById('lucid-content');
      if (!container) return;

      LucidPerf.mark(renderId, 't6_md_render_begin');
      const env = { renderId: renderId, isDeferredMath: false };
      const tokens = md.parse(rawMarkdown || '', env);

      let mathCount = 0;
      for (let i = 0; i < tokens.length; i++) {
        const t = tokens[i];
        if (t.type === 'math_block') mathCount++;
        else if (t.type === 'inline' && t.children) {
          for (let j = 0; j < t.children.length; j++) {
            const c = t.children[j];
            if (c.type === 'math_inline' || c.type === 'math_display_inline') mathCount++;
          }
        }
      }
      const isDeferredMath = (mathCount > 30);
      env.isDeferredMath = isDeferredMath;

      let html = md.renderer.render(tokens, md.options, env);
      LucidPerf.mark(renderId, 't6_md_render_end', { count: mathCount, deferred: isDeferredMath });

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
      invalidateHeadingPositions('updateContent');
    },

    updatePreferences: function(prefs) {
      const root = document.documentElement;
      const body = document.body;

      if (prefs.theme) {
        body.setAttribute('data-theme', prefs.theme);
        body.className = 'vscode-body ' + (prefs.theme === 'dark' ? 'vscode-dark' : (prefs.theme === 'light' ? 'vscode-light' : 'vscode-sepia'));
        const newThemeName = (prefs.theme === 'light' || prefs.theme === 'sepia') ? prefs.theme : 'dark';
        if (typeof mermaid !== 'undefined' && currentMermaidTheme !== newThemeName) {
          currentMermaidTheme = newThemeName;
          try {
            mermaid.initialize(getMermaidConfigForTheme(currentMermaidTheme));
            // Re-render Mermaid diagrams with new theme without full document re-render
            const containers = document.querySelectorAll('.mermaid-container');
            containers.forEach(function(c) {
              const rawAttr = c.getAttribute('data-raw-mermaid');
              const canvas = c.querySelector('.mermaid-canvas');
              if (rawAttr && canvas) {
                let rawCode = '';
                try { rawCode = decodeURIComponent(rawAttr); } catch (_) { rawCode = rawAttr; }
                const preparedCode = sanitizeMermaidSource(rawCode);
                const id = 'mermaid-dyn-' + Math.random().toString(36).substring(2, 9);
                mermaid.render(id, preparedCode).then(function(res) {
                  canvas.innerHTML = res.svg;
                  formatMermaidContainer(c);
                }).catch(function(err) {
                  console.warn('Mermaid dynamic re-render error:', err);
                  formatMermaidContainer(c, err);
                });
              }
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

    handleDiagramPointerDown: function(e, viewport) {
      const isPanActive = viewport.classList.contains('is-panning') || e.spaceKey || e.button === 1;
      if (!isPanActive) return;
      if (e.button !== 0 && e.button !== 1) return;
      e.preventDefault();

      const canvas = viewport.querySelector('.mermaid-canvas');
      if (!canvas) return;

      const pointerId = e.pointerId;
      if (typeof viewport.setPointerCapture === 'function' && pointerId !== undefined) {
        try {
          viewport.setPointerCapture(pointerId);
        } catch (err) {}
      }

      viewport.classList.add('is-dragging');
      document.body.classList.add('lucid-diagram-dragging');

      const panStartX = parseFloat(canvas.dataset.tx || '0');
      const panStartY = parseFloat(canvas.dataset.ty || '0');
      const scale = parseFloat(canvas.dataset.scale || '1.0');
      const pointerStartX = e.clientX;
      const pointerStartY = e.clientY;

      let nextTx = panStartX;
      let nextTy = panStartY;
      let rafId = null;

      function renderTransform() {
        rafId = null;
        canvas.style.transform = 'translate(' + nextTx + 'px, ' + nextTy + 'px) scale(' + scale + ')';
        canvas.dataset.tempTx = nextTx;
        canvas.dataset.tempTy = nextTy;
      }

      function onPointerMove(moveEvent) {
        if (pointerId !== undefined && moveEvent.pointerId !== undefined && moveEvent.pointerId !== pointerId) return;
        const dx = moveEvent.clientX - pointerStartX;
        const dy = moveEvent.clientY - pointerStartY;
        nextTx = panStartX + dx;
        nextTy = panStartY + dy;

        if (!rafId) {
          rafId = requestAnimationFrame(renderTransform);
        }
      }

      function cleanup() {
        if (rafId) {
          cancelAnimationFrame(rafId);
          renderTransform();
        }
        viewport.classList.remove('is-dragging');
        document.body.classList.remove('lucid-diagram-dragging');

        if (typeof viewport.releasePointerCapture === 'function' && pointerId !== undefined) {
          try {
            if (viewport.hasPointerCapture(pointerId)) {
              viewport.releasePointerCapture(pointerId);
            }
          } catch (err) {}
        }

        viewport.removeEventListener('pointermove', onPointerMove);
        viewport.removeEventListener('pointerup', onPointerUp);
        viewport.removeEventListener('pointercancel', onPointerCancel);
        viewport.removeEventListener('lostpointercapture', onPointerCancel);
        window.removeEventListener('pointermove', onPointerMove);
        window.removeEventListener('pointerup', onPointerUp);
        window.removeEventListener('pointercancel', onPointerCancel);
        window.removeEventListener('mousemove', onPointerMove);
        window.removeEventListener('mouseup', onPointerUp);
        window.removeEventListener('blur', onPointerCancel);

        if (canvas.dataset.tempTx !== undefined) {
          canvas.dataset.tx = canvas.dataset.tempTx;
          canvas.dataset.ty = canvas.dataset.tempTy;
          canvas.dataset.userInteracted = 'true';
          delete canvas.dataset.tempTx;
          delete canvas.dataset.tempTy;
        }
      }

      function onPointerUp(upEvent) {
        if (pointerId !== undefined && upEvent.pointerId !== undefined && upEvent.pointerId !== pointerId) return;
        cleanup();
      }

      function onPointerCancel(cancelEvent) {
        if (pointerId !== undefined && cancelEvent && cancelEvent.pointerId !== undefined && cancelEvent.pointerId !== pointerId) return;
        cleanup();
      }

      viewport.addEventListener('pointermove', onPointerMove);
      viewport.addEventListener('pointerup', onPointerUp);
      viewport.addEventListener('pointercancel', onPointerCancel);
      viewport.addEventListener('lostpointercapture', onPointerCancel);
      window.addEventListener('pointermove', onPointerMove);
      window.addEventListener('pointerup', onPointerUp);
      window.addEventListener('pointercancel', onPointerCancel);
      window.addEventListener('mousemove', onPointerMove);
      window.addEventListener('mouseup', onPointerUp);
      window.addEventListener('blur', onPointerCancel);
    },

    handleDiagramMouseDown: function(e, viewport) {
      window.lucid.handleDiagramPointerDown(e, viewport);
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
      canvas.dataset.userInteracted = 'true';
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
      const initialHeight = canvas.dataset.initialHeight ? parseFloat(canvas.dataset.initialHeight) : null;

      canvas.dataset.scale = initialScale;
      canvas.dataset.tx = initialTx;
      canvas.dataset.ty = initialTy;
      delete canvas.dataset.userInteracted;
      canvas.style.transform = 'translate(' + initialTx + 'px, ' + initialTy + 'px) scale(' + initialScale + ')';

      const viewport = container ? container.querySelector('.mermaid-viewport') : null;
      if (viewport && initialHeight) {
        viewport.style.height = initialHeight + 'px';
      }
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

      const availWidth = Math.max(100, viewport.clientWidth - 40);
      const availHeight = Math.max(100, viewport.clientHeight - 48);

      const fitScale = Math.min(availWidth / unscaledWidth, availHeight / unscaledHeight, 1.5);
      const contentOffsetX = parseFloat(canvas.dataset.contentOffsetX || '0');
      const contentOffsetY = parseFloat(canvas.dataset.contentOffsetY || '0');
      const fitTx = Math.round(contentOffsetX * fitScale);
      const fitTy = Math.round(contentOffsetY * fitScale);

      canvas.dataset.scale = fitScale;
      canvas.dataset.tx = fitTx;
      canvas.dataset.ty = fitTy;
      canvas.dataset.userInteracted = 'true';
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
            '<div class="lucid-mermaid-modal-body" onpointerdown="window.lucid.handleDiagramPointerDown(event, this)">' +
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
      let contentOffsetX = 0;
      let contentOffsetY = 0;
      if (modalSvg) {
        modalSvg.style.maxWidth = 'none';
        modalSvg.style.display = 'block';
        const viewBox = modalSvg.viewBox && modalSvg.viewBox.baseVal;
        if (viewBox && viewBox.width > 0) {
          modalSvg.style.width = viewBox.width + 'px';
          modalSvg.style.height = viewBox.height + 'px';
          const availWidth = Math.max(100, (modalViewport ? modalViewport.clientWidth : 800) - 64);
          const availHeight = Math.max(100, (modalViewport ? modalViewport.clientHeight : 600) - 80);
          const baseFontSize = getRepresentativeFontSize(modalSvg);
          const layout = computeSmartDiagramLayout(
            viewBox.width,
            viewBox.height,
            availWidth,
            availHeight,
            baseFontSize,
            13.5
          );
          modalInitialScale = layout.scale;

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
      modalCanvas.dataset.contentOffsetX = contentOffsetX;
      modalCanvas.dataset.contentOffsetY = contentOffsetY;
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
        startProgrammaticScroll(id, el);
      }
    },

    setScrollFraction: function(fraction) {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
      if (maxScroll > 0) {
        programmaticScrollActive = true;
        window.scrollTo({ top: fraction * maxScroll, behavior: 'instant' });
        setTimeout(function() {
          programmaticScrollActive = false;
          evaluateActiveHeading();
        }, 50);
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
      if (!container) return;
      let latex = '';
      const mathId = parseInt(container.getAttribute('data-math-id') || (container.dataset && container.dataset.mathId) || '0', 10);
      const renderId = container.getAttribute('data-render-id') || (container.dataset && container.dataset.renderId) || currentRenderRevision;
      const registry = renderMathRegistries.get(String(renderId));
      if (registry && registry.has(mathId)) {
        latex = registry.get(mathId).tex;
      } else if (container.dataset && container.dataset.rawLatex) {
        latex = decodeURIComponent(container.dataset.rawLatex);
      }
      if (latex) {
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
    },

    getCurrentRevision: function() {
      return currentRenderRevision;
    },

    computeSmartDiagramLayout: computeSmartDiagramLayout,
    getRepresentativeFontSize: getRepresentativeFontSize,
    resolveActiveHeading: resolveActiveHeading,
    captureReadingAnchor: captureReadingAnchor,
    restoreReadingAnchor: restoreReadingAnchor,
    invalidateHeadingPositions: invalidateHeadingPositions,
    rebuildHeadingPositionCache: rebuildHeadingPositionCache,
    evaluateActiveHeading: evaluateActiveHeading,
    getCachedHeadings: function() { return cachedHeadings; },
    getLastReportedHeadingId: function() { return lastReportedHeadingId; },
    setLastReportedHeadingId: function(id) { lastReportedHeadingId = id; },
    isProgrammaticScrollActive: function() { return programmaticScrollActive; }
  };

  let resizeTimer = null;
  if (typeof window !== 'undefined') {
    window.addEventListener('resize', function() {
      if (resizeTimer) clearTimeout(resizeTimer);
      resizeTimer = setTimeout(function() {
        // Settle logic: only update diagrams that have NOT been manually interacted with
        document.querySelectorAll('.mermaid-container').forEach(function(c) {
          const canvas = c.querySelector('.mermaid-canvas');
          if (canvas && !canvas.dataset.userInteracted) {
            formatMermaidContainer(c);
          }
        });
      }, 200);
    });
  }

  function isRenderingStackReady() {
    return typeof window.markdownit !== 'undefined' &&
           typeof window.katex !== 'undefined' &&
           typeof window.hljs !== 'undefined';
  }

  function notifyBridgeReady() {
    if (!isRenderingStackReady()) {
      setTimeout(notifyBridgeReady, 10);
      return;
    }
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
