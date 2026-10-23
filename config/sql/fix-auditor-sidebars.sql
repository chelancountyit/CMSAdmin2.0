SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- 1. Reset all auditor SidebarIDs to valid JSON empty array
UPDATE dbo.pages
SET SidebarIDs = '[]'
WHERE SiteID = 'auditor';

-- 2. Map pages with actual extracted subpages in dbo.page_SubPage
UPDATE dbo.pages
SET SidebarIDs = '["subpage-16","subpage-17"]'
WHERE ContentID = 88 AND SiteID = 'auditor';

UPDATE dbo.pages
SET SidebarIDs = '["subpage-18"]'
WHERE ContentID = 90 AND SiteID = 'auditor';

UPDATE dbo.pages
SET SidebarIDs = '["subpage-19","subpage-20","subpage-22"]'
WHERE ContentID = 134 AND SiteID = 'auditor';

UPDATE dbo.pages
SET SidebarIDs = '["subpage-15","subpage-21"]'
WHERE ContentID = 140 AND SiteID = 'auditor';

SELECT ContentID, Title, SidebarIDs
FROM dbo.pages
WHERE SiteID = 'auditor' AND SidebarIDs <> '[]';

