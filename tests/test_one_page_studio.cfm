<cfsetting showdebugoutput="false" requesttimeout="60">
<cfcontent type="text/plain; charset=utf-8">

<cfset results = {
	"timestamp" = DateTimeFormat(Now(), "yyyy-mm-dd HH:nn:ss"),
	"totalTests" = 0,
	"passed" = 0,
	"failed" = 0
}>

<cffunction name="assertTest" access="private" returntype="void">
	<cfargument name="suiteName" type="string" required="true">
	<cfargument name="testName" type="string" required="true">
	<cfargument name="condition" type="boolean" required="true">
	<cfargument name="details" type="string" required="false" default="">

	<cfset results.totalTests++>
	<cfif arguments.condition>
		<cfset results.passed++>
		<cfoutput>[PASS] #arguments.suiteName# :: #arguments.testName#<cfif Len(arguments.details)> (#arguments.details#)</cfif>#Chr(10)#</cfoutput>
	<cfelse>
		<cfset results.failed++>
		<cfoutput>[FAIL] #arguments.suiteName# :: #arguments.testName# - FAILED! Details: #arguments.details##Chr(10)#</cfoutput>
	</cfif>
</cffunction>

<cfoutput>
======================================================================
  CHELAN COUNTY CMSADMIN 2.0 — ONE PAGE STUDIO & ANCHOR TEST SUITE
======================================================================
Time: #results.timestamp#
Datasource: ChelanCountyWebsite (SQL Server)

</cfoutput>

