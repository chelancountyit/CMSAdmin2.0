-- ============================================================================
-- Chelan County CMSAdmin 2.0 — RFP & Solicitations Management Schema
-- Database Target: ChelanCountyWebsite (SQL Server 2019/2022/2025)
-- Conformance: RCW 39.04, RCW 39.80, RCW 36.32, RCW 42.56
-- Mandatory Settings: QUOTED_IDENTIFIER ON, ANSI_NULLS ON
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Main Solicitations Table
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'rfp_solicitations')
BEGIN
    CREATE TABLE dbo.rfp_solicitations (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        site_id NVARCHAR(50) NOT NULL,                    -- Scoped workspace (e.g. 'public-works', 'admin', 'it')
        solicitation_number NVARCHAR(100) NOT NULL,       -- E.g. 'RFP-2026-04', 'PW-BID-26-09'
        title NVARCHAR(255) NOT NULL,
        slug NVARCHAR(255) NOT NULL,
        solicitation_type NVARCHAR(50) NOT NULL DEFAULT 'RFP', -- 'RFP', 'RFQ', 'ITB', 'SWR', 'SOQ', 'NOTICE'
        status NVARCHAR(50) NOT NULL DEFAULT 'Draft',     -- 'Draft', 'Scheduled', 'Open', 'Under Review', 'Award Pending', 'Awarded', 'Cancelled'
        
        -- Scope & Contacts
        summary NVARCHAR(1000) NULL,
        description_html NVARCHAR(MAX) NULL,
        estimated_budget_range NVARCHAR(100) NULL,
        contact_name NVARCHAR(100) NULL,
        contact_email NVARCHAR(150) NULL,
        contact_phone NVARCHAR(50) NULL,
        
        -- Critical Procurement Timeline
        publish_at DATETIME2 NULL,                        -- Official publication / release
        pre_bid_datetime DATETIME2 NULL,                  -- Pre-bid meeting / conference
        pre_bid_location NVARCHAR(255) NULL,
        is_pre_bid_mandatory BIT NOT NULL DEFAULT 0,
        questions_due_at DATETIME2 NULL,                  -- Vendor Q&A deadline
        addenda_cutoff_at DATETIME2 NULL,                 -- Last date addenda can be posted
        submission_deadline DATETIME2 NOT NULL,           -- Bid closure (lockout timestamp)
        bid_opening_datetime DATETIME2 NULL,              -- Public bid opening
        bid_opening_location NVARCHAR(255) NULL,
        bocc_award_target_date DATE NULL,                 -- Target Board of Commissioners action
        
        -- Document Attachments & Links
        primary_packet_url NVARCHAR(500) NULL,            -- Path to master PDF specs in /files/...
        submission_method NVARCHAR(50) NOT NULL DEFAULT 'Physical', -- 'Physical', 'Email', 'Portal'
        submission_instructions NVARCHAR(MAX) NULL,
        
        -- Award Results
        awarded_vendor NVARCHAR(255) NULL,
        awarded_amount DECIMAL(18,2) NULL,
        bocc_resolution_number NVARCHAR(100) NULL,
        award_date DATE NULL,
        tabulation_file_url NVARCHAR(500) NULL,
        
        -- Audit & Lifecycle
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        created_by NVARCHAR(100) NULL,
        updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        updated_by NVARCHAR(100) NULL,
        deleted_at DATETIME2 NULL
    );

    PRINT 'Table dbo.rfp_solicitations created successfully.';
END
ELSE
BEGIN
    PRINT 'Table dbo.rfp_solicitations already exists.';
END
GO

