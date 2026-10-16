# Series 005: Articles & Public Information Module
**Location:** `.doclib/005_ARTICLES_AND_PUBLIC_INFORMATION.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Overview & Scope

The **Articles & Posts** module is the county's primary news, editorial announcement, and public information management system. It supports multi-department authoring, category taxonomies, tag indexing, accessible cover imagery, rich story layouts, and SEO open graph metadata.

- **Primary Controller:** [`app/controllers/Articles.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Articles.cfc)
- **Primary Views:**
  - Listing: [`app/views/articles/index.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/articles/index.cfm)
  - Editor (New/Edit): [`app/views/articles/edit.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/articles/edit.cfm)
  - Categories: [`app/views/articles/categories.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/articles/categories.cfm)
  - Tags: [`app/views/articles/tags.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/articles/tags.cfm)

---

## 2. Relational Database Schema

All articles are persisted in the `ChelanCountyWebsite` SQL Server database.

```sql
CREATE TABLE dbo.articles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    slug NVARCHAR(255) NOT NULL,
    summary NVARCHAR(1000) NULL,
    content_html NVARCHAR(MAX) NOT NULL,
    category_id INT NULL,
    tags NVARCHAR(500) NULL,
    featured_image NVARCHAR(1000) NULL,
    featured_image_alt NVARCHAR(500) NULL,
    featured_image_caption NVARCHAR(1000) NULL,
    featured_image_description NVARCHAR(2000) NULL,
    featured_image_credit NVARCHAR(255) NULL,
    featured_image_decorative BIT NOT NULL DEFAULT 0,
    author_name NVARCHAR(255) NOT NULL,
    author_title NVARCHAR(255) NULL,
    status NVARCHAR(50) NOT NULL DEFAULT 'published',
    siteid NVARCHAR(100) NOT NULL DEFAULT 'global',
    published_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    meta_title NVARCHAR(255) NULL,
    meta_description NVARCHAR(500) NULL,
    created_by NVARCHAR(255) NULL,
    modified_by NVARCHAR(255) NULL,
    createdat DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updatedat DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    deletedat DATETIME2 NULL
);
```

---

## 3. Featured Cover Image Accessibility Suite

The Article Editor incorporates a dedicated accessibility suite for featured cover photos:

1. **Decorative Checkbox (`#featuredImageDecorative`):**
   - Implements WCAG 2.1 Technique H67.
   - When enabled, assistive technologies safely skip the photo (`aria-hidden="true"`, `alt=""`), waiving mandatory alt text requirements.
2. **Alternative Text (`#featuredImageAlt`):**
   - Real-time character counter (`0/150 rec., 500 max`).
   - "Suggest from Headline" button drafts an immediate journalistic alt text from the article title.
   - Quality auditing highlights raw file names (e.g. `.jpg`) and generic words (`"photo"`, `"image"`).
3. **Live Status Badge (`#featuredImgAdaBadge`):**
   - Live badge indicators: `No Image`, `ADA Pass`, `Decorative (H67 Pass)`, `Alt Text Required`, and `Generic Alt Warning`.
4. **Visible Story Caption (`#featuredImageCaption`):**
   - Displayed publicly under the cover image on citizen-facing article templates.
5. **Extended Description (`#featuredImageDescription`):**
   - 2,000-character multiline transcription field for complex infographics, emergency maps, or statistical diagrams (WCAG 1.1.1 AA).
6. **Photo Credit / Attribution (`#featuredImageCredit`):**
   - Captures photographer or agency attribution.

---

## 4. In-Editor Automated ADA WCAG Pre-Flight Linter

The Article Editor contains `window.ArticleA11yLinter`:
- Scans cover imagery, story body visuals, heading structure, links, tables, and readability.
- Provides real-time category chips (`Cover`, `Images`, `Headings`, `Links`, `Tables`, `Readability`).
- Expandable diagnostic drawer with issue locator and one-click quick fixes.
- Quality gating in `saveArticleForm()` warns editors before publishing live if critical violations exist.

