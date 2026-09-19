(function() {
  // Alert Icons SVG definitions
  const ALERT_ICONS = {
    note: '<svg viewBox="0 0 16 16"><path d="M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8Zm8-6.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13ZM6.5 7.75A.75.75 0 0 1 7.25 7h1a.75.75 0 0 1 .75.75v2.75h.25a.75.75 0 0 1 0 1.5h-2.5a.75.75 0 0 1 0-1.5h.25v-2h-.25a.75.75 0 0 1-.75-.75ZM8 6a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"></path></svg>',
    tip: '<svg viewBox="0 0 16 16"><path d="M8 1.5c-2.363 0-4 1.69-4 3.75 0 .984.424 1.625.984 2.304l.214.253c.223.264.47.556.673.848.284.411.537.896.621 1.49a.75.75 0 0 1-1.484.211c-.04-.282-.163-.547-.37-.847a8.456 8.456 0 0 0-.542-.68c-.09-.106-.188-.22-.294-.346C3.12 7.677 2.5 6.75 2.5 5.25 2.5 2.31 4.97 0 8 0s5.5 2.31 5.5 5.25c0 1.5-.62 2.427-1.306 3.238-.106.126-.204.24-.294.346-.176.208-.356.42-.542.68-.207.3-.33.565-.37.847a.75.75 0 0 1-1.485-.212c.084-.593.337-1.078.621-1.489.203-.292.45-.584.673-.848.075-.088.147-.173.213-.253.561-.679.985-1.32.985-2.304 0-2.06-1.637-3.75-4-3.75ZM5.75 12h4.5a.75.75 0 0 1 0 1.5h-4.5a.75.75 0 0 1 0-1.5Zm1 3h2.5a.75.75 0 0 1 0 1.5h-2.5a.75.75 0 0 1 0-1.5Z"></path></svg>',
    important: '<svg viewBox="0 0 16 16"><path d="M0 1.75C0 .784.784 0 1.75 0h12.5C15.216 0 16 .784 16 1.75v9.5A1.75 1.75 0 0 1 14.25 13H9.06l-2.573 2.573A1.458 1.458 0 0 1 4 14.543V13H1.75A1.75 1.75 0 0 1 0 11.25Zm1.75-.25a.25.25 0 0 0-.25.25v9.5c0 .138.112.25.25.25h2.5a.75.75 0 0 1 .75.75v2.19l2.72-2.72a.749.749 0 0 1 .53-.22h6.5a.25.25 0 0 0 .25-.25v-9.5a.25.25 0 0 0-.25-.25Zm7 2.25v2.5a.75.75 0 0 1-1.5 0v-2.5a.75.75 0 0 1 1.5 0ZM9 9a1 1 0 1 1-2 0 1 1 0 0 1 2 0Z"></path></svg>',
    warning: '<svg viewBox="0 0 16 16"><path d="M6.457 1.047c.659-1.234 2.427-1.234 3.086 0l6.082 11.378A1.75 1.75 0 0 1 14.082 15H1.918a1.75 1.75 0 0 1-1.543-2.575Zm1.763.707a.25.25 0 0 0-.44 0L1.698 13.132a.25.25 0 0 0 .22.368h12.164a.25.25 0 0 0 .22-.368Zm.53 3.996v2.5a.75.75 0 0 1-1.5 0v-2.5a.75.75 0 0 1 1.5 0ZM9 11a1 1 0 1 1-2 0 1 1 0 0 1 2 0Z"></path></svg>',
    caution: '<svg viewBox="0 0 16 16"><path d="M4.47.22A.749.749 0 0 1 5 0h6c.199 0 .389.079.53.22l4.25 4.25c.141.14.22.331.22.53v6a.749.749 0 0 1-.22.53l-4.25 4.25A.749.749 0 0 1 11 16H5a.749.749 0 0 1-.53-.22L.22 11.53A.749.749 0 0 1 0 11V5c0-.199.079-.389.22-.53Zm.84 1.28L1.5 5.31v5.38l3.81 3.81h5.38l3.81-3.81V5.31L10.69 1.5ZM8 4a.75.75 0 0 1 .75.75v3.5a.75.75 0 0 1-1.5 0v-3.5A.75.75 0 0 1 8 4Zm0 8a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"></path></svg>'
  };

  // Initialize Markdown-it
  const md = window.markdownit({
    html: true,
    linkify: true,
    typographer: true,
    highlight: function(str, lang) {
      if (lang === 'mermaid') {
        return '<div class="mermaid-wrapper"><div class="mermaid">' + md.utils.escapeHtml(str) + '</div></div>';
      }
      return '<pre><code class="language-' + md.utils.escapeHtml(lang || '') + '">' + md.utils.escapeHtml(str) + '</code></pre>';
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

  // GitHub Alert parsing
  function parseAlerts(html) {
    const alertRegex = /<blockquote>\s*<p>\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\](?:\s*<br\s*\/?>)?([\s\S]*?)<\/p>\s*([\s\S]*?)<\/blockquote>/gi;
    return html.replace(alertRegex, function(match, type, firstLine, rest) {
      const alertType = type.toLowerCase();
      const icon = ALERT_ICONS[alertType] || '';
      const content = (firstLine.trim() ? '<p>' + firstLine.trim() + '</p>' : '') + rest;
      return '<div class="lucid-alert lucid-alert-' + alertType + '">' +
             '<div class="lucid-alert-title">' + icon + alertType + '</div>' +
             '<div class="lucid-alert-content">' + content + '</div>' +
             '</div>';
    });
  }

  // KaTeX Math parsing
  function parseKaTeX(text) {
    if (typeof katex === 'undefined') return text;
    // Block math: $$ ... $$
    text = text.replace(/\$\$([\s\S]+?)\$\$/g, function(match, math) {
      try {
        return katex.renderToString(math.trim(), { displayMode: true, throwOnError: false });
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

  // Send scroll position to Swift
  let isProgrammaticScroll = false;
  window.addEventListener('scroll', function() {
    if (isProgrammaticScroll) return;
    const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
    const fraction = maxScroll > 0 ? window.scrollY / maxScroll : 0;
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidScroll) {
      window.webkit.messageHandlers.lucidScroll.postMessage({ fraction: fraction });
    }
  }, { passive: true });

  // Public API
  window.lucid = {
    updateContent: function(rawMarkdown) {
      const container = document.getElementById('lucid-content');
      if (!container) return;

      // 1. Parse KaTeX in markdown text first
      const preprocessed = parseKaTeX(rawMarkdown);

      // 2. Render Markdown
      let html = md.render(preprocessed);

      // 3. Process GitHub Alerts
      html = parseAlerts(html);

      // 4. Update DOM
      container.innerHTML = html;

      // 5. Render Mermaid diagrams
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

      // 6. Report headings back to Swift
      const headings = extractHeadings();
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lucidHeadings) {
        window.webkit.messageHandlers.lucidHeadings.postMessage(headings);
      }
    },

    updatePreferences: function(prefs) {
      const root = document.documentElement;
      const body = document.body;

      if (prefs.theme) {
        body.setAttribute('data-theme', prefs.theme);
      }
      if (prefs.fontFamily) {
        root.style.setProperty('--lucid-font-family', prefs.fontFamily);
      }
      if (prefs.fontSize) {
        root.style.setProperty('--lucid-font-size', prefs.fontSize + 'px');
      }
      if (prefs.lineHeight) {
        root.style.setProperty('--lucid-line-height', prefs.lineHeight);
      }
      if (prefs.contentWidth) {
        root.style.setProperty('--lucid-content-width', prefs.contentWidth);
      }
      if (prefs.accentColor) {
        root.style.setProperty('--lucid-accent', prefs.accentColor);
      }
      if (typeof prefs.breakout !== 'undefined') {
        if (prefs.breakout) {
          body.classList.remove('no-breakout');
        } else {
          body.classList.add('no-breakout');
        }
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

    getStandaloneHTML: function() {
      return document.documentElement.outerHTML;
    }
  };

  // Configure Mermaid initially
  if (typeof mermaid !== 'undefined') {
    mermaid.initialize({
      startOnLoad: false,
      theme: 'neutral',
      securityLevel: 'loose'
    });
  }
})();