-- Filtered Unique Indexes on rfp_solicitations
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_rfp_solicitations_slug_site' AND object_id = OBJECT_ID('dbo.rfp_solicitations'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_rfp_solicitations_slug_site 
        ON dbo.rfp_solicitations(site_id, slug) 
        WHERE deleted_at IS NULL;
    PRINT 'Index UX_rfp_solicitations_slug_site created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_rfp_solicitations_number' AND object_id = OBJECT_ID('dbo.rfp_solicitations'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_rfp_solicitations_number 
        ON dbo.rfp_solicitations(solicitation_number) 
        WHERE deleted_at IS NULL;
    PRINT 'Index UX_rfp_solicitations_number created.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_rfp_solicitations_status' AND object_id = OBJECT_ID('dbo.rfp_solicitations'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_rfp_solicitations_status 
        ON dbo.rfp_solicitations(status, submission_deadline) 
        WHERE deleted_at IS NULL;
    PRINT 'Index IX_rfp_solicitations_status created.';
END
GO


-- 2. Sequenced Addenda Table
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'rfp_addenda')
BEGIN
    CREATE TABLE dbo.rfp_addenda (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        solicitation_id INT NOT NULL CONSTRAINT FK_rfp_addenda_solicitation REFERENCES dbo.rfp_solicitations(id) ON DELETE CASCADE,
        addendum_number INT NOT NULL,                     -- 1, 2, 3...
        title NVARCHAR(255) NOT NULL,                     -- e.g. 'Addendum 1: Clarification of Geotechnical Specs'
        description_html NVARCHAR(MAX) NULL,
        file_url NVARCHAR(500) NULL,                      -- PDF addendum packet
        published_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        created_by NVARCHAR(100) NULL
    );

    PRINT 'Table dbo.rfp_addenda created successfully.';
END
ELSE
BEGIN
    PRINT 'Table dbo.rfp_addenda already exists.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_rfp_addenda_solicitation' AND object_id = OBJECT_ID('dbo.rfp_addenda'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_rfp_addenda_solicitation 
        ON dbo.rfp_addenda(solicitation_id, addendum_number);
    PRINT 'Index IX_rfp_addenda_solicitation created.';
END
GO


-- 3. Planholders & Vendor Registration Table
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'rfp_planholders')
BEGIN
    CREATE TABLE dbo.rfp_planholders (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        solicitation_id INT NOT NULL CONSTRAINT FK_rfp_planholders_solicitation REFERENCES dbo.rfp_solicitations(id) ON DELETE CASCADE,
        company_name NVARCHAR(200) NOT NULL,
        contact_name NVARCHAR(100) NOT NULL,
        email NVARCHAR(150) NOT NULL,
        phone NVARCHAR(50) NULL,
        contractor_license_number NVARCHAR(100) NULL,
        is_prime_contractor BIT NOT NULL DEFAULT 1,
        is_dbe_certified BIT NOT NULL DEFAULT 0,          -- Disadvantaged/Women/Minority Business
        notified_addenda_count INT NOT NULL DEFAULT 0,
        registered_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );

    PRINT 'Table dbo.rfp_planholders created successfully.';
END
ELSE
BEGIN
    PRINT 'Table dbo.rfp_planholders already exists.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_rfp_planholders_solicitation' AND object_id = OBJECT_ID('dbo.rfp_planholders'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_rfp_planholders_solicitation 
        ON dbo.rfp_planholders(solicitation_id, registered_at);
    PRINT 'Index IX_rfp_planholders_solicitation created.';
END
GO


-- 4. Bid Submissions / Tabulation Results Table
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'rfp_bids')
BEGIN
    CREATE TABLE dbo.rfp_bids (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        solicitation_id INT NOT NULL CONSTRAINT FK_rfp_bids_solicitation REFERENCES dbo.rfp_solicitations(id) ON DELETE CASCADE,
        vendor_name NVARCHAR(200) NOT NULL,
        base_bid_amount DECIMAL(18,2) NULL,
        alternate_amount DECIMAL(18,2) NULL,
        total_bid_amount DECIMAL(18,2) NULL,
        is_responsive BIT NOT NULL DEFAULT 1,
        is_apparent_low BIT NOT NULL DEFAULT 0,
        is_awarded BIT NOT NULL DEFAULT 0,
        notes NVARCHAR(1000) NULL,
        submitted_at DATETIME2 NULL
    );

    PRINT 'Table dbo.rfp_bids created successfully.';
END
ELSE
BEGIN
    PRINT 'Table dbo.rfp_bids already exists.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_rfp_bids_solicitation' AND object_id = OBJECT_ID('dbo.rfp_bids'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_rfp_bids_solicitation 
        ON dbo.rfp_bids(solicitation_id, total_bid_amount);
    PRINT 'Index IX_rfp_bids_solicitation created.';
END
GO

-- Seed sample solicitations if table is empty
IF NOT EXISTS (SELECT 1 FROM dbo.rfp_solicitations)
BEGIN
    INSERT INTO dbo.rfp_solicitations (
        site_id, solicitation_number, title, slug, solicitation_type, status,
        summary, description_html, estimated_budget_range,
        contact_name, contact_email, contact_phone,
        publish_at, submission_deadline, bid_opening_datetime, bid_opening_location,
        submission_method, submission_instructions,
        created_by
    ) VALUES (
        'public-works', 'PW-2026-08', 'Manson Boulevard Roadway & Drainage Improvements', 'manson-boulevard-roadway-drainage-improvements', 'ITB', 'Open',
        'Reconstruction of 1.4 miles of roadway including storm drainage conveyance, ADA curb ramps, and asphalt paving.',
        '<p>Chelan County Public Works is soliciting competitive sealed bids for the reconstruction and drainage improvements along Manson Boulevard between MP 2.1 and MP 3.5. Work consists of asphalt planing, roadway widening, concrete curb &amp; gutter, bioretention swales, and permanent traffic control.</p><p>All work must comply with WSDOT Standard Specifications and Chelan County Road Standards. Prevailing wages apply under RCW 39.12.</p>',
        '$1,250,000 - $1,600,000',
        'Eric Pierson, P.E.', 'public.works@co.chelan.wa.us', '(509) 667-6415',
        DATEADD(day, -5, SYSUTCDATETIME()), DATEADD(day, 12, SYSUTCDATETIME()), DATEADD(day, 12, DATEADD(hour, 1, SYSUTCDATETIME())), 'Public Works Main Conference Room, 316 Washington St, Suite 402, Wenatchee WA',
        'Physical', 'Sealed bids marked "PW-2026-08: Manson Blvd Improvements" must be delivered to Public Works reception prior to the deadline.',
        'System Seed'
    ),
    (
        'it', 'IT-2026-02', 'County-Wide Enterprise Document Archival & Public Records System', 'county-wide-enterprise-document-archival-system', 'RFP', 'Open',
        'Cloud-hosted electronic document and records management system (EDRMS) adhering to Washington State Local Government Records Retention Schedules.',
        '<p>Chelan County Information Technology invites qualified technology vendors to submit written proposals for a modern, scalable Enterprise Document and Records Management System. The solution will serve all 16 County departments, the Board of Commissioners, and the Superior Court Clerk.</p><p>Vendors must demonstrate FedRAMP or SOC-2 Type II compliance, CJIS readiness for Sheriff records, and automated RCW 42.56 redaction toolsets.</p>',
        '$150,000 - $250,000 annually',
        'David Williams, IT Director', 'it.director@co.chelan.wa.us', '(509) 667-6555',
        DATEADD(day, -10, SYSUTCDATETIME()), DATEADD(day, 18, SYSUTCDATETIME()), NULL, NULL,
        'Email', 'Proposals must be submitted in PDF format via email to it.director@co.chelan.wa.us.',
        'System Seed'
    ),
    (
        'natural-resources', 'NR-2026-01', 'Icicle Creek Fish Passage & Riparian Restoration Design', 'icicle-creek-fish-passage-restoration-design', 'RFQ', 'Awarded',
        'Engineering and environmental permitting services for fish passage barrier removal and riparian corridor enhancement along Lower Icicle Creek.',
        '<p>Chelan County Natural Resources selected qualified engineering consultants under RCW 39.80 for the engineering design and NEPA/SEPA permitting of fish passage barrier removal.</p>',
        '$280,000',
        'Mike Kaputa, Director', 'natural.resources@co.chelan.wa.us', '(509) 667-6533',
        DATEADD(day, -60, SYSUTCDATETIME()), DATEADD(day, -30, SYSUTCDATETIME()), NULL, NULL,
        'Physical', 'Completed submission.',
        'System Seed'
    );

    -- Grab ID of first seed and add an addendum and planholder
    DECLARE @SeedId INT = (SELECT TOP 1 id FROM dbo.rfp_solicitations WHERE solicitation_number = 'PW-2026-08');
    IF @SeedId IS NOT NULL
    BEGIN
        INSERT INTO dbo.rfp_addenda (solicitation_id, addendum_number, title, description_html, file_url, published_at, created_by)
        VALUES (@SeedId, 1, 'Addendum 1: Geotechnical Boring Logs & Trench Backfill Clarification', '<p>Attaches supplemental boring logs B-1 through B-6 and clarifies pipe bedding aggregate requirements under Section 7-08.</p>', '/files/public-works/addendum-1-pw-2026-08.pdf', DATEADD(day, -2, SYSUTCDATETIME()), 'System Seed');

        INSERT INTO dbo.rfp_planholders (solicitation_id, company_name, contact_name, email, phone, contractor_license_number, is_prime_contractor, is_dbe_certified)
        VALUES 
        (@SeedId, 'Selland Construction, Inc.', 'Mark Selland', 'bids@sellandconstruction.com', '(509) 662-7119', 'SELLACI891DT', 1, 0),
        (@SeedId, 'Hurst Construction LLC', 'Sarah Hurst', 'estimating@hurstconstruction.com', '(509) 664-0193', 'HURSTCL922KB', 1, 0),
        (@SeedId, 'Pipkin Construction', 'Brad Pipkin', 'bids@pipkininc.com', '(509) 884-7571', 'PIPKIC*188DO', 1, 0);
    END

    -- Update natural-resources seed with award record
    DECLARE @AwardedId INT = (SELECT TOP 1 id FROM dbo.rfp_solicitations WHERE solicitation_number = 'NR-2026-01');
    IF @AwardedId IS NOT NULL
    BEGIN
        UPDATE dbo.rfp_solicitations 
        SET awarded_vendor = 'Anchor QEA, LLC',
            awarded_amount = 278450.00,
            bocc_resolution_number = 'Res. 2026-44',
            award_date = CAST(DATEADD(day, -14, SYSUTCDATETIME()) AS DATE)
        WHERE id = @AwardedId;

        INSERT INTO dbo.rfp_bids (solicitation_id, vendor_name, base_bid_amount, total_bid_amount, is_responsive, is_apparent_low, is_awarded, notes)
        VALUES
        (@AwardedId, 'Anchor QEA, LLC', 278450.00, 278450.00, 1, 1, 1, 'Highest scoring technical proposal; fee agreed under RCW 39.80 negotiation.'),
        (@AwardedId, 'Herrera Environmental Consultants', 294100.00, 294100.00, 1, 0, 0, 'Ranked 2nd in committee interview evaluation.');
    END

    PRINT 'Sample seed data inserted.';
END
GO

