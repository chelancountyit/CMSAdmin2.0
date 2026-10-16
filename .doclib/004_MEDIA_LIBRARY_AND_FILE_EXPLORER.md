# Series 004: Media Library & Workspace File Explorer
**Location:** `.doclib/004_MEDIA_LIBRARY_AND_FILE_EXPLORER.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Overview & Workspace Storage Topology

The CMSAdmin 2.0 Media Library provides file browsing, upload, document management, and image selection for editors. 

Files are partitioned by **department workspace** on disk:
```
c:\inetpub\CMSAdmin2.0\files\
├── pio\
│   ├── images\          # Photos, cover art, press images
│   └── documents\       # PDFs, official notices, ordinances
├── assessor\
│   ├── images\
│   └── documents\
├── sheriff\
│   ├── images\
│   └── documents\
└── ...
```

---

## 2. Modal Overlay & Picker Integration

The Media Picker allows content editors to select files without leaving the active editing screen.

### Triggering the Picker
Editors open the picker via the global helper:
```javascript
window.openMediaPicker(mode, options);
```
- **`mode`**: `'image'` or `'document'`.
- **`options`**:
  - `folder`: Default starting directory (`'images'` or `'documents'`).
  - `onSelect(payload)`: Custom callback receiving selected asset data.

### Protocol & Lifecycle
1. The modal `#mediaPickerModal` mounts an `<iframe>` pointing to `/media/picker`.
2. Query parameters pass the active mode, target folder, workspace, and callback name:
   ```
   /media/picker?picker=image&type=image&folder=images&ws=pio&callback=onMediaSelectedFromPicker
   ```
3. When the user selects an asset in the iframe, `javascripts/filexplorer/explorer.js` communicates with the parent window in two ways:
   - **Direct Function Invocation:** `window.parent[callback](payload)`
   - **HTML5 PostMessage Event:** `window.parent.postMessage({ type: 'CMS_MEDIA_SELECTED', ... }, '*')`
4. The parent view closes the modal, clears the iframe, restores keyboard focus to the triggering element, and applies the selected URL and metadata (alt text, caption, credit).

---

## 3. PostMessage Payload Contract

The asset payload adheres to the following interface:

```javascript
{
  "type": "CMS_MEDIA_SELECTED",
  "url": "/files/pio/images/press-briefing.jpg",
  "alt": "Commissioners meeting regarding 2027 budget",
  "title": "Press Briefing Cover Photo",
  "caption": "Commissioners discussing the annual road levy",
  "credit": "Chelan County Sheriff's Office",
  "data": {
    "webUrl": "/files/pio/images/press-briefing.jpg",
    "name": "press-briefing.jpg",
    "size": 245100,
    "extension": "jpg"
  }
}
```

---

## 4. Security & Isolation Controls

1. **Path Traversal Prevention:**
   - All folder navigations inside `Media.cfc` validate directory paths against the workspace root to prevent `../` traversal outside `/files/{workspace}/`.
2. **Allowed Extensions:**
   - Images: `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.svg`.
   - Documents: `.pdf`, `.docx`, `.xlsx`, `.pptx`, `.txt`, `.csv`.
   - Executable extensions (`.exe`, `.cfm`, `.cfc`, `.jsp`, `.asp`, `.bat`, `.ps1`) are strictly rejected on upload.

