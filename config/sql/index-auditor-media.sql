SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.media_assets WHERE site_id = 'auditor' AND filename = 'auditor-pages-eaglePlate.jpg')
BEGIN
    INSERT INTO dbo.media_assets (
        site_id, folder, filename, file_path, web_url, file_size, file_ext, mime_type,
        title, alt_text, is_image, is_wcag_compliant, created_at, updated_at
    )
    VALUES (
        'auditor', 'files/auditor/images/pages', 'auditor-pages-eaglePlate.jpg',
        'files/auditor/images/pages/auditor-pages-eaglePlate.jpg',
        '/files/auditor/images/pages/auditor-pages-eaglePlate.jpg',
        19123, 'jpg', 'image/jpeg', 'Eagle Plate License Illustration',
        'Chelan County Auditor special edition eagle vehicle plate graphic',
        1, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
END

IF NOT EXISTS (SELECT 1 FROM dbo.media_assets WHERE site_id = 'auditor' AND filename = 'county-auditor''s-office-pages-combo_plate.jpg')
BEGIN
    INSERT INTO dbo.media_assets (
        site_id, folder, filename, file_path, web_url, file_size, file_ext, mime_type,
        title, alt_text, is_image, is_wcag_compliant, created_at, updated_at
    )
    VALUES (
        'auditor', 'files/auditor/images/pages', 'county-auditor''s-office-pages-combo_plate.jpg',
        'files/auditor/images/pages/county-auditor''s-office-pages-combo_plate.jpg',
        '/files/auditor/images/pages/county-auditor''s-office-pages-combo_plate.jpg',
        33756, 'jpg', 'image/jpeg', 'Commercial Combination Plate',
        'Chelan County Auditor vehicle licensing combination truck and trailer plate',
        1, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
END

IF NOT EXISTS (SELECT 1 FROM dbo.media_assets WHERE site_id = 'auditor' AND filename = 'auditor-news-1423424367519.jpg')
BEGIN
    INSERT INTO dbo.media_assets (
        site_id, folder, filename, file_path, web_url, file_size, file_ext, mime_type,
        title, alt_text, is_image, is_wcag_compliant, created_at, updated_at
    )
    VALUES (
        'auditor', 'files/auditor/images/news', 'auditor-news-1423424367519.jpg',
        'files/auditor/images/news/auditor-news-1423424367519.jpg',
        '/files/auditor/images/news/auditor-news-1423424367519.jpg',
        9948, 'jpg', 'image/jpeg', 'Auditor News Announcement Image',
        'Chelan County Auditor election and official ballot drop box announcement',
        1, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
END
GO

