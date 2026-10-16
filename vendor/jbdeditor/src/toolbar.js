/**
 * Toolbar - Fully ADA / WCAG 2.1/2.2 AA Compliant Toolbar for JBDEditor
 * Implements WAI-ARIA Toolbar Pattern with Roving Tabindex and Arrow Key Navigation
 */
import { createElement } from './utils.js';

export const ICONS = {
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
  unlink: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="m18.84 12.25 1.72-1.71a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="m5.16 11.75-1.72 1.71a5 5 0 0 0 7.07 7.07l1.71-1.71"/><line x1="2" y1="2" x2="22" y2="22"/></svg>',
  image: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>',
  table: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M3 9h18"/><path d="M3 15h18"/><path d="M9 3v18"/><path d="M15 3v18"/></svg>',
  tableTools: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><rect width="14" height="14" x="3" y="3" rx="2"/><path d="M3 8h14"/><path d="M8 3v14"/><circle cx="18" cy="18" r="3"/><line x1="18" y1="16.5" x2="18" y2="19.5"/><line x1="16.5" y1="18" x2="19.5" y2="18"/></svg>',
  template: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/></svg>',
  hr: '<svg class="jbd-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><line x1="3" y1="12" x2="21" y2="12"/><circle cx="6" cy="12" r="1.5" fill="currentColor"/><circle cx="18" cy="12" r="1.5" fill="currentColor"/></svg>',
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

export const COLOR_PALETTE = [
  '#000000', '#434343', '#666666', '#999999', '#b7b7b7', '#cccccc', '#d9d9d9', '#efefef', '#f3f3f3', '#ffffff',
  '#980000', '#ff0000', '#ff9900', '#ffff00', '#00ff00', '#00ffff', '#4a86e8', '#0000ff', '#9900ff', '#ff00ff',
  '#e6b8af', '#f4cccc', '#fce5cd', '#fff2cc', '#d9ead3', '#d0e0e3', '#c9daf8', '#cfe2f3', '#d9d2e9', '#ead1dc',
  '#cc4125', '#e06666', '#f6b26b', '#ffd966', '#93c47d', '#76a5af', '#6d9eeb', '#6fa8dc', '#8e7cc3', '#c27ba0'
];


export const JBD_FULL_TOOLBAR = [
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

export const JBD_BASIC_TOOLBAR = [
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

export const JBD_MINIMAL_TOOLBAR = [
  ['bold', 'italic', 'underline'],
  '|',
  ['link'],
  '|',
  ['ul', 'ol'],
  '|',
  ['undo', 'redo']
];

export const JBD_SUBPAGE_TOOLBAR = [
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
  ['table', 'tableTools', 'template', 'exitBlock'],
  '|',
  ['undo', 'redo']
];

export const JBD_ARTICLE_TOOLBAR = [
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
  ['link', 'unlink', 'image', 'table', 'tableTools', 'template', 'exitBlock', 'hr', 'specialChar'],
  '|',
  ['undo', 'redo', 'find'],
  '|',
  ['maximize', 'source']
];

export const JBD_DEFAULT_INLINE_TOOLBAR = [
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

// Backward-compatibility aliases
export const JAL_FULL_TOOLBAR = JBD_FULL_TOOLBAR;
export const JAL_BASIC_TOOLBAR = JBD_BASIC_TOOLBAR;
export const JAL_MINIMAL_TOOLBAR = JBD_MINIMAL_TOOLBAR;
export const JAL_ARTICLE_TOOLBAR = JBD_ARTICLE_TOOLBAR;
export const JAL_SUBPAGE_TOOLBAR = JBD_SUBPAGE_TOOLBAR;
export const JAL_DEFAULT_INLINE_TOOLBAR = JBD_DEFAULT_INLINE_TOOLBAR;



export class Toolbar {
  /**
   * @param {import('./editor.js').CustomEditor} editor 
   * @param {Array} config 
   */
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

  /**
   * Implements WAI-ARIA arrow key navigation across toolbar controls
   */
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
      } else if (e.key === 'Escape') {
        this.closeAllPopovers();
        this.editor.contentArea.focus();
      }
    });
  }

  /**
   * Updates roving tabindex list of focusable elements
   */
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

  /**
   * Focuses the current active control in the toolbar (or the first control)
   */
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
      { label: 'Arial', val: 'Arial, sans-serif' },
      { label: 'Courier New', val: 'Courier New, monospace' },
      { label: 'Georgia', val: 'Georgia, serif' },
      { label: 'Impact', val: 'Impact, sans-serif' },
      { label: 'Tahoma', val: 'Tahoma, sans-serif' },
      { label: 'Times New Roman', val: 'Times New Roman, serif' },
      { label: 'Trebuchet MS', val: 'Trebuchet MS, sans-serif' },
      { label: 'Verdana', val: 'Verdana, sans-serif' }
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

    //const isToggle = ['bold', 'italic', 'underline', 'strike', 'subscript', 'superscript', 'alignLeft', 'alignCenter', 'alignRight', 'alignJustify', 'ul', 'ol', 'maximize'].includes(cmd);
    const isToggle = ['bold', 'italic', 'underline', 'alignLeft', 'alignCenter', 'alignRight', 'alignJustify', 'ul', 'ol', 'maximize'].includes(cmd);

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
      case 'link':
        return { title: 'Insert/Edit Link', icon: ICONS.link, action: () => ed.openLinkModal() };
      case 'unlink':
        return { title: 'Remove Link', icon: ICONS.unlink, action: () => ed.execCommand('unlink') };
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
      case 'clear':
        return { title: 'Clear Formatting', icon: ICONS.clear, action: () => ed.clearFormatting() };
      case 'anchor':
        return { title: 'Insert/Edit Named Anchor Bookmark', icon: ICONS.anchor, action: () => ed.openAnchorModal() };
      case 'exitBlock':
        return { title: 'Exit Block / Insert Paragraph Below (Shift+Enter)', shortcut: 'Shift+Enter', icon: ICONS.exitBlock, action: () => ed.exitBlock() };
      case 'cleanup':
      case 'cleanDocument':
        return { title: 'Clean Up Document (Remove Styles & Classes)', icon: ICONS.cleanup, action: () => ed.cleanDocument() };
      case 'find':
        return { title: 'Find & Replace (Ctrl+F)', shortcut: 'Control+F', icon: ICONS.find, action: () => ed.openFindReplaceModal() };
      case 'maximize':
        return { title: 'Maximize Fullscreen (Esc to exit)', icon: ICONS.maximize, action: () => ed.toggleMaximize() };
      case 'undo':
        return { title: 'Undo (Ctrl+Z)', shortcut: 'Control+Z', icon: ICONS.undo, action: () => ed.undo() };
      case 'redo':
        return { title: 'Redo (Ctrl+Y)', shortcut: 'Control+Y', icon: ICONS.redo, action: () => ed.redo() };
      case 'source':
        return { title: 'Source Code HTML', icon: ICONS.source, action: () => ed.toggleSourceView() };
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
export class InlineToolbar {
  /**
   * @param {import('./editor.js').CustomEditor} editor 
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
      case 'exitBlock':
        return { title: 'Exit Block / Insert Paragraph Below', icon: ICONS.exitBlock, action: () => ed.exitBlock() };
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
