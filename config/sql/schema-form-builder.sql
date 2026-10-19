-- =============================================================================
-- Chelan County CMS Admin 2.0 - Online Form Builder Database Schema
-- Dialect: Microsoft SQL Server (2016+ / 2019 / 2022 / Azure SQL)
-- Features: Normalized Form Defs, Field Definitions, EAV Submissions,
--           Department Grouping (HRM, PIO, etc.), ADA WCAG, and Anti-Spam Telemetry
-- Safe to rerun: creates missing Form Builder tables and indexes only.
-- Existing objects and data are not altered or dropped. Run in the intended database.
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1. Table: form_departments
-- Organizational divisions / groups (HRM, PIO, Administration, etc.)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[form_departments]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[form_departments] (
        [id] INT IDENTITY(1,1) NOT NULL,
        [code] NVARCHAR(50) NOT NULL,
        [name] NVARCHAR(150) NOT NULL,
        [description] NVARCHAR(MAX) NULL,
        [alert_email] NVARCHAR(255) NOT NULL,
        [color_hex] NVARCHAR(20) NOT NULL CONSTRAINT [DF_form_dept_color] DEFAULT ('#0073aa'),
        [badge_class] NVARCHAR(50) NOT NULL CONSTRAINT [DF_form_dept_badge] DEFAULT ('badge-primary'),
        [is_active] BIT NOT NULL CONSTRAINT [DF_form_dept_active] DEFAULT (1),
        [createdat] DATETIME2(7) NOT NULL CONSTRAINT [DF_form_dept_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat] DATETIME2(7) NOT NULL CONSTRAINT [DF_form_dept_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat] DATETIME2(7) NULL,
        CONSTRAINT [PK_form_departments] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_form_departments_code] UNIQUE NONCLUSTERED ([code] ASC)
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 2. Table: forms
-- Core Online Form definitions, settings, themes, and security thresholds
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[forms]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[forms] (
        [id] INT IDENTITY(1,1) NOT NULL,
        [department_id] INT NULL,
        [siteid] NVARCHAR(100) NULL,
        [form_key] NVARCHAR(100) NOT NULL,
        [slug] NVARCHAR(200) NOT NULL,
        [title] NVARCHAR(255) NOT NULL,
        [description] NVARCHAR(MAX) NULL,
        [status] NVARCHAR(50) NOT NULL CONSTRAINT [DF_forms_status] DEFAULT ('published'),
        [theme_color] NVARCHAR(20) NOT NULL CONSTRAINT [DF_forms_theme] DEFAULT ('#0073aa'),
        [submit_text] NVARCHAR(100) NOT NULL CONSTRAINT [DF_forms_submit_text] DEFAULT ('Submit Form'),
        [success_message] NVARCHAR(MAX) NULL,
        [redirect_url] NVARCHAR(500) NULL,
        [notification_email] NVARCHAR(255) NULL,
        [notification_email_cc] NVARCHAR(500) NULL,
        [email_notifications_enabled] BIT NOT NULL CONSTRAINT [DF_forms_email_notif] DEFAULT (1),
        
        -- Anti-Spam & Submission Delay Controls
        [anti_spam_enabled] BIT NOT NULL CONSTRAINT [DF_forms_antispam] DEFAULT (1),
        [honeypot_field_name] NVARCHAR(100) NOT NULL CONSTRAINT [DF_forms_hp_name] DEFAULT ('_chelan_gov_verify'),
        [min_delay_seconds] INT NOT NULL CONSTRAINT [DF_forms_min_delay] DEFAULT (3),
        [cooldown_seconds] INT NOT NULL CONSTRAINT [DF_forms_cooldown] DEFAULT (3),
        
        -- ADA WCAG Accessibility & Embed Settings
        [wcag_compliant] BIT NOT NULL CONSTRAINT [DF_forms_wcag] DEFAULT (1),
        [allow_iframe_embed] BIT NOT NULL CONSTRAINT [DF_forms_embed] DEFAULT (1),
        [is_standalone_public] BIT NOT NULL CONSTRAINT [DF_forms_public] DEFAULT (1),
        
        -- Aggregate Counters & JSON Blueprint Cache
        [submissions_count] INT NOT NULL CONSTRAINT [DF_forms_sub_count] DEFAULT (0),
        [views_count] INT NOT NULL CONSTRAINT [DF_forms_views_count] DEFAULT (0),
        [schema_json] NVARCHAR(MAX) NULL,
        
        [createdat] DATETIME2(7) NOT NULL CONSTRAINT [DF_forms_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat] DATETIME2(7) NOT NULL CONSTRAINT [DF_forms_updatedat] DEFAULT (SYSUTCDATETIME()),
        [publishedat] DATETIME2(7) NULL,
        [deletedat] DATETIME2(7) NULL,
        CONSTRAINT [PK_forms] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_forms_form_key] UNIQUE NONCLUSTERED ([form_key] ASC),
        CONSTRAINT [UQ_forms_slug] UNIQUE NONCLUSTERED ([slug] ASC),
        CONSTRAINT [FK_forms_departments] FOREIGN KEY ([department_id]) 
            REFERENCES [dbo].[form_departments] ([id]) ON DELETE SET NULL
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 3. Table: form_fields
-- Normalized Field / Input definitions for visual builder items
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[form_fields]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[form_fields] (
        [id] INT IDENTITY(1,1) NOT NULL,
        [form_id] INT NOT NULL,
        [field_key] NVARCHAR(100) NOT NULL,
        [field_type] NVARCHAR(50) NOT NULL, -- 'text', 'textarea', 'paragraph', 'select', 'radio', 'checkbox', 'file', 'rating', 'signature', etc.
        [label] NVARCHAR(255) NOT NULL,
        [placeholder] NVARCHAR(255) NULL,
        [default_value] NVARCHAR(MAX) NULL,
        [subtext] NVARCHAR(500) NULL,
        [paragraph_content] NVARCHAR(MAX) NULL,
        [paragraph_style] NVARCHAR(50) NOT NULL CONSTRAINT [DF_form_fields_pstyle] DEFAULT ('normal'), -- 'normal', 'callout', 'warning', 'legal'
        [options_json] NVARCHAR(MAX) NULL, -- JSON array of choices for select, radio, checkbox
        [is_required] BIT NOT NULL CONSTRAINT [DF_form_fields_req] DEFAULT (0),
        [column_width] NVARCHAR(10) NOT NULL CONSTRAINT [DF_form_fields_width] DEFAULT ('100'), -- '25', '33', '50', '100'
        [textarea_rows] INT NOT NULL CONSTRAINT [DF_form_fields_rows] DEFAULT (4),
        [sort_order] INT NOT NULL CONSTRAINT [DF_form_fields_order] DEFAULT (0),
        [validation_rules_json] NVARCHAR(MAX) NULL,
        [is_active] BIT NOT NULL CONSTRAINT [DF_form_fields_active] DEFAULT (1),
        [createdat] DATETIME2(7) NOT NULL CONSTRAINT [DF_form_fields_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat] DATETIME2(7) NOT NULL CONSTRAINT [DF_form_fields_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat] DATETIME2(7) NULL,
        CONSTRAINT [PK_form_fields] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_form_fields_key] UNIQUE NONCLUSTERED ([form_id] ASC, [field_key] ASC),
        CONSTRAINT [FK_form_fields_forms] FOREIGN KEY ([form_id]) 
            REFERENCES [dbo].[forms] ([id]) ON DELETE CASCADE
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 4. Table: form_submissions
-- Submitted Form records with anti-spam and security verification audit telemetry
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[form_submissions]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[form_submissions] (
        [id] INT IDENTITY(1,1) NOT NULL,
        [form_id] INT NOT NULL,
        [reference_id] NVARCHAR(50) NOT NULL,
        [status] NVARCHAR(50) NOT NULL CONSTRAINT [DF_form_sub_status] DEFAULT ('received'), -- 'received', 'in_review', 'approved', 'processed', 'flagged'
        [submitted_at] DATETIME2(7) NOT NULL CONSTRAINT [DF_form_sub_submittedat] DEFAULT (SYSUTCDATETIME()),
        
        -- Anti-Spam Telemetry
        [load_time_epoch_ms] BIGINT NULL,
        [elapsed_seconds] INT NULL,
        [honeypot_passed] BIT NOT NULL CONSTRAINT [DF_form_sub_hp_passed] DEFAULT (1),
        [speed_trap_passed] BIT NOT NULL CONSTRAINT [DF_form_sub_speed_passed] DEFAULT (1),
        [is_flagged_as_spam] BIT NOT NULL CONSTRAINT [DF_form_sub_spam] DEFAULT (0),
        [ip_address] NVARCHAR(45) NULL,
        [user_agent] NVARCHAR(500) NULL,
        
        -- Review & Routing
        [assigned_to_user_id] INT NULL,
        [reviewed_by] NVARCHAR(100) NULL,
        [reviewed_at] DATETIME2(7) NULL,
        [admin_notes] NVARCHAR(MAX) NULL,
        [submission_json] NVARCHAR(MAX) NOT NULL,
        
        [createdat] DATETIME2(7) NOT NULL CONSTRAINT [DF_form_sub_createdat] DEFAULT (SYSUTCDATETIME()),
        [updatedat] DATETIME2(7) NOT NULL CONSTRAINT [DF_form_sub_updatedat] DEFAULT (SYSUTCDATETIME()),
        [deletedat] DATETIME2(7) NULL,
        CONSTRAINT [PK_form_submissions] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_form_submissions_ref] UNIQUE NONCLUSTERED ([reference_id] ASC),
        CONSTRAINT [FK_form_submissions_forms] FOREIGN KEY ([form_id]) 
            REFERENCES [dbo].[forms] ([id]) ON DELETE CASCADE
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 5. Table: form_submission_values
-- Normalized EAV Key-Value data for searching, filtering, and export
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[form_submission_values]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[form_submission_values] (
        [id] INT IDENTITY(1,1) NOT NULL,
        [submission_id] INT NOT NULL,
        [field_id] INT NULL,
        [field_key] NVARCHAR(100) NOT NULL,
        [field_label] NVARCHAR(255) NULL,
        [field_type] NVARCHAR(50) NULL,
        [field_value] NVARCHAR(MAX) NULL,
        
        -- File attachments metadata (if applicable)
        [file_path] NVARCHAR(500) NULL,
        [file_name] NVARCHAR(255) NULL,
        [file_size_bytes] BIGINT NULL,
        [file_mime_type] NVARCHAR(100) NULL,
        
        [createdat] DATETIME2(7) NOT NULL CONSTRAINT [DF_form_subval_createdat] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_form_submission_values] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [FK_form_subval_submission] FOREIGN KEY ([submission_id]) 
            REFERENCES [dbo].[form_submissions] ([id]) ON DELETE CASCADE,
        CONSTRAINT [FK_form_subval_field] FOREIGN KEY ([field_id]) 
            REFERENCES [dbo].[form_fields] ([id]) ON DELETE NO ACTION
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 6. Table: form_audit_logs
-- Immutable audit log for Washington State public records compliance
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[form_audit_logs]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[form_audit_logs] (
        [id] INT IDENTITY(1,1) NOT NULL,
        [form_id] INT NULL,
        [submission_id] INT NULL,
        [action] NVARCHAR(100) NOT NULL, -- 'FORM_CREATED', 'FORM_UPDATED', 'SUBMISSION_RECEIVED', 'SPAM_BLOCKED'
        [performed_by] NVARCHAR(100) NOT NULL CONSTRAINT [DF_form_audit_by] DEFAULT ('System'),
        [ip_address] NVARCHAR(45) NULL,
        [details_json] NVARCHAR(MAX) NULL,
        [createdat] DATETIME2(7) NOT NULL CONSTRAINT [DF_form_audit_createdat] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_form_audit_logs] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [FK_form_audit_forms] FOREIGN KEY ([form_id]) 
            REFERENCES [dbo].[forms] ([id]) ON DELETE SET NULL
    );
