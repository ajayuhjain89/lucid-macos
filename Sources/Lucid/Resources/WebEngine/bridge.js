(function() {
  // Alert Icons SVG definitions (12 types)
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

  // Initialize Turndown Service for In-Place WYSIWYG Editing
  let turndownService = null;
  if (typeof TurndownService !== 'undefined') {
    turndownService = new TurndownService({
      headingStyle: 'atx',
      codeBlockStyle: 'fenced',
      bulletListMarker: '-'
    });

    // Rule: KaTeX display math
    turndownService.addRule('katexDisplay', {
      filter: function(node) {
        return node.classList && node.classList.contains('lucid-math-block');
      },
      replacement: function(content, node) {
        const raw = node.getAttribute('data-raw-latex');
        return raw ? '\n\n$$\n' + decodeURIComponent(raw) + '\n$$\n\n' : content;
      }
    });

    // Rule: Mermaid diagrams
    turndownService.addRule('mermaidBlock', {
      filter: function(node) {
        return node.classList && node.classList.contains('mermaid-wrapper');
      },
      replacement: function(content, node) {
        const raw = node.getAttribute('data-raw-mermaid');
        return raw ? '\n\n```mermaid\n' + decodeURIComponent(raw) + '\n```\n\n' : content;
      }
    });

    // Rule: Code blocks
    turndownService.addRule('codeBlock', {
      filter: function(node) {
        return node.classList && node.classList.contains('lucid-code-block');
      },
      replacement: function(content, node) {
        const langEl = node.querySelector('.lucid-code-lang');
        const lang = langEl ? langEl.textContent.trim().toLowerCase() : '';
        const codeEl = node.querySelector('pre code');
        const code = codeEl ? codeEl.innerText : '';
        return '\n\n```' + lang + '\n' + code + '\n```\n\n';
      }
    });
  }

  // Initialize Markdown-it with highlight.js integration
  const md = window.markdownit({
    html: true,
    linkify: true,
    typographer: true,
    highlight: function(str, lang) {
      if (lang === 'mermaid') {
        const escapedRaw = encodeURIComponent(str);
        return '<div class="mermaid-wrapper" data-raw-mermaid="' + escapedRaw + '">' +
               '<div class="mermaid-toolbar">' +
               '<button class="lucid-btn-copy-svg" onclick="window.lucid.copySvg(this)">Copy SVG</button>' +
               '<button class="lucid-btn-save-svg" onclick="window.lucid.saveSvg(this)">Download SVG</button>' +
               '</div>' +
               '<div class="mermaid">' + md.utils.escapeHtml(str) + '</div>' +
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

      const langLabel = (lang || 'TEXT').toUpperCase();
      return '<div class="lucid-code-block">' +
             '<div class="lucid-code-header">' +
             '<span class="lucid-code-lang">' + langLabel + '</span>' +
             '<button class="lucid-btn-copy-code" onclick="window.lucid.copyCode(this)">Copy</button>' +
             '</div>' +
             '<pre><code class="hljs language-' + md.utils.escapeHtml(lang || '') + '">' + highlighted + '</code></pre>' +
             '</div>';
    }
  });

  // Attach plugins if available
  if (window.markdownitSub) md.use(window.markdownitSub);
  if (window.markdownitSup) md.use(window.markdownitSup);
  if (window.markdownitIns) md.use(window.markdownitIns);
  if (window.markdownitMark) md.use(window.markdownitMark);
  if (window.markdownitDeflist) md.use(window.markdownitDeflist);
  if (window.markdownitAbbr) md.use(window.markdownitAbbr);
  if (window.markdownitTaskList) md.use(window.markdownitTaskList, { enabled: true });

  // Custom slugify for heading IDs
  function slugify(text) {
    return text.toLowerCase().trim()
      .replace(/[^\w\s-]/g, '')
      .replace(/[\s_-]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  // Heading ID injection rule
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

  // GitHub Alert parsing (matches extension circular icon badge and uppercase title)
  function parseAlerts(html) {
    const alertRegex = /<blockquote>\s*<p>\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION|EXAMPLE|QUESTION|QUOTE|ABSTRACT|BUG|INFO|SUCCESS|FAILURE)\]([+-]?)(?:\s*([^\n<]*))?(?:\s*<br\s*\/?>)?([\s\S]*?)<\/p>\s*([\s\S]*?)<\/blockquote>/gi;
    return html.replace(alertRegex, function(match, type, collapseFlag, customTitle, firstLine, rest) {
      const alertType = type.toLowerCase();
      const icon = ALERT_ICONS[alertType] || ALERT_ICONS.note;
      const titleText = customTitle && customTitle.trim() ? customTitle.trim() : alertType;
      const content = (firstLine && firstLine.trim() ? '<p>' + firstLine.trim() + '</p>' : '') + rest;

      const titleHtml = '<div class="lucid-alert-title"><span class="lucid-alert-icon">' + icon + '</span>' + titleText + '</div>';

      if (collapseFlag === '-' || collapseFlag === '+') {
        const isOpen = collapseFlag === '+' ? ' open' : '';
        return '<details class="lucid-alert lucid-alert-' + alertType + '"' + isOpen + '>' +
               '<summary>' + titleHtml + '</summary>' +
               '<div class="lucid-alert-content">' + content + '</div>' +
               '</details>';
      }

      return '<div class="lucid-alert lucid-alert-' + alertType + '">' +
             titleHtml +
             '<div class="lucid-alert-content">' + content + '</div>' +
             '</div>';
    });
  }

  // KaTeX Math & Chemistry parsing
  function parseKaTeX(text) {
    if (typeof katex === 'undefined') return text;
    // Block math: $$ ... $$
    text = text.replace(/\$\$([\s\S]+?)\$\$/g, function(match, math) {
      try {
        const rendered = katex.renderToString(math.trim(), { displayMode: true, throwOnError: false });
        const escapedRaw = encodeURIComponent(math.trim());
        return '<div class="lucid-math-block" data-raw-latex="' + escapedRaw + '">' +
               rendered +
               '<button class="lucid-btn-copy-latex" onclick="window.lucid.copyLatex(this)">Copy LaTeX</button>' +
               '</div>';
      } catch (e) {
        return match;
      }
    });
    // Inline math: $ ... $
    text = text.replace(/(^|[^\\])\$([^\$\n]+?)\$/g, function(match, prefix, math) {
      try {
        return prefix + katex.renderToString(math.trim(), { displayMode: false, throwOnError: false });
      } catch (e) {
        return match;
      }
    });
    return text;
  }

  // Extract headings
  function extractHeadings() {
    const headings = [];
    const elements = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
    elements.forEach(function(el) {
      const level = parseInt(el.tagName.substring(1), 10);
      headings.push({
        id: el.id,
        level: level,
        text: el.textContent.trim()
      });
    });
    return headings;
  }

  // Footnote Tooltip Setup
  function setupFootnotes() {
    const footnotes = document.querySelectorAll('a.footnote-ref, a[href^="#fn"]');
    footnotes.forEach(function(fnLink) {
      fnLink.addEventListener('mouseenter', function(e) {
        const targetId = fnLink.getAttribute('href').replace('#', '');
        const targetEl = document.getElementById(targetId);
        if (!targetEl) return;

        let tooltip = document.getElementById('lucid-active-footnote-tooltip');
        if (!tooltip) {
          tooltip = document.createElement('div');
          tooltip.id = 'lucid-active-footnote-tooltip';
          tooltip.className = 'lucid-footnote-tooltip';
          document.body.appendChild(tooltip);
        }

        tooltip.innerHTML = targetEl.innerHTML;
        const rect = fnLink.getBoundingClientRect();
        tooltip.style.left = Math.min(window.innerWidth - 340, Math.max(10, rect.left + window.scrollX - 20)) + 'px';
        tooltip.style.top = (rect.bottom + window.scrollY + 8) + 'px';
        tooltip.style.display = 'block';
      });

      fnLink.addEventListener('mouseleave', function() {
        const tooltip = document.getElementById('lucid-active-footnote-tooltip');
        if (tooltip) tooltip.style.display = 'none';
      });
    });
  }

  // Live in-place editing listener
  let isEditingByUser = false;
  let editDebounceTimer = null;

  function setupInPlaceEditing() {
    const container = document.getElementById('lucid-content');
    if (!container) return;

    container.setAttribute('contenteditable', 'true');
    container.setAttribute('spellcheck', 'false');

    container.addEventListener('input', function() {
      if (!turndownService) return;
      isEditingByUser = true;
      clearTimeout(editDebounceTimer);
      editDebounceTimer = setTimeout(function() {
        try {
          const newMarkdown = turndownService.turndown(container.innerHTML);
          if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidContentEdited) {
            window.webkit.messageHandlers.lucidContentEdited.postMessage(newMarkdown);
          }
        } catch (e) {
          console.warn('Turndown error:', e);
        }
        setTimeout(function() { isEditingByUser = false; }, 200);
      }, 350);
    });
  }

  // Scroll Spy
  let isProgrammaticScroll = false;
  let activeHeadingTimer = null;
  window.addEventListener('scroll', function() {
    if (isProgrammaticScroll) return;

    const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
    const fraction = maxScroll > 0 ? window.scrollY / maxScroll : 0;
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidScroll) {
      window.webkit.messageHandlers.lucidScroll.postMessage({ fraction: fraction });
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

  // In-Page Find state
  let findMatches = [];
  let findCurrentIndex = -1;

  // Public API
  window.lucid = {
    updateContent: function(rawMarkdown) {
      if (isEditingByUser) return; // Avoid clobbering user cursor while typing

      const container = document.getElementById('lucid-content');
      if (!container) return;

      const preprocessed = parseKaTeX(rawMarkdown);
      let html = md.render(preprocessed);
      html = parseAlerts(html);
      container.innerHTML = html;

      // Render Mermaid diagrams
      if (typeof mermaid !== 'undefined') {
        const mermaidNodes = container.querySelectorAll('.mermaid');
        if (mermaidNodes.length > 0) {
          try {
            mermaid.run({ nodes: mermaidNodes });
          } catch (e) {
            console.warn('Mermaid render error:', e);
          }
        }
      }

      setupFootnotes();
      setupInPlaceEditing();

      const headings = extractHeadings();
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidHeadings) {
        window.webkit.messageHandlers.lucidHeadings.postMessage(headings);
      }
    },

    setEditable: function(enabled) {
      const container = document.getElementById('lucid-content');
      if (container) {
        container.setAttribute('contenteditable', enabled ? 'true' : 'false');
      }
    },

    updatePreferences: function(prefs) {
      const root = document.documentElement;
      const body = document.body;

      if (prefs.theme) body.setAttribute('data-theme', prefs.theme);
      if (prefs.fontFamily) root.style.setProperty('--lucid-font-family', prefs.fontFamily);
      if (prefs.fontSize) root.style.setProperty('--lucid-font-size', prefs.fontSize + 'px');
      if (prefs.lineHeight) root.style.setProperty('--lucid-line-height', prefs.lineHeight);
      if (prefs.contentWidth) root.style.setProperty('--lucid-content-width', prefs.contentWidth);
      if (prefs.accentColor) root.style.setProperty('--lucid-accent', prefs.accentColor);
      if (typeof prefs.breakout !== 'undefined') {
        if (prefs.breakout) body.classList.remove('no-breakout');
        else body.classList.add('no-breakout');
      }
      if (typeof prefs.clickToEdit !== 'undefined') {
        window.lucid.setEditable(prefs.clickToEdit);
      }
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

    find: function(query) {
      window.lucid.clearFind();
      if (!query || query.trim().length === 0) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidFindMatches) {
          window.webkit.messageHandlers.lucidFindMatches.postMessage({ count: 0, index: 0 });
        }
        return;
      }

      const container = document.getElementById('lucid-content');
      if (!container) return;

      const walker = document.createTreeWalker(container, NodeFilter.SHOW_TEXT, null, false);
      const nodesToReplace = [];
      const regex = new RegExp(query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi');

      let node;
      while ((node = walker.nextNode())) {
        if (node.parentNode && (node.parentNode.tagName === 'SCRIPT' || node.parentNode.tagName === 'STYLE')) continue;
        if (regex.test(node.nodeValue)) {
          nodesToReplace.push(node);
        }
      }

      findMatches = [];
      nodesToReplace.forEach(function(textNode) {
        const span = document.createElement('span');
        span.innerHTML = textNode.nodeValue.replace(regex, function(match) {
          return '<mark class="lucid-find-match">' + match + '</mark>';
        });
        textNode.parentNode.replaceChild(span, textNode);
      });

      findMatches = Array.from(document.querySelectorAll('mark.lucid-find-match'));
      findCurrentIndex = findMatches.length > 0 ? 0 : -1;

      if (findCurrentIndex >= 0) {
        findMatches[findCurrentIndex].classList.add('lucid-find-active');
        findMatches[findCurrentIndex].scrollIntoView({ behavior: 'smooth', block: 'center' });
      }

      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidFindMatches) {
        window.webkit.messageHandlers.lucidFindMatches.postMessage({
          count: findMatches.length,
          index: findCurrentIndex + 1
        });
      }
    },

    findNext: function() {
      if (findMatches.length === 0) return;
      findMatches[findCurrentIndex].classList.remove('lucid-find-active');
      findCurrentIndex = (findCurrentIndex + 1) % findMatches.length;
      findMatches[findCurrentIndex].classList.add('lucid-find-active');
      findMatches[findCurrentIndex].scrollIntoView({ behavior: 'smooth', block: 'center' });

      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidFindMatches) {
        window.webkit.messageHandlers.lucidFindMatches.postMessage({
          count: findMatches.length,
          index: findCurrentIndex + 1
        });
      }
    },

    findPrev: function() {
      if (findMatches.length === 0) return;
      findMatches[findCurrentIndex].classList.remove('lucid-find-active');
      findCurrentIndex = (findCurrentIndex - 1 + findMatches.length) % findMatches.length;
      findMatches[findCurrentIndex].classList.add('lucid-find-active');
      findMatches[findCurrentIndex].scrollIntoView({ behavior: 'smooth', block: 'center' });

      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidFindMatches) {
        window.webkit.messageHandlers.lucidFindMatches.postMessage({
          count: findMatches.length,
          index: findCurrentIndex + 1
        });
      }
    },

    clearFind: function() {
      findMatches = [];
      findCurrentIndex = -1;
      const marks = document.querySelectorAll('mark.lucid-find-match');
      marks.forEach(function(m) {
        const parent = m.parentNode;
        parent.replaceChild(document.createTextNode(m.textContent), m);
        parent.normalize();
      });
    },

    copyCode: function(btn) {
      const pre = btn.closest('.lucid-code-block').querySelector('pre code');
      if (pre) {
        navigator.clipboard.writeText(pre.innerText).then(function() {
          const original = btn.innerText;
          btn.innerText = 'Copied!';
          setTimeout(function() { btn.innerText = original; }, 1800);
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
      const wrapper = btn.closest('.mermaid-wrapper');
      const svg = wrapper ? wrapper.querySelector('svg') : null;
      if (svg) {
        navigator.clipboard.writeText(svg.outerHTML).then(function() {
          const original = btn.innerText;
          btn.innerText = 'Copied!';
          setTimeout(function() { btn.innerText = original; }, 1800);
        });
      }
    },

    saveSvg: function(btn) {
      const wrapper = btn.closest('.mermaid-wrapper');
      const svg = wrapper ? wrapper.querySelector('svg') : null;
      if (svg) {
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
    },

    getStandaloneHTML: function() {
      return document.documentElement.outerHTML;
    }
  };

  if (typeof mermaid !== 'undefined') {
    mermaid.initialize({
      startOnLoad: false,
      theme: 'neutral',
      securityLevel: 'loose'
    });
  }
})();
