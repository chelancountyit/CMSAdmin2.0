/**
 * Dialog - Fully ADA / WCAG 2.1/2.2 AA Compliant Modal Dialog System for JBDEditor
 */
import { createElement, escapeHTML } from './utils.js';

export class Dialog {
  /**
   * Shows an accessible modal dialog
   * @param {Object} options
   * @param {string} options.title
   * @param {HTMLElement | string} options.body
   * @param {Array<{ label: string, className?: string, onClick?: (dialog: Dialog, overlay: HTMLElement) => void }>} [options.buttons]
   * @param {() => void} [options.onClose]
   * @returns {HTMLElement} overlay element
   */
  static show({ title, body, buttons = [], onClose = null, className = '' }) {
    Dialog.closeAll();

    // Preserve previously focused element to return focus on modal close
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

    // Keyboard Trap and Escape key handling for WCAG compliance
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

    // Close on overlay backdrop click
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
        // Prefer first input over close button if available
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

    const escapeAttr = (str) => String(str || '').replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

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
        <input type="text" id="jbd-link-text" class="jbd-input" value="${escapeAttr(currentText)}" placeholder="Link text (optional)" />
      </div>

      <div class="jbd-form-group">
        <label for="jbd-link-url" id="jbd-link-url-label">URL Destination <span aria-hidden="true">*</span></label>
        <input type="text" id="jbd-link-url" class="jbd-input" value="${escapeAttr(cleanUrl ? (initialType === 'https' ? (currentUrl || 'https://') : cleanUrl) : (initialType === 'https' ? 'https://' : ''))}" placeholder="https://example.com or document.pdf" required aria-required="true" />
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

    setLinkType(initialType, false);

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
  static openImageDialog({ onConfirm }) {
    const form = createElement('div', { className: 'jbd-form-grid' });

    form.innerHTML = `
      <div class="jbd-form-group">
        <label for="jbd-image-url">Image Web URL <span aria-hidden="true">*</span></label>
        <input type="url" id="jbd-image-url" class="jbd-input" placeholder="https://example.com/photo.jpg" required aria-required="true" />
      </div>
      <div class="jbd-form-group">
        <label for="jbd-image-alt">Alternative Text (Alt Description) <span aria-hidden="true">*</span></label>
        <input type="text" id="jbd-image-alt" class="jbd-input" placeholder="Brief description for screen readers" aria-required="true" />
      </div>
      <div class="jbd-form-group">
        <label for="jbd-image-caption">Caption (optional)</label>
        <input type="text" id="jbd-image-caption" class="jbd-input" placeholder="Visible photo caption..." />
      </div>
      <div class="jbd-form-row">
        <div class="jbd-form-group">
          <label for="jbd-image-align">Alignment</label>
          <select id="jbd-image-align" class="jbd-dialog-select">
            <option value="none">Default (Block)</option>
            <option value="left">Left (Float)</option>
            <option value="center">Center</option>
            <option value="right">Right (Float)</option>
          </select>
        </div>
        <div class="jbd-form-group">
          <label for="jbd-image-width">Max Width</label>
          <input type="text" id="jbd-image-width" class="jbd-input" value="100%" placeholder="100% or 400px" />
        </div>
      </div>
    `;

    Dialog.show({
      title: 'Insert Image',
      body: form,
      buttons: [
        { label: 'Cancel', className: 'jbd-btn-secondary' },
        {
          label: 'Insert Image',
          className: 'jbd-btn-primary',
          onClick: (d, overlay) => {
            const urlInput = overlay.querySelector('#jbd-image-url');
            const alt = overlay.querySelector('#jbd-image-alt').value.trim();
            const caption = overlay.querySelector('#jbd-image-caption').value.trim();
            const align = overlay.querySelector('#jbd-image-align').value;
            const width = overlay.querySelector('#jbd-image-width').value.trim() || '100%';

            const submit = (src) => {
              if (src) {
                onConfirm({ src, alt: alt || caption || 'Image', caption, align, width });
              }
              d.close(overlay);
            };

            if (urlInput.value.trim()) {
              submit(urlInput.value.trim());
            } else {
              if (window.adminAlert) {
                window.adminAlert({ title: 'Image URL Required', message: 'Please provide an image URL.', type: 'warning' });
              } else {
                alert('Please provide an image URL.');
              }
            }
          }
        }
      ]
    });
  }

  /**
   * Accessible Table insertion dialog with WCAG scope attributes
   */
  static openTableDialog({ onConfirm }) {
    const form = createElement('div', { className: 'jbd-form-grid' });

    form.innerHTML = `
      <div class="jbd-form-row">
        <div class="jbd-form-group">
          <label for="jbd-table-rows">Number of Rows</label>
          <input type="number" id="jbd-table-rows" class="jbd-input" min="1" max="50" value="3" aria-required="true" />
        </div>
        <div class="jbd-form-group">
          <label for="jbd-table-cols">Number of Columns</label>
          <input type="number" id="jbd-table-cols" class="jbd-input" min="1" max="20" value="3" aria-required="true" />
        </div>
      </div>
      <div class="jbd-form-group">
        <label for="jbd-table-header-type">Header Type (WCAG scope attribute)</label>
        <select id="jbd-table-header-type" class="jbd-dialog-select">
          <option value="row" selected>First Row (Column Headers &lt;th scope="col"&gt;)</option>
          <option value="col">First Column (Row Headers &lt;th scope="row"&gt;)</option>
          <option value="both">Both (Row and Column Headers)</option>
          <option value="none">No Headers (Standard Data Cells)</option>
        </select>
      </div>
      <div class="jbd-form-group">
        <label for="jbd-table-caption">Table Caption (Accessibility Summary)</label>
        <input type="text" id="jbd-table-caption" class="jbd-input" placeholder="e.g. Fee Schedule or Department Contact Directory" />
        <small style="color:var(--jbd-color-muted, #64748b); font-size:11.5px; margin-top:4px; display:block;">
          Recommended for WCAG 2.1 AA compliance to summarize table contents for screen readers.
        </small>
      </div>
      <div class="jbd-form-group-checkbox">
        <label for="jbd-table-border">
          <input type="checkbox" id="jbd-table-border" checked />
          Add Styled Borders
        </label>
      </div>
    `;

    Dialog.show({
      title: 'Insert Table',
      body: form,
      buttons: [
        { label: 'Cancel', className: 'jbd-btn-secondary' },
        {
          label: 'Create Table',
          className: 'jbd-btn-primary',
          onClick: (d, overlay) => {
            const rows = Math.max(1, Math.min(50, parseInt(overlay.querySelector('#jbd-table-rows').value, 10) || 3));
            const cols = Math.max(1, Math.min(20, parseInt(overlay.querySelector('#jbd-table-cols').value, 10) || 3));
            const headerType = overlay.querySelector('#jbd-table-header-type').value;
            const captionInput = overlay.querySelector('#jbd-table-caption');
            const caption = captionInput ? captionInput.value.trim() : '';
            const bordered = overlay.querySelector('#jbd-table-border').checked;
            const hasHeader = headerType !== 'none';

            d.close(overlay);
            onConfirm({ rows, cols, headerType, hasHeader, caption, bordered });
          }
        }
      ]
    });
  }

  /**
   * Accessible Special characters / symbols modal
   */
  static openSpecialCharsDialog({ onSelect }) {
    const charList = [
      { char: '©', name: 'Copyright symbol' },
      { char: '®', name: 'Registered trademark symbol' },
      { char: '™', name: 'Trademark symbol' },
      { char: '§', name: 'Section symbol' },
      { char: '¶', name: 'Pilcrow paragraph symbol' },
      { char: '•', name: 'Bullet symbol' },
      { char: '–', name: 'En dash' },
      { char: '—', name: 'Em dash' },
      { char: '…', name: 'Ellipsis' },
      { char: '‰', name: 'Per mille symbol' },
      { char: '€', name: 'Euro currency' },
      { char: '$', name: 'Dollar currency' },
      { char: '£', name: 'Pound currency' },
      { char: '¥', name: 'Yen currency' },
      { char: '₹', name: 'Indian Rupee currency' },
      { char: '¢', name: 'Cent currency' },
      { char: '¤', name: 'Currency symbol' },
      { char: '±', name: 'Plus-minus symbol' },
      { char: '×', name: 'Multiplication sign' },
      { char: '÷', name: 'Division sign' },
      { char: '≠', name: 'Not equal sign' },
      { char: '≤', name: 'Less-than or equal sign' },
      { char: '≥', name: 'Greater-than or equal sign' },
      { char: '≈', name: 'Almost equal sign' },
      { char: '∞', name: 'Infinity symbol' },
      { char: '√', name: 'Square root symbol' },
      { char: 'π', name: 'Pi symbol' },
      { char: 'µ', name: 'Micro sign' },
      { char: '°', name: 'Degree symbol' },
      { char: '¬', name: 'Logical negation' },
      { char: '←', name: 'Left arrow' },
      { char: '→', name: 'Right arrow' },
      { char: '↑', name: 'Up arrow' },
      { char: '↓', name: 'Down arrow' },
      { char: '↔', name: 'Left-right arrow' },
      { char: '↵', name: 'Return symbol' },
      { char: '✓', name: 'Checkmark symbol' },
      { char: '★', name: 'Black star' },
      { char: '☆', name: 'White star' },
      { char: '½', name: 'One half fraction' }
    ];

    const grid = createElement('div', { className: 'jbd-chars-grid', role: 'group', 'aria-label': 'Special characters' });
    charList.forEach(item => {
      const btn = createElement('button', {
        type: 'button',
        className: 'jbd-char-btn',
        title: item.name,
        'aria-label': item.name,
        onClick: () => {
          onSelect(item.char);
          Dialog.closeAll();
        }
      }, [item.char]);
      grid.appendChild(btn);
    });

    Dialog.show({
      title: 'Special Characters & Symbols',
      body: grid,
      buttons: [{ label: 'Close', className: 'jbd-btn-secondary' }]
    });
  }

  /**
   * Accessible Find & Replace dialog
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

    // Collect distinct categories
    const categories = ['All', ...new Set(list.map(t => t.category || 'General'))];

    const container = createElement('div', { className: 'jbd-template-dialog-content' });

    // Header filter row: search input + category pills
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

    // Browser grid (Left: template list, Right: preview pane)
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

      // If current selectedTemplate is not in filtered, select the first filtered item
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

        const iconHtml = tmpl.icon || '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#6366f1" stroke-width="2" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="2"/></svg>';
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

export const DEFAULT_BLOCK_TEMPLATES = [
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
  },
  {
    id: 'cta-card',
    title: 'Call to Action (CTA) Card',
    category: 'Call to Action',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#0b2545" stroke-width="2" aria-hidden="true" focusable="false"><rect x="3" y="3" width="18" height="18" rx="3"/><path d="M8 12h8"/><path d="m13 9 3 3-3 3"/></svg>',
    description: 'High-conversion action card with category badge, heading, description, and primary action button.',
    html: `<aside class="jbd-template jbd-cta-card" aria-label="Action: Online Service">
  <div class="jbd-cta-card-header">
    <span class="jbd-cta-badge" aria-hidden="true">ONLINE SERVICE</span>
    <p class="jbd-cta-title h4">Apply for Department Permits &amp; Licenses</p>
  </div>
  <p class="jbd-cta-desc">Submit your applications, upload engineering documents, and track review status securely through our citizen portal.</p>
  <div class="jbd-cta-card-footer">
    <a href="#portal" class="jbd-btn jbd-btn-primary jbd-cta-btn" aria-label="Apply online for Department Permits and Licenses">
      <span>Begin Online Application</span>
      <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
    </a>
  </div>
</aside>`
  },
  {
    id: 'cta-grid',
    title: 'Call to Action Grid (2-Column)',
    category: 'Call to Action',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#0f766e" stroke-width="2" aria-hidden="true" focusable="false"><rect x="2" y="3" width="9" height="18" rx="2"/><rect x="13" y="3" width="9" height="18" rx="2"/><path d="M5 14h3"/><path d="M16 14h3"/></svg>',
    description: 'Side-by-side action cards for presenting primary citizen services (payments, permits, requests).',
    html: `<section class="jbd-template jbd-cta-grid" aria-label="Popular online actions">
  <article class="jbd-cta-card">
    <div class="jbd-cta-card-header">
      <span class="jbd-cta-badge jbd-cta-badge-teal" aria-hidden="true">PAYMENT</span>
      <p class="jbd-cta-title h4">Pay Taxes &amp; Fees Online</p>
    </div>
    <p class="jbd-cta-desc">Pay real property taxes, assessment fees, and administrative charges with e-check or card.</p>
    <div class="jbd-cta-card-footer">
      <a href="#pay" class="jbd-btn jbd-btn-primary jbd-cta-btn" aria-label="Make an online payment for taxes and fees">
        <span>Pay Online Now</span>
        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
      </a>
    </div>
  </article>
  <article class="jbd-cta-card">
    <div class="jbd-cta-card-header">
      <span class="jbd-cta-badge jbd-cta-badge-blue" aria-hidden="true">PUBLIC RECORDS</span>
      <p class="jbd-cta-title h4">Submit Public Records Request</p>
    </div>
    <p class="jbd-cta-desc">Request county government records under RCW 42.56 with our automated disclosure portal.</p>
    <div class="jbd-cta-card-footer">
      <a href="#records" class="jbd-btn jbd-btn-primary jbd-cta-btn" aria-label="Submit a public records disclosure request">
        <span>Submit Request</span>
        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
      </a>
    </div>
  </article>
</section>`
  },
  {
    id: 'cta-banner',
    title: 'Call to Action Banner',
    category: 'Call to Action',
    icon: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#2563eb" stroke-width="2" aria-hidden="true" focusable="false"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="6" y1="12" x2="14" y2="12"/><path d="m12 9 3 3-3 3"/><rect x="15" y="9" width="3" height="6" rx="1"/></svg>',
    description: 'Full-width, high-contrast action banner with headline, secondary guidance, and high-visibility button.',
    html: `<aside class="jbd-template jbd-cta-banner" aria-label="Action required">
  <div class="jbd-cta-banner-content">
    <span class="jbd-cta-banner-badge" aria-hidden="true">NEXT STEP</span>
    <p class="jbd-cta-banner-title h4">Need assistance completing your submission?</p>
    <p class="jbd-cta-banner-lead">Our department specialists are available Monday through Friday from 8:00 AM to 5:00 PM to help you navigate requirements.</p>
  </div>
  <div class="jbd-cta-banner-action">
    <a href="#contact" class="jbd-btn jbd-cta-banner-btn" aria-label="Contact our department specialists for assistance">
      <span>Contact Office Specialist</span>
      <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
    </a>
  </div>
</aside>`
  }
];

Dialog.DEFAULT_BLOCK_TEMPLATES = DEFAULT_BLOCK_TEMPLATES;