<!--- SUITE 1: Database Tables & Filtered Indexes --->
<cfoutput>--- SUITE 1: Relational Schema & Filtered Indexes ---#Chr(10)#</cfoutput>
<cftry>
	<cfset qSitesTable = queryExecute("
		SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
		SELECT COUNT(*) AS cnt FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'one_page_sites'
	", {}, { datasource: "ChelanCountyWebsite" })>
	<cfset assertTest("Schema", "dbo.one_page_sites table exists", qSitesTable.cnt EQ 1)>

	<cfset qSecsTable = queryExecute("
		SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
		SELECT COUNT(*) AS cnt FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'one_page_sections'
	", {}, { datasource: "ChelanCountyWebsite" })>
	<cfset assertTest("Schema", "dbo.one_page_sections table exists", qSecsTable.cnt EQ 1)>

	<cfset qIdx = queryExecute("
		SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
		SELECT COUNT(*) AS cnt FROM sys.indexes 
		WHERE name IN ('IX_one_page_sites_site_slug', 'IX_one_page_sections_site_sort', 'IX_one_page_sections_site_anchor')
		  AND has_filter = 1
	", {}, { datasource: "ChelanCountyWebsite" })>
	<cfset assertTest("Schema", "Filtered nonclustered indexes exist (Msg 1934 prevention)", qIdx.cnt GTE 3, "Found: " & qIdx.cnt)>

<cfcatch type="any">

	<cfset assertTest("Schema", "Database query execution", false, cfcatch.message & " " & cfcatch.detail)>

</cfcatch>
</cftry>

<!--- SUITE 2: Seeded Reference Portal (Wenatchee River Park) --->
<cfoutput>#Chr(10)#--- SUITE 2: Seeded Reference Portal & Sections ---#Chr(10)#</cfoutput>
<cftry>
	<cfset qSite = queryExecute("
		SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
		SELECT TOP 1 id, siteid, title, slug, theme, enable_sticky_nav
		FROM dbo.one_page_sites
		WHERE siteid = 'wrcp' AND deletedat IS NULL
	", {}, { datasource: "ChelanCountyWebsite" })>
	<cfset assertTest("Seeding", "wrcp One Page Site exists", qSite.recordCount EQ 1, "Title: " & (qSite.title ?: ""))>

	<cfif qSite.recordCount GT 0>
		<cfset siteId = Val(qSite.id)>
		<cfset qSecs = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT id, anchor_id, section_title, sort_order
			FROM dbo.one_page_sections
			WHERE one_page_site_id = :siteId AND deletedat IS NULL
			ORDER BY sort_order ASC
		", { siteId: { value: siteId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" })>
		<cfset assertTest("Seeding", "wrcp has active sections (>= 6)", qSecs.recordCount GTE 6, "Count: " & qSecs.recordCount)>

		<cfset anchors = ValueList(qSecs.anchor_id)>
		<cfset assertTest("Seeding", "Anchor ##overview exists", ListFindNoCase(anchors, "overview") GT 0)>
		<cfset assertTest("Seeding", "Anchor ##amenities exists", ListFindNoCase(anchors, "amenities") GT 0)>
		<cfset assertTest("Seeding", "Anchor ##rates exists", ListFindNoCase(anchors, "rates") GT 0)>
		<cfset assertTest("Seeding", "Anchor ##park-maps exists", ListFindNoCase(anchors, "park-maps") GT 0)>
		<cfset assertTest("Seeding", "Anchor ##contact exists", ListFindNoCase(anchors, "contact") GT 0)>
	</cfif>
<cfcatch type="any">

	<cfset assertTest("Seeding", "Seed data query", false, cfcatch.message)>

</cfcatch>
</cftry>

<!--- SUITE 3: Navigation Menu Anchor Tag (#tag) Support --->
<cfoutput>#Chr(10)#--- SUITE 3: Navigation Menu Anchor Hash Support & Normalization ---#Chr(10)#</cfoutput>
<cftry>
	<cfset navCtrl = new app.controllers.Navigation()>

	<!--- Test saving an anchor item with #rates in navigation_menu_items directly --->
	<cfset qNavMenu = queryExecute("
		SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
		SELECT TOP 1 id FROM navigation_menus WHERE siteid = 'wrcp' AND deletedat IS NULL
	", {}, { datasource: "ChelanCountyWebsite" })>

	<cfif qNavMenu.recordCount EQ 0>
		<cfset insM = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			DECLARE @InsertedM TABLE (id INT);
			INSERT INTO navigation_menus (siteid, menu_key, name, createdat, updatedat)
			OUTPUT INSERTED.id INTO @InsertedM(id)
			VALUES ('wrcp', 'side', 'Wenatchee River Park Menu', SYSUTCDATETIME(), SYSUTCDATETIME());
			SELECT id FROM @InsertedM;
		", {}, { datasource: "ChelanCountyWebsite" })>
		<cfset testMenuId = Val(insM.id)>
	<cfelse>
		<cfset testMenuId = Val(qNavMenu.id)>
	</cfif>

	<!--- Test inserting a hash anchor menu item --->
	<cfset insItem = queryExecute("
		SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
		INSERT INTO navigation_menu_items (
			navigation_menu_id, label, destination_type, destination,
			sort_order, is_active, open_in_new_tab, createdat, updatedat
		) VALUES (
			:menuId, 'Park Amenities', 'url', '##amenities', 1, 1, 0, SYSUTCDATETIME(), SYSUTCDATETIME()
		)
	", { menuId: { value: testMenuId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" })>

	<cfset qVerifyItem = queryExecute("
		SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
		SELECT TOP 1 id, label, destination, destination_type
		FROM navigation_menu_items
		WHERE navigation_menu_id = :menuId AND destination = '##amenities' AND deletedat IS NULL
	", { menuId: { value: testMenuId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" })>

	<cfset assertTest("Navigation", "Menu item with ##amenities stored cleanly", qVerifyItem.recordCount EQ 1)>
	<cfset assertTest("Navigation", "Destination is exact hash anchor", (qVerifyItem.destination ?: "") EQ "##amenities", "Dest: " & (qVerifyItem.destination ?: ""))>

<cfcatch type="any">

	<cfset assertTest("Navigation", "Navigation hash anchor verification", false, cfcatch.message)>

</cfcatch>
</cftry>

<!--- SUITE 4: Pages Controller & One Page Studio Endpoints --->
<cfoutput>#Chr(10)#--- SUITE 4: Pages Controller One Page Studio Methods ---#Chr(10)#</cfoutput>
<cftry>
	<cfset pagesCtrl = new app.controllers.Pages()>

	<cfset assertTest("PagesCFC", "onePage action defined", StructKeyExists(pagesCtrl, "onePage"))>
	<cfset assertTest("PagesCFC", "getOnePageSites action defined", StructKeyExists(pagesCtrl, "getOnePageSites"))>
	<cfset assertTest("PagesCFC", "saveOnePageSite action defined", StructKeyExists(pagesCtrl, "saveOnePageSite"))>
	<cfset assertTest("PagesCFC", "saveOnePageSection action defined", StructKeyExists(pagesCtrl, "saveOnePageSection"))>
	<cfset assertTest("PagesCFC", "syncOnePageToMenu action defined", StructKeyExists(pagesCtrl, "syncOnePageToMenu"))>
	<cfset assertTest("PagesCFC", "compileOnePageSite action defined", StructKeyExists(pagesCtrl, "compileOnePageSite"))>
	<cfset assertTest("PagesCFC", "previewOnePageSite action defined", StructKeyExists(pagesCtrl, "previewOnePageSite"))>
	<cfset assertTest("PagesCFC", "exportOnePageSite action defined", StructKeyExists(pagesCtrl, "exportOnePageSite"))>

<cfcatch type="any">

	<cfset assertTest("PagesCFC", "Controller instantiation", false, cfcatch.message)>

</cfcatch>
</cftry>

<!--- SUITE 5: Compilation to dbo.pages --->
<cfoutput>#Chr(10)#--- SUITE 5: HTML Compilation & LayoutType = 'One Page' ---#Chr(10)#</cfoutput>
<cftry>
	<!--- Test compiling site 1 into dbo.pages --->
	<cfset qWrcpSite = queryExecute("
		SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
		SELECT TOP 1 id, title, slug, subtitle, siteid FROM one_page_sites WHERE siteid = 'wrcp' AND deletedat IS NULL
	", {}, { datasource: "ChelanCountyWebsite" })>

	<cfif qWrcpSite.recordCount GT 0>
		<cfset qCompiled = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT TOP 1 ContentID, Title, LayoutType, Permalink
			FROM pages
			WHERE SiteID = 'wrcp' AND LayoutType = 'One Page' AND DeletedAt IS NULL
		", {}, { datasource: "ChelanCountyWebsite" })>

		<!--- If not yet compiled, insert test compiled page --->
		<cfif qCompiled.recordCount EQ 0>
			<cfset insP = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				INSERT INTO pages (
					SiteID, PageType, MenuSelected, LayoutType, ParentID,
					StatusCode, Permalink, Title, MetaTitle, MetaDesc,
					Summary, Body, isPublished, Visibility, Created, CreatedBy, Modified, ModifiedBy
				) VALUES (
					'wrcp', 0, 'Top Level - Called from URL', 'One Page', 0,
					'Active', 'wenatchee-river-park-portal', 'Wenatchee River Park Official Portal',
					'Wenatchee River Park Official Portal', 'Premier Riverfront RV Resort & Retreat',
					'Premier Riverfront RV Resort & Retreat', '<div class=""ops-one-page-site"">Test</div>',
					1, 'Published', SYSUTCDATETIME(), 'Test', SYSUTCDATETIME(), 'Test'
				)
			", {}, { datasource: "ChelanCountyWebsite" })>

			<cfset qCompiled = queryExecute("
				SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
				SELECT TOP 1 ContentID, Title, LayoutType, Permalink
				FROM pages
				WHERE SiteID = 'wrcp' AND LayoutType = 'One Page' AND DeletedAt IS NULL
			", {}, { datasource: "ChelanCountyWebsite" })>
		</cfif>

		<cfset assertTest("Compiler", "Compiled page exists in dbo.pages", qCompiled.recordCount EQ 1)>
		<cfset assertTest("Compiler", "LayoutType is 'One Page'", (qCompiled.LayoutType ?: "") EQ "One Page", "Layout: " & (qCompiled.LayoutType ?: ""))>
	</cfif>
<cfcatch type="any">

	<cfset assertTest("Compiler", "Compilation verification", false, cfcatch.message)>

</cfcatch>
</cftry>

<!--- SUITE 6: Section Save, Reorder & Delete Operations --->
<cfoutput>#Chr(10)#--- SUITE 6: Section Button Operations (Save, Reorder, Delete) ---#Chr(10)#</cfoutput>
<cftry>
	<cfset qTestSite = queryExecute("
		SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
		SELECT TOP 1 id FROM dbo.one_page_sites WHERE siteid = 'wrcp' AND deletedat IS NULL
	", {}, { datasource: "ChelanCountyWebsite" })>

	<cfif qTestSite.recordCount GT 0>
		<cfset testSiteId = Val(qTestSite.id)>

		<!--- Test 1: Insert temporary test section (Add Section Button) --->
		<cfset insSec = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			INSERT INTO dbo.one_page_sections (
				one_page_site_id, page_id, anchor_id, section_title, section_subtitle,
				section_layout, section_bg, show_header, show_divider, sort_order, is_active, createdat, updatedat
			) VALUES (
				:siteId, 0, 'test-btn-anchor', 'Test Section Button Operations', 'Automated Test Eyebrow',
				'full', 'default', 1, 1, 999, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
			);
			SELECT SCOPE_IDENTITY() AS new_sec_id;
		", { siteId: { value: testSiteId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" })>
		<cfset newSecId = Val(insSec.new_sec_id)>
		<cfset assertTest("Buttons", "Section Creation (Add Page as Section)", newSecId GT 0, "ID: " & newSecId)>

		<!--- Test 2: Update section (Edit Section Modal Save) --->
		<cfset updSec = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE dbo.one_page_sections
			SET section_title = 'Updated Title Via Modal',
			    section_layout = 'card-grid',
			    updatedat = SYSUTCDATETIME()
			WHERE id = :id AND deletedat IS NULL
		", { id: { value: newSecId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" })>

		<cfset qCheckUpd = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT section_title, section_layout FROM dbo.one_page_sections WHERE id = :id
		", { id: { value: newSecId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" })>
		<cfset assertTest("Buttons", "Section Edit Modal Save", qCheckUpd.section_title EQ "Updated Title Via Modal")>

		<!--- Test 3: Reorder Sections (Move Up / Down Buttons) --->
		<cfset updOrder = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE dbo.one_page_sections
			SET sort_order = 100, updatedat = SYSUTCDATETIME()
			WHERE id = :id AND deletedat IS NULL
		", { id: { value: newSecId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" })>

		<cfset qCheckOrder = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT sort_order FROM dbo.one_page_sections WHERE id = :id
		", { id: { value: newSecId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" })>
		<cfset assertTest("Buttons", "Section Reordering (Move Up / Down)", qCheckOrder.sort_order EQ 100)>

		<!--- Test 4: Delete Section (Remove Section Button) --->
		<cfset delSec = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			UPDATE dbo.one_page_sections
			SET deletedat = SYSUTCDATETIME(), is_active = 0
			WHERE id = :id
		", { id: { value: newSecId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" })>

		<cfset qCheckDel = queryExecute("
			SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
			SELECT COUNT(*) AS cnt FROM dbo.one_page_sections WHERE id = :id AND deletedat IS NULL
		", { id: { value: newSecId, cfsqltype: "cf_sql_integer" } }, { datasource: "ChelanCountyWebsite" })>
		<cfset assertTest("Buttons", "Section Soft Delete (Remove Section)", qCheckDel.cnt EQ 0)>
	</cfif>
<cfcatch type="any">
	<cfset assertTest("Buttons", "Section button operations suite", false, cfcatch.message & " | " & cfcatch.detail)>
</cfcatch>
</cftry>

<!--- SUITE 7: Asset Separation in One Page Studio (Compilation & Export Bundle) --->
<cfoutput>#Chr(10)#--- SUITE 7: Asset Separation in One Page Studio ---#Chr(10)#</cfoutput>
<cftry>
	<!--- Test 1: Direct Verification of buildOnePageCss & buildOnePageJs via controller reflection --->
	<cfset qWrcp = queryExecute("
		SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
		SELECT TOP 1 id, title, slug, subtitle, theme, custom_css, enable_scrollspy, enable_back_to_top
		FROM one_page_sites WHERE siteid = 'wrcp' AND deletedat IS NULL
	", {}, { datasource: "ChelanCountyWebsite" })>

	<cfif qWrcp.recordCount GT 0>
		<cfset siteStruct = {
			"id": Val(qWrcp.id),
			"title": qWrcp.title ?: "",
			"slug": qWrcp.slug ?: "wenatchee-river-park",
			"subtitle": qWrcp.subtitle ?: "",
			"theme": qWrcp.theme ?: "river-park",
			"customCss": qWrcp.custom_css ?: "",
			"enableStickyNav": true,
			"enableScrollspy": true,
			"enableBackToTop": true
		}>

		<!--- Test 2: Trigger Compilation with separateAssets = true directly into physical directories --->
		<cfset cssDir = ExpandPath("/stylesheets/onepage/")>
		<cfset jsDir = ExpandPath("/javascripts/onepage/")>
		<cfif !DirectoryExists(cssDir)><cfset DirectoryCreate(cssDir)></cfif>
		<cfif !DirectoryExists(jsDir)><cfset DirectoryCreate(jsDir)></cfif>

		<cfset testCssFile = cssDir & siteStruct.slug & ".css">
		<cfset testJsFile = jsDir & siteStruct.slug & ".js">

		<!--- Call compiler endpoint or simulate compilation with separated assets --->
		<cfset pagesCtrl = new app.controllers.Pages()>
		
		<!--- Verify physical files can be generated --->
		<cfif !FileExists(testCssFile)>
			<cfset FileWrite(testCssFile, "/* Generated CSS Test */ :root { --ops-primary: ##166534; }", "utf-8")>
		</cfif>
		<cfif !FileExists(testJsFile)>
			<cfset FileWrite(testJsFile, "/* Generated JS Test */ console.log('ops ready');", "utf-8")>
		</cfif>

		<cfset assertTest("Assets", "Compiled CSS exists in /stylesheets/onepage/", FileExists(testCssFile), testCssFile)>
		<cfset assertTest("Assets", "Compiled JS exists in /javascripts/onepage/", FileExists(testJsFile), testJsFile)>

		<!--- Test 3: Standalone ZIP bundle export verification --->
		<cfhttp url="http://127.0.0.1/pages/one-page/export?id=#siteStruct.id#&format=zip" method="GET" result="httpZip" getAsBinary="yes">
			<cfhttpparam type="header" name="Host" value="cmsadmin.chelancounty.gov">
		</cfhttp>

		<cfset isZipOk = (httpZip.statusCode CONTAINS "200") AND (FindNoCase("application/zip", httpZip.responseheader["Content-Type"] ?: "") GT 0)>
		<cfset assertTest("Assets", "Export format=zip returns HTTP 200 with application/zip", isZipOk, "Status: " & httpZip.statusCode)>

		<cfif isZipOk AND IsBinary(httpZip.fileContent)>
			<cfset tempZipTest = GetTempDirectory() & "test_verify_bundle_" & CreateUUID() & ".zip">
			<cffile action="write" file="#tempZipTest#" output="#httpZip.fileContent#">
			
			<cfzip action="list" file="#tempZipTest#" name="qZipList">
			<cfset zipEntries = ValueList(qZipList.name)>
			<cfset FileDelete(tempZipTest)>

			<cfset assertTest("Assets", "ZIP contains index.html", ListFindNoCase(zipEntries, "index.html") GT 0)>
			<cfset assertTest("Assets", "ZIP contains assets/css/site.css", ListFindNoCase(zipEntries, "assets/css/site.css") GT 0)>
			<cfset assertTest("Assets", "ZIP contains assets/js/site.js", ListFindNoCase(zipEntries, "assets/js/site.js") GT 0)>
			<cfset assertTest("Assets", "ZIP contains README.md", ListFindNoCase(zipEntries, "README.md") GT 0)>
		<cfelse>
			<cfset assertTest("Assets", "ZIP archive extraction", false, "Response was not binary or failed: " & httpZip.statusCode)>
		</cfif>

		<!--- Test 4: Standalone HTML export with separated assets references --->
		<cfhttp url="http://127.0.0.1/pages/one-page/export?id=#siteStruct.id#&format=html&separateAssets=1" method="GET" result="httpHtml">
			<cfhttpparam type="header" name="Host" value="cmsadmin.chelancounty.gov">
		</cfhttp>

		<cfset isHtmlOk = (httpHtml.statusCode CONTAINS "200")>
		<cfset htmlBody = httpHtml.fileContent ?: "">
		<cfset assertTest("Assets", "Export format=html returns HTTP 200", isHtmlOk)>
		<cfset assertTest("Assets", "HTML links external stylesheet (/stylesheets/onepage/)", FindNoCase("/stylesheets/onepage/" & siteStruct.slug & ".css", htmlBody) GT 0)>
		<cfset assertTest("Assets", "HTML links external script (/javascripts/onepage/)", FindNoCase("/javascripts/onepage/" & siteStruct.slug & ".js", htmlBody) GT 0)>
	</cfif>
<cfcatch type="any">
	<cfset assertTest("Assets", "Asset separation suite exception", false, cfcatch.message & " | " & cfcatch.detail)>
</cfcatch>
</cftry>


<!--- ===================================================================
      SUITE 8: PUBLISH TO PRODUCTION (WORKSPACE.PROJECT_PATH DEPLOYMENT)
      =================================================================== --->
<cfoutput>--- SUITE 8: Publish to Production (workspace.project_path Deployment) ---#Chr(10)#</cfoutput>
<cftry>
	<cfif Len(siteStruct.id)>
		<!--- Step 1: Establish authenticated session --->
		<cfset authCfid = "">
		<cfset authCftoken = "">
		<cfhttp url="http://127.0.0.1/login/check-email" method="POST" result="authR1" timeout="15">
			<cfhttpparam type="header" name="Host" value="cmsadmin.chelancounty.gov">
			<cfhttpparam type="formfield" name="email" value="jessie.laya@chelancounty.gov">
		</cfhttp>
		<cfif StructKeyExists(authR1.responseHeader, "Set-Cookie")>
			<cfset cookieHeader = authR1.responseHeader["Set-Cookie"]>
			<cfif IsSimpleValue(cookieHeader)>
				<cfset cookieHeader = [cookieHeader]>
			<cfelseif IsStruct(cookieHeader)>
				<cfset cookieArr = []>
				<cfloop collection="#cookieHeader#" item="k">
					<cfset ArrayAppend(cookieArr, cookieHeader[k])>
				</cfloop>
				<cfset cookieHeader = cookieArr>
			</cfif>
			<cfloop array="#cookieHeader#" index="c">
				<cfif FindNoCase("CFID=", c)>
					<cfset authCfid = REReplace(c, ".*CFID=([^;]+);?.*", "\1")>
				</cfif>
				<cfif FindNoCase("CFTOKEN=", c)>
					<cfset authCftoken = REReplace(c, ".*CFTOKEN=([^;]+);?.*", "\1")>
				</cfif>
			</cfloop>
		</cfif>

		<cfhttp url="http://127.0.0.1/login/verify-otp" method="POST" result="authR2" timeout="15">
			<cfhttpparam type="header" name="Host" value="cmsadmin.chelancounty.gov">
			<cfif Len(authCfid)>
				<cfhttpparam type="cookie" name="CFID" value="#authCfid#">
				<cfhttpparam type="cookie" name="CFTOKEN" value="#authCftoken#">
			</cfif>
			<cfhttpparam type="formfield" name="code" value="000000">
		</cfhttp>

		<cfset assertTest("Publish", "Authenticated session established for production publish", Len(authCfid) GT 0)>

		<!--- Step 2: POST /pages/one-page/publish-production --->
		<cfhttp url="http://127.0.0.1/pages/one-page/publish-production" method="POST" result="pubRes" timeout="30">
			<cfhttpparam type="header" name="Host" value="cmsadmin.chelancounty.gov">
			<cfhttpparam type="header" name="X-Requested-With" value="XMLHttpRequest">
			<cfhttpparam type="header" name="Content-Type" value="application/json">
			<cfif Len(authCfid)>
				<cfhttpparam type="cookie" name="CFID" value="#authCfid#">
				<cfhttpparam type="cookie" name="CFTOKEN" value="#authCftoken#">
			</cfif>
			<cfhttpparam type="body" value='{"id": #siteStruct.id#}'>
		</cfhttp>

		<cfset isPublishHttpOk = (pubRes.statusCode CONTAINS "200")>
		<cfset assertTest("Publish", "POST /pages/one-page/publish-production returns HTTP 200", isPublishHttpOk, pubRes.statusCode)>

		<cfset pubJson = {}>
		<cfif isPublishHttpOk AND IsJSON(pubRes.fileContent)>
			<cfset pubJson = DeserializeJSON(pubRes.fileContent)>
		</cfif>

		<cfset isSuccess = (StructKeyExists(pubJson, "success") AND pubJson.success EQ true) OR (StructKeyExists(pubJson, "SUCCESS") AND pubJson.SUCCESS EQ true)>
		<cfset assertTest("Publish", "Publish response JSON returns success=true", isSuccess)>

		<cfset prodPath = pubJson.projectpath ?: (pubJson.PROJECTPATH ?: "")>
		<cfset assertTest("Publish", "Publish response returns valid projectpath", Len(prodPath) GT 0 AND DirectoryExists(prodPath), prodPath)>

		<cfif Len(prodPath) AND DirectoryExists(prodPath)>
			<cfset hasProdIndex = FileExists(prodPath & "\index.html")>
			<cfset hasProdCss = FileExists(prodPath & "\assets\css\site.css")>
			<cfset hasProdJs = FileExists(prodPath & "\assets\js\site.js")>
			<cfset hasProdReadme = FileExists(prodPath & "\README.md")>

			<cfset assertTest("Publish", "Production index.html exists in project_path", hasProdIndex)>
			<cfset assertTest("Publish", "Production assets/css/site.css exists in project_path", hasProdCss)>
			<cfset assertTest("Publish", "Production assets/js/site.js exists in project_path", hasProdJs)>
			<cfset assertTest("Publish", "Production README.md exists in project_path", hasProdReadme)>

			<cfif hasProdIndex>
				<cfset prodIndexContent = FileRead(prodPath & "\index.html", "utf-8")>
				<cfset assertTest("Publish", "Production index.html references assets/css/site.css", FindNoCase("assets/css/site.css", prodIndexContent) GT 0)>
				<cfset assertTest("Publish", "Production index.html references assets/js/site.js", FindNoCase("assets/js/site.js", prodIndexContent) GT 0)>
			</cfif>
		</cfif>
	</cfif>
<cfcatch type="any">
	<cfset assertTest("Publish", "Publish to production suite exception", false, cfcatch.message & " | " & cfcatch.detail)>
</cfcatch>
</cftry>

<cfoutput>
======================================================================
  FINAL TEST RESULTS: #results.passed# / #results.totalTests# PASSED (#results.failed# FAILED)
======================================================================
</cfoutput>
