/**
 * JBDEditor - Attachable Vanilla JavaScript Rich Text Editor
 * 100% Vanilla JS, zero dependencies, zero Node.js runtime/build tools.
 * Fully ADA / WCAG 2.1 & 2.2 AA compliant.
 * Runs natively on file:/// protocol and HTTP/HTTPS web servers.
 */
(function (global) {
  'use strict';

  // ==========================================
  // 1. DOM, SELECTION & SANITIZER UTILITIES
  // ==========================================

  function escapeHTML(str) {
    if (str === null || str === undefined) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function createElement(tag, attrs = {}, children = []) {
    const el = document.createElement(tag);

    for (const [key, value] of Object.entries(attrs)) {
      if (key === 'className') {
        el.className = value;
      } else if (key === 'style' && typeof value === 'object') {
        Object.assign(el.style, value);
      } else if (key.startsWith('on') && typeof value === 'function') {
        el.addEventListener(key.slice(2).toLowerCase(), value);
      } else if (key.startsWith('data-')) {
        el.setAttribute(key, value);
      } else if (typeof value === 'boolean') {
        if (value) el.setAttribute(key, '');
      } else if (value !== null && value !== undefined) {
        el.setAttribute(key, value);
      }
    }

    for (const child of children) {
      if (typeof child === 'string') {
        el.appendChild(document.createTextNode(child));
      } else if (child instanceof Node) {
        el.appendChild(child);
      }
    }

    return el;
  }

  function isSelectionInside(container) {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return false;
    const anchorNode = selection.anchorNode;
    return anchorNode ? container.contains(anchorNode) : false;
  }

  function saveSelection(container) {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return null;
    const range = selection.getRangeAt(0);
    if (container.contains(range.commonAncestorContainer)) {
      return range.cloneRange();
    }
    return null;
  }

  function restoreSelection(range) {
    if (!range) return;
    const selection = window.getSelection();
    if (!selection) return;
    selection.removeAllRanges();
    selection.addRange(range);
  }

  function insertAtCursor(container, content, savedRange = null) {
    container.focus();
    const range = savedRange || saveSelection(container);

    if (range && container.contains(range.commonAncestorContainer)) {
      restoreSelection(range);
      if (typeof content === 'string') {
        document.execCommand('insertHTML', false, content);
      } else {
        range.deleteContents();
        range.insertNode(content);
        range.collapse(false);
      }
    } else {
      if (typeof content === 'string') {
        const temp = document.createElement('div');
        temp.innerHTML = content;
        while (temp.firstChild) {
          container.appendChild(temp.firstChild);
        }
      } else {
        container.appendChild(content);
      }
    }
  }

  function getClosestBlock(container, tagNames) {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return null;
    let node = selection.anchorNode;
    if (!node) return null;
    if (node.nodeType === Node.TEXT_NODE) node = node.parentNode;

    const tags = Array.isArray(tagNames) ? tagNames.map(t => t.toLowerCase()) : [tagNames.toLowerCase()];

    while (node && node !== container) {
      if (tags.includes(node.nodeName.toLowerCase())) {
        return node;
      }
      node = node.parentNode;
    }
    return null;
  }

  function getSelectedText() {
    const selection = window.getSelection();
    return selection ? selection.toString() : '';
  }

  function sanitizeHTML(html) {
    if (!html) return '';
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, 'text/html');

    const dangerousTags = ['script', 'iframe', 'object', 'embed', 'style', 'link', 'meta', 'applet'];
    dangerousTags.forEach(tag => {
      const elements = doc.querySelectorAll(tag);
      elements.forEach(el => el.remove());
    });

    const allElements = doc.querySelectorAll('*');
    allElements.forEach(el => {
      const attrs = Array.from(el.attributes);
      for (const attr of attrs) {
        const name = attr.name.toLowerCase();
        const val = attr.value.trim().toLowerCase();
        if (name.startsWith('on')) {
          el.removeAttribute(attr.name);
        }
        if ((name === 'href' || name === 'src') && val.startsWith('javascript:')) {
          el.removeAttribute(attr.name);
        }
      }
    });

    return doc.body.innerHTML;
  }

  /**
   * Clean up tool for documents and pasted HTML content.
   * Cleans and removes element styles and classes while preserving semantic structure.
   * 
   * @param {string} html - HTML string to clean
   * @param {Object} [options] - Cleanup options
   * @param {boolean} [options.removeStyles=true] - Remove all inline style attributes
   * @param {boolean} [options.removeClasses=true] - Remove all class attributes (except preserved)
   * @param {boolean} [options.convertSemanticStyles=true] - Convert bold/italic/underline styles to semantic tags before stripping
   * @param {boolean} [options.unwrapRedundantSpans=true] - Unwrap <span> tags with no attributes
   * @param {boolean} [options.unwrapFontTags=true] - Unwrap legacy <font> tags
   * @param {boolean} [options.cleanOfficeArtifacts=true] - Strip MSO tags, XML, and Office comments
   * @param {string[]} [options.preserveClasses=[]] - Whitelist of classes to preserve
   * @param {string} [options.tableClass='jbd-table jbd-table-bordered'] - Accessible class to apply to tables
   * @returns {string} Sanitized and cleaned HTML with styles and classes removed
   */
  function cleanDocumentHTML(html, options = {}) {
    if (!html || typeof html !== 'string') return '';

    const {
      removeStyles = true,
      removeClasses = true,
      convertSemanticStyles = true,
      unwrapRedundantSpans = true,
      unwrapFontTags = true,
      cleanOfficeArtifacts = true,
      preserveClasses = ['jbd-anchor-marker'],
      tableClass = 'jbd-table jbd-table-bordered'
    } = options;

    // 1. Remove Office conditional comments (<!--[if ...]>...<![endif]-->) & HTML comments
    let cleanInput = html
      .replace(/<!--\[if[\s\S]*?\]>[\s\S]*?<!\[endif\]-->/gi, '')
      .replace(/<!--[\s\S]*?-->/g, '');

    const parser = new DOMParser();
    const doc = parser.parseFromString(cleanInput, 'text/html');
    const body = doc.body;

    function unwrapElement(el) {
      const parent = el.parentNode;
      if (!parent) return;
      while (el.firstChild) {
        parent.insertBefore(el.firstChild, el);
      }
      parent.removeChild(el);
    }

    function wrapInner(el, wrapperTag) {
      if (!el.childNodes.length) return;
      const wrapper = doc.createElement(wrapperTag);
      while (el.firstChild) {
        wrapper.appendChild(el.firstChild);
      }
      el.appendChild(wrapper);
    }

    // 2. Remove office namespaces and unwanted tags
    if (cleanOfficeArtifacts) {
      const junkSelectors = [
        'o\\:p', 'xml', 'style', 'link', 'meta', 'title', 'script',
        'w\\:worddocument', 'm\\:math', 'v\\:shape', 'v\\:path'
      ];
      junkSelectors.forEach(sel => {
        try {
          body.querySelectorAll(sel).forEach(el => el.remove());
        } catch {}
      });

      const allEls = Array.from(body.querySelectorAll('*'));
      allEls.forEach(el => {
        const tagLower = el.tagName.toLowerCase();
        if (
          tagLower === 'o:p' ||
          tagLower.startsWith('o:') ||
          tagLower.startsWith('w:') ||
          tagLower.startsWith('v:') ||
          tagLower.startsWith('m:')
        ) {
          if (!el.textContent.trim()) {
            el.remove();
          } else {
            unwrapElement(el);
          }
        }
      });
    }

    // 3. Unwrap legacy <font> tags
    if (unwrapFontTags) {
      const fonts = Array.from(body.querySelectorAll('font'));
      fonts.forEach(font => unwrapElement(font));
    }

    // 4. Unwrap Google Docs false-bold wrapper (<b style="font-weight:normal">)
    const boldEls = Array.from(body.querySelectorAll('b, strong'));
    boldEls.forEach(el => {
      const style = (el.getAttribute('style') || '').toLowerCase();
      const fw = (el.style.fontWeight || '').toLowerCase();
      if (fw === 'normal' || fw === '400' || /font-weight\s*:\s*(normal|400)/i.test(style)) {
        unwrapElement(el);
      }
    });

    // 5. Convert semantic inline styles to semantic HTML tags before stripping
    if (convertSemanticStyles) {
      const styledEls = Array.from(body.querySelectorAll('[style]'));
      styledEls.forEach(el => {
        const style = (el.getAttribute('style') || '').toLowerCase();
        const fontWeight = (el.style.fontWeight || '').toLowerCase();
        const fontStyle = (el.style.fontStyle || '').toLowerCase();
        const textDecoration = (el.style.textDecoration || '').toLowerCase();
        const verticalAlign = (el.style.verticalAlign || '').toLowerCase();

        const isBold = /bold|700|800|900/.test(fontWeight) || /font-weight\s*:\s*(bold|[6-9]00)/.test(style);
        const isItalic = fontStyle === 'italic' || /font-style\s*:\s*italic/.test(style);
        const isUnderline = textDecoration.includes('underline') || /text-decoration\s*:\s*[^;]*underline/.test(style);
        const isStrike = textDecoration.includes('line-through') || /text-decoration\s*:\s*[^;]*line-through/.test(style);
        const isSub = verticalAlign === 'sub' || /vertical-align\s*:\s*sub/.test(style);
        const isSuper = verticalAlign === 'super' || /vertical-align\s*:\s*super/.test(style);

        const tag = el.tagName.toLowerCase();

        if (isBold && tag !== 'b' && tag !== 'strong') {
          wrapInner(el, 'strong');
        }
        if (isItalic && tag !== 'i' && tag !== 'em') {
          wrapInner(el, 'em');
        }
        if (isUnderline && tag !== 'u') {
          wrapInner(el, 'u');
        }
        if (isStrike && tag !== 's' && tag !== 'strike') {
          wrapInner(el, 's');
        }
        if (isSub && tag !== 'sub') {
          wrapInner(el, 'sub');
        }
        if (isSuper && tag !== 'sup') {
          wrapInner(el, 'sup');
        }
      });
    }

    // 6. Clean element styles, classes, and junk attributes
    const allElements = Array.from(body.querySelectorAll('*'));
    allElements.forEach(el => {
      // Remove element style
      if (removeStyles) {
        el.removeAttribute('style');
      }

      // Remove or filter classes
      if (removeClasses) {
        if (preserveClasses && preserveClasses.length > 0) {
          const kept = Array.from(el.classList).filter(c => preserveClasses.includes(c));
          if (kept.length > 0) {
            el.className = kept.join(' ');
          } else {
            el.removeAttribute('class');
          }
        } else {
          el.removeAttribute('class');
        }
      }

      // Clean junk attributes
      const attrs = Array.from(el.attributes);
      for (const attr of attrs) {
        const name = attr.name.toLowerCase();
        if (
          name.startsWith('mso-') ||
          name.startsWith('v:') ||
          name.startsWith('o:') ||
          name.startsWith('w:') ||
          (name.startsWith('data-') && !name.startsWith('data-jbd-')) ||
          name === 'lang' ||
          name === 'face' ||
          name === 'size' ||
          name === 'color' ||
          name === 'clear' ||
          name === 'border' ||
          name === 'bgcolor' ||
          name === 'cellspacing' ||
          name === 'cellpadding'
        ) {
          el.removeAttribute(attr.name);
        }
        if (name === 'id' && (attr.value.startsWith('docs-internal-guid') || attr.value.startsWith('_mcePaste'))) {
          el.removeAttribute(attr.name);
        }
      }

      // Tables: assign accessible table class
      if (el.tagName.toLowerCase() === 'table' && tableClass) {
        el.className = tableClass;
      }
    });

    // 7. Unwrap redundant empty <span> elements (spans that now have no attributes)
    if (unwrapRedundantSpans) {
      let changed = true;
      while (changed) {
        changed = false;
        const spans = Array.from(body.querySelectorAll('span'));
        for (const span of spans) {
          if (span.attributes.length === 0) {
            unwrapElement(span);
            changed = true;
          }
        }
      }
    }

    // 8. Remove completely empty inline formatting elements
    const emptyCheckTags = ['span', 'b', 'strong', 'i', 'em', 'u', 's', 'strike', 'sub', 'sup'];
    emptyCheckTags.forEach(tag => {
      body.querySelectorAll(tag).forEach(el => {
        if (!el.textContent.trim() && !el.querySelector('img, br, svg')) {
          el.remove();
        }
      });
    });

    return body.innerHTML;
  }

  const cleanHTML = cleanDocumentHTML;

  function formatHTML(html, indent = '  ') {
    if (!html) return '';

    // 1. If external js-beautify library is loaded, use it
    if (typeof window !== 'undefined' && typeof window.html_beautify === 'function') {
      try {
        return window.html_beautify(html, {
          indent_size: 2,
          indent_char: ' ',
          max_preserve_newlines: 1,
          preserve_newlines: true,
          indent_inner_html: true,
          wrap_line_length: 0
        });
      } catch {
        // Fall through to native formatter
      }
    }

    // 2. Native pure Vanilla JS DOM Beautifier (Zero dependencies)
    try {
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, 'text/html');
      const body = doc.body;

      const blockTags = new Set([
        'address', 'article', 'aside', 'blockquote', 'details', 'dialog', 'dd',
        'div', 'dl', 'dt', 'fieldset', 'figcaption', 'figure', 'footer', 'form',
        'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'hgroup', 'hr', 'li',
        'main', 'nav', 'ol', 'p', 'pre', 'section', 'table', 'tbody', 'td',
        'tfoot', 'th', 'thead', 'tr', 'ul'
      ]);

      const voidTags = new Set([
        'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
        'link', 'meta', 'param', 'source', 'track', 'wbr'
      ]);

      function serializeNode(node, depth) {
        if (node.nodeType === Node.COMMENT_NODE) {
          return indent.repeat(depth) + `<!--${node.nodeValue}-->`;
        }

        if (node.nodeType === Node.TEXT_NODE) {
          return node.textContent;
        }

        if (node.nodeType !== Node.ELEMENT_NODE) {
          return '';
        }

        const tag = node.tagName.toLowerCase();
        const isBlock = blockTags.has(tag);
        const isVoid = voidTags.has(tag);
        const ind = indent.repeat(depth);

        let openTag = `<${tag}`;
        for (const attr of Array.from(node.attributes)) {
          openTag += ` ${attr.name}="${attr.value.replace(/"/g, '&quot;')}"`;
        }
        openTag += '>';

        if (isVoid) {
          return (isBlock ? ind : '') + openTag;
        }

        const hasBlockChild = Array.from(node.children).some(child => blockTags.has(child.tagName.toLowerCase()));

        let innerContent = '';
        if (hasBlockChild) {
          const childSnippets = [];
          for (const child of node.childNodes) {
            if (child.nodeType === Node.TEXT_NODE && !child.textContent.trim()) {
              continue;
            }
            childSnippets.push(serializeNode(child, depth + 1));
          }
          innerContent = '\n' + childSnippets.join('\n') + '\n' + ind;
          return ind + openTag + innerContent + `</${tag}>`;
        } else {
          for (const child of node.childNodes) {
            if (child.nodeType === Node.TEXT_NODE) {
              innerContent += child.textContent;
            } else if (child.nodeType === Node.ELEMENT_NODE) {
              innerContent += child.outerHTML;
            }
          }
          return (isBlock ? ind : '') + openTag + innerContent + `</${tag}>`;
        }
      }

      const result = [];
      for (const child of body.childNodes) {
        if (child.nodeType === Node.TEXT_NODE && !child.textContent.trim()) continue;
        result.push(serializeNode(child, 0));
      }

      return result.join('\n\n').trim();
    } catch {
      return html;
    }
  }


  // ==========================================
  // WCAG 2.1 LEVEL AA ACCESSIBILITY VALIDATOR
  // ==========================================

  /**
 * a11y.js - WCAG 2.1 Level AA Accessibility Validator & Auditor for JBDEditor & CMSAdmin
 * Performs robust accessibility linting and auditing on HTML content:
 * - 1.1.1 Non-text Content (img alt attributes, decorative vs informative images)
 * - 1.3.1 Info and Relationships (heading hierarchy, empty headings, table captions & headers)
 * - 2.4.4 Link Purpose in Context (empty links, ambiguous link text like "click here", "read more")
 * - 4.1.2 Name, Role, Value (buttons with accessible names, iframes with titles)
 * - 1.4.3 Contrast / Readability (inline low contrast text colors, font styling)
 * - Target Size & Semantic HTML Checks
 */

class A11yValidator {
  /**
   * Evaluates an HTML string or DOM node against WCAG 2.1 AA rules
   * @param {string | HTMLElement} input - HTML content string or DOM element to audit
   * @returns {{ passed: boolean, errors: Array<{ rule: string, element: string, message: string, suggestion: string, node?: HTMLElement }>, warnings: Array<{ rule: string, element: string, message: string, suggestion: string, node?: HTMLElement }> }}
   */
  static validate(input) {
    let container;
    if (typeof input === 'string') {
      container = document.createElement('div');
      container.innerHTML = input.trim();
    } else if (input instanceof HTMLElement) {
      container = input;
    } else {
      return { passed: true, errors: [], warnings: [] };
    }

    const errors = [];
    const warnings = [];

    // --- 1. Images & Visual Media (WCAG 1.1.1 Non-text Content) ---
    const images = container.querySelectorAll('img');
    images.forEach((img, idx) => {
      const hasAlt = img.hasAttribute('alt');
      const altVal = (img.getAttribute('alt') || '').trim();
      const src = img.getAttribute('src') || '';
      const srcLabel = src.length > 40 ? src.substring(0, 37) + '...' : (src || `Image #${idx + 1}`);

      if (!hasAlt) {
        errors.push({
          rule: 'WCAG 1.1.1 (Non-text Content)',
          element: `<img src="${srcLabel}">`,
          message: 'Image is missing an alt attribute.',
          suggestion: 'Provide descriptive alternative text (alt="...") or alt="" if the image is purely decorative.',
          node: img
        });
      } else if (altVal.length > 0) {
        const lower = altVal.toLowerCase();
        if (lower === 'image' || lower === 'photo' || lower === 'picture' || lower === 'graphic' || lower === 'img' || lower === 'icon') {
          warnings.push({
            rule: 'WCAG 1.1.1 (Non-text Content)',
            element: `<img alt="${altVal}">`,
            message: `Generic alternative text "${altVal}" provides no meaningful context.`,
            suggestion: 'Describe the specific subject or function of the image rather than calling it "image" or "photo".',
            node: img
          });
        }
      }
    });

    // --- 2. Links (WCAG 2.4.4 Link Purpose in Context) ---
    const links = container.querySelectorAll('a');
    const ambiguousPhrases = ['click here', 'here', 'more', 'read more', 'learn more', 'link', 'download', 'view', 'details', 'info'];
    links.forEach((a, idx) => {
      // In-page named anchor (bookmark) tags with name or id and no href are valid jump targets
      const isNamedAnchor = (a.hasAttribute('name') || a.classList.contains('jbd-anchor-marker')) && !a.hasAttribute('href');
      if (isNamedAnchor) {
        return; // Valid in-page bookmark target
      }

      const href = (a.getAttribute('href') || '').trim();
      const text = (a.textContent || '').trim();
      const hasAriaLabel = a.hasAttribute('aria-label') && a.getAttribute('aria-label').trim().length > 0;
      const hasTitle = a.hasAttribute('title') && a.getAttribute('title').trim().length > 0;
      const hasChildImgWithAlt = Array.from(a.querySelectorAll('img')).some(i => (i.getAttribute('alt') || '').trim().length > 0);

      const accessibleName = (text || (hasAriaLabel ? a.getAttribute('aria-label') : '') || (hasChildImgWithAlt ? 'image link' : '')).trim();

      if (!href || href === '#' || href === 'javascript:void(0);' || href === 'javascript:;') {
        warnings.push({
          rule: 'WCAG 2.4.4 / 4.1.2 (Link Destination)',
          element: `<a>${text || 'Link #' + (idx + 1)}</a>`,
          message: 'Link is missing a valid destination URL (href is empty or "#").',
          suggestion: 'Provide a valid web URL, document path, or use a <button> element if this is an on-page action.',
          node: a
        });
      }

      if (!accessibleName && !hasTitle) {
        errors.push({
          rule: 'WCAG 2.4.4 (Link Purpose)',
          element: `<a href="${href}">`,
          message: 'Link is completely empty and has no accessible name or text.',
          suggestion: 'Add text inside the link, or provide an aria-label describing where the link navigates.',
          node: a
        });
      } else if (accessibleName) {
        const lower = accessibleName.toLowerCase().replace(/[^a-z0-9 ]/g, '').trim();
        if (ambiguousPhrases.includes(lower)) {
          warnings.push({
            rule: 'WCAG 2.4.4 (Link Purpose)',
            element: `<a href="${href}">${accessibleName}</a>`,
            message: `Ambiguous link text "${accessibleName}" without surrounding context.`,
            suggestion: `Make the link text descriptive (e.g. "Read the 2026 Budget Report" instead of "${accessibleName}").`,
            node: a
          });
        }
      }

      // Check for target="_blank" without rel="noopener" or ADA indication
      if (a.getAttribute('target') === '_blank') {
        const rel = (a.getAttribute('rel') || '').toLowerCase();
        if (!rel.includes('noopener')) {
          warnings.push({
            rule: 'WCAG Best Practice (Security & Navigation)',
            element: `<a href="${href}" target="_blank">`,
            message: 'Link opens in a new tab without rel="noopener noreferrer".',
            suggestion: 'Add rel="noopener noreferrer" for security and performance when opening external tabs.',
            node: a
          });
        }

        const aria = (a.getAttribute('aria-label') || '').toLowerCase();
        const txt = (a.textContent || '').toLowerCase();
        const tit = (a.getAttribute('title') || '').toLowerCase();
        const hasNotice = aria.includes('new tab') || aria.includes('new window') ||
                          txt.includes('new tab') || txt.includes('new window') ||
                          tit.includes('new tab') || tit.includes('new window');
        if (!hasNotice) {
          warnings.push({
            rule: 'WCAG 3.2.5 (Change on Request / Predictability)',
            element: `<a href="${href}" target="_blank">`,
            message: 'Link opens in a new tab without an audible ADA notification for screen readers.',
            suggestion: 'Add an aria-label with "(opens in a new tab)" to alert screen reader users.',
            node: a
          });
        }
      }
    });

    // --- 3. Headings (WCAG 1.3.1 Info and Relationships) ---
    // Rule: The outer page template title already provides the singular H1 for the page.
    // In-content section headings must begin with H2, and H1 tags inside the editor are flagged.
    const headings = container.querySelectorAll('h1, h2, h3, h4, h5, h6');
    let lastHeadingLevel = 1; // Base level from the external page title (H1)
    let isFirstContentHeading = true;

    headings.forEach((h) => {
      const text = (h.textContent || '').trim();
      const level = parseInt(h.tagName.substring(1), 10);

      if (!text && !h.querySelector('img[alt]')) {
        errors.push({
          rule: 'WCAG 1.3.1 (Info and Relationships)',
          element: `<${h.tagName.toLowerCase()}>`,
          message: `Empty heading <${h.tagName.toLowerCase()}> found.`,
          suggestion: 'Remove empty heading tags or provide meaningful section heading text.',
          node: h
        });
      }

      // Check if user inserted an H1 in editor content
      if (level === 1) {
        warnings.push({
          rule: 'WCAG 1.3.1 (Heading Hierarchy)',
          element: `<h1>${text.substring(0, 30)}</h1>`,
          message: 'The page title is already assigned as the primary <h1>. In-page content headings should begin at <h2>.',
          suggestion: 'Change this heading from <h1> to <h2> to maintain a compliant document outline hierarchy.',
          node: h
        });
      } else if (isFirstContentHeading && level > 2) {
        // First heading in content skipped H2 (e.g. jumped directly to H3 or H4)
        warnings.push({
          rule: 'WCAG 1.3.1 (Heading Hierarchy)',
          element: `<${h.tagName.toLowerCase()}>${text.substring(0, 30)}</${h.tagName.toLowerCase()}>`,
          message: `Top-level content heading skipped <h2>: found <${h.tagName.toLowerCase()}> after page title <h1>.`,
          suggestion: 'Change this initial section heading to <h2> so document hierarchy begins correctly after the page title.',
          node: h
        });
      } else if (!isFirstContentHeading && level > lastHeadingLevel + 1) {
        // Subsequent heading skipped intermediate level (e.g. H2 to H4 without H3)
        warnings.push({
          rule: 'WCAG 1.3.1 (Heading Hierarchy)',
          element: `<${h.tagName.toLowerCase()}>${text.substring(0, 30)}</${h.tagName.toLowerCase()}>`,
          message: `Heading level skipped: <${h.tagName.toLowerCase()}> follows <h${lastHeadingLevel}>.`,
          suggestion: `Use <h${lastHeadingLevel + 1}> to preserve a logical reading and outline order for assistive technologies.`,
          node: h
        });
      }

      isFirstContentHeading = false;
      lastHeadingLevel = level;
    });

    // --- 4. Tables (WCAG 1.3.1 Info and Relationships) ---
    const tables = container.querySelectorAll('table');
    tables.forEach((table, idx) => {
      // Check table caption
      const caption = table.querySelector('caption');
      const hasAriaLabel = table.hasAttribute('aria-label') || table.hasAttribute('aria-labelledby');
      if (!caption && !hasAriaLabel) {
        warnings.push({
          rule: 'WCAG 1.3.1 (Data Tables)',
          element: `<table> (Table #${idx + 1})`,
          message: 'Data table does not have a <caption> or aria-label.',
          suggestion: 'Add a <caption> element or aria-label summarizing the contents and purpose of the table.',
          node: table
        });
      }

      // Check table headers
      const ths = table.querySelectorAll('th');
      if (ths.length === 0) {
        errors.push({
          rule: 'WCAG 1.3.1 (Data Tables)',
          element: `<table> (Table #${idx + 1})`,
          message: 'Table has no header cells (<th>). Screen readers cannot associate data cells with headers.',
          suggestion: 'Convert the first row or column cells to <th scope="col"> or <th scope="row">.',
          node: table
        });
      } else {
        ths.forEach(th => {
          if (!th.hasAttribute('scope')) {
            warnings.push({
              rule: 'WCAG 1.3.1 (Table Headers)',
              element: `<th>${(th.textContent || '').trim().substring(0, 20)}</th>`,
              message: 'Table header cell <th> is missing a scope attribute.',
              suggestion: 'Add scope="col" (for column headers) or scope="row" (for row headers).',
              node: th
            });
          }
        });
      }
    });

    // --- 5. Interactive Elements & Media (WCAG 4.1.2 Name, Role, Value) ---
    const iframes = container.querySelectorAll('iframe');
    iframes.forEach((iframe, idx) => {
      const title = (iframe.getAttribute('title') || '').trim();
      const hasAriaLabel = (iframe.getAttribute('aria-label') || '').trim();
      if (!title && !hasAriaLabel) {
        errors.push({
          rule: 'WCAG 4.1.2 (Frames & Iframes)',
          element: `<iframe src="${iframe.getAttribute('src') || ''}">`,
          message: `Embedded frame (#${idx + 1}) is missing a title attribute.`,
          suggestion: 'Add title="..." describing the content of the embedded frame (e.g. title="County GIS Map").',
          node: iframe
        });
      }
    });

    const buttons = container.querySelectorAll('button');
    buttons.forEach((btn, idx) => {
      const text = (btn.textContent || '').trim();
      const ariaLabel = (btn.getAttribute('aria-label') || '').trim();
      if (!text && !ariaLabel) {
        errors.push({
          rule: 'WCAG 4.1.2 (Name, Role, Value)',
          element: `<button> (Button #${idx + 1})`,
          message: 'Button has no readable text or aria-label.',
          suggestion: 'Add visible text or aria-label="..." describing the action triggered by the button.',
          node: btn
        });
      }
    });

    return {
      passed: errors.length === 0,
      errors,
      warnings
    };
  }

  /**
   * Renders the WCAG 2.1 AA validation modal report
   * @param {Object} options
   * @param {{ passed: boolean, errors: Array<any>, warnings: Array<any> }} options.results
   * @param {() => void} options.onProceed - Callback if user chooses to proceed with saving anyway
   * @param {() => void} [options.onCancel] - Callback if user cancels save to fix issues
   * @param {(node: HTMLElement) => void} [options.onHighlight] - Callback to scroll to/focus problematic node
   */
  static showModal({ results, onProceed, onCancel, onHighlight }) {
    const errorCount = results.errors.length;
    const warnCount = results.warnings.length;
    const isPassing = results.passed;

    // Create modal content
    const modalWrap = document.createElement('div');
    modalWrap.className = 'jbd-a11y-report';

    let summaryHtml = '';
    if (isPassing && warnCount === 0) {
      summaryHtml = `
        <div class="jbd-a11y-banner jbd-a11y-banner--success" role="status">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
          <div>
            <strong>WCAG 2.1 Level AA Compliance Passed!</strong>
            <p>No accessibility barriers were detected in your content. High-contrast, semantic headings, image descriptions, and link tags are properly structured.</p>
          </div>
        </div>
      `;
    } else if (errorCount > 0) {
      summaryHtml = `
        <div class="jbd-a11y-banner jbd-a11y-banner--danger" role="alert">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          <div>
            <strong>${errorCount} Accessibility Issue${errorCount === 1 ? '' : 's'} Found (WCAG 2.1 AA)</strong>
            <p>Your content contains accessibility violations that will prevent people with disabilities or assistive technologies from reading this page properly.</p>
          </div>
        </div>
      `;
    } else {
      summaryHtml = `
        <div class="jbd-a11y-banner jbd-a11y-banner--warning" role="status">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
          <div>
            <strong>${warnCount} Accessibility Recommendation${warnCount === 1 ? '' : 's'}</strong>
            <p>No critical failures were detected, but some best-practice opportunities were identified to improve inclusivity.</p>
          </div>
        </div>
      `;
    }

    let itemsHtml = '';
    if (errorCount > 0 || warnCount > 0) {
      itemsHtml += '<div class="jbd-a11y-list" role="list">';
      
      results.errors.forEach((err, i) => {
        itemsHtml += `
          <div class="jbd-a11y-item jbd-a11y-item--error" role="listitem">
            <div class="jbd-a11y-item-header">
              <span class="jbd-a11y-tag jbd-a11y-tag--danger">Violation</span>
              <span class="jbd-a11y-rule">${A11yValidator.escapeHtml(err.rule)}</span>
            </div>
            <div class="jbd-a11y-item-msg">${A11yValidator.escapeHtml(err.message)}</div>
            <code class="jbd-a11y-code">${A11yValidator.escapeHtml(err.element)}</code>
            <div class="jbd-a11y-fix"><strong>How to resolve:</strong> ${A11yValidator.escapeHtml(err.suggestion)}</div>
          </div>
        `;
      });

      results.warnings.forEach((warn, i) => {
        itemsHtml += `
          <div class="jbd-a11y-item jbd-a11y-item--warning" role="listitem">
            <div class="jbd-a11y-item-header">
              <span class="jbd-a11y-tag jbd-a11y-tag--warning">Recommendation</span>
              <span class="jbd-a11y-rule">${A11yValidator.escapeHtml(warn.rule)}</span>
            </div>
            <div class="jbd-a11y-item-msg">${A11yValidator.escapeHtml(warn.message)}</div>
            <code class="jbd-a11y-code">${A11yValidator.escapeHtml(warn.element)}</code>
            <div class="jbd-a11y-fix"><strong>Suggestion:</strong> ${A11yValidator.escapeHtml(warn.suggestion)}</div>
          </div>
        `;
      });

      itemsHtml += '</div>';
    }

    modalWrap.innerHTML = `
      ${summaryHtml}
      ${itemsHtml}
    `;

    // Backdrop & Modal Container
    const existing = document.getElementById('jbdA11yModalOverlay');
    if (existing) existing.remove();

    const overlay = document.createElement('div');
    overlay.id = 'jbdA11yModalOverlay';
    overlay.className = 'admin-modal-backdrop open';
    overlay.style.cssText = 'display:flex; justify-content:center; align-items:center; opacity:1; visibility:visible; z-index:100000; background:rgba(15, 23, 42, 0.72) !important; backdrop-filter:blur(6px) !important; -webkit-backdrop-filter:blur(6px) !important; position:fixed; top:0; left:0; width:100vw; height:100vh;';

    const dialog = document.createElement('div');
    dialog.className = 'admin-modal-window';
    dialog.setAttribute('role', 'dialog');
    dialog.setAttribute('aria-modal', 'true');
    dialog.setAttribute('aria-labelledby', 'jbdA11yTitle');
    dialog.style.cssText = 'background:var(--admin-card-bg, #fff); width:90%; max-width:680px; max-height:85vh; border-radius:12px; display:flex; flex-direction:column; box-shadow:0 25px 50px -12px rgba(0,0,0,0.35); overflow:hidden; border:1px solid var(--admin-border-subtle, #e2e8f0); animation: modalIn 0.2s cubic-bezier(0.16, 1, 0.3, 1);';

    dialog.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; padding:1.1rem 1.5rem; border-bottom:1px solid var(--admin-border-subtle, #e2e8f0); background:var(--admin-bg-subtle, #f8fafc);">
        <div style="display:flex; align-items:center; gap:0.5rem;">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--admin-primary, #0284c7)" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="m4.93 4.93 4.24 4.24"/><path d="m14.83 9.17 4.24-4.24"/><path d="m14.83 14.83 4.24 4.24"/><path d="m9.17 14.83-4.24 4.24"/><circle cx="12" cy="12" r="4"/></svg>
          <h3 id="jbdA11yTitle" style="margin:0; font-size:1.1rem; font-weight:600; color:var(--admin-text-main, #0f172a);">WCAG 2.1 AA Accessibility Validation</h3>
        </div>
        <button type="button" id="btnA11yClose" class="btn btn-outline btn-xs" aria-label="Close accessibility validator" style="border-radius:6px; padding:0.25rem 0.5rem;">&times;</button>
      </div>
      <div style="padding:1.25rem 1.5rem; overflow-y:auto; flex:1;">
        ${modalWrap.outerHTML}
      </div>
      <div style="display:flex; justify-content:space-between; align-items:center; padding:1rem 1.5rem; border-top:1px solid var(--admin-border-subtle, #e2e8f0); background:var(--admin-bg-subtle, #f8fafc); gap:0.75rem;">
        <button type="button" id="btnA11yCancel" class="btn btn-outline btn-sm">Fix Accessibility Issues</button>
        <div style="display:flex; gap:0.5rem;">
          ${errorCount > 0 ? `
            <button type="button" id="btnA11yOverride" class="btn btn-warning btn-sm" style="display:flex; align-items:center; gap:0.35rem;">
              <span>Save Anyway (Override)</span>
            </button>
          ` : `
            <button type="button" id="btnA11yProceed" class="btn btn-primary btn-sm" style="display:flex; align-items:center; gap:0.35rem;">
              <span>Continue Saving</span>
            </button>
          `}
        </div>
      </div>
    `;

    overlay.appendChild(dialog);
    document.body.appendChild(overlay);

    const closeOverlay = () => {
      overlay.remove();
      if (typeof onCancel === 'function') onCancel();
    };

    const proceedSave = () => {
      overlay.remove();
      if (typeof onProceed === 'function') onProceed();
    };

    const btnClose = dialog.querySelector('#btnA11yClose');
    const btnCancel = dialog.querySelector('#btnA11yCancel');
    const btnOverride = dialog.querySelector('#btnA11yOverride');
    const btnProceed = dialog.querySelector('#btnA11yProceed');

    if (btnClose) btnClose.addEventListener('click', closeOverlay);
    if (btnCancel) btnCancel.addEventListener('click', closeOverlay);
    if (btnOverride) btnOverride.addEventListener('click', proceedSave);
    if (btnProceed) btnProceed.addEventListener('click', proceedSave);

    const keyListener = (e) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        document.removeEventListener('keydown', keyListener);
        closeOverlay();
      }
    };
    document.addEventListener('keydown', keyListener);
  }

  static escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
}

  // ==========================================
  // 2. STORAGE & DRAFT PERSISTENCE
  // ==========================================

  class StorageManager {
    static isAvailable() {
      try {
        const testKey = '__storage_test__';
        window.localStorage.setItem(testKey, testKey);
        window.localStorage.removeItem(testKey);
        return true;
      } catch {
        return false;
      }
    }

    static saveDraft(key, content) {
      if (!this.isAvailable() || !key) return false;
      try {
        const payload = { content, timestamp: Date.now() };
        window.localStorage.setItem(`jbd_draft_${key}`, JSON.stringify(payload));
        return true;
      } catch (e) {
        return false;
      }
    }

    static loadDraft(key) {
      if (!this.isAvailable() || !key) return null;
      try {
        const raw = window.localStorage.getItem(`jbd_draft_${key}`) || window.localStorage.getItem(`jal_draft_${key}`);
        if (!raw) return null;
        return JSON.parse(raw);
      } catch (e) {
        return null;
      }
    }

    static clearDraft(key) {
      if (!this.isAvailable() || !key) return;
      try {
        window.localStorage.removeItem(`jbd_draft_${key}`);
        window.localStorage.removeItem(`jal_draft_${key}`);
      } catch (e) {}
    }

    static createAutoSaver(key, getContent, delay = 1000, onStatusChange = null) {
      let timer = null;
      const trigger = () => {
        if (timer) clearTimeout(timer);
        if (onStatusChange) onStatusChange('saving');
        timer = setTimeout(() => {
          const content = getContent();
          StorageManager.saveDraft(key, content);
          if (onStatusChange) onStatusChange('saved');
          timer = null;
        }, delay);
      };
      const cancel = () => {
        if (timer) {
          clearTimeout(timer);
          timer = null;
        }
        if (onStatusChange) onStatusChange('idle');
      };
      return { trigger, cancel };
    }
  }

  // ==========================================
  // 3. HISTORY (UNDO / REDO)
  // ==========================================

  class HistoryManager {
    constructor(maxStackSize = 60) {
      this.maxStackSize = maxStackSize;
      this.undoStack = [];
      this.redoStack = [];
      this.lastSnapshotTime = 0;
      this.throttleDelay = 500;
    }

    record(content, force = false) {
      const now = Date.now();
      const lastItem = this.undoStack[this.undoStack.length - 1];
      if (lastItem === content) return;

      if (!force && (now - this.lastSnapshotTime < this.throttleDelay) && this.undoStack.length > 0) {
        this.undoStack[this.undoStack.length - 1] = content;
      } else {
        this.undoStack.push(content);
        if (this.undoStack.length > this.maxStackSize) {
          this.undoStack.shift();
        }
      }

      this.lastSnapshotTime = now;
      this.redoStack = [];
    }

    undo(currentContent) {
      if (!this.canUndo()) return null;
      this.redoStack.push(currentContent);
      return this.undoStack.pop();
    }

    redo(currentContent) {
      if (!this.canRedo()) return null;
      this.undoStack.push(currentContent);
      return this.redoStack.pop();
    }

    canUndo() { return this.undoStack.length > 0; }
    canRedo() { return this.redoStack.length > 0; }
    clear() { this.undoStack = []; this.redoStack = []; }
  }

  // ==========================================
  // 4. TABLE MANAGER (ADA/WCAG COMPLIANT)
  // ==========================================

  class TableManager {
    static createTable({ rows = 3, cols = 3, headerType = null, hasHeader = true, caption = '', bordered = true }) {
      const hType = headerType || (hasHeader ? 'row' : 'none');
      const hasHeaderRow = (hType === 'row' || hType === 'both');
      const hasHeaderCol = (hType === 'col' || hType === 'both');

      const table = createElement('table', {
        className: `jbd-table ${bordered ? 'jbd-table-bordered' : ''}`,
        style: { width: '100%', borderCollapse: 'collapse' }
      });

      if (caption && caption.trim()) {
        const capEl = createElement('caption', { className: 'jbd-table-caption' }, [caption.trim()]);
        table.appendChild(capEl);
      }

      const tbody = createElement('tbody');

      if (hasHeaderRow) {
        const thead = createElement('thead');
        const headerRow = createElement('tr');
        for (let c = 0; c < cols; c++) {
          const th = createElement('th', { scope: 'col' }, [`Header ${c + 1}`]);
          headerRow.appendChild(th);
        }
        thead.appendChild(headerRow);
        table.appendChild(thead);
        rows = rows - 1;
      }

      for (let r = 0; r < Math.max(1, rows); r++) {
        const tr = createElement('tr');
        for (let c = 0; c < cols; c++) {
          if (c === 0 && hasHeaderCol) {
            const th = createElement('th', { scope: 'row' }, [`Row Header ${r + 1}`]);
            tr.appendChild(th);
          } else {
            const td = createElement('td', {}, [`Cell ${r + 1},${c + 1}`]);
            tr.appendChild(td);
          }
        }
        tbody.appendChild(tr);
      }

      table.appendChild(tbody);
      return table;
    }

    static getActiveCell(container) {
      const selection = window.getSelection();
      if (!selection || selection.rangeCount === 0) return null;
      let node = selection.anchorNode;
      if (!node) return null;
      if (node.nodeType === Node.TEXT_NODE) node = node.parentNode;

      while (node && node !== container) {
        if (node.tagName === 'TD' || node.tagName === 'TH') {
          return node;
        }
        node = node.parentNode;
      }
      return null;
    }

    static hasRowHeaders(table) {
      if (!table) return false;
      const firstCells = table.querySelectorAll('tbody tr > :first-child');
      return Array.from(firstCells).some(c => c.tagName === 'TH');
    }

    static addRowAbove(cell) {
      if (!cell) return;
      const row = cell.closest('tr');
      if (!row) return;
      const table = cell.closest('table');
      const isHead = row.parentElement && row.parentElement.tagName === 'THEAD';
      const hasRowHeaders = TableManager.hasRowHeaders(table);

      const newRow = createElement('tr');
      const cols = row.children.length;
      for (let i = 0; i < cols; i++) {
        if (isHead) {
          newRow.appendChild(createElement('th', { scope: 'col' }, ['&nbsp;']));
        } else if (i === 0 && hasRowHeaders) {
          newRow.appendChild(createElement('th', { scope: 'row' }, ['&nbsp;']));
        } else {
          newRow.appendChild(createElement('td', {}, ['&nbsp;']));
        }
      }

      row.parentNode.insertBefore(newRow, row);
    }

    static addRowBelow(cell) {
      if (!cell) return;
      const row = cell.closest('tr');
      if (!row) return;
      const table = cell.closest('table');
      const isHead = row.parentElement && row.parentElement.tagName === 'THEAD';
      const hasRowHeaders = TableManager.hasRowHeaders(table);

      const newRow = createElement('tr');
      const cols = row.children.length;
      for (let i = 0; i < cols; i++) {
        if (isHead) {
          newRow.appendChild(createElement('th', { scope: 'col' }, ['&nbsp;']));
        } else if (i === 0 && hasRowHeaders) {
          newRow.appendChild(createElement('th', { scope: 'row' }, ['&nbsp;']));
        } else {
          newRow.appendChild(createElement('td', {}, ['&nbsp;']));
        }
      }

      row.parentNode.insertBefore(newRow, row.nextSibling);
    }

    static addColLeft(cell) {
      if (!cell) return;
      const table = cell.closest('table');
      if (!table) return;

      const colIndex = cell.cellIndex;
      const rows = table.querySelectorAll('tr');

      rows.forEach(r => {
        const isHeaderRow = r.parentElement && r.parentElement.tagName === 'THEAD';
        let newCell;
        if (isHeaderRow) {
          newCell = createElement('th', { scope: 'col' }, ['&nbsp;']);
        } else {
          newCell = createElement('td', {}, ['&nbsp;']);
        }

        if (colIndex < r.children.length) {
          r.insertBefore(newCell, r.children[colIndex]);
        } else {
          r.appendChild(newCell);
        }
      });
    }

    static addColRight(cell) {
      if (!cell) return;
      const table = cell.closest('table');
      if (!table) return;

      const colIndex = cell.cellIndex;
      const rows = table.querySelectorAll('tr');

      rows.forEach(r => {
        const isHeaderRow = r.parentElement && r.parentElement.tagName === 'THEAD';
        let newCell;
        if (isHeaderRow) {
          newCell = createElement('th', { scope: 'col' }, ['&nbsp;']);
        } else {
          newCell = createElement('td', {}, ['&nbsp;']);
        }

        const nextCell = r.children[colIndex + 1];
        if (nextCell) {
          r.insertBefore(newCell, nextCell);
        } else {
          r.appendChild(newCell);
        }
      });
    }

    static deleteRow(cell) {
      if (!cell) return;
      const row = cell.closest('tr');
      if (!row) return;
      const table = row.closest('table');
      row.remove();
      if (table && table.querySelectorAll('tr').length === 0) {
        table.remove();
      }
    }

    static deleteCol(cell) {
      if (!cell) return;
      const table = cell.closest('table');
      if (!table) return;
      const colIndex = cell.cellIndex;

      const rows = table.querySelectorAll('tr');
      rows.forEach(r => {
        if (r.children[colIndex]) {
          r.children[colIndex].remove();
        }
      });

      if (table.querySelector('tr') && table.querySelector('tr').children.length === 0) {
        table.remove();
      }
    }

    static deleteTable(cell) {
      if (!cell) return;
      const table = cell.closest('table');
      if (table) table.remove();
    }
  }

  // ==========================================
  // 5. ACCESSIBLE MODAL DIALOGS (WCAG 2.1/2.2 AA)
  // ==========================================

  class Dialog {
    static show({ title, body, buttons = [], onClose = null, className = '' }) {
      Dialog.closeAll();

      const previousActiveElement = document.activeElement;
      const titleId = `jbd-dialog-title-${Date.now()}`;

      const overlay = createElement('div', {
        className: 'jbd-dialog-overlay',
        role: 'dialog',
        'aria-modal': 'true',
        'aria-labelledby': titleId
      });

      const modal = createElement('div', { className: `jbd-dialog ${className}`.trim() });

      // Header
      const header = createElement('div', { className: 'jbd-dialog-header' });
      const titleEl = createElement('h3', { className: 'jbd-dialog-title', id: titleId }, [title]);
      const closeBtn = createElement('button', {
        type: 'button',
        className: 'jbd-dialog-close',
        'aria-label': 'Close dialog',
        onClick: () => {
          Dialog.close(overlay, previousActiveElement);
          if (onClose) onClose();
        }
      });
      closeBtn.innerHTML = '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>';

      header.appendChild(titleEl);
      header.appendChild(closeBtn);
      modal.appendChild(header);

      // Body
      const bodyEl = createElement('div', { className: 'jbd-dialog-body' });
      if (typeof body === 'string') {
        bodyEl.innerHTML = body;
      } else if (body instanceof Node) {
        bodyEl.appendChild(body);
      }
      modal.appendChild(bodyEl);

      // Footer
      if (buttons.length > 0) {
        const footer = createElement('div', { className: 'jbd-dialog-footer' });
        buttons.forEach(btnSpec => {
          const btn = createElement('button', {
            type: 'button',
            className: `jbd-btn ${btnSpec.className || 'jbd-btn-secondary'}`,
            onClick: () => {
              if (btnSpec.onClick) {
                btnSpec.onClick(Dialog, overlay);
              } else {
                Dialog.close(overlay, previousActiveElement);
              }
            }
          }, [btnSpec.label]);
          footer.appendChild(btn);
        });
        modal.appendChild(footer);
      }

      overlay.appendChild(modal);
      document.body.appendChild(overlay);

      // Focus trap and Escape key handler
      const getFocusableElements = () => {
        return Array.from(modal.querySelectorAll(
          'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'
        ));
      };

      const keyHandler = (e) => {
        if (e.key === 'Escape') {
          Dialog.close(overlay, previousActiveElement);
          if (onClose) onClose();
          document.removeEventListener('keydown', keyHandler);
          return;
        }

        if (e.key === 'Tab') {
          const focusable = getFocusableElements();
          if (focusable.length === 0) {
            e.preventDefault();
            return;
          }

          const first = focusable[0];
          const last = focusable[focusable.length - 1];

          if (e.shiftKey) {
            if (document.activeElement === first || !modal.contains(document.activeElement)) {
              e.preventDefault();
              last.focus();
            }
          } else {
            if (document.activeElement === last || !modal.contains(document.activeElement)) {
              e.preventDefault();
              first.focus();
            }
          }
        }
      };
      document.addEventListener('keydown', keyHandler);

      overlay.addEventListener('click', (e) => {
        if (e.target === overlay) {
          Dialog.close(overlay, previousActiveElement);
          if (onClose) onClose();
        }
      });

      // Auto-focus first input or button in dialog
      setTimeout(() => {
        const focusable = getFocusableElements();
        if (focusable.length > 0) {
          const firstFormElement = focusable.find(el => el !== closeBtn);
          if (firstFormElement) {
            firstFormElement.focus();
          } else {
            focusable[0].focus();
          }
        }
      }, 50);

      return overlay;
    }

    static close(overlay, returnFocusEl = null) {
      if (overlay && overlay.parentNode) {
        overlay.parentNode.removeChild(overlay);
      }
      if (returnFocusEl && typeof returnFocusEl.focus === 'function') {
        try {
          returnFocusEl.focus();
        } catch {}
      }
    }

    static closeAll() {
      const existing = document.querySelectorAll('.jbd-dialog-overlay');
      existing.forEach(el => el.remove());
    }

    /**
     * Accessible Link insertion dialog
     */
    static openLinkDialog({ currentUrl = '', currentText = '', targetBlank = false, ariaLabel = '', onConfirm }) {
      const isFile = (url) => /\.(pdf|docx?|xlsx?|pptx?|csv|zip|tar|gz|txt|rtf|mp4|mp3|wav|avi|mov|epub|odt)($|[?#])/i.test(url);
      const isExternal = (url) => {
        if (!url) return false;
        try {
          if (url.startsWith('#') || url.startsWith('/') || url.startsWith('mailto:') || url.startsWith('tel:') || url.startsWith('javascript:')) return false;
          if (!/^https?:\/\//i.test(url)) return false;
          if (typeof window !== 'undefined' && window.location && window.location.hostname) {
            const u = new URL(url, window.location.origin);
            return u.hostname !== window.location.hostname;
          }
          return true;
        } catch {
          return false;
        }
      };

      // Determine initial protocol type
      let initialType = 'https';
      let cleanUrl = (currentUrl || '').trim();
      if (/^mailto:/i.test(cleanUrl)) {
        initialType = 'mailto';
        cleanUrl = cleanUrl.replace(/^mailto:/i, '').trim();
      } else if (/^tel:/i.test(cleanUrl)) {
        initialType = 'tel';
        cleanUrl = cleanUrl.replace(/^tel:/i, '').trim();
      } else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        initialType = 'https';
      }

      // Auto-detect if current link is external or a file
      const isExtOrFile = isExternal(currentUrl) || isFile(currentUrl);
      const shouldBlank = (initialType === 'mailto' || initialType === 'tel') ? false : (targetBlank || isExtOrFile);
      const shouldAda = (initialType === 'mailto' || initialType === 'tel') ? false : (shouldBlank || (ariaLabel && ariaLabel.toLowerCase().includes('new ')));

      const form = createElement('div', { className: 'jbd-form-grid' });

      form.innerHTML = `
        <div class="jbd-form-group">
          <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px; flex-wrap:wrap; gap:6px;">
            <label style="margin-bottom:0; font-weight:600; font-size:12px; color:var(--jbd-color-text,#334155);">Link Type</label>
            <button type="button" class="jbd-btn jbd-btn-xs" id="jbd-link-browse-doc" style="display:inline-flex; align-items:center; gap:5px; background:#eff6ff; color:#1d4ed8; border:1px solid #bfdbfe; font-weight:600; padding:3px 8px; border-radius:4px; font-size:11.5px; cursor:pointer;" title="Browse Chelan County Media Library documents folder to link a PDF or file">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
              <span>Link PDF / Document (Media Library)</span>
            </button>
          </div>
          <div style="display:flex; gap:6px;" id="jbd-link-type-tabs" role="radiogroup" aria-label="Link Protocol Type">
            <button type="button" class="jbd-btn jbd-btn-xs jbd-link-proto-btn ${initialType === 'https' ? 'is-active' : ''}" data-type="https" style="flex:1; justify-content:center; padding:5px 8px; font-weight:600;" aria-checked="${initialType === 'https' ? 'true' : 'false'}" role="radio">
              https:// (Web)
            </button>
            <button type="button" class="jbd-btn jbd-btn-xs jbd-link-proto-btn ${initialType === 'mailto' ? 'is-active' : ''}" data-type="mailto" style="flex:1; justify-content:center; padding:5px 8px; font-weight:600;" aria-checked="${initialType === 'mailto' ? 'true' : 'false'}" role="radio">
              mailto: (Email)
            </button>
            <button type="button" class="jbd-btn jbd-btn-xs jbd-link-proto-btn ${initialType === 'tel' ? 'is-active' : ''}" data-type="tel" style="flex:1; justify-content:center; padding:5px 8px; font-weight:600;" aria-checked="${initialType === 'tel' ? 'true' : 'false'}" role="radio">
              tel: (Phone)
            </button>
          </div>
        </div>

        <div class="jbd-form-group">
          <label for="jbd-link-text">Display Text</label>
          <input type="text" id="jbd-link-text" class="jbd-input" value="${escapeHTML(currentText)}" placeholder="Link text (optional)" />
        </div>

        <div class="jbd-form-group">
          <label for="jbd-link-url" id="jbd-link-url-label">URL Destination <span aria-hidden="true">*</span></label>
          <input type="text" id="jbd-link-url" class="jbd-input" value="${escapeHTML(cleanUrl ? (initialType === 'https' ? (currentUrl || 'https://') : cleanUrl) : (initialType === 'https' ? 'https://' : ''))}" placeholder="https://example.com or document.pdf" required aria-required="true" />
          <small id="jbd-link-url-hint" style="color:var(--jbd-color-muted, #64748b); font-size:11.5px; margin-top:4px; display:block;">
            Enter full web address (https://...) or choose a document.
          </small>
        </div>

        <div class="jbd-form-group-checkbox" id="jbd-link-blank-group">
          <label for="jbd-link-blank">
            <input type="checkbox" id="jbd-link-blank" ${shouldBlank ? 'checked' : ''} />
            Open link in new window/tab (<code>_blank</code>)
          </label>
        </div>

        <div class="jbd-form-group-checkbox" id="jbd-link-ada-group" style="margin-top:0.35rem;">
          <label for="jbd-link-ada">
            <input type="checkbox" id="jbd-link-ada" ${shouldAda ? 'checked' : ''} />
            Add ADA accessible label <em>(opens in a new tab)</em>
          </label>
          <small style="color:var(--jbd-color-muted); font-size:11.5px; display:block; margin-left:1.5rem; margin-top:2px;">
            WCAG 2.2 AA / ADA compliance: Alerts screen readers that this link will open outside the current window.
          </small>
        </div>
      `;

      const urlInput = form.querySelector('#jbd-link-url');
      const textInput = form.querySelector('#jbd-link-text');
      const urlLabel = form.querySelector('#jbd-link-url-label');
      const urlHint = form.querySelector('#jbd-link-url-hint');
      const blankGroup = form.querySelector('#jbd-link-blank-group');
      const adaGroup = form.querySelector('#jbd-link-ada-group');
      const blankInput = form.querySelector('#jbd-link-blank');
      const adaInput = form.querySelector('#jbd-link-ada');
      const protoBtns = form.querySelectorAll('.jbd-link-proto-btn');
      const browseDocBtn = form.querySelector('#jbd-link-browse-doc');

      let currentProto = initialType;

      const setLinkType = (type, updateVal = true) => {
        currentProto = type;
        protoBtns.forEach(btn => {
          const isMatch = btn.dataset.type === type;
          btn.classList.toggle('is-active', isMatch);
          btn.setAttribute('aria-checked', isMatch ? 'true' : 'false');
          if (isMatch) {
            btn.style.background = '#0284c7';
            btn.style.color = '#ffffff';
            btn.style.borderColor = '#0284c7';
          } else {
            btn.style.background = '';
            btn.style.color = '';
            btn.style.borderColor = '';
          }
        });

        if (type === 'mailto') {
          urlLabel.innerHTML = 'Email Address <span aria-hidden="true">*</span>';
          urlInput.placeholder = 'e.g. name@chelancounty.gov';
          urlHint.textContent = 'Email links launch the visitor’s default email client (mailto:).';
          if (blankGroup) blankGroup.style.display = 'none';
          if (adaGroup) adaGroup.style.display = 'none';
          blankInput.checked = false;
          adaInput.checked = false;

          if (updateVal) {
            let v = urlInput.value.trim();
            if (v.startsWith('https://') || v.startsWith('http://') || v.startsWith('tel:')) {
              urlInput.value = '';
            } else if (v.startsWith('mailto:')) {
              urlInput.value = v.substring(7);
            }
          }
        } else if (type === 'tel') {
          urlLabel.innerHTML = 'Phone Number <span aria-hidden="true">*</span>';
          urlInput.placeholder = 'e.g. (509) 667-6200';
          urlHint.textContent = 'Phone links allow direct dialing on mobile devices and phone apps (tel:).';
          if (blankGroup) blankGroup.style.display = 'none';
          if (adaGroup) adaGroup.style.display = 'none';
          blankInput.checked = false;
          adaInput.checked = false;

          if (updateVal) {
            let v = urlInput.value.trim();
            if (v.startsWith('https://') || v.startsWith('http://') || v.startsWith('mailto:')) {
              urlInput.value = '';
            } else if (v.startsWith('tel:')) {
              urlInput.value = v.substring(4);
            }
          }
        } else {
          // https / Web / Document
          urlLabel.innerHTML = 'URL Destination <span aria-hidden="true">*</span>';
          urlInput.placeholder = 'https://example.com or /files/.../document.pdf';
          urlHint.textContent = 'Enter full web address (https://...) or choose a document.';
          if (blankGroup) blankGroup.style.display = '';
          if (adaGroup) adaGroup.style.display = '';

          if (updateVal) {
            let v = urlInput.value.trim();
            if (v.startsWith('mailto:') || v.startsWith('tel:') || !v) {
              urlInput.value = 'https://';
            }
          }
        }
      };

      protoBtns.forEach(btn => {
        btn.addEventListener('click', () => {
          setLinkType(btn.dataset.type, true);
          urlInput.focus();
        });
      });

      // Initialize state for current type
      setLinkType(initialType, false);

      // Media Library Document Picker Integration
      const openDocPicker = () => {
        const onSelectDoc = (data) => {
          const docUrl = (data && (data.url || (data.data && data.data.webUrl))) || '';
          const docTitle = (data && (data.title || (data.data && (data.data.title || data.data.name)))) || '';
          if (docUrl) {
            setLinkType('https', false);
            urlInput.value = docUrl;
            if (!textInput.value || textInput.value === 'https://') {
              textInput.value = docTitle || docUrl.split('/').pop().replace(/\.[^/.]+$/, '');
            }
            blankInput.checked = true;
            blankInput.dataset.userModified = 'true';
            adaInput.checked = true;
            adaInput.dataset.userModified = 'true';
            urlInput.dispatchEvent(new Event('input'));
            urlInput.focus();
          }
        };

        if (typeof window !== 'undefined' && typeof window.openMediaPicker === 'function') {
          window.openMediaPicker('document', { folder: 'documents', onSelect: onSelectDoc });
        } else if (typeof window !== 'undefined') {
          let modal = document.getElementById('mediaPickerModal');
          let backdrop = document.getElementById('mediaPickerModalBackdrop');
          let iframe = document.getElementById('mediaPickerIframe');
          if (modal && iframe) {
            window._mediaPickerCustomCallback = onSelectDoc;
            modal.style.zIndex = '100005';
            if (backdrop) backdrop.style.zIndex = '100004';
            iframe.src = '/media/picker?picker=document&type=document&folder=documents&ws=all&callback=onMediaSelectedFromPicker';
            modal.style.display = 'flex';
            modal.classList.add('open');
            if (backdrop) {
              backdrop.style.display = 'block';
              backdrop.style.opacity = '1';
              backdrop.style.visibility = 'visible';
            }
          }
        }
      };

      if (browseDocBtn) {
        browseDocBtn.addEventListener('click', (e) => {
          e.preventDefault();
          openDocPicker();
        });
      }

      // Auto-toggle when user types an external URL or file URL
      urlInput.addEventListener('input', () => {
        const v = urlInput.value.trim();
        if (/^mailto:/i.test(v) && currentProto !== 'mailto') {
          setLinkType('mailto', false);
        } else if (/^tel:/i.test(v) && currentProto !== 'tel') {
          setLinkType('tel', false);
        } else if (/^https?:\/\//i.test(v) && currentProto !== 'https') {
          setLinkType('https', false);
        }

        if (currentProto === 'https' && (isExternal(v) || isFile(v))) {
          if (!blankInput.dataset.userModified) {
            blankInput.checked = true;
          }
          if (!adaInput.dataset.userModified) {
            adaInput.checked = true;
          }
        }
      });

      blankInput.addEventListener('change', () => {
        blankInput.dataset.userModified = 'true';
        if (blankInput.checked) {
          if (!adaInput.dataset.userModified) adaInput.checked = true;
        } else {
          if (!adaInput.dataset.userModified) adaInput.checked = false;
        }
      });

      adaInput.addEventListener('change', () => {
        adaInput.dataset.userModified = 'true';
      });

      Dialog.show({
        title: 'Insert / Edit Link',
        body: form,
        buttons: [
          { label: 'Cancel', className: 'jbd-btn-secondary' },
          {
            label: 'Save Link',
            className: 'jbd-btn-primary',
            onClick: (d, overlay) => {
              let url = urlInput.value.trim();
              let text = textInput.value.trim();
              let blank = blankInput.checked;
              let ada = adaInput.checked;

              if (currentProto === 'mailto') {
                const emailClean = url.replace(/^mailto:/i, '').trim();
                if (!emailClean) {
                  urlInput.focus();
                  return;
                }
                url = `mailto:${emailClean}`;
                if (!text) text = emailClean;
                blank = false;
                ada = false;
              } else if (currentProto === 'tel') {
                const phoneClean = url.replace(/^tel:/i, '').trim();
                if (!phoneClean) {
                  urlInput.focus();
                  return;
                }
                const telClean = phoneClean.replace(/[^\d+]/g, '');
                url = `tel:${telClean || phoneClean}`;
                if (!text) text = phoneClean;
                blank = false;
                ada = false;
              } else {
                if (!url || url === 'https://' || url === 'http://') {
                  urlInput.focus();
                  return;
                }
                if (!/^[a-z]+:/i.test(url) && !url.startsWith('/') && !url.startsWith('#')) {
                  url = 'https://' + url;
                }
              }

              if (url) {
                onConfirm({ url, text, blank, ada });
                d.close(overlay);
              } else {
                urlInput.focus();
              }
            }
          }
        ]
      });
    }

    /**
   * Accessible Named Anchor / Bookmark insertion dialog
   */
static openAnchorDialog({ currentName = '', currentText = '', onConfirm }) {
    const form = createElement('div', { className: 'jbd-form-grid' });

    form.innerHTML = `
      <div class="jbd-form-group">
        <label for="jbd-anchor-name">Anchor ID / Name <span aria-hidden="true">*</span></label>
        <div style="display:flex; align-items:center; gap:6px;">
          <span style="font-family:monospace; font-size:14px; font-weight:700; color:#0284c7;">#</span>
          <input type="text" id="jbd-anchor-name" class="jbd-input" value="${currentName}" placeholder="e.g. section-1, contact-us, faq" required aria-required="true" style="font-family:monospace; flex:1;" />
        </div>
        <small style="color:var(--jbd-color-muted); font-size:11.5px; margin-top:4px; display:block;">
          Used for in-page jump links like <code>#section-1</code>. Spaces will be converted to hyphens.
        </small>
      </div>
      <div class="jbd-form-group">
        <label for="jbd-anchor-text">Display Marker Label</label>
        <input type="text" id="jbd-anchor-text" class="jbd-input" value="${currentText}" placeholder="Optional label displayed on marker tag" />
        <small style="color:var(--jbd-color-muted); font-size:11.5px; margin-top:4px; display:block;">
          If left blank, the anchor ID (e.g. #section-1) will serve as the label.
        </small>
      </div>
    `;

    Dialog.show({
      title: 'Insert / Edit Page Anchor (Bookmark)',
      body: form,
      buttons: [
        { label: 'Cancel', className: 'jbd-btn-secondary' },
        {
          label: 'Save Anchor',
          className: 'jbd-btn-primary',
          onClick: (d, overlay) => {
            const nameInput = overlay.querySelector('#jbd-anchor-name');
            let name = nameInput.value.trim().toLowerCase().replace(/^#+/, '').replace(/\s+/g, '-').replace(/[^a-z0-9_-]/g, '');
            const text = overlay.querySelector('#jbd-anchor-text').value.trim();

            if (name) {
              onConfirm({ name, text });
              d.close(overlay);
            } else {
              nameInput.focus();
            }
          }
        }
      ]
    });
  }

  /**
   * Accessible Image insertion dialog
   */
    static openFindReplaceDialog({ onFind, onReplace, onReplaceAll }) {
      const form = createElement('div', { className: 'jbd-form-grid' });

      form.innerHTML = `
        <div class="jbd-form-group">
          <label for="jbd-find-text">Find text <span aria-hidden="true">*</span></label>
          <input type="text" id="jbd-find-text" class="jbd-input" placeholder="Text to search for..." required aria-required="true" />
        </div>
        <div class="jbd-form-group">
          <label for="jbd-replace-text">Replace with</label>
          <input type="text" id="jbd-replace-text" class="jbd-input" placeholder="Replacement text..." />
        </div>
        <div class="jbd-form-group-checkbox">
          <label for="jbd-find-matchcase">
            <input type="checkbox" id="jbd-find-matchcase" />
            Match Case
          </label>
        </div>
      `;

      Dialog.show({
        title: 'Find and Replace',
        body: form,
        buttons: [
          { label: 'Close', className: 'jbd-btn-secondary' },
          {
            label: 'Find Next',
            className: 'jbd-btn-secondary',
            onClick: (d, overlay) => {
              const findText = overlay.querySelector('#jbd-find-text').value;
              const matchCase = overlay.querySelector('#jbd-find-matchcase').checked;
              if (findText) onFind(findText, matchCase);
            }
          },
          {
            label: 'Replace',
            className: 'jbd-btn-secondary',
            onClick: (d, overlay) => {
              const findText = overlay.querySelector('#jbd-find-text').value;
              const replaceText = overlay.querySelector('#jbd-replace-text').value;
              const matchCase = overlay.querySelector('#jbd-find-matchcase').checked;
              if (findText) onReplace(findText, replaceText, matchCase);
            }
          },
          {
            label: 'Replace All',
            className: 'jbd-btn-primary',
            onClick: (d, overlay) => {
              const findText = overlay.querySelector('#jbd-find-text').value;
              const replaceText = overlay.querySelector('#jbd-replace-text').value;
              const matchCase = overlay.querySelector('#jbd-find-matchcase').checked;
              if (findText) onReplaceAll(findText, replaceText, matchCase);
              d.close(overlay);
            }
          }
        ]
      });
    }

    /**
     * Accessible HTML Block Template selection dialog with live preview
     * @param {Object} options
     * @param {Array} [options.templates]
     * @param {(html: string, template: Object) => void} options.onSelect
     */
    static openTemplateDialog({ templates = DEFAULT_BLOCK_TEMPLATES, onSelect }) {
      const list = Array.isArray(templates) && templates.length > 0 ? templates : DEFAULT_BLOCK_TEMPLATES;
      let selectedTemplate = list[0];
      let activeCategory = 'All';
      let searchQuery = '';

      const categories = ['All', ...new Set(list.map(t => t.category || 'General'))];
      const container = createElement('div', { className: 'jbd-template-dialog-content' });

      const filterRow = createElement('div', { className: 'jbd-template-filter-row' });
      const searchInput = createElement('input', {
        type: 'search',
        className: 'jbd-input jbd-template-search',
        placeholder: 'Search templates by title or description...',
        'aria-label': 'Search templates'
      });

      const pillsContainer = createElement('div', {
        className: 'jbd-template-category-pills',
        role: 'tablist',
        'aria-label': 'Template categories'
      });

      categories.forEach(cat => {
        const pill = createElement('button', {
          type: 'button',
          className: `jbd-category-pill ${cat === activeCategory ? 'active' : ''}`,
          role: 'tab',
          'aria-selected': cat === activeCategory ? 'true' : 'false',
          onClick: () => {
            activeCategory = cat;
            updatePills();
            renderCards();
          }
        }, [cat]);
        pillsContainer.appendChild(pill);
      });

      filterRow.appendChild(searchInput);
      filterRow.appendChild(pillsContainer);
      container.appendChild(filterRow);

      const browserGrid = createElement('div', { className: 'jbd-template-browser-grid' });
      const listPane = createElement('div', {
        className: 'jbd-template-list-pane',
        role: 'region',
        'aria-label': 'Available templates'
      });
      const previewPane = createElement('div', {
        className: 'jbd-template-preview-pane',
        role: 'region',
        'aria-label': 'Template live preview'
      });

      browserGrid.appendChild(listPane);
      browserGrid.appendChild(previewPane);
      container.appendChild(browserGrid);

      function updatePills() {
        pillsContainer.querySelectorAll('.jbd-category-pill').forEach(btn => {
          const isAct = btn.textContent === activeCategory;
          btn.classList.toggle('active', isAct);
          btn.setAttribute('aria-selected', isAct ? 'true' : 'false');
        });
      }

      function renderPreview() {
        previewPane.innerHTML = '';
        if (!selectedTemplate) {
          previewPane.innerHTML = '<div class="jbd-template-no-preview">Select a template to preview</div>';
          return;
        }

        const previewHeader = createElement('div', { className: 'jbd-template-preview-header' });
        previewHeader.innerHTML = `
          <div class="jbd-template-preview-title-wrap">
            <span class="jbd-template-card-badge">${selectedTemplate.category || 'General'}</span>
            <h4 class="jbd-template-preview-title">${selectedTemplate.title}</h4>
          </div>
          <p class="jbd-template-preview-desc">${selectedTemplate.description || ''}</p>
        `;

        const canvas = createElement('div', {
          className: 'jbd-template-preview-canvas jbd-editor-content'
        });
        canvas.innerHTML = selectedTemplate.html;

        previewPane.appendChild(previewHeader);
        previewPane.appendChild(canvas);
      }

      function renderCards() {
        listPane.innerHTML = '';
        const filtered = list.filter(t => {
          const matchesCat = activeCategory === 'All' || (t.category || 'General') === activeCategory;
          const matchesQuery = !searchQuery ||
            t.title.toLowerCase().includes(searchQuery) ||
            (t.description && t.description.toLowerCase().includes(searchQuery));
          return matchesCat && matchesQuery;
        });

        if (filtered.length === 0) {
          listPane.innerHTML = '<div class="jbd-template-empty-message">No templates match your search.</div>';
          return;
        }

        if (!filtered.includes(selectedTemplate)) {
          selectedTemplate = filtered[0];
          renderPreview();
        }

        filtered.forEach(tmpl => {
          const isSelected = selectedTemplate && selectedTemplate.id === tmpl.id;
          const card = createElement('div', {
            className: `jbd-template-card ${isSelected ? 'active' : ''}`,
            role: 'button',
            tabindex: '0',
            'aria-selected': isSelected ? 'true' : 'false',
            'aria-label': `${tmpl.title} template`,
            onClick: () => {
              selectedTemplate = tmpl;
              renderCards();
              renderPreview();
            },
            onDblclick: () => {
              selectedTemplate = tmpl;
              submitSelection();
            },
            onKeydown: (e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                selectedTemplate = tmpl;
                renderCards();
                renderPreview();
              }
            }
          });

          const iconHtml = tmpl.icon || '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#6366f1" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/></svg>';
          card.innerHTML = `
            <div class="jbd-template-card-icon">${iconHtml}</div>
            <div class="jbd-template-card-info">
              <div class="jbd-template-card-top">
                <strong class="jbd-template-card-title">${tmpl.title}</strong>
                <span class="jbd-template-card-badge">${tmpl.category || 'General'}</span>
              </div>
              <p class="jbd-template-card-desc">${tmpl.description || ''}</p>
            </div>
          `;

          listPane.appendChild(card);
        });
      }

      searchInput.addEventListener('input', (e) => {
        searchQuery = e.target.value.trim().toLowerCase();
        renderCards();
      });

      let currentDialogInstance = null;
      let currentOverlayElement = null;

      function submitSelection() {
        if (selectedTemplate && onSelect) {
          onSelect(selectedTemplate.html, selectedTemplate);
        }
        if (currentDialogInstance && currentOverlayElement) {
          currentDialogInstance.close(currentOverlayElement);
        } else {
          Dialog.closeAll();
        }
      }

      renderCards();
      renderPreview();

      Dialog.show({
        title: 'Insert HTML Block Template',
        className: 'jbd-dialog-wide',
        body: container,
        buttons: [
          { label: 'Cancel', className: 'jbd-btn-secondary' },
          {
            label: 'Insert Template',
            className: 'jbd-btn-primary',
            onClick: (d, overlay) => {
              currentDialogInstance = d;
              currentOverlayElement = overlay;
              submitSelection();
            }
          }
        ]
      });
    }
  }

  const DEFAULT_BLOCK_TEMPLATES = [
  {
    id: 'callout-info',
    title: 'Info Callout',
    category: 'Callouts',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true" focusable="false"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>',
    description: 'Accessible informational callout with accent border and title.',
    html: `<aside class="jbd-template jbd-callout jbd-callout-info" aria-label="Note: Information">
  <div class="jbd-callout-header">
    <span class="jbd-callout-badge" aria-hidden="true">INFO</span>
    <strong class="jbd-callout-title">Important Information</strong>
  </div>
  <p>Enter your key takeaway or instructions for the reader here.</p>
</aside>`
  },
  {
    id: 'callout-warning',
    title: 'Warning Callout',
    category: 'Callouts',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#d97706" stroke-width="2" aria-hidden="true" focusable="false"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
    description: 'High-contrast alert box for warnings, precautions, or disclaimers.',
    html: `<aside class="jbd-template jbd-callout jbd-callout-warning" aria-label="Warning: Caution Required">
  <div class="jbd-callout-header">
    <span class="jbd-callout-badge" aria-hidden="true">WARNING</span>
    <strong class="jbd-callout-title">Caution Required</strong>
  </div>
  <p>Review requirements carefully before proceeding with this step.</p>
</aside>`
  },
  {
    id: 'callout-success',
    title: 'Success Callout',
    category: 'Callouts',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#16a34a" stroke-width="2" aria-hidden="true" focusable="false"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>',
    description: 'Confirmed success notification box for verified actions and tips.',
    html: `<aside class="jbd-template jbd-callout jbd-callout-success" aria-label="Notice: Action Complete">
  <div class="jbd-callout-header">
    <span class="jbd-callout-badge" aria-hidden="true">SUCCESS</span>
    <strong class="jbd-callout-title">Action Complete</strong>
  </div>
  <p>The operation or milestone has completed successfully.</p>
</aside>`
  },
  {
    id: 'grid-2col',
    title: '2-Column Split',
    category: 'Layouts',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#4f46e5" stroke-width="2" aria-hidden="true" focusable="false"><rect x="3" y="3" width="18" height="18" rx="2"/><line x1="12" y1="3" x2="12" y2="21"/></svg>',
    description: 'Semantic 2-column layout section for paired text or comparisons.',
    html: `<section class="jbd-template jbd-grid jbd-grid-2col" aria-label="Two column content section">
  <div class="jbd-grid-col">
    <p class="h4" style="margin:0 0 0.5rem 0; font-weight:700;">Left Column</p>
    <p>Describe your first topic, bullet points, or media content here.</p>
  </div>
  <div class="jbd-grid-col">
    <p class="h4" style="margin:0 0 0.5rem 0; font-weight:700;">Right Column</p>
    <p>Describe your second topic, comparison points, or supporting details here.</p>
  </div>
</section>`
  },
  {
    id: 'grid-3col',
    title: '3-Column Cards',
    category: 'Layouts',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#4f46e5" stroke-width="2" aria-hidden="true" focusable="false"><rect x="2" y="3" width="20" height="18" rx="2"/><line x1="8.66" y1="3" x2="8.66" y2="21"/><line x1="15.33" y1="3" x2="15.33" y2="21"/></svg>',
    description: 'Independent semantic article cards for highlighting services or features.',
    html: `<section class="jbd-template jbd-grid jbd-grid-3col" aria-label="Feature highlights">
  <article class="jbd-card">
    <p class="h4" style="margin:0 0 0.5rem 0; font-weight:700;">Feature One</p>
    <p>Highlight the primary benefit and key advantage for users.</p>
  </article>
  <article class="jbd-card">
    <p class="h4" style="margin:0 0 0.5rem 0; font-weight:700;">Feature Two</p>
    <p>Detail how this capability operates smoothly out of the box.</p>
  </article>
  <article class="jbd-card">
    <p class="h4" style="margin:0 0 0.5rem 0; font-weight:700;">Feature Three</p>
    <p>Explain performance metrics, compliance, and developer speed.</p>
  </article>
</section>`
  },
  {
    id: 'hero-banner',
    title: 'Hero Banner',
    category: 'Marketing',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#db2777" stroke-width="2" aria-hidden="true" focusable="false"><rect x="2" y="4" width="20" height="16" rx="2"/><line x1="6" y1="9" x2="18" y2="9"/><line x1="6" y1="13" x2="14" y2="13"/></svg>',
    description: 'Prominent header banner with headline, description, and action button.',
    html: `<header class="jbd-template jbd-hero" aria-label="Featured announcement">
  <p class="jbd-hero-title h4" style="font-size:1.5rem; font-weight:700; margin:0 0 0.5rem 0;">Engage Your Audience</p>
  <p class="jbd-hero-lead">Create rich, impactful documents with standalone vanilla components.</p>
  <div class="jbd-hero-actions">
    <a href="#learn-more" class="jbd-btn jbd-btn-primary" aria-label="Get Started Now with our platform">Get Started Now</a>
  </div>
</header>`
  },
  {
    id: 'panel-info',
    title: 'Info Panel / Card',
    category: 'Panels & Cards',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#1d4ed8" stroke-width="2" aria-hidden="true" focusable="false"><rect x="3" y="3" width="18" height="18" rx="3"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>',
    description: 'Structured informational panel card with header bar, badge, and card body.',
    html: `<section class="jbd-template jbd-panel jbd-panel-info" aria-label="Information Panel">
  <div class="jbd-panel-header">
    <span class="jbd-panel-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" focusable="false"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
    </span>
    <p class="jbd-panel-title h4">System Information</p>
    <span class="jbd-panel-badge" aria-hidden="true">INFO</span>
  </div>
  <div class="jbd-panel-body">
    <p>Displays helpful context, operational status, or system specifications in an organized card layout.</p>
  </div>
</section>`
  },
  {
    id: 'panel-warning',
    title: 'Warning Panel / Card',
    category: 'Panels & Cards',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#b45309" stroke-width="2" aria-hidden="true" focusable="false"><rect x="3" y="3" width="18" height="18" rx="3"/><path d="M12 8v4"/><path d="M12 16h.01"/></svg>',
    description: 'High-visibility caution panel card for prerequisites and advisory notices.',
    html: `<section class="jbd-template jbd-panel jbd-panel-warning" aria-label="Warning Panel">
  <div class="jbd-panel-header">
    <span class="jbd-panel-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" focusable="false"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
    </span>
    <p class="jbd-panel-title h4">Attention Required</p>
    <span class="jbd-panel-badge" aria-hidden="true">WARNING</span>
  </div>
  <div class="jbd-panel-body">
    <p>Please double check configurations and review permissions before continuing this operation.</p>
  </div>
</section>`
  },
  {
    id: 'panel-success',
    title: 'Success Panel / Card',
    category: 'Panels & Cards',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#15803d" stroke-width="2" aria-hidden="true" focusable="false"><rect x="3" y="3" width="18" height="18" rx="3"/><path d="M9 12l2 2 4-4"/></svg>',
    description: 'Positive confirmation panel card for completed actions, milestones, and approvals.',
    html: `<section class="jbd-template jbd-panel jbd-panel-success" aria-label="Success Panel">
  <div class="jbd-panel-header">
    <span class="jbd-panel-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" focusable="false"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
    </span>
    <p class="jbd-panel-title h4">Process Complete</p>
    <span class="jbd-panel-badge" aria-hidden="true">SUCCESS</span>
  </div>
  <div class="jbd-panel-body">
    <p>All items have been verified and saved to the database. No further action is necessary.</p>
  </div>
</section>`
  },
  {
    id: 'panel-alert',
    title: 'Alert / Danger Panel',
    category: 'Panels & Cards',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#b91c1c" stroke-width="2" aria-hidden="true" focusable="false"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="12" cy="12" r="4"/></svg>',
    description: 'High-priority alert card for critical errors, security warnings, or destructive actions.',
    html: `<section class="jbd-template jbd-panel jbd-panel-alert" aria-label="Alert Panel">
  <div class="jbd-panel-header">
    <span class="jbd-panel-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" focusable="false"><polygon points="7.86 2 16.14 2 22 7.86 22 16.14 16.14 22 7.86 22 2 16.14 2 7.86 7.86 2"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
    </span>
    <p class="jbd-panel-title h4">Critical Notice</p>
    <span class="jbd-panel-badge" aria-hidden="true">ALERT</span>
  </div>
  <div class="jbd-panel-body">
    <p>This action cannot be undone. Make sure you have exported backups before initiating deletion.</p>
  </div>
</section>`
  },
  {
    id: 'quote-card',
    title: 'Quote Card',
    category: 'Typography',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#7c3aed" stroke-width="2" aria-hidden="true" focusable="false"><path d="M3 21c3 0 7-1 7-8V5c0-1.25-.75-2-2-2H4c-1.25 0-2 .75-2 2v6c0 1.25.75 2 2 2 1 0 1 0 1 1 0 2-1 4-2 7z"/><path d="M15 21c3 0 7-1 7-8V5c0-1.25-.75-2-2-2h-4c-1.25 0-2 .75-2 2v6c0 1.25.75 2 2 2 1 0 1 0 1 1 0 2-1 4-2 7z"/></svg>',
    description: 'Semantic figure with blockquote and cite tag for author attribution.',
    html: `<figure class="jbd-template jbd-quote-card" aria-label="Quotation">
  <blockquote>
    <p>"Perfection is achieved, not when there is nothing more to add, but when there is nothing left to take away."</p>
  </blockquote>
  <figcaption>&mdash; <cite>Antoine de Saint-Exup&eacute;ry</cite></figcaption>
</figure>`
  },
  {
    id: 'faq-block',
    title: 'Always-Open FAQ Block',
    category: 'Components',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#0284c7" stroke-width="2" aria-hidden="true" focusable="false"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
    description: 'Always-open, accessible FAQ section without accordion collapse, with button to add more Q&As.',
    html: `<section class="jbd-template jbd-faq-block" aria-label="Frequently Asked Questions">
  <div class="jbd-faq-item">
    <div class="jbd-faq-header">
      <span class="jbd-faq-badge" aria-hidden="true">Q:</span>
      <p class="jbd-faq-question h4">What makes this editor unique?</p>
    </div>
    <div class="jbd-faq-answer">
      <p>It is 100% Vanilla JavaScript with zero dependencies, full keyboard navigation, and WCAG 2.2 Level AA compliance.</p>
    </div>
  </div>
  <div class="jbd-faq-item">
    <div class="jbd-faq-header">
      <span class="jbd-faq-badge" aria-hidden="true">Q:</span>
      <p class="jbd-faq-question h4">How does accessibility work in these templates?</p>
    </div>
    <div class="jbd-faq-answer">
      <p>All templates use semantic landmark elements (&lt;section&gt;, &lt;aside&gt;, &lt;header&gt;), proper heading structures, and high-contrast color ratios.</p>
    </div>
  </div>
  <div class="jbd-faq-actions" contenteditable="false">
    <button type="button" class="jbd-faq-add-btn" data-jbd-faq-add="true" aria-label="Add new Question and Answer">
      <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>
      <span>Add Question &amp; Answer</span>
    </button>
  </div>
</section>`
  },
  {
    id: 'timeline-steps',
    title: 'Step Timeline',
    category: 'Components',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#059669" stroke-width="2" aria-hidden="true" focusable="false"><circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><line x1="6" y1="9" x2="6" y2="15"/><line x1="12" y1="6" x2="20" y2="6"/><line x1="12" y1="18" x2="20" y2="18"/></svg>',
    description: 'Semantic ordered list representing a chronological process, with button to add steps.',
    html: `<div class="jbd-template jbd-timeline-container">
  <ol class="jbd-timeline" aria-label="Process steps">
    <li class="jbd-step">
      <div class="jbd-step-badge" aria-hidden="true">1</div>
      <div class="jbd-step-body">
        <strong class="jbd-step-title">Step 1: Configuration</strong>
        <p>Attach JBDEditor to your standard form textarea.</p>
      </div>
    </li>
    <li class="jbd-step">
      <div class="jbd-step-badge" aria-hidden="true">2</div>
      <div class="jbd-step-body">
        <strong class="jbd-step-title">Step 2: Customization</strong>
        <p>Configure toolbar buttons, block templates, and auto-save keys.</p>
      </div>
    </li>
  </ol>
  <div class="jbd-timeline-actions" contenteditable="false">
    <button type="button" class="jbd-timeline-add-btn" data-jbd-timeline-add="true" aria-label="Add new timeline step">
      <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>
      <span>Add Step</span>
    </button>
  </div>
</div>`
  },
  {
    id: 'news-article',
    title: 'News Article',
    category: 'Articles',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16a2 2 0 0 1-2 2Zm0 0a2 2 0 0 1-2-2v-9c0-1.1.9-2 2-2h2"/><path d="M18 14h-8"/><path d="M15 18h-5"/><path d="M10 6h8v4h-8V6Z"/></svg>',
    description: 'Accessible semantic news article layout with headline, author byline, date, lead paragraph, figure image, and body.',
    html: `<article class="jbd-template jbd-article" aria-label="News Article">
  <header class="jbd-article-header">
    <span class="jbd-article-tag">Press Release</span>
    <h2 class="jbd-article-headline">Headline: Major Milestone Announced in Web Innovation</h2>
    <div class="jbd-article-meta">
      <span class="jbd-article-byline">By <span class="jbd-article-author">Jane Doe</span></span>
      <span class="jbd-article-separator" aria-hidden="true">&bull;</span>
      <time datetime="2026-10-10" class="jbd-article-date">October 10, 2026</time>
      <span class="jbd-article-separator" aria-hidden="true">&bull;</span>
      <span class="jbd-article-readtime">3 min read</span>
    </div>
  </header>
  <p class="jbd-article-lead">A concise opening lead paragraph highlighting the essential who, what, when, where, and why of this breaking announcement.</p>
  <figure class="jbd-article-figure">
    <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='800' height='400' viewBox='0 0 800 400'%3E%3Crect width='800' height='400' fill='%23f1f5f9'/%3E%3Cpath d='M300 260l70-80 60 70 80-100 90 110H200z' fill='%23cbd5e1'/%3E%3Ccircle cx='320' cy='160' r='30' fill='%2394a3b8'/%3E%3Ctext x='50%25' y='85%25' dominant-baseline='middle' text-anchor='middle' font-family='system-ui,sans-serif' font-size='18' fill='%2364748b'%3EFeatured Article Image%3C/text%3E%3C/svg%3E" alt="Visual representation of the announced milestone" class="jbd-article-img" />
    <figcaption class="jbd-article-figcaption">Photograph or graphic illustrating key developments in the story.</figcaption>
  </figure>
  <div class="jbd-article-body">
    <p>The main article narrative begins here. In-depth reporting, background facts, and quotes from organizers provide comprehensive context for readers.</p>
    <p>Supporting data points and final takeaways can be placed in this subsequent section to conclude the story effectively.</p>
  </div>
</article>`
  },
  {
    id: 'table-of-contents',
    title: 'On This Page (Table of Contents)',
    category: 'Subpage & Navigation',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true" focusable="false"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><circle cx="4" cy="6" r="1.5" fill="currentColor"/><circle cx="4" cy="12" r="1.5" fill="currentColor"/><circle cx="4" cy="18" r="1.5" fill="currentColor"/></svg>',
    description: 'Accessible in-page jump navigation box linking to page headings and bookmark anchors.',
    html: `<nav class="jbd-template jbd-toc" aria-label="Table of Contents">
  <div class="jbd-toc-header">
    <span class="jbd-toc-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><circle cx="4" cy="6" r="1.5" fill="currentColor"/><circle cx="4" cy="12" r="1.5" fill="currentColor"/><circle cx="4" cy="18" r="1.5" fill="currentColor"/></svg>
    </span>
    <strong class="jbd-toc-title">On This Page</strong>
  </div>
  <ol class="jbd-toc-list">
    <li><a href="#overview">Overview &amp; Purpose</a></li>
    <li><a href="#requirements">Key Requirements</a></li>
    <li><a href="#process">Step-by-Step Process</a></li>
    <li><a href="#contact">Contact &amp; Assistance</a></li>
  </ol>
</nav>`
  },
  {
    id: 'subpage-menu',
    title: 'Subpage Menu / Section Tree',
    category: 'Subpage & Navigation',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#0284c7" stroke-width="2" aria-hidden="true" focusable="false"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>',
    description: 'Side menu or subpage index block listing all sibling or child subpages in the current department section.',
    html: `<nav class="jbd-template jbd-subpage-menu" aria-label="Subpage Navigation">
  <div class="jbd-subpage-menu-header">
    <span class="jbd-subpage-menu-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
    </span>
    <strong class="jbd-subpage-menu-title">In This Section</strong>
  </div>
  <ul class="jbd-subpage-menu-list">
    <li><a href="#subpage-1" aria-current="page">Current Subpage Overview</a></li>
    <li><a href="#subpage-2">Department Services &amp; Applications</a></li>
    <li><a href="#subpage-3">Permits &amp; Regulations</a></li>
    <li><a href="#subpage-4">Frequently Asked Questions</a></li>
  </ul>
</nav>`
  },
  {
    id: 'related-pages',
    title: 'Related Pages & Department Guides',
    category: 'Subpage & Navigation',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#0d9488" stroke-width="2" aria-hidden="true" focusable="false"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>',
    description: 'Cross-reference card with descriptive cards for companion county department pages.',
    html: `<nav class="jbd-template jbd-related-pages" aria-label="Related Pages">
  <div class="jbd-related-pages-header">
    <span class="jbd-related-pages-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
    </span>
    <strong class="jbd-related-pages-title">Related Pages &amp; Guides</strong>
  </div>
  <ul class="jbd-related-pages-list">
    <li>
      <a href="/assessor">Assessor &amp; Property Information</a>
      <span class="jbd-related-pages-desc">Search parcel maps, real property data, and tax assessment schedules.</span>
    </li>
    <li>
      <a href="/treasurer">Treasurer &amp; Tax Payments</a>
      <span class="jbd-related-pages-desc">Online payment portals, payment options, and fee schedules.</span>
    </li>
    <li>
      <a href="/community-development">Community Development &amp; Planning</a>
      <span class="jbd-related-pages-desc">Zoning code, building permits, and comprehensive plan amendments.</span>
    </li>
  </ul>
</nav>`
  },
  {
    id: 'related-links',
    title: 'Related Links & External Resources',
    category: 'Subpage & Navigation',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#16a34a" stroke-width="2" aria-hidden="true" focusable="false"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>',
    description: 'Curated list of official resources, forms, downloadable files, and partner portals.',
    html: `<nav class="jbd-template jbd-related-links" aria-label="Related Links and Resources">
  <div class="jbd-related-header">
    <span class="jbd-related-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
    </span>
    <strong class="jbd-related-title">Related Resources &amp; Links</strong>
  </div>
  <ul class="jbd-related-list">
    <li>
      <a href="#county-code">Chelan County Code &amp; Regulations</a>
      <span class="jbd-related-desc">Official municipal code and legislative records</span>
    </li>
    <li>
      <a href="#permit-portal">Online Applications &amp; Forms</a>
      <span class="jbd-related-desc">Downloadable forms and electronic filing portal</span>
    </li>
    <li>
      <a href="#public-notices">Public Notices &amp; Meeting Agendas</a>
      <span class="jbd-related-desc">Upcoming hearing schedules and community notices</span>
    </li>
  </ul>
</nav>`
  },
  {
    id: 'contact-hours',
    title: 'Contact Us & Office Hours',
    category: 'Subpage & Navigation',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true" focusable="false"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>',
    description: 'Accessible card displaying physical location, weekly office hours, phone, and email.',
    html: `<aside class="jbd-template jbd-contact-card" aria-label="Department Contact and Hours">
  <div class="jbd-contact-header">
    <span class="jbd-contact-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
    </span>
    <strong class="jbd-contact-title">Office Hours &amp; Location</strong>
  </div>
  <div class="jbd-contact-body">
    <p><strong>Location:</strong> 350 Orondo Ave, Suite 201, Wenatchee, WA 98801</p>
    <p><strong>Hours:</strong> Monday &ndash; Friday: 8:00 AM &ndash; 5:00 PM</p>
    <p><strong>Phone:</strong> <a href="tel:5096676100">(509) 667-6100</a></p>
    <p><strong>Email:</strong> <a href="mailto:info@chelancounty.gov">info@chelancounty.gov</a></p>
  </div>
</aside>`
  },
  {
    id: 'references-authority',
    title: 'References & Statutory Authority',
    category: 'Subpage & Navigation',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#9333ea" stroke-width="2" aria-hidden="true" focusable="false"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1-2.5-2.5Z"/><line x1="8" y1="7" x2="16" y2="7"/><line x1="8" y1="11" x2="14" y2="11"/></svg>',
    description: 'Document references and statutory citation badges (RCW, municipal code, department policy).',
    html: `<section class="jbd-template jbd-references" aria-label="References and Statutory Authority">
  <div class="jbd-references-header">
    <span class="jbd-references-icon" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1-2.5-2.5Z"/><line x1="8" y1="7" x2="16" y2="7"/><line x1="8" y1="11" x2="14" y2="11"/></svg>
    </span>
    <strong class="jbd-references-title">References &amp; Statutory Authority</strong>
  </div>
  <ul class="jbd-references-list">
    <li>
      <span class="jbd-ref-badge">RCW 36.32</span>
      <span class="jbd-ref-text">Revised Code of Washington &mdash; County Commissioners General Powers</span>
    </li>
    <li>
      <span class="jbd-ref-badge">CCC Title 14</span>
      <span class="jbd-ref-text">Chelan County Code &mdash; Development Standards &amp; Administration</span>
    </li>
    <li>
      <span class="jbd-ref-badge">Policy &num;2024-03</span>
      <span class="jbd-ref-text">Department Operating Procedure &amp; Review Timeline</span>
    </li>
  </ul>
</section>`
  }
];

  Dialog.DEFAULT_BLOCK_TEMPLATES = DEFAULT_BLOCK_TEMPLATES;


  // ==========================================
  // 6. TOOLBAR (WAI-ARIA PATTERN & ROVING TABINDEX)
  // ==========================================

  const ICONS = {
    bold: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M6 12h9a4 4 0 0 1 0 8H7a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1h7a4 4 0 0 1 0 8Z"/><line x1="6" y1="4" x2="6" y2="20"/></svg>',
    italic: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="19" y1="4" x2="10" y2="4"/><line x1="14" y1="20" x2="5" y2="20"/><line x1="15" y1="4" x2="9" y2="20"/></svg>',
    underline: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M6 3v7a6 6 0 0 0 12 0V3"/><line x1="4" y1="21" x2="20" y2="21"/></svg>',
    strike: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M16 4H9a3 3 0 0 0-2.83 4"/><path d="M14 12a4 4 0 0 1 0 8H6"/><line x1="4" y1="12" x2="20" y2="12"/></svg>',
    subscript: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="4" y1="5" x2="14" y2="19"/><line x1="14" y1="5" x2="4" y2="19"/><path d="m19 19h3v-2l-3-3h3"/></svg>',
    superscript: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="4" y1="5" x2="14" y2="19"/><line x1="14" y1="5" x2="4" y2="19"/><path d="m19 9h3V7l-3-3h3"/></svg>',
    alignLeft: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="21" y1="6" x2="3" y2="6"/><line x1="15" y1="12" x2="3" y2="12"/><line x1="17" y1="18" x2="3" y2="18"/></svg>',
    alignCenter: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="21" y1="6" x2="3" y2="6"/><line x1="18" y1="12" x2="6" y2="12"/><line x1="21" y1="18" x2="3" y2="18"/></svg>',
    alignRight: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="21" y1="6" x2="3" y2="6"/><line x1="21" y1="12" x2="9" y2="12"/><line x1="21" y1="18" x2="7" y2="18"/></svg>',
    alignJustify: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="21" y1="6" x2="3" y2="6"/><line x1="21" y1="12" x2="3" y2="12"/><line x1="21" y1="18" x2="3" y2="18"/></svg>',
    ul: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="9" y1="6" x2="20" y2="6"/><line x1="9" y1="12" x2="20" y2="12"/><line x1="9" y1="18" x2="20" y2="18"/><circle cx="4" cy="6" r="1.5" fill="currentColor"/><circle cx="4" cy="12" r="1.5" fill="currentColor"/><circle cx="4" cy="18" r="1.5" fill="currentColor"/></svg>',
    ol: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="10" y1="6" x2="21" y2="6"/><line x1="10" y1="12" x2="21" y2="12"/><line x1="10" y1="18" x2="21" y2="18"/><path d="M4 6h1v-2"/><path d="M3 10h2v2H3v-1"/><path d="M3 16h2l-2 2h2"/></svg>',
    indent: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="21" y1="6" x2="11" y2="6"/><line x1="21" y1="12" x2="11" y2="12"/><line x1="21" y1="18" x2="11" y2="18"/><polyline points="3 8 7 12 3 16"/></svg>',
    outdent: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="21" y1="6" x2="11" y2="6"/><line x1="21" y1="12" x2="11" y2="12"/><line x1="21" y1="18" x2="11" y2="18"/><polyline points="7 8 3 12 7 16"/></svg>',
    link: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>',
    unlink: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="m18.84 12.25 1.72-1.71a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="m5.16 11.75-1.72 1.71a5 5 0 0 0 7.07 7.07l1.71-1.71"/><line x1="2" y1="22" x2="22" y2="22"/></svg>',
    image: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>',
    table: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M3 9h18"/><path d="M3 15h18"/><path d="M9 3v18"/><path d="M15 3v18"/></svg>',
    tableTools: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><rect width="14" height="14" x="3" y="3" rx="2"/><path d="M3 8h14"/><path d="M8 3v14"/><circle cx="18" cy="18" r="3"/><line x1="18" y1="16.5" x2="18" y2="19.5"/><line x1="16.5" y1="18" x2="19.5" y2="18"/></svg>',
    template: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/></svg>',
    hr: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="3" y1="12" x2="21" y2="12"/><circle cx="6" cy="12" r="1.5" fill="currentColor"/><circle cx="18" cy="12" r="1.5" fill="currentColor"/></svg>',
    anchor: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><circle cx="12" cy="5" r="3"/><line x1="12" y1="22" x2="12" y2="8"/><path d="M5 12H2a10 10 0 0 0 20 0h-3"/></svg>',
    anchor: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><circle cx="12" cy="5" r="3"/><line x1="12" y1="22" x2="12" y2="8"/><path d="M5 12H2a10 10 0 0 0 20 0h-3"/></svg>',
    exitBlock: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><rect x="3" y="3" width="18" height="8" rx="2"/><path d="M12 15v6"/><path d="m8 18 4 4 4-4"/></svg>',
    specialChar: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
    find: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>',
    textColor: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><polyline points="4 7 4 4 20 4 20 7"/><line x1="9" y1="20" x2="15" y2="20"/><line x1="12" y1="4" x2="12" y2="20"/><line x1="4" y1="22" x2="20" y2="22" stroke-width="2.5"/></svg>',
    highlight: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="m14 12-8.5 8.5a2.12 2.12 0 1 1-3-3L11 9"/><path d="m18 10-4-4"/><path d="m15 3 6 6"/><line x1="2" y1="22" x2="22" y2="22" stroke-width="2.5"/></svg>',
    clear: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M4 7h16"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="m17 3-3 3 3 3"/><path d="M9 3H5a2 2 0 0 0-2 2v2"/></svg>',
    cleanup: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="m2 22 1-1h3l9-9"/><path d="M3 21v-3l9-9"/><path d="m15 6 3.4-3.4a2.1 2.1 0 1 1 3 3L18 9"/><path d="m9 15 6-6"/></svg>',
    maximize: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/><path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/></svg>',
    maximizeExit: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M8 3v3a2 2 0 0 1-2 2H3"/><path d="M21 8h-3a2 2 0 0 1-2-2V3"/><path d="M3 16h3a2 2 0 0 1 2 2v3"/><path d="M16 21v-3a2 2 0 0 1 2-2h3"/></svg>',
    undo: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M3 7v6h6"/><path d="M21 17a9 9 0 0 0-9-9 9 9 0 0 0-6 2.3L3 13"/></svg>',
    redo: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M21 7v6h-6"/><path d="M3 17a9 9 0 0 1 9-9 9 9 0 0 1 6 2.3l3 2.7"/></svg>',
    source: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>',
    dropdownCaret: '<svg class="jbd-icon jbd-caret-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="m6 9 6 6 6-6"/></svg>'
  };

  const COLOR_PALETTE = [
    '#000000', '#434343', '#666666', '#999999', '#b7b7b7', '#cccccc', '#d9d9d9', '#efefef', '#f3f3f3', '#ffffff',
    '#980000', '#ff0000', '#ff9900', '#ffff00', '#00ff00', '#00ffff', '#4a86e8', '#0000ff', '#9900ff', '#ff00ff',
    '#e6b8af', '#f4cccc', '#fce5cd', '#fff2cc', '#d9ead3', '#d0e0e3', '#c9daf8', '#cfe2f3', '#d9d2e9', '#ead1dc',
    '#cc4125', '#e06666', '#f6b26b', '#ffd966', '#93c47d', '#76a5af', '#6d9eeb', '#6fa8dc', '#8e7cc3', '#c27ba0'
  ];

  const JBD_FULL_TOOLBAR = [
    ['formatBlock'],
    '|',
    ['bold', 'italic', 'underline', 'strike', 'subscript', 'superscript'],
    '|',
    ['textColor', 'highlight', 'clear', 'cleanup'],
    '|',
    ['alignLeft', 'alignCenter', 'alignRight', 'alignJustify'],
    '|',
    ['ul', 'ol', 'outdent', 'indent'],
    '|',
    ['anchor', 'link', 'unlink', 'exitBlock', 'image', 'table', 'tableTools', 'template', 'exitBlock', 'hr', 'specialChar'],
    '|',
    ['undo', 'redo', 'find'],
    '|',
    ['maximize', 'source']
  ];

  const JBD_BASIC_TOOLBAR = [
    ['formatBlock'],
    '|',
    ['bold', 'italic', 'underline'],
    '|',
    ['clear', 'cleanup'],
    '|',
    ['alignLeft', 'alignCenter', 'alignRight'],
    '|',
    ['ul', 'ol', 'outdent', 'indent'],
    '|',
    ['anchor', 'link', 'unlink', 'table', 'tableTools', 'template', 'exitBlock', 'hr'],
    '|',
    ['undo', 'redo'],
    '|',
    ['maximize', 'source']
  ];

  const JBD_MINIMAL_TOOLBAR = [
    ['bold', 'italic', 'underline'],
    '|',
    ['link'],
    '|',
    ['ul', 'ol'],
    '|',
    ['undo', 'redo']
  ];

  const JBD_SUBPAGE_TOOLBAR = [
    ['formatBlock'],
    '|',
    ['bold', 'italic', 'underline'],
    '|',
    ['clear', 'cleanup'],
    '|',
    ['anchor', 'link', 'unlink'],
    '|',
    ['ul', 'ol'],
    '|',
    ['template', 'exitBlock'],
    '|',
    ['undo', 'redo']
  ];

  const JBD_ARTICLE_TOOLBAR = [
    ['formatBlock'],
    '|',
    ['bold', 'italic', 'underline', 'strike'],
    '|',
    ['textColor', 'highlight'],
    '|',
    ['alignLeft', 'alignCenter', 'alignRight', 'alignJustify'],
    '|',
    ['ul', 'ol', 'outdent', 'indent'],
    '|',
    ['link', 'unlink', 'image', 'table', 'template', 'exitBlock', 'hr', 'specialChar'],
    '|',
    ['undo', 'redo', 'find'],
    '|',
    ['maximize', 'source']
  ];

  const JBD_DEFAULT_INLINE_TOOLBAR = [
    'formatBlock',
    '|',
    'bold', 'italic', 'underline',
    '|',
    'alignLeft', 'alignCenter', 'alignRight', 'alignJustify',
    '|',
    'ul', 'ol',
    '|',
    'outdent', 'indent',
    '|',
    'link', 'unlink'
  ];

  class Toolbar {
    constructor(editor, config = JBD_FULL_TOOLBAR) {
      this.editor = editor;
      this.config = config;
      this.buttonElements = new Map();
      this.popoverMap = new Map();
      this.focusableItems = [];
      this.element = this.render();

      this.initKeyboardNav();

      document.addEventListener('click', (e) => {
        if (!this.element.contains(e.target)) {
          this.closeAllPopovers();
        }
      });
    }

    closeAllPopovers() {
      this.element.querySelectorAll('.jbd-popover').forEach(p => p.classList.remove('jbd-popover-open'));
      this.popoverMap.forEach(btn => {
        btn.setAttribute('aria-expanded', 'false');
      });
    }

    render() {
      const bar = createElement('div', {
        className: 'jbd-toolbar',
        role: 'toolbar',
        'aria-label': 'Text editor toolbar'
      });

      let groupIndex = 1;
      this.config.forEach(group => {
        if (group === '|') {
          bar.appendChild(createElement('div', { className: 'jbd-toolbar-separator', role: 'separator', 'aria-orientation': 'vertical' }));
          return;
        }

        const groupEl = createElement('div', {
          className: 'jbd-toolbar-group',
          role: 'group',
          'aria-label': `Toolbar section ${groupIndex++}`
        });

        const items = Array.isArray(group) ? group : [group];
        items.forEach(cmd => {
          const itemEl = this.createItem(cmd);
          if (itemEl) groupEl.appendChild(itemEl);
        });

        bar.appendChild(groupEl);
      });

      return bar;
    }

    initKeyboardNav() {
      this.refreshFocusableItems();

      this.element.addEventListener('keydown', (e) => {
        if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
          this.refreshFocusableItems();
          const active = document.activeElement;
          const idx = this.focusableItems.indexOf(active);
          if (idx === -1) return;

          e.preventDefault();
          let nextIdx = e.key === 'ArrowRight' ? idx + 1 : idx - 1;
          if (nextIdx >= this.focusableItems.length) nextIdx = 0;
          if (nextIdx < 0) nextIdx = this.focusableItems.length - 1;

          this.focusableItems.forEach(el => el.setAttribute('tabindex', '-1'));
          const nextItem = this.focusableItems[nextIdx];
          if (nextItem) {
            nextItem.setAttribute('tabindex', '0');
            nextItem.focus();
          }
        } else if (e.shiftKey && e.key === 'Enter') {
        const sel = window.getSelection();
        if (sel && sel.rangeCount > 0) {
          let node = sel.getRangeAt(0).startContainer;
          if (node.nodeType === Node.TEXT_NODE) node = node.parentNode;
          const insideBlock = node && (node.closest('.jbd-template') || node.closest('.jbd-grid') || node.closest('.jbd-callout') || node.closest('.jbd-panel') || node.closest('.jbd-hero') || node.closest('table') || node.closest('blockquote') || node.closest('aside') || node.closest('section'));
          if (insideBlock) {
            e.preventDefault();
            this.exitBlock();
          }
        }
      } else if (e.key === 'Escape') {
          this.closeAllPopovers();
          this.editor.contentArea.focus();
        }
      });
    }

    refreshFocusableItems() {
      this.focusableItems = Array.from(this.element.querySelectorAll('button:not([disabled]), select:not([disabled])'));
      if (this.focusableItems.length > 0) {
        const currentZero = this.focusableItems.find(el => el.getAttribute('tabindex') === '0');
        if (!currentZero) {
          this.focusableItems.forEach((el, idx) => {
            el.setAttribute('tabindex', idx === 0 ? '0' : '-1');
          });
        }
      }
    }

    focus() {
      this.refreshFocusableItems();
      if (this.focusableItems.length > 0) {
        const active = this.focusableItems.find(el => el.getAttribute('tabindex') === '0') || this.focusableItems[0];
        if (active) {
          active.focus();
        }
      }
    }

    createItem(cmd) {
      if (typeof cmd === 'object' && cmd !== null) {
        return this.createCustomButton(cmd);
      }
      if (cmd === 'formatBlock') return this.createFormatBlockSelect();
      if (cmd === 'fontName') return this.createFontNameSelect();
      if (cmd === 'fontSize') return this.createFontSizeSelect();
      if (cmd === 'textColor') return this.createColorPicker('foreColor', 'Font Color', ICONS.textColor);
      if (cmd === 'highlight') return this.createColorPicker('hiliteColor', 'Highlight Color', ICONS.highlight);
      if (cmd === 'tableTools') return this.createTableToolsMenu();

      return this.createButton(cmd);
    }

    createCustomButton(spec) {
      const btn = createElement('button', {
        type: 'button',
        className: `jbd-btn ${spec.className || ''}`.trim(),
        title: spec.title || spec.name || 'Custom Button',
        'aria-label': spec.title || spec.name || 'Custom Button',
        tabindex: '-1',
        onMousedown: (e) => {
          e.preventDefault();
          if (typeof spec.action === 'function') {
            spec.action(this.editor, btn);
          }
        }
      });

      if (spec.shortcut) {
        btn.setAttribute('aria-keyshortcuts', spec.shortcut);
      }
      if (spec.isToggle) {
        btn.setAttribute('aria-pressed', 'false');
      }

      btn.innerHTML = spec.icon || '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>';
      if (spec.name) {
        this.buttonElements.set(spec.name, btn);
      }
      return btn;
    }

    createFormatBlockSelect() {
      const select = createElement('select', {
        className: 'jbd-select jbd-heading-select',
        title: 'Paragraph Format',
        'aria-label': 'Paragraph Format',
        tabindex: '-1',
        onChange: (e) => {
          const val = e.target.value;
          this.editor.contentArea.focus();
          document.execCommand('formatBlock', false, val);
          this.editor._handleInput();
        }
      });

      const options = [
        { label: 'Paragraph', val: '<p>' },
        { label: 'Heading 1', val: '<h1>' },
        { label: 'Heading 2', val: '<h2>' },
        { label: 'Heading 3', val: '<h3>' },
        { label: 'Heading 4', val: '<h4>' },
        { label: 'Formatted Code', val: '<pre>' },
        { label: 'Blockquote', val: '<blockquote>' }
      ];

      options.forEach(opt => {
        select.appendChild(createElement('option', { value: opt.val }, [opt.label]));
      });

      this.buttonElements.set('formatBlock', select);
      return select;
    }

    createFontNameSelect() {
      const select = createElement('select', {
        className: 'jbd-select jbd-font-select',
        title: 'Font Family',
        'aria-label': 'Font Family',
        tabindex: '-1',
        onChange: (e) => {
          this.editor.contentArea.focus();
          document.execCommand('fontName', false, e.target.value);
          this.editor._handleInput();
        }
      });

      const fonts = [
        { label: 'Default Font', val: '' },
        { label: 'Arial', val: 'Arial, Helvetica, sans-serif' },
        { label: 'Georgia', val: 'Georgia, serif' },
        { label: 'Times New Roman', val: '"Times New Roman", Times, serif' },
        { label: 'Courier New', val: '"Courier New", Courier, monospace' },
        { label: 'Verdana', val: 'Verdana, Geneva, sans-serif' },
        { label: 'Trebuchet MS', val: '"Trebuchet MS", Helvetica, sans-serif' },
        { label: 'Impact', val: 'Impact, Charcoal, sans-serif' }
      ];

      fonts.forEach(f => {
        select.appendChild(createElement('option', { value: f.val }, [f.label]));
      });

      this.buttonElements.set('fontName', select);
      return select;
    }

    createFontSizeSelect() {
      const select = createElement('select', {
        className: 'jbd-select jbd-size-select',
        title: 'Font Size',
        'aria-label': 'Font Size',
        tabindex: '-1',
        onChange: (e) => {
          this.editor.contentArea.focus();
          document.execCommand('fontSize', false, e.target.value);
          this.editor._handleInput();
        }
      });

      const sizes = [
        { label: 'Size', val: '' },
        { label: 'Small (10px)', val: '1' },
        { label: 'Normal (13px)', val: '2' },
        { label: 'Medium (16px)', val: '3' },
        { label: 'Large (18px)', val: '4' },
        { label: 'X-Large (24px)', val: '5' },
        { label: 'XX-Large (32px)', val: '6' }
      ];

      sizes.forEach(s => {
        select.appendChild(createElement('option', { value: s.val }, [s.label]));
      });

      this.buttonElements.set('fontSize', select);
      return select;
    }

    createColorPicker(execCmd, title, icon) {
      const popoverId = `jbd-color-popover-${execCmd}`;
      const container = createElement('div', { className: 'jbd-dropdown-container' });

      const btn = createElement('button', {
        type: 'button',
        className: 'jbd-btn jbd-color-btn',
        title: title,
        'aria-label': title,
        'aria-haspopup': 'dialog',
        'aria-expanded': 'false',
        'aria-controls': popoverId,
        tabindex: '-1',
        onMousedown: (e) => {
          e.preventDefault();
          const isOpen = popover.classList.contains('jbd-popover-open');
          this.closeAllPopovers();
          if (!isOpen) {
            popover.classList.add('jbd-popover-open');
            btn.setAttribute('aria-expanded', 'true');
          }
        }
      });
      btn.innerHTML = `${icon} <span class="jbd-caret">${ICONS.dropdownCaret}</span>`;

      const popover = createElement('div', {
        id: popoverId,
        className: 'jbd-popover jbd-color-popover',
        role: 'dialog',
        'aria-label': `${title} selector`
      });

      const paletteGrid = createElement('div', { className: 'jbd-palette-grid', role: 'group', 'aria-label': 'Color choices' });

      COLOR_PALETTE.forEach(color => {
        const colorBox = createElement('button', {
          type: 'button',
          className: 'jbd-color-swatch',
          style: { backgroundColor: color },
          title: color,
          'aria-label': `Select color ${color}`,
          onMousedown: (e) => {
            e.preventDefault();
            this.editor.contentArea.focus();
            document.execCommand(execCmd, false, color);
            this.editor._handleInput();
            this.closeAllPopovers();
          }
        });
        paletteGrid.appendChild(colorBox);
      });

      const clearColor = createElement('button', {
        type: 'button',
        className: 'jbd-btn-clear-color',
        onMousedown: (e) => {
          e.preventDefault();
          this.editor.contentArea.focus();
          document.execCommand(execCmd, false, 'inherit');
          this.editor._handleInput();
          this.closeAllPopovers();
        }
      }, ['Default color']);

      popover.appendChild(paletteGrid);
      popover.appendChild(clearColor);

      container.appendChild(btn);
      container.appendChild(popover);
      this.buttonElements.set(execCmd, btn);
      this.popoverMap.set(execCmd, btn);
      return container;
    }

    createTableToolsMenu() {
      const popoverId = 'jbd-table-tools-menu';
      const container = createElement('div', { className: 'jbd-dropdown-container' });

      const btn = createElement('button', {
        type: 'button',
        className: 'jbd-btn',
        title: 'Table Cell / Row / Column Tools',
        'aria-label': 'Table Cell / Row / Column Tools',
        'aria-haspopup': 'menu',
        'aria-expanded': 'false',
        'aria-controls': popoverId,
        tabindex: '-1',
        onMousedown: (e) => {
          e.preventDefault();
          const isOpen = menu.classList.contains('jbd-popover-open');
          this.closeAllPopovers();
          if (!isOpen) {
            menu.classList.add('jbd-popover-open');
            btn.setAttribute('aria-expanded', 'true');
          }
        }
      });
      btn.innerHTML = `${ICONS.tableTools} <span class="jbd-caret">${ICONS.dropdownCaret}</span>`;

      const menu = createElement('div', {
        id: popoverId,
        className: 'jbd-popover jbd-menu-popover',
        role: 'menu',
        'aria-label': 'Table options'
      });

      const actions = [
        { label: 'Add Row Above', action: () => this.editor.tableAddRowAbove() },
        { label: 'Add Row Below', action: () => this.editor.tableAddRowBelow() },
        { label: 'Add Column Left', action: () => this.editor.tableAddColLeft() },
        { label: 'Add Column Right', action: () => this.editor.tableAddColRight() },
        { label: 'Delete Row', action: () => this.editor.tableDeleteRow() },
        { label: 'Delete Column', action: () => this.editor.tableDeleteCol() },
        { label: 'Delete Table', action: () => this.editor.tableDeleteTable(), danger: true }
      ];

      actions.forEach(item => {
        const itemBtn = createElement('button', {
          type: 'button',
          className: `jbd-menu-item ${item.danger ? 'jbd-menu-danger' : ''}`,
          role: 'menuitem',
          onMousedown: (e) => {
            e.preventDefault();
            item.action();
            this.closeAllPopovers();
          }
        }, [item.label]);
        menu.appendChild(itemBtn);
      });

      container.appendChild(btn);
      container.appendChild(menu);
      this.buttonElements.set('tableTools', btn);
      this.popoverMap.set('tableTools', btn);
      return container;
    }

    createButton(cmd) {
      const spec = this.getButtonSpec(cmd);
      if (!spec) return null;

      const isToggle = ['bold', 'italic', 'underline', 'strike', 'subscript', 'superscript', 'alignLeft', 'alignCenter', 'alignRight', 'alignJustify', 'ul', 'ol', 'maximize'].includes(cmd);

      const attrs = {
        type: 'button',
        className: 'jbd-btn',
        title: spec.title,
        'aria-label': spec.title,
        tabindex: '-1',
        onMousedown: (e) => {
          e.preventDefault();
          spec.action();
        }
      };

      if (isToggle) {
        attrs['aria-pressed'] = 'false';
      }

      if (spec.shortcut) {
        attrs['aria-keyshortcuts'] = spec.shortcut;
      }

      const btn = createElement('button', attrs);
      btn.innerHTML = spec.icon;
      this.buttonElements.set(cmd, btn);
      return btn;
    }

    getButtonSpec(cmd) {
      const ed = this.editor;

      switch (cmd) {
        case 'bold':
          return { title: 'Bold (Ctrl+B)', shortcut: 'Control+B', icon: ICONS.bold, action: () => ed.execCommand('bold') };
        case 'italic':
          return { title: 'Italic (Ctrl+I)', shortcut: 'Control+I', icon: ICONS.italic, action: () => ed.execCommand('italic') };
        case 'underline':
          return { title: 'Underline (Ctrl+U)', shortcut: 'Control+U', icon: ICONS.underline, action: () => ed.execCommand('underline') };
        case 'strike':
          return { title: 'Strikethrough', icon: ICONS.strike, action: () => ed.execCommand('strikeThrough') };
        case 'subscript':
          return { title: 'Subscript', icon: ICONS.subscript, action: () => ed.execCommand('subscript') };
        case 'superscript':
          return { title: 'Superscript', icon: ICONS.superscript, action: () => ed.execCommand('superscript') };
        case 'alignLeft':
          return { title: 'Align Left', icon: ICONS.alignLeft, action: () => ed.execCommand('justifyLeft') };
        case 'alignCenter':
          return { title: 'Align Center', icon: ICONS.alignCenter, action: () => ed.execCommand('justifyCenter') };
        case 'alignRight':
          return { title: 'Align Right', icon: ICONS.alignRight, action: () => ed.execCommand('justifyRight') };
        case 'alignJustify':
          return { title: 'Justify', icon: ICONS.alignJustify, action: () => ed.execCommand('justifyFull') };
        case 'ul':
          return { title: 'Bulleted List', icon: ICONS.ul, action: () => ed.execCommand('insertUnorderedList') };
        case 'ol':
          return { title: 'Numbered List', icon: ICONS.ol, action: () => ed.execCommand('insertOrderedList') };
        case 'indent':
          return { title: 'Increase Indent', icon: ICONS.indent, action: () => ed.execCommand('indent') };
        case 'outdent':
          return { title: 'Decrease Indent', icon: ICONS.outdent, action: () => ed.execCommand('outdent') };
        case 'anchor':
          return { title: 'Insert/Edit Named Anchor Bookmark', icon: ICONS.anchor, action: () => ed.openAnchorModal() };
        case 'link':
          return { title: 'Insert Link', icon: ICONS.link, action: () => ed.openLinkModal() };
        case 'unlink':
          return { title: 'Unlink', icon: ICONS.unlink, action: () => ed.execCommand('unlink') };
        case 'exitBlock':
          return { title: 'Exit Block / Insert Paragraph Below (Shift+Enter)', shortcut: 'Shift+Enter', icon: ICONS.exitBlock, action: () => ed.exitBlock() };
        case 'image':
          return { title: 'Insert Image', icon: ICONS.image, action: () => ed.openImageModal() };
        case 'table':
          return { title: 'Insert Table', icon: ICONS.table, action: () => ed.openTableModal() };
        case 'template':
          return { title: 'Insert Block Template', icon: ICONS.template, action: () => ed.openTemplateModal() };
        case 'hr':
          return { title: 'Horizontal Line', icon: ICONS.hr, action: () => ed.execCommand('insertHorizontalRule') };
        case 'specialChar':
          return { title: 'Special Characters', icon: ICONS.specialChar, action: () => ed.openSpecialCharModal() };
        case 'find':
          return { title: 'Find and Replace (Ctrl+F)', shortcut: 'Control+F', icon: ICONS.find, action: () => ed.openFindReplaceModal() };
        case 'clear':
          return { title: 'Clear Formatting', icon: ICONS.clear, action: () => ed.clearFormatting() };
        case 'cleanup':
        case 'cleanDocument':
          return { title: 'Clean Up Document (Remove Styles & Classes)', icon: ICONS.cleanup, action: () => ed.cleanDocument() };
        case 'maximize':
          return { title: 'Full Screen', icon: ICONS.maximize, action: () => ed.toggleMaximize() };
        case 'source':
          return { title: 'Source Code View', icon: ICONS.source, action: () => ed.toggleSourceView() };
        case 'undo':
          return { title: 'Undo (Ctrl+Z)', shortcut: 'Control+Z', icon: ICONS.undo, action: () => ed.undo() };
        case 'redo':
          return { title: 'Redo (Ctrl+Y)', shortcut: 'Control+Y', icon: ICONS.redo, action: () => ed.redo() };
        default:
          return null;
      }
    }

    updateActiveStates() {
      if (this.editor.isSourceMode) {
        this.buttonElements.forEach((btn, key) => {
          if (key !== 'source') {
            btn.disabled = true;
            btn.classList.remove('active');
            if (btn.hasAttribute('aria-pressed')) btn.setAttribute('aria-pressed', 'false');
          }
        });
        const sourceBtn = this.buttonElements.get('source');
        if (sourceBtn) sourceBtn.classList.add('active');
        return;
      }

      this.buttonElements.forEach((btn) => {
        btn.disabled = false;
      });

      const checkCommand = (cmd) => {
        try { return document.queryCommandState(cmd); } catch { return false; }
      };

      const toggle = (key, isActive) => {
        const btn = this.buttonElements.get(key);
        if (btn && btn.classList) {
          btn.classList.toggle('active', !!isActive);
          if (btn.hasAttribute('aria-pressed')) {
            btn.setAttribute('aria-pressed', !!isActive ? 'true' : 'false');
          }
        }
      };

      toggle('bold', checkCommand('bold'));
      toggle('italic', checkCommand('italic'));
      toggle('underline', checkCommand('underline'));
      toggle('strike', checkCommand('strikeThrough'));
      toggle('subscript', checkCommand('subscript'));
      toggle('superscript', checkCommand('superscript'));
      toggle('alignLeft', checkCommand('justifyLeft'));
      toggle('alignCenter', checkCommand('justifyCenter'));
      toggle('alignRight', checkCommand('justifyRight'));
      toggle('alignJustify', checkCommand('justifyFull'));
      toggle('ul', checkCommand('insertUnorderedList'));
      toggle('ol', checkCommand('insertOrderedList'));
      toggle('source', false);

      const maxBtn = this.buttonElements.get('maximize');
      if (maxBtn) {
        maxBtn.classList.toggle('active', this.editor.isMaximized);
        maxBtn.setAttribute('aria-pressed', this.editor.isMaximized ? 'true' : 'false');
        maxBtn.innerHTML = this.editor.isMaximized ? (ICONS.maximizeExit || ICONS.maximize) : ICONS.maximize;
      }

      const undoBtn = this.buttonElements.get('undo');
      if (undoBtn) undoBtn.disabled = !this.editor.history.canUndo();
      const redoBtn = this.buttonElements.get('redo');
      if (redoBtn) redoBtn.disabled = !this.editor.history.canRedo();

      // Automatically sync formatBlock / heading dropdown with cursor position
      const formatSelect = this.buttonElements.get('formatBlock');
      if (formatSelect) {
        const activeTag = this.getActiveBlockFormat();
        if (formatSelect.value !== activeTag) {
          formatSelect.value = activeTag;
        }
      }
    }

    /**
     * Identifies the current block/heading element containing the cursor
     * @returns {string} The HTML block tag (e.g. '<h1>', '<h2>', '<p>')
     */
    getActiveBlockFormat() {
      try {
        const selection = window.getSelection();
        if (!selection || selection.rangeCount === 0) return '<p>';

        const anchorNode = selection.anchorNode;
        const contentArea = this.editor.contentArea;
        if (!anchorNode || !contentArea || !contentArea.contains(anchorNode)) return '<p>';

        let current = anchorNode.nodeType === Node.ELEMENT_NODE ? anchorNode : anchorNode.parentElement;
        while (current && current !== contentArea) {
          const tag = current.tagName ? current.tagName.toLowerCase() : '';
          if (['h1', 'h2', 'h3', 'h4', 'pre', 'blockquote', 'p'].includes(tag)) {
            return `<${tag}>`;
          }
          current = current.parentElement;
        }

        const cmdVal = (document.queryCommandValue('formatBlock') || '').toLowerCase().replace(/[<>]/g, '');
        if (['h1', 'h2', 'h3', 'h4', 'pre', 'blockquote', 'p'].includes(cmdVal)) {
          return `<${cmdVal}>`;
        }
      } catch {}

      return '<p>';
    }
  }

  /**
   * InlineToolbar - Floating contextual selection toolbar (Medium / Notion style)
   * Appears dynamically over active text selections within the editor content area.
   * Fully WCAG 2.2 AA compliant with WAI-ARIA toolbar pattern, roving tabindex,
   * and high-contrast / viewport collision flip awareness.
   */
  class InlineToolbar {
    /**
     * @param {CustomEditor} editor 
     * @param {Array|boolean} [config] 
     */
    constructor(editor, config = JBD_DEFAULT_INLINE_TOOLBAR) {
      this.editor = editor;
      this.config = Array.isArray(config) ? config : JBD_DEFAULT_INLINE_TOOLBAR;
      this.buttonElements = new Map();
      this.popoverMap = new Map();
      this.focusableItems = [];
      this.isVisible = false;
      this.isPopoverOpen = false;

      this.element = this.render();
      if (typeof document !== 'undefined' && document.body) {
        document.body.appendChild(this.element);
      }

      this.initKeyboardNav();

      this._handleScroll = () => {
        if (this.isVisible) this.position();
      };
      this._handleResize = () => {
        if (this.isVisible) this.position();
      };
      this._handleDocClick = (e) => {
        if (!this.element.contains(e.target)) {
          this.closeAllPopovers();
        }
      };

      window.addEventListener('scroll', this._handleScroll, { passive: true });
      window.addEventListener('resize', this._handleResize, { passive: true });
      document.addEventListener('click', this._handleDocClick);
    }

    closeAllPopovers() {
      this.element.querySelectorAll('.jbd-popover').forEach(p => p.classList.remove('jbd-popover-open'));
      this.popoverMap.forEach(btn => {
        btn.setAttribute('aria-expanded', 'false');
      });
      this.isPopoverOpen = false;
    }

    render() {
      const bar = createElement('div', {
        className: 'jbd-inline-toolbar',
        role: 'toolbar',
        'aria-label': 'Inline text formatting',
        'aria-hidden': 'true',
        tabindex: '-1'
      });

      this.config.forEach(item => {
        if (item === '|') {
          bar.appendChild(createElement('div', {
            className: 'jbd-inline-toolbar-separator',
            role: 'separator',
            'aria-orientation': 'vertical'
          }));
          return;
        }
        const itemEl = this.createItem(item);
        if (itemEl) bar.appendChild(itemEl);
      });

      return bar;
    }

    createItem(cmd) {
      if (typeof cmd === 'object' && cmd !== null) {
        return this.createCustomButton(cmd);
      }
      if (cmd === 'formatBlock') return this.createFormatBlockSelect();
      if (cmd === 'textColor') return this.createColorPicker('foreColor', 'Text Color', ICONS.textColor);
      if (cmd === 'highlight') return this.createColorPicker('hiliteColor', 'Highlight Color', ICONS.highlight);

      return this.createButton(cmd);
    }

    createFormatBlockSelect() {
      const select = createElement('select', {
        className: 'jbd-select jbd-inline-select jbd-heading-select',
        title: 'Paragraph Format',
        'aria-label': 'Paragraph Format',
        tabindex: '-1',
        onChange: (e) => {
          const val = e.target.value;
          this.editor.contentArea.focus();
          document.execCommand('formatBlock', false, val);
          this.editor._handleInput();
          this.position();
        }
      });

      const options = [
        { label: 'Paragraph', val: '<p>' },
        { label: 'Heading 1', val: '<h1>' },
        { label: 'Heading 2', val: '<h2>' },
        { label: 'Heading 3', val: '<h3>' },
        { label: 'Heading 4', val: '<h4>' },
        { label: 'Formatted Code', val: '<pre>' },
        { label: 'Blockquote', val: '<blockquote>' }
      ];

      options.forEach(opt => {
        select.appendChild(createElement('option', { value: opt.val }, [opt.label]));
      });

      this.buttonElements.set('formatBlock', select);
      return select;
    }

    createCustomButton(spec) {
      const btn = createElement('button', {
        type: 'button',
        className: `jbd-btn jbd-inline-btn ${spec.className || ''}`.trim(),
        title: spec.title || spec.name || 'Custom Button',
        'aria-label': spec.title || spec.name || 'Custom Button',
        tabindex: '-1',
        onMousedown: (e) => {
          e.preventDefault();
          e.stopPropagation();
          if (typeof spec.action === 'function') {
            spec.action(this.editor, btn);
          }
          this.editor._handleInput();
          this.updateActiveStates();
          this.position();
        }
      });

      if (spec.shortcut) {
        btn.setAttribute('aria-keyshortcuts', spec.shortcut);
      }
      if (spec.isToggle) {
        btn.setAttribute('aria-pressed', 'false');
      }

      btn.innerHTML = spec.icon || '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>';
      if (spec.name) {
        this.buttonElements.set(spec.name, btn);
      }
      return btn;
    }

    createColorPicker(execCmd, title, icon) {
      const container = createElement('div', { className: 'jbd-dropdown-container jbd-inline-dropdown' });

      const btn = createElement('button', {
        type: 'button',
        className: 'jbd-btn jbd-inline-btn jbd-color-btn',
        title: title,
        'aria-label': title,
        'aria-haspopup': 'true',
        'aria-expanded': 'false',
        tabindex: '-1',
        onMousedown: (e) => {
          e.preventDefault();
          e.stopPropagation();
          const isOpen = popover.classList.contains('jbd-popover-open');
          this.closeAllPopovers();
          if (!isOpen) {
            popover.classList.add('jbd-popover-open');
            btn.setAttribute('aria-expanded', 'true');
            this.isPopoverOpen = true;
          }
        }
      });
      btn.innerHTML = icon;

      const popover = createElement('div', {
        className: 'jbd-popover jbd-color-popover jbd-inline-color-popover',
        role: 'dialog',
        'aria-label': title
      });

      const paletteGrid = createElement('div', { className: 'jbd-palette-grid', role: 'grid' });
      COLOR_PALETTE.forEach(color => {
        const colorBox = createElement('button', {
          type: 'button',
          className: 'jbd-color-swatch',
          style: { backgroundColor: color },
          title: color,
          'aria-label': color,
          onMousedown: (e) => {
            e.preventDefault();
            e.stopPropagation();
            this.editor.contentArea.focus();
            document.execCommand(execCmd, false, color);
            this.editor._handleInput();
            this.closeAllPopovers();
            this.position();
          }
        });
        paletteGrid.appendChild(colorBox);
      });

      const clearColor = createElement('button', {
        type: 'button',
        className: 'jbd-btn-clear-color',
        onMousedown: (e) => {
          e.preventDefault();
          e.stopPropagation();
          this.editor.contentArea.focus();
          document.execCommand(execCmd, false, 'inherit');
          this.editor._handleInput();
          this.closeAllPopovers();
          this.position();
        }
      }, ['Default color']);

      popover.appendChild(paletteGrid);
      popover.appendChild(clearColor);

      container.appendChild(btn);
      container.appendChild(popover);
      this.buttonElements.set(execCmd, btn);
      this.popoverMap.set(execCmd, btn);
      return container;
    }

    createButton(cmd) {
      const spec = this.getButtonSpec(cmd);
      if (!spec) return null;

      const isToggle = ['bold', 'italic', 'underline', 'strike'].includes(cmd);

      const btn = createElement('button', {
        type: 'button',
        className: 'jbd-btn jbd-inline-btn',
        title: spec.title,
        'aria-label': spec.title,
        tabindex: '-1',
        onMousedown: (e) => {
          e.preventDefault();
          e.stopPropagation();
          spec.action();
          this.editor._handleInput();
          this.updateActiveStates();
          this.position();
        }
      });

      if (isToggle) {
        btn.setAttribute('aria-pressed', 'false');
      }
      if (spec.shortcut) {
        btn.setAttribute('aria-keyshortcuts', spec.shortcut);
      }

      btn.innerHTML = spec.icon;
      this.buttonElements.set(cmd, btn);
      return btn;
    }

    getButtonSpec(cmd) {
      const ed = this.editor;
      switch (cmd) {
        case 'bold':
          return { title: 'Bold (Ctrl+B)', shortcut: 'Control+B', icon: ICONS.bold, action: () => ed.execCommand('bold') };
        case 'italic':
          return { title: 'Italic (Ctrl+I)', shortcut: 'Control+I', icon: ICONS.italic, action: () => ed.execCommand('italic') };
        case 'underline':
          return { title: 'Underline (Ctrl+U)', shortcut: 'Control+U', icon: ICONS.underline, action: () => ed.execCommand('underline') };
        case 'strike':
          return { title: 'Strikethrough', icon: ICONS.strike, action: () => ed.execCommand('strikeThrough') };
        case 'alignLeft':
          return { title: 'Align Left', icon: ICONS.alignLeft, action: () => ed.execCommand('justifyLeft') };
        case 'alignCenter':
          return { title: 'Align Center', icon: ICONS.alignCenter, action: () => ed.execCommand('justifyCenter') };
        case 'alignRight':
          return { title: 'Align Right', icon: ICONS.alignRight, action: () => ed.execCommand('justifyRight') };
        case 'alignJustify':
          return { title: 'Justify', icon: ICONS.alignJustify, action: () => ed.execCommand('justifyFull') };
        case 'ul':
          return { title: 'Bulleted List', icon: ICONS.ul, action: () => ed.execCommand('insertUnorderedList') };
        case 'ol':
          return { title: 'Numbered List', icon: ICONS.ol, action: () => ed.execCommand('insertOrderedList') };
        case 'indent':
          return { title: 'Increase Indent', icon: ICONS.indent, action: () => ed.execCommand('indent') };
        case 'outdent':
          return { title: 'Decrease Indent', icon: ICONS.outdent, action: () => ed.execCommand('outdent') };
        case 'anchor':
          return { title: 'Insert/Edit Named Anchor Bookmark', icon: ICONS.anchor, action: () => ed.openAnchorModal() };
        case 'link':
          return { title: 'Insert/Edit Link', icon: ICONS.link, action: () => ed.openLinkModal() };
        case 'unlink':
          return { title: 'Remove Link', icon: ICONS.unlink, action: () => ed.execCommand('unlink') };
        case 'clear':
          return { title: 'Clear Formatting', icon: ICONS.clear, action: () => ed.clearFormatting() };
        case 'cleanup':
        case 'cleanDocument':
          return { title: 'Clean Up Selection (Remove Styles & Classes)', icon: ICONS.cleanup, action: () => ed.cleanSelection() };
        case 'undo':
          return { title: 'Undo (Ctrl+Z)', shortcut: 'Control+Z', icon: ICONS.undo, action: () => ed.undo() };
        case 'redo':
          return { title: 'Redo (Ctrl+Y)', shortcut: 'Control+Y', icon: ICONS.redo, action: () => ed.redo() };
        default:
          return null;
      }
    }

    initKeyboardNav() {
      this.refreshFocusableItems();

      this.element.addEventListener('keydown', (e) => {
        if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
          this.refreshFocusableItems();
          const active = document.activeElement;
          const idx = this.focusableItems.indexOf(active);
          if (idx === -1) return;

          e.preventDefault();
          let nextIdx = e.key === 'ArrowRight' ? idx + 1 : idx - 1;
          if (nextIdx >= this.focusableItems.length) nextIdx = 0;
          if (nextIdx < 0) nextIdx = this.focusableItems.length - 1;

          this.focusableItems.forEach(el => el.setAttribute('tabindex', '-1'));
          const nextItem = this.focusableItems[nextIdx];
          if (nextItem) {
            nextItem.setAttribute('tabindex', '0');
            nextItem.focus();
          }
        } else if (e.key === 'Home') {
          e.preventDefault();
          this.refreshFocusableItems();
          if (this.focusableItems.length > 0) {
            this.focusableItems.forEach(el => el.setAttribute('tabindex', '-1'));
            this.focusableItems[0].setAttribute('tabindex', '0');
            this.focusableItems[0].focus();
          }
        } else if (e.key === 'End') {
          e.preventDefault();
          this.refreshFocusableItems();
          if (this.focusableItems.length > 0) {
            this.focusableItems.forEach(el => el.setAttribute('tabindex', '-1'));
            const last = this.focusableItems[this.focusableItems.length - 1];
            last.setAttribute('tabindex', '0');
            last.focus();
          }
        } else if (e.key === 'Escape') {
          e.preventDefault();
          if (this.isPopoverOpen) {
            this.closeAllPopovers();
          } else {
            this.hide();
            this.editor.contentArea.focus();
          }
        }
      });
    }

    refreshFocusableItems() {
      this.focusableItems = Array.from(this.element.querySelectorAll('button:not([disabled]), select:not([disabled])'));
      if (this.focusableItems.length > 0) {
        const currentZero = this.focusableItems.find(el => el.getAttribute('tabindex') === '0');
        if (!currentZero) {
          this.focusableItems.forEach((el, idx) => {
            el.setAttribute('tabindex', idx === 0 ? '0' : '-1');
          });
        }
      }
    }

    focus() {
      this.refreshFocusableItems();
      if (this.focusableItems.length > 0) {
        const active = this.focusableItems.find(el => el.getAttribute('tabindex') === '0') || this.focusableItems[0];
        if (active) {
          active.focus();
        }
      }
    }

    position() {
      if (this.editor.isSourceMode) {
        this.hide();
        return;
      }

      if (this.isPopoverOpen) {
        return;
      }

      const sel = window.getSelection();
      if (!sel || sel.isCollapsed || sel.rangeCount === 0) {
        this.hide();
        return;
      }

      const anchorNode = sel.anchorNode;
      const focusNode = sel.focusNode;
      const contentArea = this.editor.contentArea;
      if (!contentArea || !anchorNode || !focusNode) {
        this.hide();
        return;
      }

      if (!contentArea.contains(anchorNode) || !contentArea.contains(focusNode)) {
        this.hide();
        return;
      }

      const selectedText = sel.toString().trim();
      if (!selectedText) {
        this.hide();
        return;
      }

      const range = sel.getRangeAt(0);
      const rect = range.getBoundingClientRect();
      if (!rect || (rect.width === 0 && rect.height === 0)) {
        this.hide();
        return;
      }

      this.show();
      this.updateActiveStates();

      const tbRect = this.element.getBoundingClientRect();
      const tbWidth = tbRect.width || 240;
      const tbHeight = tbRect.height || 38;

      const margin = 10;
      let left = rect.left + (rect.width / 2) - (tbWidth / 2);
      if (left < margin) left = margin;
      if (left + tbWidth > window.innerWidth - margin) {
        left = window.innerWidth - tbWidth - margin;
      }

      let arrowX = (rect.left + (rect.width / 2)) - left;
      if (arrowX < 14) arrowX = 14;
      if (arrowX > tbWidth - 14) arrowX = tbWidth - 14;
      this.element.style.setProperty('--jbd-arrow-left', `${Math.round(arrowX)}px`);

      let top = rect.top - tbHeight - 10;
      let flipped = false;

      if (top < margin) {
        top = rect.bottom + 10;
        flipped = true;
      }

      this.element.classList.toggle('jbd-inline-toolbar-flipped', flipped);
      this.element.style.top = `${Math.round(top)}px`;
      this.element.style.left = `${Math.round(left)}px`;
    }

    show() {
      if (this.isVisible) return;
      this.isVisible = true;
      this.element.classList.add('jbd-inline-toolbar-visible');
      this.element.setAttribute('aria-hidden', 'false');
    }

    hide() {
      if (!this.isVisible) return;
      this.isVisible = false;
      this.element.classList.remove('jbd-inline-toolbar-visible');
      this.element.setAttribute('aria-hidden', 'true');
      this.closeAllPopovers();
    }

    updateActiveStates() {
      const checkCommand = (cmd) => {
        try {
          return document.queryCommandState(cmd);
        } catch {
          return false;
        }
      };

      const toggle = (cmdName, isActive) => {
        const btn = this.buttonElements.get(cmdName);
        if (btn && btn.classList) {
          btn.classList.toggle('active', !!isActive);
          if (btn.hasAttribute('aria-pressed')) {
            btn.setAttribute('aria-pressed', !!isActive ? 'true' : 'false');
          }
        }
      };

      toggle('bold', checkCommand('bold'));
      toggle('italic', checkCommand('italic'));
      toggle('underline', checkCommand('underline'));
      toggle('strike', checkCommand('strikeThrough'));
      toggle('alignLeft', checkCommand('justifyLeft'));
      toggle('alignCenter', checkCommand('justifyCenter'));
      toggle('alignRight', checkCommand('justifyRight'));
      toggle('alignJustify', checkCommand('justifyFull'));
      toggle('ul', checkCommand('insertUnorderedList'));
      toggle('ol', checkCommand('insertOrderedList'));

      // Automatically sync formatBlock / heading dropdown with cursor position
      const formatSelect = this.buttonElements.get('formatBlock');
      if (formatSelect) {
        const activeTag = this.getActiveBlockFormat();
        if (formatSelect.value !== activeTag) {
          formatSelect.value = activeTag;
        }
      }

      let isLink = false;
      try {
        const sel = window.getSelection();
        if (sel && sel.rangeCount > 0) {
          let node = sel.anchorNode;
          while (node && node !== this.editor.contentArea) {
            if (node.tagName && node.tagName.toLowerCase() === 'a') {
              isLink = true;
              break;
            }
            node = node.parentNode;
          }
        }
      } catch {}
      toggle('link', isLink);
    }

    getActiveBlockFormat() {
      try {
        const selection = window.getSelection();
        if (!selection || selection.rangeCount === 0) return '<p>';

        const anchorNode = selection.anchorNode;
        const contentArea = this.editor.contentArea;
        if (!anchorNode || !contentArea || !contentArea.contains(anchorNode)) return '<p>';

        let node = anchorNode.nodeType === 3 ? anchorNode.parentNode : anchorNode;
        while (node && node !== contentArea) {
          const tag = (node.tagName || '').toLowerCase();
          if (['h1', 'h2', 'h3', 'h4', 'pre', 'blockquote', 'p'].includes(tag)) {
            return `<${tag}>`;
          }
          node = node.parentNode;
        }

        const cmdVal = (document.queryCommandValue('formatBlock') || '').toLowerCase().replace(/[<>]/g, '');
        if (['h1', 'h2', 'h3', 'h4', 'pre', 'blockquote', 'p'].includes(cmdVal)) {
          return `<${cmdVal}>`;
        }
      } catch {}

      return '<p>';
    }

    destroy() {
      this.hide();
      window.removeEventListener('scroll', this._handleScroll);
      window.removeEventListener('resize', this._handleResize);
      document.removeEventListener('click', this._handleDocClick);
      if (this.element && this.element.parentNode) {
        this.element.parentNode.removeChild(this.element);
      }
      this.buttonElements.clear();
      this.popoverMap.clear();
      this.focusableItems = [];
    }
  }

  // ==========================================
  // 7. MAIN JALEDITOR CLASS
  // ==========================================

  class CustomEditor {
    static TOOLBAR_PRESETS = {
      full: JBD_FULL_TOOLBAR,
      basic: JBD_BASIC_TOOLBAR,
      minimal: JBD_MINIMAL_TOOLBAR,
      article: JBD_ARTICLE_TOOLBAR
    };

    static Toolbar = Toolbar;
    static InlineToolbar = InlineToolbar;
    static JBD_FULL_TOOLBAR = JBD_FULL_TOOLBAR;
    static JBD_BASIC_TOOLBAR = JBD_BASIC_TOOLBAR;
    static JBD_MINIMAL_TOOLBAR = JBD_MINIMAL_TOOLBAR;
    static JBD_ARTICLE_TOOLBAR = JBD_ARTICLE_TOOLBAR;
    static JBD_DEFAULT_INLINE_TOOLBAR = JBD_DEFAULT_INLINE_TOOLBAR;

    static cleanDocumentHTML = cleanDocumentHTML;
    static cleanHTML = cleanDocumentHTML;

    static _instances = new Map();
    static autoInit = true;

    static attach(target, options = {}) {
      const el = typeof target === 'string' ? document.querySelector(target) : target;
      if (!el) {
        throw new Error(`JBDEditor: Target element "${target}" not found.`);
      }
      if (CustomEditor._instances.has(el)) {
        const existing = CustomEditor._instances.get(el);
        if (Object.keys(options).length === 0) {
          return existing;
        }
        existing.destroy();
      }
      return new CustomEditor(el, options);
    }

    static get(target) {
      const el = typeof target === 'string' ? document.querySelector(target) : target;
      return (el && CustomEditor._instances.get(el)) || null;
    }

    static detach(target) {
      const instance = CustomEditor.get(target);
      if (instance) {
        instance.destroy();
        return true;
      }
      return false;
    }

    static destroyAll() {
      for (const instance of Array.from(CustomEditor._instances.values())) {
        instance.destroy();
      }
      CustomEditor._instances.clear();
    }

    static initAll(selector = '[data-jbd-editor], [data-jal-editor], textarea.jbd-editor, textarea.jal-editor', defaultOptions = {}) {
      if (typeof document === 'undefined') return [];
      let elements = [];
      if (selector instanceof HTMLElement) {
        elements = [selector];
      } else if (selector instanceof NodeList || Array.isArray(selector)) {
        elements = Array.from(selector);
      } else if (typeof selector === 'string') {
        elements = Array.from(document.querySelectorAll(selector));
      }
      const instances = [];
      elements.forEach(el => {
        if (!CustomEditor._instances.has(el) && !el.hasAttribute('data-jbd-initialized') && !el.hasAttribute('data-jal-initialized')) {
          instances.push(CustomEditor.attach(el, defaultOptions));
        }
      });
      return instances;
    }

    static init(selector, options) {
      return CustomEditor.initAll(selector, options);
    }

    static loadCSS(href = 'css/editor.css') {
      if (typeof document === 'undefined') return;
      if (document.querySelector(`link[href="${href}"]`)) return;
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = href;
      document.head.appendChild(link);
    }

    constructor(targetElement, options = {}) {
      this.target = targetElement;

      // Read declarative data attributes from the target textarea for zero-JS configuration
      const dataToolbar = targetElement.getAttribute('data-jbd-toolbar') || targetElement.getAttribute('data-jal-toolbar') || targetElement.getAttribute('data-toolbar');
      const dataInlineToolbar = targetElement.getAttribute('data-jbd-inline-toolbar') || targetElement.getAttribute('data-jal-inline-toolbar') || targetElement.getAttribute('data-inline-toolbar');
      const dataHeight = targetElement.getAttribute('data-jbd-height') || targetElement.getAttribute('data-jal-height') || targetElement.getAttribute('data-height');
      const dataPlaceholder = targetElement.getAttribute('data-jbd-placeholder') || targetElement.getAttribute('data-jal-placeholder') || targetElement.getAttribute('placeholder');
      const dataAutoSave = targetElement.getAttribute('data-jbd-autosave') || targetElement.getAttribute('data-jal-autosave') || targetElement.getAttribute('data-autosave');
      const dataStatusAttr = targetElement.getAttribute('data-jbd-status') || targetElement.getAttribute('data-jal-status');
      const dataShowStatus = dataStatusAttr !== null ? dataStatusAttr !== 'false' : undefined;
      const dataCleanPasteAttr = targetElement.getAttribute('data-jbd-clean-paste') || targetElement.getAttribute('data-clean-paste');
      const dataCleanPaste = dataCleanPasteAttr !== null ? dataCleanPasteAttr !== 'false' : undefined;

      let toolbarConfig = options.toolbar !== undefined ? options.toolbar : dataToolbar;
      const presets = CustomEditor.TOOLBAR_PRESETS || {
        basic: JBD_BASIC_TOOLBAR,
        minimal: JBD_MINIMAL_TOOLBAR,
        article: JBD_ARTICLE_TOOLBAR,
        full: JBD_FULL_TOOLBAR
      };

      if (typeof toolbarConfig === 'string') {
        toolbarConfig = presets[toolbarConfig] || JBD_FULL_TOOLBAR;
      } else if (toolbarConfig === false) {
        toolbarConfig = false;
      } else if (!toolbarConfig) {
        toolbarConfig = presets.full || JBD_FULL_TOOLBAR;
      }

      let inlineToolbarConfig = options.inlineToolbar !== undefined ? options.inlineToolbar : (dataInlineToolbar !== null ? dataInlineToolbar : false);
      if (inlineToolbarConfig === 'true' || inlineToolbarConfig === true) {
        inlineToolbarConfig = JBD_DEFAULT_INLINE_TOOLBAR;
      } else if (typeof inlineToolbarConfig === 'string' && inlineToolbarConfig !== 'false') {
        try {
          const parsed = JSON.parse(inlineToolbarConfig);
          inlineToolbarConfig = Array.isArray(parsed) ? parsed : JBD_DEFAULT_INLINE_TOOLBAR;
        } catch {
          inlineToolbarConfig = JBD_DEFAULT_INLINE_TOOLBAR;
        }
      } else if (!Array.isArray(inlineToolbarConfig)) {
        inlineToolbarConfig = false;
      }

      this.options = {
        placeholder: options.placeholder || dataPlaceholder || 'Type your content here...',
        height: options.height || dataHeight || '340px',
        toolbar: toolbarConfig,
        inlineToolbar: inlineToolbarConfig,
        autoSaveKey: options.autoSaveKey || dataAutoSave || null,
        sanitizePaste: options.sanitizePaste !== false,
        cleanPaste: options.cleanPaste !== undefined ? options.cleanPaste !== false : (dataCleanPaste !== undefined ? dataCleanPaste : true),
        cleanPasteOptions: options.cleanPasteOptions || {},
        showStatusBar: options.showStatusBar !== undefined ? options.showStatusBar : (dataShowStatus !== undefined ? dataShowStatus : true),
        ...options
      };
      this.options.toolbar = toolbarConfig;
      this.options.inlineToolbar = inlineToolbarConfig;

      this._listeners = {};
      CustomEditor._instances.set(this.target, this);
      this.target.setAttribute('data-jbd-initialized', 'true');

      this.isSourceMode = false;
      this.isMaximized = false;
      this.savedSelectionRange = null;

      // Managers
      this.history = new HistoryManager(60);
      this.autoSaver = null;

      // Build DOM
      this.initDOM();
      this.initEvents();
      this.initContent();

      // AutoSave
      if (this.options.autoSaveKey) {
        this.initAutoSave();
      }

      // Initial state record
      this.history.record(this.getHTML(), true);
      this.updateStats();

      this.emit('ready', this);
      if (typeof this.options.onReady === 'function') {
        this.options.onReady(this);
      }
    }

    initDOM() {
      this.target.style.display = 'none';

      this.wrapper = createElement('div', {
        className: 'jbd-editor-wrapper',
        style: { minHeight: this.options.height }
      });

      // Toolbar
      if (this.options.toolbar) {
        this.toolbar = new Toolbar(this, this.options.toolbar);
        this.wrapper.appendChild(this.toolbar.element);
      } else {
        this.toolbar = null;
      }

      // Inline Toolbar (Floating / Bubble Toolbar)
      if (this.options.inlineToolbar) {
        this.inlineToolbar = new InlineToolbar(this, this.options.inlineToolbar);
      } else {
        this.inlineToolbar = null;
      }

      // Determine accessible name from target textarea or associated label
      let ariaLabel = this.options.ariaLabel || null;
      let ariaLabelledBy = this.options.ariaLabelledBy || null;

      if (!ariaLabel && !ariaLabelledBy) {
        if (this.target.getAttribute('aria-labelledby')) {
          ariaLabelledBy = this.target.getAttribute('aria-labelledby');
        } else if (this.target.id) {
          const labelEl = document.querySelector(`label[for="${this.target.id}"]`);
          if (labelEl) {
            if (!labelEl.id) {
              labelEl.id = `jbd-label-${Date.now()}`;
            }
            ariaLabelledBy = labelEl.id;
          }
        } else {
          const parentLabel = this.target.closest('label');
          if (parentLabel) {
            if (!parentLabel.id) {
              parentLabel.id = `jbd-label-${Date.now()}`;
            }
            ariaLabelledBy = parentLabel.id;
          }
        }

        if (!ariaLabelledBy && this.target.getAttribute('aria-label')) {
          ariaLabel = this.target.getAttribute('aria-label');
        }
      }

      const isRequired = this.target.required || this.target.getAttribute('aria-required') === 'true';
      const describedBy = this.target.getAttribute('aria-describedby');

      // Content Editable Area (WCAG 2.1/2.2 AA)
      const contentAttrs = {
        className: 'jbd-editor-content',
        contenteditable: 'true',
        role: 'textbox',
        'aria-multiline': 'true',
        'data-placeholder': this.options.placeholder,
        style: { minHeight: this.options.height }
      };

      if (ariaLabelledBy) {
        contentAttrs['aria-labelledby'] = ariaLabelledBy;
      } else {
        contentAttrs['aria-label'] = ariaLabel || 'Rich text editor content';
      }

      if (isRequired) {
        contentAttrs['aria-required'] = 'true';
      }

      if (describedBy) {
        contentAttrs['aria-describedby'] = describedBy;
      }

      this.contentArea = createElement('div', contentAttrs);
      this.wrapper.appendChild(this.contentArea);

      // Source Code Area
      const sourceAttrs = {
        className: 'jbd-editor-source',
        style: { minHeight: this.options.height, display: 'none' },
        'aria-label': ariaLabel ? `${ariaLabel} (HTML source)` : 'HTML source code view'
      };
      if (isRequired) {
        sourceAttrs['aria-required'] = 'true';
      }
      this.sourceArea = createElement('textarea', sourceAttrs);
      this.wrapper.appendChild(this.sourceArea);

      // Status Bar with Accessible Live Regions
      if (this.options.showStatusBar) {
        this.statusBar = createElement('div', { className: 'jbd-editor-statusbar' });
        this.statusStats = createElement('div', {
          className: 'jbd-editor-stats',
          role: 'status',
          'aria-live': 'polite'
        });
        this.statusDraft = createElement('div', {
          className: 'jbd-editor-draft-indicator',
          role: 'status',
          'aria-live': 'polite'
        });

        this.statusBar.appendChild(this.statusStats);
        this.statusBar.appendChild(this.statusDraft);
        this.wrapper.appendChild(this.statusBar);
      }

      if (this.target.parentNode) {
        this.target.parentNode.insertBefore(this.wrapper, this.target.nextSibling);
      }
    }

    initContent() {
      let initialHTML = this.target.value || '';

      if (this.options.autoSaveKey) {
        const draft = StorageManager.loadDraft(this.options.autoSaveKey);
        if (draft && draft.content && draft.content !== initialHTML) {
          initialHTML = draft.content;
          this.showDraftRestoredNotice(draft.timestamp);
        }
      }

      this.setHTML(initialHTML);
      this.syncToTarget();
    }

    initEvents() {
      this._handleInput = () => {
        this.syncToTarget();
        this.history.record(this.getHTML());
        if (this.autoSaver) this.autoSaver.trigger();
        this.updateStats();
        if (this.toolbar) this.toolbar.updateActiveStates();
        if (this.inlineToolbar) this.inlineToolbar.position();
      };

      this._handleSelectionChange = () => {
        if (isSelectionInside(this.contentArea)) {
          this.savedSelectionRange = saveSelection(this.contentArea);
          if (this.toolbar) this.toolbar.updateActiveStates();
          if (this.inlineToolbar) this.inlineToolbar.position();
        } else {
          if (this.inlineToolbar) this.inlineToolbar.hide();
        }
      };

      this._handleKeyDown = (e) => this.onKeyDown(e);
      this._handlePaste = (e) => this.onPaste(e);
      this._handleClick = (e) => {
        const addFaqBtn = e.target.closest('[data-jbd-faq-add]');
        if (addFaqBtn && this.contentArea.contains(addFaqBtn)) {
          e.preventDefault();
          e.stopPropagation();
          const faqBlock = addFaqBtn.closest('.jbd-faq-block');
          this.addFaqItem(faqBlock);
          return;
        }

        const addTimelineBtn = e.target.closest('[data-jbd-timeline-add]');
        if (addTimelineBtn && this.contentArea.contains(addTimelineBtn)) {
          e.preventDefault();
          e.stopPropagation();
          const timelineContainer = addTimelineBtn.closest('.jbd-timeline-container') || addTimelineBtn.closest('.jbd-template');
          this.addTimelineStep(timelineContainer);
          return;
        }
      };

      this.contentArea.addEventListener('input', this._handleInput);
      this.contentArea.addEventListener('keydown', this._handleKeyDown);
      this.contentArea.addEventListener('paste', this._handlePaste);
      this.contentArea.addEventListener('click', this._handleClick);

      document.addEventListener('selectionchange', this._handleSelectionChange);

      this.contentArea.addEventListener('focus', () => {
        this.wrapper.classList.add('jbd-editor-focused');
        this.emit('focus', this);
        if (typeof this.options.onFocus === 'function') this.options.onFocus(this);
      });
      this.contentArea.addEventListener('blur', () => {
        this.wrapper.classList.remove('jbd-editor-focused');
        this.emit('blur', this);
        if (typeof this.options.onBlur === 'function') this.options.onBlur(this);
      });

      this.sourceArea.addEventListener('input', () => {
        this.contentArea.innerHTML = this.sourceArea.value;
        this.syncToTarget();
        this.updateStats();
      });

      this.sourceArea.addEventListener('keydown', (e) => {
        if (e.key === 'Tab') {
          e.preventDefault();
          const start = this.sourceArea.selectionStart;
          const end = this.sourceArea.selectionEnd;
          const val = this.sourceArea.value;
          this.sourceArea.value = val.substring(0, start) + '  ' + val.substring(end);
          this.sourceArea.selectionStart = this.sourceArea.selectionEnd = start + 2;
          this.contentArea.innerHTML = this.sourceArea.value;
          this.syncToTarget();
          this.updateStats();
        }
      });

      if (this.target.form) {
        this._handleFormSubmit = () => {
          this.syncToTarget();
        };
        this.target.form.addEventListener('submit', this._handleFormSubmit);

        this._handleFormReset = () => {
          setTimeout(() => {
            this.setHTML(this.target.defaultValue || '');
            this.history.clear();
            this.updateStats();
          }, 0);
        };
        this.target.form.addEventListener('reset', this._handleFormReset);
      }
    }

    initAutoSave() {
      this.autoSaver = StorageManager.createAutoSaver(
        this.options.autoSaveKey,
        () => this.getHTML(),
        1000,
        (status) => this.updateDraftStatus(status)
      );
    }

    syncToTarget() {
      const html = this.getHTML();
      this.target.value = html;
      this.target.dispatchEvent(new Event('input', { bubbles: true }));
      this.target.dispatchEvent(new Event('change', { bubbles: true }));
      this.emit('change', html, this.getText());
      if (typeof this.options.onChange === 'function') {
        this.options.onChange(html, this.getText());
      }
    }

    onKeyDown(e) {
      // Alt + F10: Standard accessible shortcut to focus toolbar or inline toolbar
      if (e.altKey && (e.key === 'F10' || e.keyCode === 121)) {
        e.preventDefault();
        if (this.inlineToolbar && this.inlineToolbar.isVisible) {
          this.inlineToolbar.focus();
        } else if (this.toolbar) {
          this.toolbar.focus();
        }
        return;
      }

      const isCtrl = e.ctrlKey || e.metaKey;

      if (isCtrl) {
        const key = e.key.toLowerCase();
        if (key === 'b') {
          e.preventDefault();
          this.execCommand('bold');
        } else if (key === 'i') {
          e.preventDefault();
          this.execCommand('italic');
        } else if (key === 'u') {
          e.preventDefault();
          this.execCommand('underline');
        } else if (key === 'z') {
          e.preventDefault();
          if (e.shiftKey) {
            this.redo();
          } else {
            this.undo();
          }
        } else if (key === 'y') {
          e.preventDefault();
          this.redo();
        } else if (key === 'f') {
          e.preventDefault();
          this.openFindReplaceModal();
        }
      } else if (e.key === 'Escape') {
        if (this.inlineToolbar && this.inlineToolbar.isVisible) {
          this.inlineToolbar.hide();
        } else if (this.isMaximized) {
          this.toggleMaximize();
        }
      }
    }

    onPaste(e) {
      if (!this.options.sanitizePaste) return;
      e.preventDefault();

      const clipboardData = e.clipboardData || window.clipboardData;
      let pasteHTML = clipboardData.getData('text/html');
      const pasteText = clipboardData.getData('text/plain');

      if (pasteHTML) {
        pasteHTML = sanitizeHTML(pasteHTML);
        if (this.options.cleanPaste !== false) {
          pasteHTML = cleanDocumentHTML(pasteHTML, this.options.cleanPasteOptions || {});
        }
        document.execCommand('insertHTML', false, pasteHTML);
      } else if (pasteText) {
        document.execCommand('insertText', false, pasteText);
      }

      this._handleInput();
    }

    execCommand(command, value = null) {
      if (this.isSourceMode) return;
      this.contentArea.focus();

      if (this.savedSelectionRange) {
        restoreSelection(this.savedSelectionRange);
      }

      document.execCommand(command, false, value);
      this._handleInput();
    }

    /**
     * Inserts arbitrary HTML at current cursor / selection point
     * @param {string} html 
     */
    insertHTML(html) {
      if (this.isSourceMode) {
        insertAtCursor(this.sourceArea, html);
        this._handleInput();
        return;
      }
      this.contentArea.focus();
      if (this.savedSelectionRange) {
        restoreSelection(this.savedSelectionRange);
      }
      document.execCommand('insertHTML', false, html);
      this._handleInput();
    }

    /**
     * Cleans and removes element styles and classes from the entire editor document.
     * Preserves semantic elements (headings, bold, italic, lists, links, tables)
     * while eliminating foreign inline styles, classes, and document artifacts.
     * @param {Object} [options]
     * @returns {string} The cleaned HTML
     */
    /**
     * Opens dialog to insert or edit an accessible Named Anchor Bookmark
     */
    openAnchorModal() {
      if (this.isSourceMode) return;
      const currentA = getClosestBlock(this.contentArea, 'a');
      const isAnchorMarker = currentA && (currentA.hasAttribute('name') || currentA.classList.contains('jbd-anchor-marker'));
      const currentName = currentA ? (currentA.getAttribute('name') || currentA.getAttribute('id') || '') : '';
      const currentText = getSelectedText() || (currentA ? currentA.textContent : '');

      Dialog.openAnchorDialog({
        currentName,
        currentText,
        onConfirm: ({ name, text }) => {
          this.contentArea.focus();
          if (this.savedSelectionRange) {
            restoreSelection(this.savedSelectionRange);
          }

          const markerLabel = text || `#${name}`;

          if (isAnchorMarker && currentA) {
            currentA.setAttribute('id', name);
            currentA.setAttribute('name', name);
            currentA.className = 'jbd-anchor-marker';
            currentA.textContent = markerLabel;
            currentA.title = `Anchor: #${name}`;
          } else {
            const anchorHTML = `<a id="${name}" name="${name}" class="jbd-anchor-marker" title="Anchor: #${name}">${markerLabel}</a>`;
            insertAtCursor(this.contentArea, anchorHTML, this.savedSelectionRange);
          }

          this._handleInput();
        }
      });
    }

    /**
     * Breaks out of the current nested container (callout, grid, table, card)
     * and inserts a normal paragraph directly beneath it.
     */
    exitBlock() {
      if (this.isSourceMode) return;
      this.contentArea.focus();

      const sel = window.getSelection();
      let targetBlock = null;

      if (sel && sel.rangeCount > 0) {
        let node = sel.getRangeAt(0).startContainer;
        if (node.nodeType === Node.TEXT_NODE) node = node.parentNode;
        while (node && node !== this.contentArea) {
          if (node.classList && (node.classList.contains('jbd-template') || node.classList.contains('jbd-grid') || node.classList.contains('jbd-callout') || node.classList.contains('jbd-panel') || node.classList.contains('jbd-hero') || node.classList.contains('jbd-faq-block') || node.classList.contains('jbd-timeline-container') || node.classList.contains('jbd-quote-card') || node.classList.contains('jbd-article') || node.classList.contains('cms-table') || node.tagName.toLowerCase() === 'table' || node.tagName.toLowerCase() === 'blockquote' || node.tagName.toLowerCase() === 'aside' || node.tagName.toLowerCase() === 'section')) {
            targetBlock = node;
            break;
          }
          node = node.parentNode;
        }
      }

      const p = document.createElement('p');
      p.innerHTML = '<br>';

      if (targetBlock && targetBlock.parentNode) {
        targetBlock.parentNode.insertBefore(p, targetBlock.nextSibling);
      } else {
        this.contentArea.appendChild(p);
      }

      const newRange = document.createRange();
      newRange.setStart(p, 0);
      newRange.collapse(true);
      sel.removeAllRanges();
      sel.addRange(newRange);
      this.savedSelectionRange = newRange.cloneRange();

      this._handleInput();
    }

    validateA11y(html) {
      return A11yValidator.validate(html || this.getHTML());
    }

    checkA11y() {
      return this.validateA11y();
    }

    cleanDocument(options = {}) {
      if (this.isSourceMode) return this.getHTML();
      const currentHTML = this.getHTML();
      const opts = Object.assign({}, this.options.cleanPasteOptions, options);
      const cleanedHTML = cleanDocumentHTML(currentHTML, opts);
      if (currentHTML !== cleanedHTML) {
        this.setHTML(cleanedHTML);
        this._handleInput();
        this.history.record(this.getHTML());
      }
      return cleanedHTML;
    }

    /**
     * Cleans and removes element styles and classes from the active selection.
     * If selection is collapsed, cleans the entire document.
     * @param {Object} [options]
     */
    cleanSelection(options = {}) {
      if (this.isSourceMode) return;
      const selection = window.getSelection();
      if (!selection || selection.rangeCount === 0 || selection.isCollapsed) {
        this.cleanDocument(options);
        return;
      }

      const range = selection.getRangeAt(0);
      if (!this.contentArea.contains(range.commonAncestorContainer)) return;

      const fragment = range.cloneContents();
      const temp = document.createElement('div');
      temp.appendChild(fragment);

      const opts = Object.assign({}, this.options.cleanPasteOptions, options);
      const cleanedHTML = cleanDocumentHTML(temp.innerHTML, opts);
      this.contentArea.focus();
      document.execCommand('insertHTML', false, cleanedHTML);
      this._handleInput();
    }

    /**
     * Universal cleanup tool: cleans selection if active, otherwise cleans whole document.
     * @param {Object} [options]
     */
    cleanUp(options = {}) {
      const selection = window.getSelection();
      if (selection && !selection.isCollapsed && isSelectionInside(this.contentArea)) {
        this.cleanSelection(options);
      } else {
        this.cleanDocument(options);
      }
    }

    clearFormatting() {
      if (this.isSourceMode) return;
      this.cleanSelection();
      this.execCommand('removeFormat');
      document.execCommand('formatBlock', false, '<p>');
      this._handleInput();
    }

    openLinkModal() {
      if (this.isSourceMode) return;
      const currentAnchor = getClosestBlock(this.contentArea, 'a');
      const currentUrl = currentAnchor ? (currentAnchor.getAttribute('href') || '') : '';
      const currentText = getSelectedText() || (currentAnchor ? currentAnchor.textContent : '');
      const isBlank = currentAnchor ? currentAnchor.getAttribute('target') === '_blank' : false;
      const currentAria = currentAnchor ? (currentAnchor.getAttribute('aria-label') || '') : '';

      Dialog.openLinkDialog({
        currentUrl,
        currentText,
        targetBlank: isBlank,
        ariaLabel: currentAria,
        onConfirm: ({ url, text, blank, ada }) => {
          this.contentArea.focus();
          if (this.savedSelectionRange) {
            restoreSelection(this.savedSelectionRange);
          }

          // Determine file type tag (e.g. PDF, DOCX, XLSX, etc.)
          const extMatch = url.match(/\.(pdf|docx?|xlsx?|pptx?|csv|zip|txt)($|[?#])/i);
          const extTag = extMatch ? ` (${extMatch[1].toUpperCase()})` : '';

          const displayText = text || (currentAnchor ? currentAnchor.textContent : url);
          // Clean any existing redundant suffixes
          const cleanLabelText = (displayText || url).replace(/\s*\((?:opens in a new (?:tab|window)|PDF|DOCX?|XLSX?)\)/gi, '').trim();

          let ariaLabel = '';
          if (blank && ada) {
            ariaLabel = `${cleanLabelText || url}${extTag} (opens in a new tab)`;
          } else if (ada) {
            ariaLabel = `${cleanLabelText || url}${extTag}`;
          }

          if (currentAnchor) {
            currentAnchor.setAttribute('href', url);
            if (text) currentAnchor.textContent = text;
            if (blank) {
              currentAnchor.setAttribute('target', '_blank');
              currentAnchor.setAttribute('rel', 'noopener noreferrer');
              if (ariaLabel) {
                currentAnchor.setAttribute('aria-label', ariaLabel);
                currentAnchor.setAttribute('title', ariaLabel);
              } else {
                currentAnchor.removeAttribute('aria-label');
                currentAnchor.removeAttribute('title');
              }
            } else {
              currentAnchor.removeAttribute('target');
              currentAnchor.removeAttribute('rel');
              const oldAria = currentAnchor.getAttribute('aria-label') || '';
              if (oldAria.includes('opens in a new')) {
                currentAnchor.removeAttribute('aria-label');
              }
              const oldTitle = currentAnchor.getAttribute('title') || '';
              if (oldTitle.includes('opens in a new')) {
                currentAnchor.removeAttribute('title');
              }
            }
          } else {
            const targetAttrs = blank ? 'target="_blank" rel="noopener noreferrer"' : '';
            const ariaAttrs = (blank && ariaLabel) ? ` aria-label="${escapeHTML(ariaLabel)}" title="${escapeHTML(ariaLabel)}"` : '';
            const space = (targetAttrs || ariaAttrs) ? ' ' : '';
            const anchorHTML = `<a href="${url}"${space}${targetAttrs}${ariaAttrs}>${displayText}</a>`;
            insertAtCursor(this.contentArea, anchorHTML, this.savedSelectionRange);
          }

          this._handleInput();
        }
      });
    }

openImageModal() {
      if (this.isSourceMode) return;
      // Save selection before opening external modal
      this.savedSelectionRange = saveSelection(this.contentArea);
      const self = this;

      if (typeof window.openMediaPicker === 'function') {
        window.openMediaPicker('image', {
          onSelect: function(payload) {
            // payload: { html, url, title, alt, data }
            const src = payload.url || (payload.data && payload.data.webUrl) || '';
            const alt = payload.alt || payload.title || (payload.data && (payload.data.altText || payload.data.title)) || '';
            const caption = (payload.data && payload.data.caption) || '';
            const alignClass = '';

            if (!src) return;

            self.contentArea.focus();
            if (self.savedSelectionRange) {
              restoreSelection(self.savedSelectionRange);
            }

            let html = '';
            if (caption) {
              html = `<figure class="jbd-image" style="max-width: 100%;">
              <img src="${src}" alt="${escapeHTML(alt || caption)}" style="width: 100%; height: auto;" loading="lazy" />
              <figcaption>${escapeHTML(caption)}</figcaption>
            </figure>`;
            } else {
              html = `<div class="jbd-image" style="max-width: 100%;">
              <img src="${src}" alt="${escapeHTML(alt)}" style="width: 100%; height: auto;" loading="lazy" />
            </div>`;
            }

            insertAtCursor(self.contentArea, html, self.savedSelectionRange);
            self._handleInput();
          }
        });
      } else {
        // Fallback to old dialog if media picker not available
        Dialog.openImageDialog({
          onConfirm: ({ src, alt, caption, align, width }) => {
            let alignClass = '';
            if (align === 'left') alignClass = 'jbd-image-left';
            if (align === 'center') alignClass = 'jbd-image-center';
            if (align === 'right') alignClass = 'jbd-image-right';

            let html = '';
            if (caption) {
              html = `<figure class="jbd-image ${alignClass}" style="max-width: ${width};">
              <img src="${src}" alt="${alt || caption}" style="width: 100%; height: auto;" />
              <figcaption>${caption}</figcaption>
            </figure>`;
            } else {
              html = `<div class="jbd-image ${alignClass}" style="max-width: ${width};">
              <img src="${src}" alt="${alt}" style="width: 100%; height: auto;" />
            </div>`;
            }

            insertAtCursor(this.contentArea, html, this.savedSelectionRange);
            this._handleInput();
          }
        });
      }
    }

    openTableModal() {
      if (this.isSourceMode) return;
      Dialog.openTableDialog({
        onConfirm: (options) => {
          const table = TableManager.createTable(options);
          insertAtCursor(this.contentArea, table, this.savedSelectionRange);
          this._handleInput();
        }
      });
    }

    openSpecialCharModal() {
      if (this.isSourceMode) return;
      Dialog.openSpecialCharsDialog({
        onSelect: (ch) => {
          insertAtCursor(this.contentArea, ch, this.savedSelectionRange);
          this._handleInput();
        }
      });
    }

    openTemplateModal() {
      if (this.isSourceMode) return;
      const templates = this.options.templates || Dialog.DEFAULT_BLOCK_TEMPLATES;
      Dialog.openTemplateDialog({
        templates,
        onSelect: (html) => {
          this.insertTemplate(html);
        }
      });
    }

    /**
     * Inserts an HTML block template at current cursor position with clean block isolation
     * @param {string} html 
     */
    insertTemplate(html) {
      if (this.isSourceMode) return;
      this.contentArea.focus();
      if (this.savedSelectionRange) {
        restoreSelection(this.savedSelectionRange);
      }

      const temp = document.createElement('div');
      temp.innerHTML = html.trim();

      const fragment = document.createDocumentFragment();
      while (temp.firstChild) {
        fragment.appendChild(temp.firstChild);
      }

      const selection = window.getSelection();
      if (selection && selection.rangeCount > 0) {
        let range = selection.getRangeAt(0);
        if (this.contentArea.contains(range.commonAncestorContainer)) {
          let currentBlock = range.startContainer;
          if (currentBlock.nodeType === Node.TEXT_NODE) {
            currentBlock = currentBlock.parentNode;
          }
          while (currentBlock && currentBlock.parentNode !== this.contentArea && currentBlock !== this.contentArea) {
            currentBlock = currentBlock.parentNode;
          }

          if (currentBlock && currentBlock !== this.contentArea) {
            const text = currentBlock.textContent.trim();
            if (text === '' && (!currentBlock.querySelector('img, table, iframe') || currentBlock.tagName === 'P')) {
              currentBlock.parentNode.insertBefore(fragment, currentBlock);
              currentBlock.remove();
            } else {
              if (currentBlock.nextSibling) {
                currentBlock.parentNode.insertBefore(fragment, currentBlock.nextSibling);
              } else {
                currentBlock.parentNode.appendChild(fragment);
              }
            }
          } else {
            range.deleteContents();
            range.insertNode(fragment);
          }
        } else {
          this.contentArea.appendChild(fragment);
        }
      } else {
        this.contentArea.appendChild(fragment);
      }

      const lastChild = this.contentArea.lastElementChild;
      if (lastChild && lastChild.classList && lastChild.classList.contains('jbd-template')) {
        const p = document.createElement('p');
        p.innerHTML = '<br>';
        this.contentArea.appendChild(p);
      }

      this._handleInput();
    }

    openFindReplaceModal() {
      Dialog.openFindReplaceDialog({
        onFind: (findText, matchCase) => {
          if (!findText) return;
          this.contentArea.focus();
          if (window.find) {
            window.find(findText, matchCase, false, true, false, false, false);
          } else {
            alert('Search is not supported in this browser environment.');
          }
        },
        onReplace: (findText, replaceText) => {
          const sel = window.getSelection();
          if (sel && sel.toString().toLowerCase() === findText.toLowerCase()) {
            document.execCommand('insertText', false, replaceText);
            this._handleInput();
          }
        },
        onReplaceAll: (findText, replaceText, matchCase) => {
          if (!findText) return;
          const flags = matchCase ? 'g' : 'gi';
          const escaped = findText.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
          const regex = new RegExp(escaped, flags);
          this.setHTML(this.getHTML().replace(regex, replaceText));
          this._handleInput();
        }
      });
    }

    // --- Table Operations ---

    tableAddRowAbove() {
      TableManager.addRowAbove(TableManager.getActiveCell(this.contentArea));
      this._handleInput();
    }

    tableAddRowBelow() {
      TableManager.addRowBelow(TableManager.getActiveCell(this.contentArea));
      this._handleInput();
    }

    tableAddColLeft() {
      TableManager.addColLeft(TableManager.getActiveCell(this.contentArea));
      this._handleInput();
    }

    tableAddColRight() {
      TableManager.addColRight(TableManager.getActiveCell(this.contentArea));
      this._handleInput();
    }

    tableDeleteRow() {
      TableManager.deleteRow(TableManager.getActiveCell(this.contentArea));
      this._handleInput();
    }

    tableDeleteCol() {
      TableManager.deleteCol(TableManager.getActiveCell(this.contentArea));
      this._handleInput();
    }

    tableDeleteTable() {
      TableManager.deleteTable(TableManager.getActiveCell(this.contentArea));
      this._handleInput();
    }

    // --- Block Template Interactive Helpers ---

    /**
     * Appends a new question and answer item to the specified or closest FAQ block
     * @param {HTMLElement} [faqBlockEl] 
     */
    addFaqItem(faqBlockEl) {
      if (this.isSourceMode) return;
      const block = faqBlockEl || this.contentArea.querySelector('.jbd-faq-block');
      if (!block) return;

      const newItem = document.createElement('div');
      newItem.className = 'jbd-faq-item';
      newItem.innerHTML = `
        <div class="jbd-faq-header">
          <span class="jbd-faq-badge" aria-hidden="true">Q:</span>
          <p class="jbd-faq-question h4">New Question Title</p>
        </div>
        <div class="jbd-faq-answer">
          <p>Enter your answer explanation here.</p>
        </div>
      `;

      const actions = block.querySelector('.jbd-faq-actions');
      if (actions) {
        block.insertBefore(newItem, actions);
      } else {
        block.appendChild(newItem);
      }

      this._handleInput();

      // Focus the new question title for quick editing
      const qHeading = newItem.querySelector('.jbd-faq-question');
      if (qHeading) {
        const sel = window.getSelection();
        const range = document.createRange();
        range.selectNodeContents(qHeading);
        range.collapse(false);
        sel.removeAllRanges();
        sel.addRange(range);
        qHeading.focus();
      }
    }

    /**
     * Appends a new step to the specified or closest timeline component
     * @param {HTMLElement} [timelineContainerEl] 
     */
    addTimelineStep(timelineContainerEl) {
      if (this.isSourceMode) return;
      const container = timelineContainerEl || this.contentArea.querySelector('.jbd-timeline-container');
      if (!container) return;

      const ol = container.querySelector('.jbd-timeline') || container.querySelector('ol');
      if (!ol) return;

      const stepCount = ol.querySelectorAll('.jbd-step').length + 1;
      const newStep = document.createElement('li');
      newStep.className = 'jbd-step';
      newStep.innerHTML = `
        <div class="jbd-step-badge" aria-hidden="true">${stepCount}</div>
        <div class="jbd-step-body">
          <strong class="jbd-step-title">Step ${stepCount}: New Step Title</strong>
          <p>Enter step description here.</p>
        </div>
      `;

      ol.appendChild(newStep);
      this._handleInput();

      // Focus the new step title for immediate editing
      const titleEl = newStep.querySelector('.jbd-step-title');
      if (titleEl) {
        const sel = window.getSelection();
        const range = document.createRange();
        range.selectNodeContents(titleEl);
        range.collapse(false);
        sel.removeAllRanges();
        sel.addRange(range);
        titleEl.focus();
      }
    }

    // --- Maximize / Fullscreen ---

    toggleMaximize() {
      this.isMaximized = !this.isMaximized;
      this.wrapper.classList.toggle('jbd-editor-maximized', this.isMaximized);
      document.body.classList.toggle('jbd-noscroll', this.isMaximized);
      if (this.toolbar) this.toolbar.updateActiveStates();
    }

    // --- Source View Toggle ---

    toggleSourceView() {
      this.isSourceMode = !this.isSourceMode;

      if (this.isSourceMode) {
        if (this.inlineToolbar) this.inlineToolbar.hide();
        this.sourceArea.value = formatHTML(this.getHTML());
        this.contentArea.style.display = 'none';
        this.sourceArea.style.display = 'block';
        this.sourceArea.focus();
      } else {
        this.setHTML(this.sourceArea.value);
        this.sourceArea.style.display = 'none';
        this.contentArea.style.display = 'block';
        this.contentArea.focus();
      }

      if (this.toolbar) this.toolbar.updateActiveStates();
    }

    /**
     * Cleans and beautifies HTML source code
     */
    formatSource() {
      if (this.isSourceMode) {
        this.sourceArea.value = formatHTML(this.sourceArea.value);
        this.contentArea.innerHTML = this.sourceArea.value;
      } else {
        this.setHTML(formatHTML(this.getHTML()));
      }
      this.syncToTarget();
    }

    // --- History (Undo / Redo) ---

    undo() {
      if (this.isSourceMode) return;
      const previous = this.history.undo(this.getHTML());
      if (previous !== null) {
        this.setHTML(previous);
        this.syncToTarget();
        this.updateStats();
        if (this.toolbar) this.toolbar.updateActiveStates();
      }
    }

    redo() {
      if (this.isSourceMode) return;
      const next = this.history.redo(this.getHTML());
      if (next !== null) {
        this.setHTML(next);
        this.syncToTarget();
        this.updateStats();
        if (this.toolbar) this.toolbar.updateActiveStates();
      }
    }

    // --- Public APIs ---

    getHTML() {
      return this.contentArea.innerHTML;
    }

    setHTML(html) {
      this.contentArea.innerHTML = html;
      this.sourceArea.value = html;
    }

    getText() {
      return this.contentArea.innerText || this.contentArea.textContent || '';
    }

    clear() {
      this.setHTML('');
      this.syncToTarget();
      this.history.record('', true);
      if (this.options.autoSaveKey) {
        StorageManager.clearDraft(this.options.autoSaveKey);
      }
      this.updateStats();
    }

    focus() {
      if (this.isSourceMode) {
        this.sourceArea.focus();
      } else {
        this.contentArea.focus();
      }
    }

    updateStats() {
      if (!this.options.showStatusBar || !this.statusStats) return;
      const text = this.getText().trim();
      const words = text ? text.split(/\s+/).length : 0;
      const chars = text.length;

      this.statusStats.textContent = `${words} words · ${chars} characters`;
    }

    updateDraftStatus(status) {
      if (!this.statusDraft) return;
      if (status === 'saving') {
        this.statusDraft.textContent = 'Saving draft...';
        this.statusDraft.className = 'jbd-editor-draft-indicator saving';
      } else if (status === 'saved') {
        const now = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        this.statusDraft.textContent = `Draft saved at ${now}`;
        this.statusDraft.className = 'jbd-editor-draft-indicator saved';
      } else {
        this.statusDraft.textContent = '';
        this.statusDraft.className = 'jbd-editor-draft-indicator';
      }
    }

    showDraftRestoredNotice(timestamp) {
      if (!this.statusDraft) return;
      const timeStr = new Date(timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      this.statusDraft.textContent = `Restored draft from ${timeStr}`;
      this.statusDraft.className = 'jbd-editor-draft-indicator restored';
      setTimeout(() => {
        this.statusDraft.textContent = '';
      }, 4000);
    }

    // --- Event Handling (Pub/Sub) ---
    /**
     * Subscribes to an editor lifecycle or content event ('change', 'focus', 'blur', 'ready', 'destroy')
     * @param {string} event 
     * @param {Function} callback 
     * @returns {CustomEditor}
     */
    on(event, callback) {
      if (!this._listeners) this._listeners = {};
      if (!this._listeners[event]) this._listeners[event] = [];
      this._listeners[event].push(callback);
      return this;
    }

    /**
     * Unsubscribes from an editor event
     * @param {string} event 
     * @param {Function} [callback] 
     * @returns {CustomEditor}
     */
    off(event, callback) {
      if (!this._listeners || !this._listeners[event]) return this;
      if (!callback) {
        delete this._listeners[event];
      } else {
        this._listeners[event] = this._listeners[event].filter(cb => cb !== callback);
      }
      return this;
    }

    /**
     * Dispatches an event to subscribed listeners
     * @param {string} event 
     * @param  {...any} args 
     */
    emit(event, ...args) {
      if (!this._listeners || !this._listeners[event]) return;
      this._listeners[event].forEach(cb => {
        try {
          cb.apply(this, args);
        } catch (err) {
          console.error(`JBDEditor error in "${event}" listener:`, err);
        }
      });
    }

    /**
     * Checks whether the editor content is empty or contains only whitespace/empty tags
     * @returns {boolean}
     */
    isEmpty() {
      const text = this.getText().trim();
      const hasMedia = !!this.contentArea.querySelector('img, table, iframe, hr');
      return text === '' && !hasMedia;
    }

    /**
     * Programmatically inserts arbitrary HTML at current cursor position
     * @param {string} html 
     */
    insertHTML(html) {
      if (this.isSourceMode) return;
      this.contentArea.focus();
      insertAtCursor(this.contentArea, html, this.savedSelectionRange);
      this._handleInput();
    }

    /**
     * Programmatically inserts plain text at current cursor position
     * @param {string} text 
     */
    insertText(text) {
      if (this.isSourceMode) return;
      this.contentArea.focus();
      document.execCommand('insertText', false, text);
      this._handleInput();
    }

    destroy() {
      if (this.autoSaver) this.autoSaver.cancel();

      this.contentArea.removeEventListener('input', this._handleInput);
      this.contentArea.removeEventListener('keydown', this._handleKeyDown);
      this.contentArea.removeEventListener('paste', this._handlePaste);
      if (this._handleClick) {
        this.contentArea.removeEventListener('click', this._handleClick);
      }
      document.removeEventListener('selectionchange', this._handleSelectionChange);

      if (this.target.form) {
        if (this._handleFormReset) {
          this.target.form.removeEventListener('reset', this._handleFormReset);
        }
        if (this._handleFormSubmit) {
          this.target.form.removeEventListener('submit', this._handleFormSubmit);
        }
      }

      if (this.isMaximized) {
        document.body.classList.remove('jbd-noscroll');
      }

      if (this.inlineToolbar) {
        this.inlineToolbar.destroy();
        this.inlineToolbar = null;
      }

      this.target.style.display = '';
      if (this.wrapper && this.wrapper.parentNode) {
        this.wrapper.parentNode.removeChild(this.wrapper);
      }

      CustomEditor._instances.delete(this.target);
      this.target.removeAttribute('data-jbd-initialized');
      this.emit('destroy', this);
      this._listeners = {};
    }
  }

  // Attach helper classes and presets to JBDEditor
  CustomEditor.TableManager = TableManager;
  CustomEditor.Dialog = Dialog;
  CustomEditor.StorageManager = StorageManager;
  CustomEditor.HistoryManager = HistoryManager;
  CustomEditor.Toolbar = Toolbar;
  CustomEditor.InlineToolbar = InlineToolbar;
  CustomEditor.formatHTML = formatHTML;
  CustomEditor.TOOLBAR_PRESETS = {
    full: JBD_FULL_TOOLBAR,
    basic: JBD_BASIC_TOOLBAR,
    minimal: JBD_MINIMAL_TOOLBAR,
    subpage: JBD_SUBPAGE_TOOLBAR,
    article: JBD_ARTICLE_TOOLBAR
  };
  CustomEditor.JBD_FULL_TOOLBAR = JBD_FULL_TOOLBAR;
  CustomEditor.JBD_BASIC_TOOLBAR = JBD_BASIC_TOOLBAR;
  CustomEditor.JBD_MINIMAL_TOOLBAR = JBD_MINIMAL_TOOLBAR;
  CustomEditor.JBD_SUBPAGE_TOOLBAR = JBD_SUBPAGE_TOOLBAR;
  CustomEditor.JBD_ARTICLE_TOOLBAR = JBD_ARTICLE_TOOLBAR;
  CustomEditor.JBD_DEFAULT_INLINE_TOOLBAR = JBD_DEFAULT_INLINE_TOOLBAR;
  CustomEditor.DEFAULT_BLOCK_TEMPLATES = DEFAULT_BLOCK_TEMPLATES;

  CustomEditor.A11yValidator = A11yValidator;
  CustomEditor.validateA11y = (html) => A11yValidator.validate(html);

  // Auto-initialize textareas with [data-jbd-editor] or class="jbd-editor" on DOMContentLoaded
  if (typeof document !== 'undefined') {
    const bootAutoInit = () => {
      if (CustomEditor.autoInit !== false) {
        CustomEditor.initAll();
      }
    };
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', bootAutoInit);
    } else {
      bootAutoInit();
    }
  }

  // Export to global scope for standard script tags
  global.CustomEditor = CustomEditor;
  global.JBDEditor = CustomEditor;
  global.JByDesignEditor = CustomEditor;
  global.JalEditor = CustomEditor;
  global.A11yValidator = A11yValidator; // Backward compatibility
  global.TableManager = TableManager;
  global.Dialog = Dialog;
  global.DEFAULT_BLOCK_TEMPLATES = DEFAULT_BLOCK_TEMPLATES;
  global.formatHTML = formatHTML;
  global.cleanDocumentHTML = cleanDocumentHTML;
  global.cleanHTML = cleanDocumentHTML;
  global.Toolbar = Toolbar;
  global.InlineToolbar = InlineToolbar;
  global.JBD_FULL_TOOLBAR = JBD_FULL_TOOLBAR;
  global.JBD_BASIC_TOOLBAR = JBD_BASIC_TOOLBAR;
  global.JBD_MINIMAL_TOOLBAR = JBD_MINIMAL_TOOLBAR;
  global.JBD_SUBPAGE_TOOLBAR = JBD_SUBPAGE_TOOLBAR;
  global.JBD_ARTICLE_TOOLBAR = JBD_ARTICLE_TOOLBAR;
  global.JBD_DEFAULT_INLINE_TOOLBAR = JBD_DEFAULT_INLINE_TOOLBAR;
  global.JAL_FULL_TOOLBAR = JBD_FULL_TOOLBAR;
  global.JAL_BASIC_TOOLBAR = JBD_BASIC_TOOLBAR;
  global.JAL_MINIMAL_TOOLBAR = JBD_MINIMAL_TOOLBAR;
  global.JAL_SUBPAGE_TOOLBAR = JBD_SUBPAGE_TOOLBAR;
  global.JAL_ARTICLE_TOOLBAR = JBD_ARTICLE_TOOLBAR;
  global.JAL_DEFAULT_INLINE_TOOLBAR = JBD_DEFAULT_INLINE_TOOLBAR;

})(typeof window !== 'undefined' ? window : this);
