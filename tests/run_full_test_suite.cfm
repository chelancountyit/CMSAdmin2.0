<cfsetting showdebugoutput="false" requesttimeout="120">
<cfcontent type="text/plain; charset=utf-8">

<cfset results = {
	"timestamp" = DateTimeFormat(Now(), "yyyy-mm-dd HH:nn:ss"),
	"totalTests" = 0,
	"passed" = 0,
	"failed" = 0,
	"testSuites" = []
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
  CHELAN COUNTY CMSADMIN 2.0 — FULL DOCUMENT CONVERTER TEST SUITE
======================================================================
Time: #results.timestamp#
Server: Adobe ColdFusion 2025 on Microsoft IIS 10
Workspace: commissioners / shared

</cfoutput>

<!--- ===================================================================
      SUITE 1: PDF CONVERSION ENGINE — CMSAdmin 2.0 Documentation.pdf
      =================================================================== --->
<cfoutput>--- SUITE 1: CMSAdmin 2.0 Documentation.pdf (Complex 17-page Architecture Manual) ---#Chr(10)#</cfoutput>
<cftry>
	<cfset converter = new app.models.DocumentConverter()>
	<cfset t0 = GetTickCount()>
	<cfset pdfDocRes = converter.convertDocument("C:\inetpub\CMSAdmin2.0\CMSAdmin 2.0 Documentation.pdf", "CMSAdmin 2.0 Documentation.pdf", "commissioners")>
	<cfset latencyDoc = GetTickCount() - t0>

	<cfset assertTest("PDF-Doc", "Conversion success flag", pdfDocRes.success EQ true)>
	<cfset assertTest("PDF-Doc", "Document Title extracted", pdfDocRes.title EQ "Overview", "Title: " & pdfDocRes.title)>
	<cfset assertTest("PDF-Doc", "Summary extracted", Len(pdfDocRes.summary) gt 30, "Length: " & Len(pdfDocRes.summary))>
	<cfset assertTest("PDF-Doc", "Execution latency under 2000ms", latencyDoc lt 2000, latencyDoc & "ms")>
	<cfset assertTest("PDF-Doc", "Headings count >= 15", pdfDocRes.stats.headingsCount gte 15, "Found: " & pdfDocRes.stats.headingsCount)>
	<cfset assertTest("PDF-Doc", "Tables count >= 5", pdfDocRes.stats.tablesCount gte 5, "Found: " & pdfDocRes.stats.tablesCount)>
	<cfset assertTest("PDF-Doc", "Paragraphs count >= 40", pdfDocRes.stats.paragraphsCount gte 40, "Found: " & pdfDocRes.stats.paragraphsCount)>
	<cfset assertTest("PDF-Doc", "Lists count >= 3", pdfDocRes.stats.listsCount gte 3, "Found: " & pdfDocRes.stats.listsCount)>
	<cfset assertTest("PDF-Doc", "Word count >= 3000", pdfDocRes.stats.wordCount gte 3000, "Words: " & pdfDocRes.stats.wordCount)>

	<!--- Strict Invariants: ZERO classes, ZERO inline styles --->
	<cfset classMatches = REMatchNoCase("class\s*=", pdfDocRes.html)>
	<cfset assertTest("PDF-Doc", "Strict Invariant: ZERO classes in HTML", ArrayLen(classMatches) EQ 0, "Matches: " & ArrayLen(classMatches))>

	<cfset styleMatches = REMatchNoCase("style\s*=", pdfDocRes.html)>
	<cfset assertTest("PDF-Doc", "Strict Invariant: ZERO inline styles in HTML", ArrayLen(styleMatches) EQ 0, "Matches: " & ArrayLen(styleMatches))>

	<!--- Semantic Headings Invariant: No h1 in body, starts at h2 --->
	<cfset h1Matches = REMatchNoCase("<h1\b", pdfDocRes.html)>
	<cfset assertTest("PDF-Doc", "WCAG 1.3.1: No <h1> in body (hierarchy preserved)", ArrayLen(h1Matches) EQ 0, "h1 count: " & ArrayLen(h1Matches))>

	<cfset h2Matches = REMatchNoCase("<h2\b", pdfDocRes.html)>
	<cfset assertTest("PDF-Doc", "WCAG 1.3.1: Contains semantic <h2> tags", ArrayLen(h2Matches) gt 0, "h2 count: " & ArrayLen(h2Matches))>

	<!--- Table Accessibility: Must contain <thead> and <th scope="col"> --->
	<cfset thScopeMatches = REMatchNoCase('<th\s+scope="col">', pdfDocRes.html)>
	<cfset assertTest("PDF-Doc", "WCAG 1.3.1: Tables contain <th scope=""col""> headers", ArrayLen(thScopeMatches) gt 0, "th[scope=col] count: " & ArrayLen(thScopeMatches))>

	<!--- Auto-linkifier Check: Contains <a href= --->
	<cfset linkMatches = REMatchNoCase('<a\s+href="http', pdfDocRes.html)>
	<cfset assertTest("PDF-Doc", "Auto-linkifier: Converted raw URLs to <a> tags", ArrayLen(linkMatches) gt 0, "Links count: " & ArrayLen(linkMatches))>

	<cfcatch type="any">
		<cfset assertTest("PDF-Doc", "Exception during PDF Doc conversion", false, cfcatch.message & " - " & cfcatch.detail)>
	</cfcatch>
</cftry>

<cfoutput>#Chr(10)#</cfoutput>

<!--- ===================================================================
      SUITE 2: PDF CONVERSION ENGINE — CMSAdmin 2.0 User Guide.pdf
      =================================================================== --->
<cfoutput>--- SUITE 2: CMSAdmin 2.0 User Guide.pdf (14-page End-User Guide) ---#Chr(10)#</cfoutput>
<cftry>
	<cfset t1 = GetTickCount()>
	<cfset pdfUserRes = converter.convertDocument("C:\inetpub\CMSAdmin2.0\CMSAdmin 2.0 User Guide.pdf", "CMSAdmin 2.0 User Guide.pdf", "commissioners")>
	<cfset latencyUser = GetTickCount() - t1>

	<cfset assertTest("PDF-User", "Conversion success flag", pdfUserRes.success EQ true)>
	<cfset assertTest("PDF-User", "Document Title extracted", pdfUserRes.title EQ "Welcome", "Title: " & pdfUserRes.title)>
	<cfset assertTest("PDF-User", "Summary extracted", Len(pdfUserRes.summary) gt 30, "Length: " & Len(pdfUserRes.summary))>
	<cfset assertTest("PDF-User", "Execution latency under 2000ms", latencyUser lt 2000, latencyUser & "ms")>
	<cfset assertTest("PDF-User", "Headings count >= 8", pdfUserRes.stats.headingsCount gte 8, "Found: " & pdfUserRes.stats.headingsCount)>
	<cfset assertTest("PDF-User", "Tables count >= 2", pdfUserRes.stats.tablesCount gte 2, "Found: " & pdfUserRes.stats.tablesCount)>
	<cfset assertTest("PDF-User", "Lists count >= 10", pdfUserRes.stats.listsCount gte 10, "Found: " & pdfUserRes.stats.listsCount)>
	<cfset assertTest("PDF-User", "Paragraphs count >= 100", pdfUserRes.stats.paragraphsCount gte 100, "Found: " & pdfUserRes.stats.paragraphsCount)>

	<!--- Strict Invariants: ZERO classes, ZERO inline styles --->
	<cfset classMatchesU = REMatchNoCase("class\s*=", pdfUserRes.html)>
	<cfset assertTest("PDF-User", "Strict Invariant: ZERO classes in HTML", ArrayLen(classMatchesU) EQ 0, "Matches: " & ArrayLen(classMatchesU))>

	<cfset styleMatchesU = REMatchNoCase("style\s*=", pdfUserRes.html)>
	<cfset assertTest("PDF-User", "Strict Invariant: ZERO inline styles in HTML", ArrayLen(styleMatchesU) EQ 0, "Matches: " & ArrayLen(styleMatchesU))>

	<cfset thScopeU = REMatchNoCase('<th\s+scope="col">', pdfUserRes.html)>
	<cfset assertTest("PDF-User", "WCAG 1.3.1: Table headers contain scope=""col""", ArrayLen(thScopeU) gte 2, "Headers found: " & ArrayLen(thScopeU))>

	<cfcatch type="any">
		<cfset assertTest("PDF-User", "Exception during PDF User Guide conversion", false, cfcatch.message & " - " & cfcatch.detail)>
	</cfcatch>
</cftry>

<cfoutput>#Chr(10)#</cfoutput>

<!--- ===================================================================
      SUITE 3: WORD (.DOCX) OPENXML CONVERSION ENGINE
      =================================================================== --->
<cfoutput>--- SUITE 3: Synthetic Microsoft Word (.docx) OpenXML Conversion Engine ---#Chr(10)#</cfoutput>
<cfset testDocxDir = GetTempDirectory() & "docx_test_" & CreateUUID()>
<cfset testDocxPath = testDocxDir & "\Sample_Commissioners_Resolution.docx">

<cftry>
	<cfdirectory action="create" directory="#testDocxDir#">

	<!--- Build OpenXML structure --->
	<cfset docXmlDir = testDocxDir & "\unpacked">
	<cfdirectory action="create" directory="#docXmlDir#">
	<cfdirectory action="create" directory="#docXmlDir#\_rels">
	<cfdirectory action="create" directory="#docXmlDir#\word">
	<cfdirectory action="create" directory="#docXmlDir#\word\_rels">

	<!--- [Content_Types].xml --->
	<cfset contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &
		'<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' &
		'<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' &
		'<Default Extension="xml" ContentType="application/xml"/>' &
		'<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' &
		'</Types>'>
	<cffile action="write" file="#docXmlDir#\[Content_Types].xml" output="#contentTypes#" charset="utf-8">

	<!--- _rels/.rels --->
	<cfset rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &
		'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' &
		'<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' &
		'</Relationships>'>
	<cffile action="write" file="#docXmlDir#\_rels\.rels" output="#rootRels#" charset="utf-8">

	<!--- word/_rels/document.xml.rels with external hyperlink --->
	<cfset docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &
		'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' &
		'<Relationship Id="rIdLink1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="https://www.chelancounty.gov/commissioners" TargetMode="External"/>' &
		'</Relationships>'>
	<cffile action="write" file="#docXmlDir#\word\_rels\document.xml.rels" output="#docRels#" charset="utf-8">

	<!--- word/document.xml: Title, Heading 1, Heading 2, Bold Heading, Table, List, and Inline Styles --->
	<cfset docXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &
		'<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' &
		'<w:body>' &
		'<!-- Title -->' &
		'<w:p><w:pPr><w:pStyle w:val="Title"/></w:pPr><w:r><w:t>Chelan County Resolution 2026-88</w:t></w:r></w:p>' &
		'<!-- Opening Paragraph -->' &
		'<w:p><w:r><w:t>A resolution establishing updated guidelines for county administrative operations and public facilities maintenance.</w:t></w:r></w:p>' &
		'<!-- Heading 1 (should downshift to h2) -->' &
		'<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Section 1: Background and Purpose</w:t></w:r></w:p>' &
		'<w:p><w:r><w:t>The Board of County Commissioners finds that modernizing web communications enhances civic engagement.</w:t></w:r></w:p>' &
		'<!-- Heading 2 (should downshift to h3) -->' &
		'<w:p><w:pPr><w:pStyle w:val="Heading2"/></w:pPr><w:r><w:t>Operational Standards</w:t></w:r></w:p>' &
		'<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>Bold directive</w:t></w:r><w:r><w:t> and </w:t></w:r><w:r><w:rPr><w:i/></w:rPr><w:t>italic specification</w:t></w:r><w:r><w:t>.</w:t></w:r></w:p>' &
		'<!-- Standalone bold unstyled line (heuristic heading test) -->' &
		'<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>Directives for Municipal Staff</w:t></w:r></w:p>' &
		'<!-- Bullet List Item 1 -->' &
		'<w:p><w:pPr><w:pStyle w:val="ListBullet"/></w:pPr><w:r><w:t>All public documents must adhere to ADA Title II WCAG 2.1 AA standards.</w:t></w:r></w:p>' &
		'<!-- Bullet List Item 2 -->' &
		'<w:p><w:pPr><w:pStyle w:val="ListBullet"/></w:pPr><w:r><w:t>Departments must review quarterly content logs.</w:t></w:r></w:p>' &
		'<!-- Hyperlink in Word -->' &
		'<w:p><w:hyperlink r:id="rIdLink1"><w:r><w:t>Official Chelan County Commissioners Portal</w:t></w:r></w:hyperlink></w:p>' &
		'<!-- Semantic Table with Header Row -->' &
		'<w:tbl>' &
		'  <w:tr>' &
		'    <w:trPr><w:tblHeader/></w:trPr>' &
		'    <w:tc><w:p><w:r><w:t>Department</w:t></w:r></w:p></w:tc>' &
		'    <w:tc><w:p><w:r><w:t>Officer</w:t></w:r></w:p></w:tc>' &
		'    <w:tc><w:p><w:r><w:t>Term Expiration</w:t></w:r></w:p></w:tc>' &
		'  </w:tr>' &
		'  <w:tr>' &
		'    <w:tc><w:p><w:r><w:t>District 1</w:t></w:r></w:p></w:tc>' &
		'    <w:tc><w:p><w:r><w:t>Commissioner Kevin Overbay</w:t></w:r></w:p></w:tc>' &
		'    <w:tc><w:p><w:r><w:t>2028</w:t></w:r></w:p></w:tc>' &
		'  </w:tr>' &
		'  <w:tr>' &
		'    <w:tc><w:p><w:r><w:t>District 2</w:t></w:r></w:p></w:tc>' &
		'    <w:tc><w:p><w:r><w:t>Commissioner Shon Smith</w:t></w:r></w:p></w:tc>' &
		'    <w:tc><w:p><w:r><w:t>2026</w:t></w:r></w:p></w:tc>' &
		'  </w:tr>' &
		'</w:tbl>' &
		'</w:body></w:document>'>
	<cffile action="write" file="#docXmlDir#\word\document.xml" output="#docXml#" charset="utf-8">

	<!--- Package into .docx using native cfzip --->
	<cfzip action="zip" file="#testDocxPath#" source="#docXmlDir#">

	<cfset assertTest("DOCX", "Synthetic .docx package created", FileExists(testDocxPath))>

	<!--- Convert .docx via DocumentConverter.cfc --->
	<cfset t2 = GetTickCount()>
	<cfset docxRes = converter.convertDocument(testDocxPath, "Sample_Commissioners_Resolution.docx", "commissioners")>
	<cfset latencyDocx = GetTickCount() - t2>

	<cfset assertTest("DOCX", "Word conversion success flag", docxRes.success EQ true)>
	<cfset assertTest("DOCX", "Document Title extracted from Title style", docxRes.title EQ "Chelan County Resolution 2026-88", "Title: " & docxRes.title)>
	<cfset assertTest("DOCX", "Execution latency under 1000ms", latencyDocx lt 1000, latencyDocx & "ms")>
	<cfset assertTest("DOCX", "Heading 1 downshifted to <h2>", FindNoCase("<h2>Section 1: Background and Purpose</h2>", docxRes.html) gt 0)>
	<cfset assertTest("DOCX", "Heading 2 downshifted to <h3>", FindNoCase("<h3>Operational Standards</h3>", docxRes.html) gt 0)>
	<cfset assertTest("DOCX", "Unstyled bold line recognized as <h2>", FindNoCase("<h2>Directives for Municipal Staff</h2>", docxRes.html) gt 0)>
	<cfset assertTest("DOCX", "Inline <strong> and <em> tags preserved", FindNoCase("<strong>Bold directive</strong>", docxRes.html) gt 0 and FindNoCase("<em>italic specification</em>", docxRes.html) gt 0)>
	<cfset assertTest("DOCX", "Bullet list grouped into <ul><li>", FindNoCase("<ul>", docxRes.html) gt 0 and FindNoCase("<li>All public documents", docxRes.html) gt 0)>
	<cfset assertTest("DOCX", "Hyperlink extracted into <a> tag", FindNoCase('href="https://www.chelancounty.gov/commissioners"', docxRes.html) gt 0)>
	<cfset assertTest("DOCX", "Table header row parsed with <th scope=""col"">", FindNoCase('<th scope="col">Department</th>', docxRes.html) gt 0)>
	<cfset assertTest("DOCX", "Table data rows parsed into <tbody><tr><td>", FindNoCase('<td>Commissioner Kevin Overbay</td>', docxRes.html) gt 0)>

	<!--- Invariants --->
	<cfset classMatchesDocx = REMatchNoCase("class\s*=", docxRes.html)>
	<cfset assertTest("DOCX", "Strict Invariant: ZERO classes in HTML", ArrayLen(classMatchesDocx) EQ 0, "Matches: " & ArrayLen(classMatchesDocx))>

	<cfset styleMatchesDocx = REMatchNoCase("style\s*=", docxRes.html)>
	<cfset assertTest("DOCX", "Strict Invariant: ZERO inline styles in HTML", ArrayLen(styleMatchesDocx) EQ 0, "Matches: " & ArrayLen(styleMatchesDocx))>

	<cfcatch type="any">
		<cfset assertTest("DOCX", "Exception during Word DOCX conversion", false, cfcatch.message & " - " & cfcatch.detail)>
	</cfcatch>
	<cffinally>
		<cftry>
			<cfif DirectoryExists(testDocxDir)>
				<cfdirectory action="delete" directory="#testDocxDir#" recurse="true">
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cffinally>
</cftry>

<cfoutput>#Chr(10)#</cfoutput>

<!--- ===================================================================
      SUITE 4: HTTP CONTROLLER ENDPOINTS INTEGRATION
      =================================================================== --->
<cfoutput>--- SUITE 4: HTTP Controller Endpoints (Pages & Articles) ---#Chr(10)#</cfoutput>

<!--- Step 0: Authenticate session to obtain CFID/CFTOKEN for controller endpoints --->
<cfset authCfid = "">
<cfset authCftoken = "">
<cftry>
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
	<cfcatch type="any">
	</cfcatch>
</cftry>

<cfset assertTest("HTTP-Auth", "Session established for controller tests", Len(authCfid) gt 0, "CFID: " & authCfid)>

<!--- Test Pages Endpoint: POST /pages/convert-document --->
<cftry>
	<cfhttp url="http://127.0.0.1/pages/convert-document" method="POST" result="httpPagesRes" timeout="30">
		<cfhttpparam type="header" name="Host" value="cmsadmin.chelancounty.gov">
		<cfhttpparam type="header" name="X-Requested-With" value="XMLHttpRequest">
		<cfif Len(authCfid)>
			<cfhttpparam type="cookie" name="CFID" value="#authCfid#">
			<cfhttpparam type="cookie" name="CFTOKEN" value="#authCftoken#">
		</cfif>
		<cfhttpparam type="cookie" name="cmsadmin_workspace" value="commissioners">
		<cfhttpparam type="formfield" name="workspace" value="commissioners">
		<cfhttpparam type="file" name="documentFile" file="C:\inetpub\CMSAdmin2.0\CMSAdmin 2.0 User Guide.pdf">
	</cfhttp>

	<cfset assertTest("HTTP-Pages", "Status code is 200", httpPagesRes.statusCode EQ "200 OK", "Status: " & httpPagesRes.statusCode)>
	<cfset assertTest("HTTP-Pages", "Content-Type is application/json", FindNoCase("application/json", httpPagesRes.responseHeader["Content-Type"]) gt 0)>

	<cfset jsonPages = {}>
	<cfif IsJson(httpPagesRes.fileContent)>
		<cfset jsonPages = DeserializeJSON(httpPagesRes.fileContent)>
		<cfset assertTest("HTTP-Pages", "JSON success is true", StructKeyExists(jsonPages, "success") and jsonPages.success EQ true)>
		<cfset pageData = StructKeyExists(jsonPages, "data") ? jsonPages.data : jsonPages>
		<cfset assertTest("HTTP-Pages", "Title returned", StructKeyExists(pageData, "title") and Len(pageData.title) gt 0, "Title: " & (StructKeyExists(pageData, "title") ? pageData.title : "none"))>
		<cfset assertTest("HTTP-Pages", "HTML returned with > 1000 chars", StructKeyExists(pageData, "html") and Len(pageData.html) gt 1000, "Length: " & (StructKeyExists(pageData, "html") ? Len(pageData.html) : 0))>
		<cfset assertTest("HTTP-Pages", "WCAG highlights returned", StructKeyExists(pageData, "wcagHighlights") and ArrayLen(pageData.wcagHighlights) gt 0)>
	<cfelse>
		<cfset assertTest("HTTP-Pages", "Response is valid JSON", false, "Raw: " & Left(httpPagesRes.fileContent, 200))>
	</cfif>

	<cfcatch type="any">
		<cfset assertTest("HTTP-Pages", "Exception invoking /pages/convert-document", false, cfcatch.message)>
	</cfcatch>
</cftry>

<!--- Test Articles Endpoint: POST /articles/convert-document --->
<cftry>
	<cfhttp url="http://127.0.0.1/articles/convert-document" method="POST" result="httpArticlesRes" timeout="30">
		<cfhttpparam type="header" name="Host" value="cmsadmin.chelancounty.gov">
		<cfhttpparam type="header" name="X-Requested-With" value="XMLHttpRequest">
		<cfif Len(authCfid)>
			<cfhttpparam type="cookie" name="CFID" value="#authCfid#">
			<cfhttpparam type="cookie" name="CFTOKEN" value="#authCftoken#">
		</cfif>
		<cfhttpparam type="cookie" name="cmsadmin_workspace" value="pio">
		<cfhttpparam type="formfield" name="workspace" value="pio">
		<cfhttpparam type="file" name="documentFile" file="C:\inetpub\CMSAdmin2.0\CMSAdmin 2.0 User Guide.pdf">
	</cfhttp>

	<cfset assertTest("HTTP-Articles", "Status code is 200", httpArticlesRes.statusCode EQ "200 OK", "Status: " & httpArticlesRes.statusCode)>
	<cfset assertTest("HTTP-Articles", "Content-Type is application/json", FindNoCase("application/json", httpArticlesRes.responseHeader["Content-Type"]) gt 0)>

	<cfset jsonArticles = {}>
	<cfif IsJson(httpArticlesRes.fileContent)>
		<cfset jsonArticles = DeserializeJSON(httpArticlesRes.fileContent)>
		<cfset assertTest("HTTP-Articles", "JSON success is true", StructKeyExists(jsonArticles, "success") and jsonArticles.success EQ true)>
		<cfset artData = StructKeyExists(jsonArticles, "data") ? jsonArticles.data : jsonArticles>
		<cfset assertTest("HTTP-Articles", "Title returned", StructKeyExists(artData, "title") and Len(artData.title) gt 0, "Title: " & (StructKeyExists(artData, "title") ? artData.title : "none"))>
		<cfset assertTest("HTTP-Articles", "HTML returned with > 1000 chars", StructKeyExists(artData, "html") and Len(artData.html) gt 1000, "Length: " & (StructKeyExists(artData, "html") ? Len(artData.html) : 0))>
	<cfelse>
		<cfset assertTest("HTTP-Articles", "Response is valid JSON", false, "Raw: " & Left(httpArticlesRes.fileContent, 200))>
	</cfif>

	<cfcatch type="any">
		<cfset assertTest("HTTP-Articles", "Exception invoking /articles/convert-document", false, cfcatch.message)>
	</cfcatch>
</cftry>

<cfoutput>#Chr(10)#</cfoutput>

<!--- ===================================================================
      SUITE 5: REJECT MALFORMED / UNSUPPORTED FILES
      =================================================================== --->
<cfoutput>--- SUITE 5: Security & Unsupported File Handling ---#Chr(10)#</cfoutput>
<cfset badFilePath = GetTempDirectory() & "malicious_script_" & CreateUUID() & ".cfm">
<cftry>
	<cffile action="write" file="#badFilePath#" output="<cfoutput>malicious</cfoutput>" charset="utf-8">

	<cfset badRes = converter.convertDocument(badFilePath, "malicious_script.cfm", "commissioners")>
	<cfset assertTest("Security", "Rejects .cfm script file", badRes.success EQ false, "Message: " & badRes.message)>
	<cfset assertTest("Security", "Returns proper warning", ArrayLen(badRes.warnings) gt 0)>

	<cfcatch type="any">
		<cfset assertTest("Security", "Exception testing unsupported file rejection", false, cfcatch.message)>
	</cfcatch>
	<cffinally>
		<cftry>
			<cfif FileExists(badFilePath)><cffile action="delete" file="#badFilePath#"></cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cffinally>
</cftry>

<cfoutput>
======================================================================
  FINAL TEST EXECUTION SUMMARY
======================================================================
Total Tests Run : #results.totalTests#
Passed          : #results.passed#
Failed          : #results.failed#
Success Rate    : #NumberFormat((results.passed / Max(1, results.totalTests)) * 100, "999.9")#%
Overall Verdict : #(results.failed EQ 0 ? "ALL TESTS PASSED (100% GREEN)" : "FAILURES DETECTED")#
======================================================================
</cfoutput>
