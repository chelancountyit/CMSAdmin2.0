# Series 004: Media Library & Workspace File Explorer
**Location:** `.doclib/004_MEDIA_LIBRARY_AND_FILE_EXPLORER.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Overview & Workspace Storage Topology

The CMSAdmin 2.0 Media Library provides file browsing, upload, document management, and image selection for editors. 

The authoritative main repository for documents and workspace assets is permanently assigned to:
```
c:\inetpub\chelan-county\files\
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

In CMSAdmin 2.0, `c:\inetpub\CMSAdmin2.0\files\` is an NTFS directory junction linking directly to `c:\inetpub\chelan-county\files\`, enabling IIS to serve `/files/...` seamlessly from the county repository.

Additionally, a county-wide shared photo repository (`shared images`) is located **outside** all workspace folders at the files root via an NTFS directory junction pointing to `c:\inetpub\chelan-county\images\picjumbo`:
```
c:\inetpub\chelan-county\files\shared images\  ->  c:\inetpub\chelan-county\images\picjumbo
c:\inetpub\CMSAdmin2.0\images\picjumbo\        ->  c:\inetpub\chelan-county\images\picjumbo
```
- Workspace folders only host department-specific folders (`images`, `documents`).
- `shared images` resides at the root level outside any workspace folder and is rendered as its own dedicated library in the explorer tree.
- Web URLs resolve to `/images/picjumbo/<filename>` when selected.
- The `shared images` directory is permanently strictly **Read-Only** for all users across the entire system.

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

---

## 5. Read-Only Shared Images Governance

To share county-wide stock photography without risking file deletion or modification:
1. **Physical Repository:** `c:\inetpub\chelan-county\images\picjumbo`
2. **Auto-Provisioning (`ensureSharedImagesJunction`):**
   - Both `api/Files.cfc` and `app/controllers/Media.cfc` automatically inspect the workspace root upon folder listing.
   - If `shared images` junction does not exist, an NTFS directory junction is provisioned at runtime via `mklink /J`.
3. **Four-Layer Enforcement:**
   - **UI Layer:** The "New Folder" / "Upload" actions are disabled when navigating into `shared images`. Folder deletion button is hidden. `READ-ONLY` and `RO` badges visually clarify immutable access.
   - **Files API (`api/Files.cfc`):** Both `createFolder()` and `deleteFolder()` explicitly check if the path resolves to or inside `shared images` and abort with an informative error message.
   - **Media Controller (`app/controllers/Media.cfc`):** `processUpload()` and `updateMeta()` block any upload or metadata modification targeted at `shared images`.
   - **Git Isolation:** `.gitignore` explicitly ignores `/files/*/shared images/`, `/files/shared images/`, and `/images/picjumbo/` to prevent external media files from entering version control.