END;
GO

-- -----------------------------------------------------------------------------
-- Performance Indexes
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_forms_department_status' AND object_id = OBJECT_ID(N'[dbo].[forms]'))
    CREATE NONCLUSTERED INDEX [IX_forms_department_status] ON [dbo].[forms] ([department_id], [status]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_forms_siteid' AND object_id = OBJECT_ID(N'[dbo].[forms]'))
    CREATE NONCLUSTERED INDEX [IX_forms_siteid] ON [dbo].[forms] ([siteid]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_form_fields_form_sort' AND object_id = OBJECT_ID(N'[dbo].[form_fields]'))
    CREATE NONCLUSTERED INDEX [IX_form_fields_form_sort] ON [dbo].[form_fields] ([form_id], [sort_order]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_form_submissions_form_date' AND object_id = OBJECT_ID(N'[dbo].[form_submissions]'))
    CREATE NONCLUSTERED INDEX [IX_form_submissions_form_date] ON [dbo].[form_submissions] ([form_id], [submitted_at] DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_form_submissions_status' AND object_id = OBJECT_ID(N'[dbo].[form_submissions]'))
    CREATE NONCLUSTERED INDEX [IX_form_submissions_status] ON [dbo].[form_submissions] ([status]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_form_submission_values_lookup' AND object_id = OBJECT_ID(N'[dbo].[form_submission_values]'))
    CREATE NONCLUSTERED INDEX [IX_form_submission_values_lookup] ON [dbo].[form_submission_values] ([submission_id], [field_key]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_form_audit_form_date' AND object_id = OBJECT_ID(N'[dbo].[form_audit_logs]'))
    CREATE NONCLUSTERED INDEX [IX_form_audit_form_date] ON [dbo].[form_audit_logs] ([form_id], [createdat] DESC);
GO

-- -----------------------------------------------------------------------------
-- Verification: expected Form Builder tables in the current database
-- -----------------------------------------------------------------------------
SELECT [name]
FROM sys.tables
WHERE [schema_id] = SCHEMA_ID(N'dbo')
  AND [name] IN (
      N'form_departments',
      N'forms',
      N'form_fields',
      N'form_submissions',
      N'form_submission_values',
      N'form_audit_logs'
  )
ORDER BY [name];
GO
