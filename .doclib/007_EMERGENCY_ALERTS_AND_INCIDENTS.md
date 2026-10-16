# Series 007: Emergency Alerts & Incident Dispatch System
**Location:** `.doclib/007_EMERGENCY_ALERTS_AND_INCIDENTS.md`  
**Parent Index:** [000_SERIES_INDEX.md](file:///c:/inetpub/CMSAdmin2.0/.doclib/000_SERIES_INDEX.md)

---

## 1. Overview & Public Safety Function

The **Emergency Alerts & Incident Dispatch System** ([`Alerts.cfc`](file:///c:/inetpub/CMSAdmin2.0/app/controllers/Alerts.cfc)) allows county emergency management and Public Information Officers (PIO) to publish instantaneous, color-coded emergency notification banners across all county websites and public API endpoints.

- **Admin Dispatch Studio:** [`app/views/alerts/index.cfm`](file:///c:/inetpub/CMSAdmin2.0/app/views/alerts/index.cfm)
- **Public REST API Endpoint:** `GET /api/v1/alerts/active`

---

## 2. Database Schema: `dbo.emergency_alerts`

Schema file: [`config/sql/schema-emergency-alerts.sql`](file:///c:/inetpub/CMSAdmin2.0/config/sql/schema-emergency-alerts.sql).

```sql
CREATE TABLE dbo.emergency_alerts (
    id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    message NVARCHAR(MAX) NOT NULL,
    severity NVARCHAR(50) NOT NULL DEFAULT 'warning', -- 'critical', 'warning', 'info'
    link_url NVARCHAR(500) NULL,
    link_text NVARCHAR(100) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    starts_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    expires_at DATETIME2 NULL,
    dismissible BIT NOT NULL DEFAULT 1,
    created_by NVARCHAR(255) NULL,
    site_id NVARCHAR(100) NOT NULL DEFAULT 'global',
    createdat DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updatedat DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    deletedat DATETIME2 NULL
);

CREATE NONCLUSTERED INDEX IX_emergency_alerts_active 
ON dbo.emergency_alerts (is_active, site_id) 
WHERE deletedat IS NULL;
```

---

## 3. Incident Severity Tiers & Presets

1. **Critical (Red):**
   - Immediate life-safety hazards, Level 3 "GO NOW" evacuation notices, catastrophic flooding, or active shooter incidents.
2. **Warning (Amber):**
   - Level 2 "BE SET" evacuation notices, mountain pass closures (Blewett / Stevens Pass), extreme fire weather watches, or county office closures.
3. **Info (Blue):**
   - Road construction detours, public health notices, voting reminders, or general community notices.

### One-Click Incident Presets
The dispatch studio includes fast templates for:
- Wildfire Evacuation Notices (Level 1, Level 2, Level 3).
- Mountain Pass Winter Closures.
- River Flood Warnings.
- Courthouse Severe Weather Facility Closures.

---

## 4. Public High-Speed JSON API (`/api/v1/alerts/active`)

The dispatch system serves active alerts to external county web properties and mobile apps:
- Public access exception in `app/controllers/Controller.cfc:isPublicRequest()`.
- Filtered by `is_active = 1`, `deletedat IS NULL`, and optional `?site_id=...` parameter.
- Cached in memory (`application.activeAlertsCache`) and purged on every alert create/update/toggle/delete action.

