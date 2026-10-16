# Series 009: Development Standards, Invariants & AI Guidelines
**Location:** `.doclib/009_DEVELOPMENT_STANDARDS_AND_RULES.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Zero External Dependencies & CDN Prohibition

CMSAdmin 2.0 must run reliably in strictly isolated, air-gapped, or intranet environments without external internet connectivity.

> [!WARNING]
> NEVER introduce external CDN links into any template, stylesheet, or script:
> - ❌ `<script src="https://cdnjs.cloudflare.com/..."></script>`
> - ❌ `<link rel="stylesheet" href="https://fonts.googleapis.com/...">`
> - ❌ `<script src="https://cdn.jsdelivr.net/..."></script>`
> 
> All CSS custom properties, icon sets (inline SVG via `#svgIcon(name="...", size=N)#`), fonts, and scripts must reside locally under `/stylesheets/`, `/javascripts/`, or `/images/`.

---

## 2. Prohibition of Native Browser Dialogs

Native browser dialogs (`window.alert()`, `window.confirm()`, and `window.prompt()`) are strictly forbidden across CMSAdmin 2.0:
- They halt UI execution synchronously.
- They fail accessibility audits and screen reader requirements.
- They break touch screens and responsive web workflows.

### Approved Replacements (`javascripts/admin.js`):
1. **Informational Dialogs:**
   ```javascript
   window.adminAlert({
       title: 'Operation Notice',
       message: 'Detailed accessible explanation of the event.',
       type: 'info' // 'info', 'warning', 'danger'
   });
   ```
2. **Confirmation & Quality Gates:**
   ```javascript
   const proceed = await window.adminConfirm({
       title: 'Action Confirmation',
       message: 'Do you want to proceed with this destructive or publishing action?',
       type: 'warning',
       acceptText: 'Confirm & Proceed',
       cancelText: 'Cancel'
   });
   if (!proceed) return;
   ```
3. **Toast Notifications:**
   ```javascript
   window.showToast('Article published successfully!', 'success');
   ```

---

## 3. CFWheels Controller & View Conventions

1. **Explicit Parameter Sanitization:**
   - Always sanitize string inputs using `Trim()`, `Left(..., maxLength)`, and HTML encoding when outputting to views (`EncodeForHTML()`, `EncodeForHTMLAttribute()`, `EncodeForJavaScript()`).
2. **JSON Envelope Response Standards:**
   - All AJAX controller actions must return normalized JSON envelopes:
     ```cfml
     return renderJsonEnvelope(success = true, message = "Saved", data = { ... });
     ```
3. **CSRF Protection:**
   - Every state-mutating `POST` request must include the `X-CSRF-Token` header retrieved from `<meta name="csrf-token" content="...">`.

