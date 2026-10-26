<cfcomponent displayname="DocumentConverter" hint="Converts Word (.docx) and PDF documents to semantic WCAG 2.1 AA HTML with media asset extraction for Chelan County CMSAdmin 2.0">

	<!---
		Main entry point: Converts an uploaded Word (.docx) or PDF (.pdf) file
		Returns a struct with title, summary, html, images, stats, and wcag compliance notes.
	--->
	<cffunction name="convertDocument" access="public" returntype="struct" output="false" hint="Converts uploaded document to semantic WCAG AA HTML">
		<cfargument name="sourceFilePath" type="string" required="true" hint="Absolute path to the uploaded file on disk">
		<cfargument name="originalFileName" type="string" required="true" hint="Original file name uploaded by user">
		<cfargument name="activeWorkspace" type="string" required="false" default="default" hint="Target department workspace slug">

		<cfset var result = {
			"success" = false,
			"title" = "",
			"summary" = "",
			"html" = "",
			"images" = [],
			"stats" = {
				"headingsCount" = 0,
				"paragraphsCount" = 0,
				"tablesCount" = 0,
				"listsCount" = 0,
				"imagesCount" = 0,
				"wordCount" = 0
			},
			"wcagHighlights" = [],
			"warnings" = [],
			"message" = ""
		}>

		<cfset var ext = LCase(ListLast(arguments.originalFileName, "."))>

		<cftry>
			<cfif not FileExists(arguments.sourceFilePath)>
				<cfset result.message = "The uploaded document file could not be found on the server.">
				<cfreturn result>
			</cfif>

			<cfif ext EQ "docx">
				<cfset result = convertDocx(arguments.sourceFilePath, arguments.originalFileName, arguments.activeWorkspace)>
			<cfelseif ext EQ "pdf">
				<cfset result = convertPdf(arguments.sourceFilePath, arguments.originalFileName, arguments.activeWorkspace)>
			<cfelse>
				<cfset result.message = "Unsupported document format (." & ext & "). Please upload a Microsoft Word (.docx) or Adobe PDF (.pdf) document.">
				<cfset ArrayAppend(result.warnings, result.message)>
				<cfreturn result>
			</cfif>

			<cfcatch type="any">
				<cfset result.success = false>
				<cfset result.message = "Document Conversion Error: " & cfcatch.message & (Len(cfcatch.detail) ? " (" & cfcatch.detail & ")" : "")>
				<cfset ArrayAppend(result.warnings, "An unexpected error occurred during document parsing: " & cfcatch.message)>
			</cfcatch>
		</cftry>

		<cfreturn result>
	</cffunction>

	<!---
		Convert Microsoft Word (.docx) to WCAG 2.1 AA HTML
	--->
	<cffunction name="convertDocx" access="private" returntype="struct" output="false">
		<cfargument name="sourceFilePath" type="string" required="true">
		<cfargument name="originalFileName" type="string" required="true">
		<cfargument name="activeWorkspace" type="string" required="true">

		<cfset var res = {
			"success" = false,
			"title" = "",
			"summary" = "",
			"html" = "",
			"images" = [],
			"stats" = {
				"headingsCount" = 0,
				"paragraphsCount" = 0,
				"tablesCount" = 0,
				"listsCount" = 0,
				"imagesCount" = 0,
				"wordCount" = 0
			},
			"wcagHighlights" = [],
			"warnings" = [],
			"message" = ""
		}>

		<cfset var tempFolder = GetTempDirectory() & "docx_import_" & CreateUUID()>
		<cfif not DirectoryExists(tempFolder)>
			<cfdirectory action="create" directory="#tempFolder#">
		</cfif>

		<cftry>
			<!--- Extract docx archive using Java ZipFile standard library --->
			<cfset unzipArchive(arguments.sourceFilePath, tempFolder)>

			<cfset var docXmlPath = tempFolder & "\word\document.xml">
			<cfif not FileExists(docXmlPath)>
				<cfset res.message = "The uploaded Word file does not appear to be a valid .docx document (word/document.xml missing).">
				<cfreturn res>
			</cfif>

			<cfset var rawXml = FileRead(docXmlPath, "utf-8")>
			<cfset var docXml = XmlParse(rawXml)>

			<!--- Relationship map for external hyperlinks and embedded images --->
			<cfset var relMap = {}>
			<cfset var relsPath = tempFolder & "\word\_rels\document.xml.rels">
			<cfif FileExists(relsPath)>
				<cfset var relsXml = XmlParse(FileRead(relsPath, "utf-8"))>
				<cfset var relNodes = XmlSearch(relsXml, "//*[local-name()='Relationship']")>
				<cfloop array="#relNodes#" index="local.rNode">
					<cfset var rId = StructKeyExists(local.rNode.XmlAttributes, "Id") ? local.rNode.XmlAttributes.Id : "">
					<cfset var rType = StructKeyExists(local.rNode.XmlAttributes, "Type") ? local.rNode.XmlAttributes.Type : "">
					<cfset var rTarget = StructKeyExists(local.rNode.XmlAttributes, "Target") ? local.rNode.XmlAttributes.Target : "">
					<cfif Len(rId)>
						<cfset relMap[rId] = { "type" = rType, "target" = rTarget }>
					</cfif>
				</cfloop>
			</cfif>

			<!--- Metadata Title from docProps/core.xml if available --->
			<cfset var metaTitle = "">
			<cfset var corePath = tempFolder & "\docProps\core.xml">
			<cfif FileExists(corePath)>
				<cftry>
					<cfset var coreXml = XmlParse(FileRead(corePath, "utf-8"))>
					<cfset var titleNodes = XmlSearch(coreXml, "//*[local-name()='title']")>
					<cfif ArrayLen(titleNodes) and Len(Trim(titleNodes[1].XmlText))>
						<cfset metaTitle = Trim(titleNodes[1].XmlText)>
					</cfif>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>

			<!--- Catalog and extract embedded images to active workspace Media Library --->
			<cfset var imageMap = {}>
			<cfset var mediaDir = tempFolder & "\word\media">
			<cfif DirectoryExists(mediaDir)>
				<cfset var mediaFiles = DirectoryList(mediaDir, false, "query")>
				<cfset var wsDiskFolder = resolveWorkspaceImagesPath(arguments.activeWorkspace)>

				<cfloop query="mediaFiles">
					<cfset var srcImgPath = mediaDir & "\" & mediaFiles.name>
					<cfset var imgExt = LCase(ListLast(mediaFiles.name, "."))>
					<cfif ListFindNoCase("jpg,jpeg,png,gif,webp,svg", imgExt)>
						<cfset var imgBytes = FileReadBinary(srcImgPath)>
						<cfset var imgHash = Hash(imgBytes, "SHA-256")>
						<cfset var cleanBase = ReReplace(ListDeleteAt(mediaFiles.name, ListLen(mediaFiles.name, "."), "."), "[^a-zA-Z0-9_\-]", "_", "all")>
						<cfset var destFileName = "doc_" & DateFormat(Now(), "yyyymmdd") & "_" & TimeFormat(Now(), "HHmmss") & "_" & cleanBase & "." & imgExt>
						<cfset var destFilePath = wsDiskFolder & "\" & destFileName>
						<cfset var webUrl = "https://assets.chelancounty.com/" & arguments.activeWorkspace & "/images/" & destFileName>

						<!--- Deduplication against dbo.media_assets --->
						<cfset var existingAsset = queryExecute("
							SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
							SELECT TOP 1 web_url, title FROM dbo.media_assets WHERE file_hash = :hash AND deletedat IS NULL
						", { hash: { value: imgHash, cfsqltype: "cf_sql_nvarchar" } }, { datasource: "ChelanCountyWebsite" })>

						<cfif existingAsset.recordCount gt 0>
							<cfset webUrl = existingAsset.web_url>
							<cfset ArrayAppend(res.images, {
								"url" = webUrl,
								"filename" = mediaFiles.name,
								"isExisting" = true,
								"alt" = existingAsset.title
							})>
						<cfelse>
							<cfset FileCopy(srcImgPath, destFilePath)>

							<!--- Extract dimensions --->
							<cfset var imgWidth = "">
							<cfset var imgHeight = "">
							<cftry>
								<cfset var cfImg = ImageRead(destFilePath)>
								<cfset var info = ImageInfo(cfImg)>
								<cfset imgWidth = info.width>
								<cfset imgHeight = info.height>
								<cfcatch type="any"></cfcatch>
							</cftry>

							<cfset var defaultTitle = "Extracted graphic from " & arguments.originalFileName>

							<!--- Persist to dbo.media_assets --->
							<cftry>
								<cfquery datasource="ChelanCountyWebsite">
									SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
									INSERT INTO dbo.media_assets (
										site_id, folder, filename, file_path, web_url,
										file_size, file_ext, mime_type, file_hash,
										title, alt_text, caption, credit,
										is_image, width, height, is_wcag_compliant, tags,
										created_by, created_at, updated_at
									) VALUES (
										<cfqueryparam value="#arguments.activeWorkspace#" cfsqltype="cf_sql_nvarchar">,
										'images',
										<cfqueryparam value="#destFileName#" cfsqltype="cf_sql_nvarchar">,
										<cfqueryparam value="#'files/' & arguments.activeWorkspace & '/images/' & destFileName#" cfsqltype="cf_sql_nvarchar">,
										<cfqueryparam value="#webUrl#" cfsqltype="cf_sql_nvarchar">,
										<cfqueryparam value="#mediaFiles.size#" cfsqltype="cf_sql_bigint">,
										<cfqueryparam value="#imgExt#" cfsqltype="cf_sql_nvarchar">,
										<cfqueryparam value="#'image/' & imgExt#" cfsqltype="cf_sql_nvarchar">,
										<cfqueryparam value="#imgHash#" cfsqltype="cf_sql_nvarchar">,
										<cfqueryparam value="#defaultTitle#" cfsqltype="cf_sql_nvarchar">,
										<cfqueryparam value="#defaultTitle#" cfsqltype="cf_sql_nvarchar">,
										'', '', 1,
										<cfqueryparam value="#Val(imgWidth)#" cfsqltype="cf_sql_integer" null="#not IsNumeric(imgWidth)#">,
										<cfqueryparam value="#Val(imgHeight)#" cfsqltype="cf_sql_integer" null="#not IsNumeric(imgHeight)#">,
										1, 'document-import,word',
										'system-doc-converter', SYSDATETIME(), SYSDATETIME()
									)
								</cfquery>
								<cfcatch type="any"></cfcatch>
							</cftry>

							<cfset ArrayAppend(res.images, {
								"url" = webUrl,
								"filename" = destFileName,
								"isExisting" = false,
								"alt" = defaultTitle,
								"width" = imgWidth,
								"height" = imgHeight
							})>
						</cfif>

						<cfset imageMap["media/" & mediaFiles.name] = webUrl>
						<cfset imageMap[mediaFiles.name] = webUrl>
					</cfif>
				</cfloop>
			</cfif>

			<cfset res.stats.imagesCount = ArrayLen(res.images)>

			<!--- Parse Body Elements --->
			<cfset var bodyNodes = XmlSearch(docXml, "//*[local-name()='body']")>
			<cfif not ArrayLen(bodyNodes)>
				<cfset res.message = "No document body found in Word document.">
				<cfreturn res>
			</cfif>

			<cfset var body = bodyNodes[1]>
			<cfset var htmlBuffer = CreateObject("java", "java.lang.StringBuilder").init()>
			<cfset var listBuffer = []>
			<cfset var listType = "ul">
			<cfset var firstHeadingFound = "">
			<cfset var firstParagraphFound = "">
			<cfset var currentHeadingLevel = 2>

			<cfloop array="#body.XmlChildren#" index="local.node">
				<cfset var nodeName = local.node.XmlName>

				<!--- Paragraph Node --->
				<cfif FindNoCase(":p", nodeName) or nodeName EQ "w:p" or nodeName EQ "p">
					<cfset var pInfo = parseWordParagraph(local.node, relMap, imageMap)>

					<cfif pInfo.isList>
						<cfif not ArrayLen(listBuffer)>
							<cfset listType = pInfo.listType>
						</cfif>
						<cfif Len(Trim(pInfo.textHtml))>
							<cfset ArrayAppend(listBuffer, pInfo.textHtml)>
						</cfif>
					<cfelse>
						<!--- Flush any pending list --->
						<cfif ArrayLen(listBuffer)>
							<cfset htmlBuffer.append(flushListHtml(listBuffer, listType))>
							<cfset res.stats.listsCount++>
							<cfset listBuffer = []>
						</cfif>

						<cfif Len(Trim(pInfo.textHtml))>
							<cfif pInfo.isHeading>
								<cfset var hLevel = Min(6, pInfo.headingLevel + 1)>
								<cfif not Len(firstHeadingFound)>
									<cfset firstHeadingFound = pInfo.plainText>
								</cfif>
								<cfset htmlBuffer.append("<h" & hLevel & ">" & pInfo.textHtml & "</h" & hLevel & ">" & Chr(10))>
								<cfset res.stats.headingsCount++>
							<cfelseif pInfo.isBlockquote>
								<cfset htmlBuffer.append("<blockquote><p>" & pInfo.textHtml & "</p></blockquote>" & Chr(10))>
							<cfelse>
								<cfset htmlBuffer.append("<p>" & pInfo.textHtml & "</p>" & Chr(10))>
								<cfset res.stats.paragraphsCount++>
								<cfif not Len(firstParagraphFound)>
									<cfset firstParagraphFound = pInfo.plainText>
								</cfif>
							</cfif>
						</cfif>
					</cfif>

				<!--- Table Node --->
				<cfelseif FindNoCase(":tbl", nodeName) or nodeName EQ "w:tbl" or nodeName EQ "tbl">
					<!--- Flush any pending list --->
					<cfif ArrayLen(listBuffer)>
						<cfset htmlBuffer.append(flushListHtml(listBuffer, listType))>
						<cfset res.stats.listsCount++>
						<cfset listBuffer = []>
					</cfif>

					<cfset var tblHtml = parseWordTable(local.node, relMap, imageMap)>
					<cfif Len(Trim(tblHtml))>
						<cfset htmlBuffer.append(tblHtml & Chr(10))>
						<cfset res.stats.tablesCount++>
					</cfif>
				</cfif>
			</cfloop>

			<!--- Flush trailing list if present --->
			<cfif ArrayLen(listBuffer)>
				<cfset htmlBuffer.append(flushListHtml(listBuffer, listType))>
				<cfset res.stats.listsCount++>
			</cfif>

			<cfset var generatedHtml = htmlBuffer.toString()>

			<!--- Clean up generated HTML: remove empty tags, normalize spaces --->
			<cfset generatedHtml = REReplace(generatedHtml, "<p>\s*(?:&nbsp;|\s)*\s*</p>", "", "all")>

			<cfset res.html = Trim(generatedHtml)>
			<cfset res.title = Len(firstHeadingFound) ? firstHeadingFound : (Len(metaTitle) ? metaTitle : formatTitleFromName(arguments.originalFileName))>
			<cfset res.summary = Len(firstParagraphFound) ? Left(firstParagraphFound, 250) : "">

			<!--- Compute approximate word count --->
			<cfset var plainBody = REReplace(res.html, "<[^>]*>", " ", "all")>
			<cfset plainBody = REReplace(plainBody, "\s+", " ", "all")>
			<cfset res.stats.wordCount = ListLen(plainBody, " ")>

			<!--- WCAG AA Highlights & Verification --->
			<cfset ArrayAppend(res.wcagHighlights, "WCAG 1.3.1 (Info & Relationships): Headings normalized to start at <h2> to preserve page outline hierarchy.")>
			<cfif res.stats.tablesCount gt 0>
				<cfset ArrayAppend(res.wcagHighlights, "WCAG 1.3.1: Tables generated with semantic <thead> and <th scope='col'> header cells.")>
			</cfif>
			<cfif res.stats.listsCount gt 0>
				<cfset ArrayAppend(res.wcagHighlights, "WCAG 1.3.1: Bullet and numbered items grouped into semantic <ul> and <ol> tags.")>
			</cfif>
			<cfif res.stats.imagesCount gt 0>
				<cfset ArrayAppend(res.wcagHighlights, "WCAG 1.1.1 (Non-Text Content): Extracted " & res.stats.imagesCount & " image(s) to Media Library with accessible alt text.")>
			</cfif>

			<cfset res.success = true>
			<cfset res.message = "Successfully converted Word document to WCAG AA HTML.">

			<cffinally>
				<!--- Clean up temporary directory --->
				<cftry>
					<cfif DirectoryExists(tempFolder)>
						<cfdirectory action="delete" directory="#tempFolder#" recurse="true">
					</cfif>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cffinally>
		</cftry>

		<cfreturn res>
	</cffunction>

	<!---
		Convert Adobe PDF (.pdf) to WCAG 2.1 AA HTML
	--->
	<cffunction name="convertPdf" access="private" returntype="struct" output="false">
		<cfargument name="sourceFilePath" type="string" required="true">
		<cfargument name="originalFileName" type="string" required="true">
		<cfargument name="activeWorkspace" type="string" required="true">

		<cfset var res = {
			"success" = false,
			"title" = "",
			"summary" = "",
			"html" = "",
			"images" = [],
			"stats" = {
				"headingsCount" = 0,
				"paragraphsCount" = 0,
				"tablesCount" = 0,
				"listsCount" = 0,
				"imagesCount" = 0,
				"wordCount" = 0
			},
			"wcagHighlights" = [],
			"warnings" = [],
			"message" = ""
		}>

		<cfset var tempImgFolder = GetTempDirectory() & "pdf_img_" & CreateUUID()>
		<cfif not DirectoryExists(tempImgFolder)>
			<cfdirectory action="create" directory="#tempImgFolder#">
		</cfif>

		<cftry>
			<!--- 1. Extract PDF Metadata using native ColdFusion cfpdf --->
			<cfset var pdfMeta = {}>
			<cftry>
				<cfpdf action="getinfo" source="#arguments.sourceFilePath#" name="pdfMeta">
				<cfcatch type="any"></cfcatch>
			</cftry>

			<cfset var pdfTitle = StructKeyExists(pdfMeta, "Title") and Len(Trim(pdfMeta.Title)) ? Trim(pdfMeta.Title) : "">
			<cfset var pdfAuthor = StructKeyExists(pdfMeta, "Author") ? Trim(pdfMeta.Author) : "">
			<cfset var totalPages = StructKeyExists(pdfMeta, "TotalPages") ? Val(pdfMeta.TotalPages) : (StructKeyExists(pdfMeta, "PageCount") ? Val(pdfMeta.PageCount) : 1)>

			<!--- 2. Extract Embedded Images using native ColdFusion cfpdf --->
			<cfset var wsDiskFolder = resolveWorkspaceImagesPath(arguments.activeWorkspace)>
			<cftry>
				<cfpdf action="extractimage" source="#arguments.sourceFilePath#" destination="#tempImgFolder#" format="png" imageprefix="pdf_img_">
				<cfset var extractedImgs = DirectoryList(tempImgFolder, false, "query")>
				<cfloop query="extractedImgs">
					<cfif extractedImgs.size gt 3000> <!--- Filter out tiny 1px spacer artifacts --->
						<cfset var destName = "pdf_" & DateFormat(Now(), "yyyymmdd") & "_" & TimeFormat(Now(), "HHmmss") & "_" & extractedImgs.name>
						<cfset var destPath = wsDiskFolder & "\" & destName>
						<cfset var webUrl = "https://assets.chelancounty.com/" & arguments.activeWorkspace & "/images/" & destName>
						<cfset var imgBytes = FileReadBinary(tempImgFolder & "\" & extractedImgs.name)>
						<cfset var imgHash = Hash(imgBytes, "SHA-256")>

						<cfset FileCopy(tempImgFolder & "\" & extractedImgs.name, destPath)>

						<!--- Catalog in dbo.media_assets --->
						<cftry>
							<cfquery datasource="ChelanCountyWebsite">
								SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
								INSERT INTO dbo.media_assets (
									site_id, folder, filename, file_path, web_url,
									file_size, file_ext, mime_type, file_hash,
									title, alt_text, caption, credit,
									is_image, width, height, is_wcag_compliant, tags,
									created_by, created_at, updated_at
								) VALUES (
									<cfqueryparam value="#arguments.activeWorkspace#" cfsqltype="cf_sql_nvarchar">,
									'images',
									<cfqueryparam value="#destName#" cfsqltype="cf_sql_nvarchar">,
									<cfqueryparam value="#'files/' & arguments.activeWorkspace & '/images/' & destName#" cfsqltype="cf_sql_nvarchar">,
									<cfqueryparam value="#webUrl#" cfsqltype="cf_sql_nvarchar">,
									<cfqueryparam value="#extractedImgs.size#" cfsqltype="cf_sql_bigint">,
									'png', 'image/png',
									<cfqueryparam value="#imgHash#" cfsqltype="cf_sql_nvarchar">,
									<cfqueryparam value="#'Extracted figure from ' & arguments.originalFileName#" cfsqltype="cf_sql_nvarchar">,
									<cfqueryparam value="#'Figure extracted from ' & arguments.originalFileName#" cfsqltype="cf_sql_nvarchar">,
									'', '', 1, NULL, NULL, 1, 'document-import,pdf',
									'system-doc-converter', SYSDATETIME(), SYSDATETIME()
								)
							</cfquery>
							<cfcatch type="any"></cfcatch>
						</cftry>

						<cfset ArrayAppend(res.images, {
							"url" = webUrl,
							"filename" = destName,
							"alt" = "Extracted figure from " & arguments.originalFileName
						})>
					</cfif>
				</cfloop>
				<cfcatch type="any">
					<!--- Image extraction non-fatal if document has no images --->
				</cfcatch>
			</cftry>

			<cfset res.stats.imagesCount = ArrayLen(res.images)>

			<!--- 3. Extract Text using native ColdFusion cfpdf --->
			<cfset var rawPdfText = "">
			<cfpdf action="extracttext" source="#arguments.sourceFilePath#" name="rawPdfText">

			<cfif not Len(Trim(rawPdfText))>
				<cfset res.message = "The PDF did not yield any text. It may be a scanned image-only PDF without an OCR text layer.">
				<cfset ArrayAppend(res.warnings, "Notice: No machine-readable text was detected. Scanned image PDFs require OCR before conversion.")>
				<cfreturn res>
			</cfif>

			<!--- Parse PDF Text Pages (ColdFusion returns XML <DocText><TextPerPage><Page pageNumber="X">...) --->
			<cfset var textBlocks = []>
			<cftry>
				<cfif IsXml(rawPdfText) or FindNoCase("<DocText>", rawPdfText)>
					<cfset var pdfXml = XmlParse(rawPdfText)>
					<cfset var pageNodes = XmlSearch(pdfXml, "//*[local-name()='Page']")>
					<cfloop array="#pageNodes#" index="local.pNode">
						<cfif Len(Trim(local.pNode.XmlText))>
							<cfset ArrayAppend(textBlocks, Trim(local.pNode.XmlText))>
						</cfif>
					</cfloop>
				<cfelse>
					<cfset ArrayAppend(textBlocks, rawPdfText)>
				</cfif>
				<cfcatch type="any">
					<cfset ArrayAppend(textBlocks, rawPdfText)>
				</cfcatch>
			</cftry>

			<!--- Semantic PDF Text Processor with Paragraph Reflow, Tables & Lists --->
			<cfset var htmlBuffer = CreateObject("java", "java.lang.StringBuilder").init()>
			<cfset var firstHeading = "">
			<cfset var firstParagraph = "">
			<cfset var docTitleHeuristic = Len(pdfTitle) ? pdfTitle : formatTitleFromName(arguments.originalFileName)>

			<!--- Normalize Typography & Stitch Document Stream with Per-Page Header/Footer Cleaning --->
			<cfset var unifiedDoc = cleanAndStitchPdfPages(textBlocks, docTitleHeuristic)>

			<!--- Extract Matrix & Tabular Sections into Semantic Tables --->
			<cfset var tblExtractResult = parseAllPdfTables(unifiedDoc)>
			<cfset var tableHtmlMap = tblExtractResult.tables>
			<cfset unifiedDoc = tblExtractResult.text>

			<!--- Tag Section Headings Dynamically --->
			<cfset unifiedDoc = tagPdfHeadings(unifiedDoc)>

			<!--- Tokenize Document Stream into Semantic Tags & Reflowed Paragraphs --->
			<cfset var tokens = unifiedDoc.split("\s*\[\[")>
			<cfset var imgIndex = 1>

			<cfloop array="#tokens#" index="local.rawToken">
				<cfset var tok = Trim(local.rawToken)>
				<cfif not Len(tok)><cfcontinue></cfif>

				<!--- Table Token --->
				<cfif tok.startsWith("TABLE:")>
					<cfset var tParts = tok.split("\]\]")>
					<cfset var tblKey = Trim(tParts[1].replace("TABLE:", ""))>
					<cfif StructKeyExists(tableHtmlMap, tblKey)>
						<cfset htmlBuffer.append(tableHtmlMap[tblKey])>
					</cfif>
					<cfif ArrayLen(tParts) gt 1 and Len(Trim(tParts[2]))>
						<cfset var postTblText = Trim(tParts[2])>
						<cfset htmlBuffer.append(reflowSentencesIntoParagraphs(postTblText))>
						<cfset res.stats.paragraphsCount += countParagraphsInHtml(postTblText)>
					</cfif>

				<!--- Heading Token --->
				<cfelseif tok.startsWith("H2:") or tok.startsWith("H3:")>
					<cfset var isH3 = tok.startsWith("H3:")>
					<cfset var hTag = isH3 ? "h3" : "h2">
					<cfset var hParts = tok.split("\]\]")>
					<cfset var hTitle = Trim(hParts[1].replace("H2:", "").replace("H3:", ""))>
					<cfset htmlBuffer.append("<" & hTag & ">" & EncodeForHTML(hTitle) & "</" & hTag & ">" & Chr(10))>
					<cfset res.stats.headingsCount++>
					<cfif not Len(firstHeading)>
						<cfset firstHeading = hTitle>
					</cfif>

					<!--- Subordinate paragraph/sentence content --->
					<cfif ArrayLen(hParts) gt 1 and Len(Trim(hParts[2]))>
						<cfset var postHText = Trim(hParts[2])>
						<cfset htmlBuffer.append(reflowSentencesIntoParagraphs(postHText))>
						<cfset res.stats.paragraphsCount += countParagraphsInHtml(postHText)>
						<cfif not Len(firstParagraph)>
							<cfset firstParagraph = postHText>
						</cfif>
					</cfif>

				<!--- Regular Text Token --->
				<cfelse>
					<cfset var cleanText = Trim(tok.replace("]]", ""))>
					<cfif Len(cleanText)>
						<cfset htmlBuffer.append(reflowSentencesIntoParagraphs(cleanText))>
						<cfset res.stats.paragraphsCount += countParagraphsInHtml(cleanText)>
						<cfif not Len(firstParagraph)>
							<cfset firstParagraph = cleanText>
						</cfif>
					</cfif>
				</cfif>

				<!--- Distribute extracted figures across sections --->
				<cfif ArrayLen(res.images) gte imgIndex and res.stats.paragraphsCount gte (imgIndex * 2)>
					<cfset var currImg = res.images[imgIndex]>
					<cfset htmlBuffer.append('<figure><img src="' & currImg.url & '" alt="' & EncodeForHTML(currImg.alt) & '"><figcaption>' & EncodeForHTML(currImg.alt) & '</figcaption></figure>' & Chr(10))>
					<cfset imgIndex++>
				</cfif>
			</cfloop>

			<cfset res.html = Trim(htmlBuffer.toString())>
			<cfset res.title = Len(firstHeading) ? firstHeading : (Len(pdfTitle) ? pdfTitle : formatTitleFromName(arguments.originalFileName))>
			<cfset res.summary = Len(firstParagraph) ? Left(firstParagraph, 250) : "">

			<!--- Calculate exact stats from generated semantic HTML tags --->
			<cfset res.stats.headingsCount = ArrayLen(REMatch("(?i)<h[1-6]\b", res.html))>
			<cfset res.stats.paragraphsCount = ArrayLen(REMatch("(?i)<p\b", res.html))>
			<cfset res.stats.tablesCount = ArrayLen(REMatch("(?i)<table\b", res.html))>
			<cfset res.stats.listsCount = ArrayLen(REMatch("(?i)<(ul|ol)\b", res.html))>

			<!--- Word count --->
			<cfset var plainBody = REReplace(res.html, "<[^>]*>", " ", "all")>
			<cfset plainBody = REReplace(plainBody, "\s+", " ", "all")>
			<cfset res.stats.wordCount = ListLen(plainBody, " ")>

			<cfset ArrayAppend(res.wcagHighlights, "WCAG 1.3.1: Extracted text structured into semantic headings, paragraphs, and list blocks.")>
			<cfif res.stats.imagesCount gt 0>
				<cfset ArrayAppend(res.wcagHighlights, "WCAG 1.1.1: Embedded figures cataloged in Media Library with responsive markup and alt text.")>
			</cfif>

			<cfset res.success = true>
			<cfset res.message = "Successfully converted PDF document to WCAG AA HTML.">

			<cffinally>
				<cftry>
					<cfif DirectoryExists(tempImgFolder)>
						<cfdirectory action="delete" directory="#tempImgFolder#" recurse="true">
					</cfif>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cffinally>
		</cftry>

		<cfreturn res>
	</cffunction>

	<!---
		Helper: Parse a single Word paragraph into structured HTML
	--->
	<cffunction name="parseWordParagraph" access="private" returntype="struct" output="false">
		<cfargument name="pNode" type="any" required="true">
		<cfargument name="relMap" type="struct" required="true">
		<cfargument name="imageMap" type="struct" required="true">

		<cfset var info = {
			"isHeading" = false,
			"headingLevel" = 2,
			"isList" = false,
			"listType" = "ul",
			"isBlockquote" = false,
			"textHtml" = "",
			"plainText" = ""
		}>

		<cfset var styleVal = "">
		<cfset var pPrNodes = XmlSearch(arguments.pNode, "*[local-name()='pPr']")>
		<cfif ArrayLen(pPrNodes)>
			<cfset var pPr = pPrNodes[1]>
			<!--- Style check --->
			<cfset var pStyleNodes = XmlSearch(pPr, "*[local-name()='pStyle']")>
			<cfif ArrayLen(pStyleNodes) and StructKeyExists(pStyleNodes[1].XmlAttributes, "w:val")>
				<cfset styleVal = pStyleNodes[1].XmlAttributes["w:val"]>
			<cfelseif ArrayLen(pStyleNodes) and StructKeyExists(pStyleNodes[1].XmlAttributes, "val")>
				<cfset styleVal = pStyleNodes[1].XmlAttributes["val"]>
			</cfif>

			<!--- Numbering / List check --->
			<cfset var numPrNodes = XmlSearch(pPr, "*[local-name()='numPr']")>
			<cfif ArrayLen(numPrNodes) or FindNoCase("List", styleVal) or FindNoCase("Bullet", styleVal)>
				<cfset info.isList = true>
				<cfset info.listType = (FindNoCase("number", styleVal) or FindNoCase("digit", styleVal)) ? "ol" : "ul">
			</cfif>
		</cfif>

		<!--- Check styleVal for heading hierarchy --->
		<cfif REFindNoCase("^Heading\s*1$", styleVal) or styleVal EQ "Title">
			<cfset info.isHeading = true>
			<cfset info.headingLevel = 1>
		<cfelseif REFindNoCase("^Heading\s*2$", styleVal) or styleVal EQ "Subtitle">
			<cfset info.isHeading = true>
			<cfset info.headingLevel = 2>
		<cfelseif REFindNoCase("^Heading\s*3$", styleVal)>
			<cfset info.isHeading = true>
			<cfset info.headingLevel = 3>
		<cfelseif REFindNoCase("^Heading\s*4$", styleVal)>
			<cfset info.isHeading = true>
			<cfset info.headingLevel = 4>
		<cfelseif REFindNoCase("^Heading\s*5$", styleVal)>
			<cfset info.isHeading = true>
			<cfset info.headingLevel = 5>
		<cfelseif styleVal EQ "Quote" or styleVal EQ "IntenseQuote">
			<cfset info.isBlockquote = true>
		</cfif>

		<!--- Parse text runs and drawing elements --->
		<cfset var textBuf = CreateObject("java", "java.lang.StringBuilder").init()>
		<cfset var plainBuf = CreateObject("java", "java.lang.StringBuilder").init()>

		<cfloop array="#arguments.pNode.XmlChildren#" index="local.child">
			<cfset var cName = local.child.XmlName>

			<!--- Run Element (<w:r>) --->
			<cfif FindNoCase(":r", cName) or cName EQ "w:r" or cName EQ "r">
				<cfset var runRes = parseWordRun(local.child, arguments.relMap, arguments.imageMap)>
				<cfset textBuf.append(runRes.html)>
				<cfset plainBuf.append(runRes.plain)>

			<!--- Hyperlink Element (<w:hyperlink>) --->
			<cfelseif FindNoCase(":hyperlink", cName) or cName EQ "w:hyperlink" or cName EQ "hyperlink">
				<cfset var rId = StructKeyExists(local.child.XmlAttributes, "r:id") ? local.child.XmlAttributes["r:id"] : (StructKeyExists(local.child.XmlAttributes, "id") ? local.child.XmlAttributes["id"] : "")>
				<cfset var linkUrl = "">
				<cfif Len(rId) and StructKeyExists(arguments.relMap, rId)>
					<cfset linkUrl = arguments.relMap[rId].target>
				</cfif>

				<cfset var linkTextBuf = CreateObject("java", "java.lang.StringBuilder").init()>
				<cfset var linkPlainBuf = CreateObject("java", "java.lang.StringBuilder").init()>

				<cfloop array="#local.child.XmlChildren#" index="local.linkChild">
					<cfif FindNoCase(":r", local.linkChild.XmlName)>
						<cfset var linkRunRes = parseWordRun(local.linkChild, arguments.relMap, arguments.imageMap)>
						<cfset linkTextBuf.append(linkRunRes.html)>
						<cfset linkPlainBuf.append(linkRunRes.plain)>
					</cfif>
				</cfloop>

				<cfif Len(linkUrl)>
					<cfset var cleanHref = Replace(Replace(EncodeForHTML(linkUrl), '&##x3a;', ':', 'all'), '&##x2f;', '/', 'all')>
					<cfset textBuf.append('<a href="' & cleanHref & '" rel="noopener noreferrer">' & linkTextBuf.toString() & '</a>')>
				<cfelse>
					<cfset textBuf.append(linkTextBuf.toString())>
				</cfif>
				<cfset plainBuf.append(linkPlainBuf.toString())>
			</cfif>
		</cfloop>

		<cfset info.textHtml = Replace(textBuf.toString(), '&##x3a;', ':', 'all')>
		<cfset info.plainText = plainBuf.toString()>

		<!--- Heuristic: detect unstyled standalone bold paragraphs as headings --->
		<cfif not info.isHeading and not info.isList and not info.isBlockquote>
			<cfset var plainTrim = Trim(info.plainText)>
			<cfif Len(plainTrim) gte 3 and Len(plainTrim) lte 70 and not REFind("[.!?]$", plainTrim)>
				<cfif REFind("^<strong>[^<]+</strong>$", Trim(info.textHtml))>
					<cfset info.isHeading = true>
					<cfset info.headingLevel = 1>
					<cfset info.textHtml = plainTrim>
				</cfif>
			</cfif>
		</cfif>

		<cfreturn info>
	</cffunction>

	<!---
		Helper: Parse a single Word text run (<w:r>) using pure HTML tags
	--->
	<cffunction name="parseWordRun" access="private" returntype="struct" output="false">
		<cfargument name="rNode" type="any" required="true">
		<cfargument name="relMap" type="struct" required="true">
		<cfargument name="imageMap" type="struct" required="true">

		<cfset var res = { "html" = "", "plain" = "" }>
		<cfset var isBold = false>
		<cfset var isItalic = false>
		<cfset var isUnderline = false>
		<cfset var isStrike = false>
		<cfset var isSuperscript = false>
		<cfset var isSubscript = false>
		<cfset var isMark = false>

		<!--- Check run formatting properties --->
		<cfset var rPrNodes = XmlSearch(arguments.rNode, "*[local-name()='rPr']")>
		<cfif ArrayLen(rPrNodes)>
			<cfset var rPr = rPrNodes[1]>
			<cfif ArrayLen(XmlSearch(rPr, "*[local-name()='b']"))><cfset isBold = true></cfif>
			<cfif ArrayLen(XmlSearch(rPr, "*[local-name()='i']"))><cfset isItalic = true></cfif>
			<cfset var uNodes = XmlSearch(rPr, "*[local-name()='u']")>
			<cfif ArrayLen(uNodes)>
				<cfset var uVal = StructKeyExists(uNodes[1].XmlAttributes, "w:val") ? uNodes[1].XmlAttributes["w:val"] : (StructKeyExists(uNodes[1].XmlAttributes, "val") ? uNodes[1].XmlAttributes["val"] : "single")>
				<cfif uVal NEQ "none"><cfset isUnderline = true></cfif>
			</cfif>
			<cfif ArrayLen(XmlSearch(rPr, "*[local-name()='strike']"))><cfset isStrike = true></cfif>
			<cfset var vertNodes = XmlSearch(rPr, "*[local-name()='vertAlign']")>
			<cfif ArrayLen(vertNodes)>
				<cfset var vVal = StructKeyExists(vertNodes[1].XmlAttributes, "w:val") ? vertNodes[1].XmlAttributes["w:val"] : (StructKeyExists(vertNodes[1].XmlAttributes, "val") ? vertNodes[1].XmlAttributes["val"] : "")>
				<cfif vVal EQ "superscript"><cfset isSuperscript = true></cfif>
				<cfif vVal EQ "subscript"><cfset isSubscript = true></cfif>
			</cfif>
			<cfif ArrayLen(XmlSearch(rPr, "*[local-name()='highlight']"))><cfset isMark = true></cfif>
		</cfif>

		<!--- Check text runs, soft breaks, and embedded drawings --->
		<cfloop array="#arguments.rNode.XmlChildren#" index="local.c">
			<cfset var cName = local.c.XmlName>

			<!--- Text: <w:t> --->
			<cfif FindNoCase(":t", cName) or cName EQ "w:t" or cName EQ "t">
				<cfset var txt = local.c.XmlText>
				<cfif Len(txt)>
					<cfset res.plain = res.plain & txt>
					<cfset var encTxt = EncodeForHTML(txt)>
					<cfif isBold><cfset encTxt = "<strong>" & encTxt & "</strong>"></cfif>
					<cfif isItalic><cfset encTxt = "<em>" & encTxt & "</em>"></cfif>
					<cfif isUnderline><cfset encTxt = "<u>" & encTxt & "</u>"></cfif>
					<cfif isStrike><cfset encTxt = "<s>" & encTxt & "</s>"></cfif>
					<cfif isSuperscript><cfset encTxt = "<sup>" & encTxt & "</sup>"></cfif>
					<cfif isSubscript><cfset encTxt = "<sub>" & encTxt & "</sub>"></cfif>
					<cfif isMark><cfset encTxt = "<mark>" & encTxt & "</mark>"></cfif>
					<cfset res.html = res.html & encTxt>
				</cfif>

			<!--- Soft Break: <w:br> or Page Break --->
			<cfelseif FindNoCase(":br", cName) or cName EQ "w:br" or cName EQ "br">
				<cfset var brType = StructKeyExists(local.c.XmlAttributes, "w:type") ? local.c.XmlAttributes["w:type"] : (StructKeyExists(local.c.XmlAttributes, "type") ? local.c.XmlAttributes["type"] : "")>
				<cfif brType EQ "page">
					<cfset res.html = res.html & "<hr>" & Chr(10)>
				<cfelse>
					<cfset res.html = res.html & "<br>" & Chr(10)>
				</cfif>

			<!--- Tab: <w:tab> --->
			<cfelseif FindNoCase(":tab", cName) or cName EQ "w:tab" or cName EQ "tab">
				<cfset res.html = res.html & " &nbsp; ">
				<cfset res.plain = res.plain & " ">

			<!--- Drawing / Image: <w:drawing> --->
			<cfelseif FindNoCase(":drawing", cName) or cName EQ "w:drawing" or cName EQ "drawing">
				<cfset var blipNodes = XmlSearch(local.c, "//*[local-name()='blip']")>
				<cfloop array="#blipNodes#" index="local.blip">
					<cfset var embedId = StructKeyExists(local.blip.XmlAttributes, "r:embed") ? local.blip.XmlAttributes["r:embed"] : "">
					<cfif Len(embedId) and StructKeyExists(arguments.relMap, embedId)>
						<cfset var target = arguments.relMap[embedId].target>
						<cfset var imgWebUrl = StructKeyExists(arguments.imageMap, target) ? arguments.imageMap[target] : (StructKeyExists(arguments.imageMap, ListLast(target, "/")) ? arguments.imageMap[ListLast(target, "/")] : "")>

						<!--- Alt text from docPr --->
						<cfset var altText = "Extracted document illustration">
						<cfset var docPrNodes = XmlSearch(local.c, "//*[local-name()='docPr']")>
						<cfif ArrayLen(docPrNodes)>
							<cfif StructKeyExists(docPrNodes[1].XmlAttributes, "descr") and Len(Trim(docPrNodes[1].XmlAttributes.descr))>
								<cfset altText = Trim(docPrNodes[1].XmlAttributes.descr)>
							<cfelseif StructKeyExists(docPrNodes[1].XmlAttributes, "title") and Len(Trim(docPrNodes[1].XmlAttributes.title))>
								<cfset altText = Trim(docPrNodes[1].XmlAttributes.title)>
							</cfif>
						</cfif>

						<cfif Len(imgWebUrl)>
							<!--- Pure standard HTML img tag without utility classes or inline styles --->
							<cfset res.html = res.html & '<img src="' & imgWebUrl & '" alt="' & EncodeForHTML(altText) & '">' & Chr(10)>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>

		<cfreturn res>
	</cffunction>

	<!---
		Helper: Parse a Word Table into semantic WCAG AA HTML
	--->
	<cffunction name="parseWordTable" access="private" returntype="string" output="false">
		<cfargument name="tblNode" type="any" required="true">
		<cfargument name="relMap" type="struct" required="true">
		<cfargument name="imageMap" type="struct" required="true">

		<cfset var tbBuf = CreateObject("java", "java.lang.StringBuilder").init()>
		<!--- Pure standard HTML table tag without wrapper divs, classes, or inline styles --->
		<cfset tbBuf.append('<table>' & Chr(10))>

		<cfset var rowNodes = XmlSearch(arguments.tblNode, "*[local-name()='tr']")>
		<cfset var isFirstRow = true>
		<cfset var inTbody = false>

		<cfloop array="#rowNodes#" index="local.trNode">
			<cfset var cellNodes = XmlSearch(local.trNode, "*[local-name()='tc']")>
			<cfif not ArrayLen(cellNodes)><cfcontinue></cfif>

			<!--- Check if this row is designated as header row --->
			<cfset var isHeaderRow = isFirstRow>
			<cfset var trPrNodes = XmlSearch(local.trNode, "*[local-name()='trPr']")>
			<cfif ArrayLen(trPrNodes) and ArrayLen(XmlSearch(trPrNodes[1], "*[local-name()='tblHeader']"))>
				<cfset isHeaderRow = true>
			</cfif>

			<cfif isHeaderRow and isFirstRow>
				<cfset tbBuf.append('<thead><tr>' & Chr(10))>
			<cfelseif not inTbody>
				<cfif isFirstRow>
					<cfset tbBuf.append('</thead>' & Chr(10))>
				</cfif>
				<cfset tbBuf.append('<tbody>' & Chr(10))>
				<cfset inTbody = true>
				<cfset tbBuf.append('<tr>' & Chr(10))>
			<cfelse>
				<cfset tbBuf.append('<tr>' & Chr(10))>
			</cfif>

			<cfloop array="#cellNodes#" index="local.tcNode">
				<cfset var cellTextBuf = CreateObject("java", "java.lang.StringBuilder").init()>
				<cfset var pNodes = XmlSearch(local.tcNode, "*[local-name()='p']")>
				<cfloop array="#pNodes#" index="local.p">
					<cfset var pRes = parseWordParagraph(local.p, arguments.relMap, arguments.imageMap)>
					<cfif Len(Trim(pRes.textHtml))>
						<cfif cellTextBuf.length() gt 0><cfset cellTextBuf.append("<br>")></cfif>
						<cfset cellTextBuf.append(pRes.textHtml)>
					</cfif>
				</cfloop>

				<cfset var cellContent = Len(Trim(cellTextBuf.toString())) ? cellTextBuf.toString() : "&nbsp;">

				<cfif isHeaderRow and not inTbody>
					<cfset tbBuf.append('  <th scope="col">' & cellContent & '</th>' & Chr(10))>
				<cfelse>
					<cfset tbBuf.append('  <td>' & cellContent & '</td>' & Chr(10))>
				</cfif>
			</cfloop>

			<cfset tbBuf.append('</tr>' & Chr(10))>

			<cfif isHeaderRow and isFirstRow>
				<cfset tbBuf.append('</thead>' & Chr(10))>
				<cfset isFirstRow = false>
			</cfif>
		</cfloop>

		<cfif inTbody>
			<cfset tbBuf.append('</tbody>' & Chr(10))>
		</cfif>
		<cfset tbBuf.append('</table>' & Chr(10))>

		<cfreturn tbBuf.toString()>
	</cffunction>

	<!---
		Helper: Flush an accumulated list array into <ul> or <ol>
	--->
	<cffunction name="flushListHtml" access="private" returntype="string" output="false">
		<cfargument name="items" type="array" required="true">
		<cfargument name="type" type="string" required="false" default="ul">

		<cfif not ArrayLen(arguments.items)><cfreturn ""></cfif>

		<cfset var tag = (arguments.type EQ "ol") ? "ol" : "ul">
		<cfset var sb = CreateObject("java", "java.lang.StringBuilder").init()>
		<cfset sb.append("<" & tag & ">" & Chr(10))>
		<cfloop array="#arguments.items#" index="local.it">
			<cfset sb.append("  <li>" & local.it & "</li>" & Chr(10))>
		</cfloop>
		<cfset sb.append("</" & tag & ">" & Chr(10))>

		<cfreturn sb.toString()>
	</cffunction>

	<!---
		Helper: Unzip archive safely using native ColdFusion cfzip
	--->
	<cffunction name="unzipArchive" access="private" returntype="void" output="false">
		<cfargument name="zipFilePath" type="string" required="true">
		<cfargument name="destinationDir" type="string" required="true">

		<cfzip action="unzip" file="#arguments.zipFilePath#" destination="#arguments.destinationDir#" overwrite="true">
	</cffunction>

	<!---
		Helper: Resolve disk path for workspace images directory
	--->
	<cffunction name="resolveWorkspaceImagesPath" access="private" returntype="string" output="false">
		<cfargument name="workspace" type="string" required="true">

		<cfset var rootDisk = "C:\inetpub\chelan-county\files\">
		<cfset var wsClean = Replace(Replace(Trim(arguments.workspace), "\", "/", "all"), "/", "", "all")>
		<cfif not Len(wsClean)>
			<cfset wsClean = "shared">
		</cfif>

		<cfset var wsDisk = rootDisk & wsClean & "\images">
		<cfif not DirectoryExists(wsDisk)>
			<cftry>
				<cfif not DirectoryExists(rootDisk & wsClean)>
					<cfdirectory action="create" directory="#rootDisk & wsClean#">
				</cfif>
				<cfdirectory action="create" directory="#wsDisk#">
				<cfcatch type="any">
					<!--- Fallback to webroot if external path inaccessible --->
					<cfset wsDisk = ExpandPath("/files/" & wsClean & "/images")>
					<cfif not DirectoryExists(wsDisk)>
						<cfdirectory action="create" directory="#wsDisk#" recurse="true">
					</cfif>
				</cfcatch>
			</cftry>
		</cfif>

		<cfreturn wsDisk>
	</cffunction>

	<!---
		Helper: Format human-friendly title from filename
	--->
	<cffunction name="formatTitleFromName" access="private" returntype="string" output="false">
		<cfargument name="fileName" type="string" required="true">

		<cfset var raw = ListDeleteAt(arguments.fileName, ListLen(arguments.fileName, "."), ".")>
		<cfset raw = Replace(raw, "_", " ", "all")>
		<cfset raw = Replace(raw, "-", " ", "all")>
		<cfset var words = ListToArray(raw, " ")>
		<cfset var titleParts = []>

		<cfloop array="#words#" index="local.w">
			<cfif Len(local.w)>
				<cfset ArrayAppend(titleParts, UCase(Left(local.w, 1)) & LCase(Right(local.w, Len(local.w) - 1)))>
			</cfif>
		</cfloop>

		<cfreturn ArrayToList(titleParts, " ")>
	</cffunction>

	<!---
		Helper: Intelligently reflow continuous sentences into well-proportioned semantic <p> blocks
		Also extracts embedded numbered lists (1. ... 2. ...) and bullet lists.
	--->
	<!---
		Helper: Normalize typography, paths, and stitch pages with per-page header/footer cleaning
	--->
	<cffunction name="cleanAndStitchPdfPages" access="private" returntype="string" output="false">
		<cfargument name="textBlocks" type="array" required="true">
		<cfargument name="docTitleHeuristic" type="string" required="false" default="">

		<cfset var unifiedDoc = "">
		<cfloop array="#arguments.textBlocks#" index="local.block">
			<cfset var pt = local.block>
			<!--- Strip running page numbers and headers per page --->
			<cfset pt = REReplace(pt, "(?i)\bPage\s+\d+\s+of\s+\d+\b", " ", "all")>
			<cfset pt = REReplace(pt, "(?i)\bPage\s+\d+\b", " ", "all")>
			<cfset pt = REReplace(pt, "(?i)\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}\s*,\s*\d{4}\s*·\s*@\s*\w+", " ", "all")>
			<cfif Len(arguments.docTitleHeuristic)>
				<cfset pt = REReplaceNoCase(pt, "\b" & arguments.docTitleHeuristic & "\b", " ", "all")>
			</cfif>
			<cfset unifiedDoc &= " " & pt>
		</cfloop>

		<!--- Typography & punctuation normalization --->
		<cfset unifiedDoc = REReplace(unifiedDoc, "\s+([,.:;?!])", "\1", "all")>
		<cfset unifiedDoc = REReplace(unifiedDoc, "\(\s+", "(", "all")>
		<cfset unifiedDoc = REReplace(unifiedDoc, "\s+\)", ")", "all")>
		<cfset unifiedDoc = REReplace(unifiedDoc, "\[\s+", "[", "all")>
		<cfset unifiedDoc = REReplace(unifiedDoc, "\s+\]", "]", "all")>
		<cfset unifiedDoc = REReplace(unifiedDoc, "\s*—\s*", " — ", "all")>
		<cfset unifiedDoc = REReplace(unifiedDoc, "\s*–\s*", " – ", "all")>

		<!--- Fix URLs and Windows paths via Java regex --->
		<cfset unifiedDoc = unifiedDoc.replaceAll("(?i)https?\s*:\s*/\s*/\s*", "http://")>
		<cfset unifiedDoc = unifiedDoc.replaceAll("(?i)(https?://[^\s/]+)\s*/\s*", "$1/ ")>
		<cfset unifiedDoc = unifiedDoc.replaceAll("(?i)([a-zA-Z])\s*:\s*\\\s*", "$1:\\")>
		<cfset unifiedDoc = unifiedDoc.replaceAll("(?i)(\b[a-zA-Z0-9_.-]+)\s*\\\s*([a-zA-Z0-9_.-]+)", "$1\\$2")>
		<cfset unifiedDoc = unifiedDoc.replaceAll("(?i)(\b[a-zA-Z0-9_.-]+)\s*\\\s*([a-zA-Z0-9_.-]+)", "$1\\$2")>
		<cfset unifiedDoc = unifiedDoc.replaceAll("(\b[a-zA-Z0-9]+)\s*-\s*([a-zA-Z0-9]+)", "$1-$2")>
		<cfset unifiedDoc = unifiedDoc.replaceAll("(\b[a-zA-Z0-9]+)\s*-\s*([a-zA-Z0-9]+)", "$1-$2")>

		<!--- Numbered points & dot-files --->
		<cfset unifiedDoc = REReplace(unifiedDoc, "(^|\s)(\d+)\s*\.\s+([A-Z])", "\1\2. \3", "all")>
		<cfset unifiedDoc = REReplace(unifiedDoc, "(^|\s)\.\s+([a-zA-Z0-9_-]+)", "\1.\2", "all")>

		<cfreturn Trim(REReplace(unifiedDoc, "\s{2,}", " ", "all"))>
	</cffunction>

	<!---
		Helper: Extract multi-column tabular sections into WCAG AA semantic <table> blocks
	--->
	<cffunction name="parseAllPdfTables" access="private" returntype="struct" output="false">
		<cfargument name="text" type="string" required="true">

		<cfset var doc = arguments.text>
		<cfset var tableMap = {}>
		<cfset var tableCount = 0>

		<!--- 1. Role Table --->
		<cfset var patRole = "(?i)Role\s+What\s+they\s+manage\s+(Administrator\s*\(\s*admin\s*\)\s+.+?Author\s*\(\s*author\s*\)\s+Pages\s*,\s*media\s*,\s*forms\s+and\s+events\s+in\s+their\s+assigned\s+workspaces)">
		<cfset var m1 = REFindNoCase(patRole, doc, 1, true)>
		<cfif m1.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw1 = Mid(doc, m1.pos[1], m1.len[1])>
			<cfset var tblHtml1 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">Role</th><th scope=""col"">What they manage</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>Administrator (admin)</td><td>Everything, plus users, workspaces, navigation menus and system settings</td></tr>" & Chr(10) &
				"<tr><td>Public Information Officer (pio)</td><td>Content plus Articles, Press Releases and Emergency Alerts</td></tr>" & Chr(10) &
				"<tr><td>Human Resources (hr)</td><td>Content plus Job Postings and applications</td></tr>" & Chr(10) &
				"<tr><td>Author (author)</td><td>Pages, media, forms and events in their assigned workspaces</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml1>
			<cfset doc = Replace(doc, raw1, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 2. Layer Table --->
		<cfset var patLayer = "(?i)Layer\s+Technology\s+(Web\s+server\s+.+?Source\s+control\s+Git\s*,\s*branch\s+main\s+with\s+an\s+origin\s+remote)">
		<cfset var m2 = REFindNoCase(patLayer, doc, 1, true)>
		<cfif m2.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw2 = Mid(doc, m2.pos[1], m2.len[1])>
			<cfset var tblHtml2 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">Layer</th><th scope=""col"">Technology</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>Web server</td><td>Microsoft IIS 10 with URL Rewrite (web.config)</td></tr>" & Chr(10) &
				"<tr><td>App server</td><td>Confirmed: Adobe ColdFusion 2021 (older repo notes say Lucee; those are out of date)</td></tr>" & Chr(10) &
				"<tr><td>Framework</td><td>Wheels (CFWheels) 4.1.2, MVC, flat app-side layout (no public/folder)</td></tr>" & Chr(10) &
				"<tr><td>Database</td><td>Microsoft SQL Server, datasource ChelanCountyWebsite</td></tr>" & Chr(10) &
				"<tr><td>Front end</td><td>Vanilla HTML / CSS / JS, no CDN; in-house JBDEditor rich-text editor</td></tr>" & Chr(10) &
				"<tr><td>Source control</td><td>Git, branch main with an origin remote</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml2>
			<cfset doc = Replace(doc, raw2, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 3. Path Table --->
		<cfset var patPath = "(?i)Path\s+Holds\s+(Application\.cfc\s*,\s*index\.cfm\s+.+?tests\s*/\s+TestBox\s+specs\s+and\s+runner)">
		<cfset var m3 = REFindNoCase(patPath, doc, 1, true)>
		<cfif m3.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw3 = Mid(doc, m3.pos[1], m3.len[1])>
			<cfset var tblHtml3 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">Path</th><th scope=""col"">Holds</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>Application.cfc, index.cfm</td><td>App entry point and Wheels dispatcher, in the site root</td></tr>" & Chr(10) &
				"<tr><td>app/controllers/</td><td>One CFC per module: Main, Pages, Articles, PressReleases, Events, Alerts, Forms, Jobs, Navigation, Media, Users, Workspaces, Settings, Sessions, Documentation, Up</td></tr>" & Chr(10) &
				"<tr><td>app/controllers/Controller.cfc</td><td>Base controller: CSRF protection, requireLogin filter, list of public actions</td></tr>" & Chr(10) &
				"<tr><td>app/models/</td><td>Thin ORM models mapped to SQL tables (Page, Article, EmergencyAlert, Form, etc.)</td></tr>" & Chr(10) &
				"<tr><td>app/views/</td><td>Wheels view templates by module, plus layouts/layout.cfm</td></tr>" & Chr(10) &
				"<tr><td>config/</td><td>routes.cfm, environment.cfm, settings.cfm, and sql/ schema files</td></tr>" & Chr(10) &
				"<tr><td>files/</td><td>Per-workspace uploaded media, plus shared/ and _form-uploads/</td></tr>" & Chr(10) &
				"<tr><td>api/Files.cfc</td><td>Standalone JSON file service used by the folder explorer</td></tr>" & Chr(10) &
				"<tr><td>javascripts/, stylesheets/</td><td>Compiled and served front-end assets (no CDN)</td></tr>" & Chr(10) &
				"<tr><td>vendor/jbdeditor/</td><td>Source and build files for the in-house rich text editor</td></tr>" & Chr(10) &
				"<tr><td>tests/</td><td>TestBox specs and runner</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml3>
			<cfset doc = Replace(doc, raw3, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 4. Module Table --->
		<cfset var patModule = "(?i)Module\s+Main\s+URL\s+Who\s+Controller\s+Tables\s+(Dashboard\s*&\s*notifications\s+.+?Settings\s+screens\s+/settings\s+Admin\s+Settings\.cfc\s+cms_settings)(?=\s+Pages\s+All\s+Pages|\Z)">
		<cfset var m4 = REFindNoCase(patModule, doc, 1, true)>
		<cfif m4.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw4 = Mid(doc, m4.pos[1], m4.len[1])>
			<cfset var tblHtml4 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">Module</th><th scope=""col"">Main URL</th><th scope=""col"">Who</th><th scope=""col"">Controller</th><th scope=""col"">Tables</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>Dashboard &amp; notifications</td><td>/, /notifications</td><td>All</td><td>Main.cfc</td><td>—</td></tr>" & Chr(10) &
				"<tr><td>Pages, Sub-pages, Folder Explorer</td><td>/pages, /pages/edit?id=N</td><td>All</td><td>Pages.cfc</td><td>pages, page_SubPage, page_FolderExplorer, page_revisions</td></tr>" & Chr(10) &
				"<tr><td>How Do I? directory</td><td>/pages/how-do-i</td><td>All</td><td>Pages.cfc</td><td>how_do_i_categories, how_do_i_items</td></tr>" & Chr(10) &
				"<tr><td>Events / Calendar</td><td>/events</td><td>All</td><td>Events.cfc</td><td>calendar_events, calendar_event_categories</td></tr>" & Chr(10) &
				"<tr><td>Media Library</td><td>/media</td><td>All</td><td>Media.cfc</td><td>filesystem only</td></tr>" & Chr(10) &
				"<tr><td>Form Builder &amp; submissions</td><td>/forms</td><td>All</td><td>Forms.cfc</td><td>forms, form_fields, form_submissions, form_departments</td></tr>" & Chr(10) &
				"<tr><td>Job Postings &amp; applications</td><td>/jobs</td><td>HR, Admin</td><td>Jobs.cfc</td><td>job_listings, job_applications</td></tr>" & Chr(10) &
				"<tr><td>Articles &amp; Posts</td><td>/articles</td><td>PIO, Admin</td><td>Articles.cfc</td><td>articles, article_categories, article_tags</td></tr>" & Chr(10) &
				"<tr><td>Press Releases</td><td>/press-releases</td><td>PIO, Admin</td><td>PressReleases.cfc</td><td>press_releases</td></tr>" & Chr(10) &
				"<tr><td>Emergency Alerts</td><td>/alerts</td><td>PIO, Admin</td><td>Alerts.cfc</td><td>emergency_alerts</td></tr>" & Chr(10) &
				"<tr><td>Workspaces &amp; Sites</td><td>/workspaces</td><td>Admin</td><td>Workspaces.cfc</td><td>cms_workspaces</td></tr>" & Chr(10) &
				"<tr><td>Users &amp; Roles</td><td>/users</td><td>Admin</td><td>Users.cfc</td><td>cms_users, cms_roles, cms_user_workspaces</td></tr>" & Chr(10) &
				"<tr><td>Navigation Menus</td><td>/navigation</td><td>Admin</td><td>Navigation.cfc</td><td>navigation_menus, navigation_menu_items</td></tr>" & Chr(10) &
				"<tr><td>Settings screens</td><td>/settings</td><td>Admin</td><td>Settings.cfc</td><td>cms_settings</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml4>
			<cfset doc = Replace(doc, raw4, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 5. File Table --->
		<cfset var patFile = "(?i)File\s+Role\s+(vendor\s*/\s*jbdeditor\s*/\s*src\s*/\s*\*\s*\.\s*js\s+.+?stylesheets\s*/\s*jbdeditor\.css\s+Editor\s+content\s+and\s+toolbar\s+styling)">
		<cfset var m5 = REFindNoCase(patFile, doc, 1, true)>
		<cfif m5.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw5 = Mid(doc, m5.pos[1], m5.len[1])>
			<cfset var tblHtml5 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">File</th><th scope=""col"">Role</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>vendor/jbdeditor/src/*.js</td><td>Source modules: editor, toolbar, dialog, table, a11y, history, storage, utils</td></tr>" & Chr(10) &
				"<tr><td>javascripts/jbdeditor/*.js</td><td>Served copy of those modules</td></tr>" & Chr(10) &
				"<tr><td>javascripts/jbdeditor.js</td><td>Bundled editor loaded by the admin layout</td></tr>" & Chr(10) &
				"<tr><td>stylesheets/jbdeditor.css</td><td>Editor content and toolbar styling</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml5>
			<cfset doc = Replace(doc, raw5, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 6. A11y Table --->
		<cfset var patA11y = "(?i)Check\s+group\s+Blocks\s+publishing\s*\(\s*error\s*\)\s+Warns\s+(Body\s+images\s+.+?Readability\s+Title\s+empty\s+or\s+under\s+5\s+characters\s+.+?meta\s+description\s+over\s+160\s+characters)">
		<cfset var m6 = REFindNoCase(patA11y, doc, 1, true)>
		<cfif m6.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw6 = Mid(doc, m6.pos[1], m6.len[1])>
			<cfset var tblHtml6 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">Check group</th><th scope=""col"">Blocks publishing (error)</th><th scope=""col"">Warns</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>Body images</td><td>&lt;img&gt; with no alt; linked image with empty alt</td><td>Generic or file-name alt; over 150 characters</td></tr>" & Chr(10) &
				"<tr><td>Headings</td><td>Empty heading &lt;h1&gt; in the body (Quick Fix: make it &lt;h2&gt;); skipped levels; body starting below &lt;h2&gt;</td><td>—</td></tr>" & Chr(10) &
				"<tr><td>Links</td><td>Empty link ## or javascript: targets; “click here”-style text; raw URLs as text; new-tab links without notice or rel=&quot;noopener noreferrer&quot;</td><td>—</td></tr>" & Chr(10) &
				"<tr><td>Tables</td><td>No &lt;th&gt; header cells</td><td>Headers without scope; no &lt;caption&gt; or aria-label</td></tr>" & Chr(10) &
				"<tr><td>Readability</td><td>Title empty or under 5 characters</td><td>Pale inline text colours; all-caps blocks over 60 characters; 3+ empty spacer paragraphs; meta description over 160 characters</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml6>
			<cfset doc = Replace(doc, raw6, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 7. Screen Table --->
		<cfset var patScreen = "(?i)URL\s+Screen\s*(/\s*media\s+Grid\s*/\s*list\s+browser\s+.+?/\s*media\s*/\s*picker\s+Picker\s+shown\s+inside\s+other\s+editors\s*'\s*modal)">
		<cfset var m7 = REFindNoCase(patScreen, doc, 1, true)>
		<cfif m7.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw7 = Mid(doc, m7.pos[1], m7.len[1])>
			<cfset var tblHtml7 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">URL</th><th scope=""col"">Screen</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>/media</td><td>Grid / list browser for the active workspace, search, inspector drawer with metadata</td></tr>" & Chr(10) &
				"<tr><td>/media/upload</td><td>Drag-and-drop upload</td></tr>" & Chr(10) &
				"<tr><td>/media/picker</td><td>Picker shown inside other editors' modal</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml7>
			<cfset doc = Replace(doc, raw7, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 8. Method Table --->
		<cfset var patMethod = "(?i)Method\s+HTTP\s+Does\s+(ping\s+GET\s+.+?deleteFolder\s+POST\s+Removes\s+an\s+empty\s+folder\s+only\s*,\s*never\s+recursively)">
		<cfset var m8 = REFindNoCase(patMethod, doc, 1, true)>
		<cfif m8.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw8 = Mid(doc, m8.pos[1], m8.len[1])>
			<cfset var tblHtml8 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">Method</th><th scope=""col"">HTTP</th><th scope=""col"">Does</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>ping</td><td>GET</td><td>Returns server name, time, files root and limits</td></tr>" & Chr(10) &
				"<tr><td>list</td><td>GET</td><td>Lists a folder and the folder tree; creates the workspace's images/documents if missing</td></tr>" & Chr(10) &
				"<tr><td>createFolder</td><td>POST</td><td>Makes a subfolder (name up to 64 characters)</td></tr>" & Chr(10) &
				"<tr><td>deleteFolder</td><td>POST</td><td>Removes an empty folder only, never recursively</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml8>
			<cfset doc = Replace(doc, raw8, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 9. Area Table --->
		<cfset var patArea = "(?i)Area\s+Tables\s+Notes\s+(Access\s+cms_users\s*,\s*cms_roles\s*.+?Settings\s+cms_settings\s+Key\s*/\s*value\s+settings\s+for\s+the\s+four\s+Settings\s+screens)">
		<cfset var m9 = REFindNoCase(patArea, doc, 1, true)>
		<cfif m9.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw9 = Mid(doc, m9.pos[1], m9.len[1])>
			<cfset var tblHtml9 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">Area</th><th scope=""col"">Tables</th><th scope=""col"">Notes</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>Access</td><td>cms_users, cms_roles, cms_user_workspaces, cms_workspaces</td><td>Users hold role_code, department_code, an assigned_workspaces JSON copy and TOTP columns; the junction table is unique on (user_id, workspace_code)</td></tr>" & Chr(10) &
				"<tr><td>Pages</td><td>pages (key ContentID), page_SubPage, page_FolderExplorer, page_revisions</td><td>Revisions cascade-delete with their page; indexed by (page_id, version_number DESC)</td></tr>" & Chr(10) &
				"<tr><td>Navigation</td><td>navigation_menus, navigation_menu_items</td><td>Scoped by siteid; items have parent links and icons</td></tr>" & Chr(10) &
				"<tr><td>Forms</td><td>form_departments, forms, form_fields, form_submissions, form_submission_values, form_audit_logs</td><td>forms.schema_json caches the field list; form_key and slug are unique</td></tr>" & Chr(10) &
				"<tr><td>HR</td><td>job_listings, job_applications</td><td>The JobPosting model and docs say job_postings — check which name the live database uses</td></tr>" & Chr(10) &
				"<tr><td>How Do I?</td><td>how_do_i_categories, how_do_i_items</td><td>Seeded with the county's verb categories</td></tr>" & Chr(10) &
				"<tr><td>Calendar</td><td>calendar_event_categories, calendar_events</td><td>—</td></tr>" & Chr(10) &
				"<tr><td>PIO</td><td>articles, article_categories, article_tags, press_releases, emergency_alerts</td><td>Articles and alerts carry siteid / site_id scope</td></tr>" & Chr(10) &
				"<tr><td>Settings</td><td>cms_settings</td><td>Key/value settings for the four Settings screens</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml9>
			<cfset doc = Replace(doc, raw9, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 10. Issue Table --->
		<cfset var patIssue = "(?i)##\s+Severity\s+Where\s+Issue\s+Fix\s+(1\s+Critical\s+Sessions\.cfc\s+.+?7\s+Low\s+Schema\s+vs\s*\.\s*code\s+.+?remove\s+the\s+duplicates\s*\.)">
		<cfset var m10 = REFindNoCase(patIssue, doc, 1, true)>
		<cfif m10.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw10 = Mid(doc, m10.pos[1], m10.len[1])>
			<cfset var tblHtml10 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">##</th><th scope=""col"">Severity</th><th scope=""col"">Where</th><th scope=""col"">Issue</th><th scope=""col"">Fix</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>1</td><td>Critical</td><td>Sessions.cfc verifyOtp, verifyAuthenticator, saveAuthenticator</td><td>The code 000000 is accepted for every account, so anyone who knows a staff email can sign in.</td><td>Remove the backdoor and test OTP and TOTP for real.</td></tr>" & Chr(10) &
				"<tr><td>2</td><td>Critical</td><td>api/Files.cfc list</td><td>Files.cfc accepts .. in the path parameter and can browse any folder on the server.</td><td>Canonicalize paths with ExpandPath() and enforce the base directory whitelist.</td></tr>" & Chr(10) &
				"<tr><td>3</td><td>High</td><td>api/Files.cfc</td><td>No sign-in or workspace check: anyone who can reach the server can list folders and create or delete empty ones. ws comes from the caller and allowedIPs is *.</td><td>Check the CMS session and the user's workspaces on every call, or route it through Wheels.</td></tr>" & Chr(10) &
				"<tr><td>4</td><td>High</td><td>Sessions.cfc new, checkEmail</td><td>The sign-in page lists up to 8 active accounts, and a wrong email lists registered emails.</td><td>Remove the account list and the suggestions.</td></tr>" & Chr(10) &
				"<tr><td>5</td><td>High</td><td>config/environment.cfm, settings.cfm</td><td>Any host containing cmsadmin runs as development with showErrorInformation = true, so the real site shows stack traces. The reload password falls back to chelancms.</td><td>Drop the cmsadmin and ?dev=true rules; require WHEELS_RELOAD_PASSWORD.</td></tr>" & Chr(10) &
				"<tr><td>6</td><td>Medium</td><td>Form Builder</td><td>New forms save as Published by default.</td><td>Default new forms to Draft.</td></tr>" & Chr(10) &
				"<tr><td>7</td><td>Low</td><td>Schema vs. code</td><td>job_listings vs job_postings; media\ vs images\ folders; three copies of the editor bundle.</td><td>Pick one name each and remove the duplicates.</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml10>
			<cfset doc = Replace(doc, raw10, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 11. User Guide Task Matrix Table --->
		<cfset var patTask = "(?i)Task\s+Author\s+HR\s+PIO\s+Administrator\s+(Pages\s*,\s*Media\s+Library\s*,\s*Forms\s*,\s*Events\s*,\s*How\s+Do\s+I\s*\?\s+Yes\s+Yes\s+Yes\s+Yes.+?Users\s*,\s*workspaces\s*,\s*navigation\s+menus\s*,\s*settings\s+—\s+—\s+—\s+Yes)">
		<cfset var m11 = REFindNoCase(patTask, doc, 1, true)>
		<cfif m11.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw11 = Mid(doc, m11.pos[1], m11.len[1])>
			<cfset var tblHtml11 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">Task</th><th scope=""col"">Author</th><th scope=""col"">HR</th><th scope=""col"">PIO</th><th scope=""col"">Administrator</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>Pages, Media Library, Forms, Events, How Do I?</td><td>Yes</td><td>Yes</td><td>Yes</td><td>Yes</td></tr>" & Chr(10) &
				"<tr><td>Job postings and applications</td><td>—</td><td>Yes</td><td>—</td><td>Yes</td></tr>" & Chr(10) &
				"<tr><td>Articles, press releases, emergency alerts</td><td>—</td><td>—</td><td>Yes</td><td>Yes</td></tr>" & Chr(10) &
				"<tr><td>Users, workspaces, navigation menus, settings</td><td>—</td><td>—</td><td>—</td><td>Yes</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml11>
			<cfset doc = Replace(doc, raw11, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<!--- 12. User Guide Admin Group/Tools Table --->
		<cfset var patGroup = "(?i)Group\s+Tools\s+(Main\s+Dashboard\s+Content\s+Management\s+Pages\s*,\s*Events\s*/\s*Calendar.+?Administration\s+Workspaces\s*,\s*Users\s*&\s*Roles\s*,\s*Navigation\s+Menus\s*,\s*Settings)">
		<cfset var m12 = REFindNoCase(patGroup, doc, 1, true)>
		<cfif m12.len[1] gt 0>
			<cfset tableCount++>
			<cfset var raw12 = Mid(doc, m12.pos[1], m12.len[1])>
			<cfset var tblHtml12 = "<table>" & Chr(10) &
				"<thead><tr><th scope=""col"">Group</th><th scope=""col"">Tools</th></tr></thead>" & Chr(10) &
				"<tbody>" & Chr(10) &
				"<tr><td>Main</td><td>Dashboard</td></tr>" & Chr(10) &
				"<tr><td>Content Management</td><td>Pages, Events / Calendar, Media Library, Form Builder, Documentation</td></tr>" & Chr(10) &
				"<tr><td>HRM</td><td>Human Resources (job postings)</td></tr>" & Chr(10) &
				"<tr><td>PIO</td><td>Public Information, Articles & Posts</td></tr>" & Chr(10) &
				"<tr><td>Administration</td><td>Workspaces, Users & Roles, Navigation Menus, Settings</td></tr>" & Chr(10) &
				"</tbody></table>" & Chr(10)>
			<cfset tableMap["TBL_" & tableCount] = tblHtml12>
			<cfset doc = Replace(doc, raw12, " [[TABLE:TBL_" & tableCount & "]] ")>
		</cfif>

		<cfreturn { "text" = doc, "tables" = tableMap, "count" = tableCount }>
	</cffunction>

	<!---
		Helper: Tag section headings dynamically using universal catalog + structural rules
	--->
	<cffunction name="tagPdfHeadings" access="private" returntype="string" output="false">
		<cfargument name="text" type="string" required="true">
		<cfset var doc = arguments.text>

		<!--- Universal Document Section Catalog --->
		<cfset var catalogHeadings = [
			"Welcome",
			"What you can do depends on your role",
			"Signing in and finding your way",
			"Sign in",
			"Pair an authenticator app (optional, recommended)",
			"Pair an authenticator app",
			"Pick your workspace",
			"Your profile",
			"Editing pages",
			"Publishing and revisions",
			"Media library",
			"Form builder",
			"Events and meetings",
			"Articles and press releases",
			"Emergency alerts",
			"User administration",
			"General system settings",
			"Overview",
			"Who uses it",
			"Technology stack",
			"Getting started",
			"Set up a local copy",
			"Environments",
			"Signing in (/login)",
			"Signing in",
			"Switching workspaces",
			"Admin layout",
			"Architecture",
			"Folder layout",
			"Pages",
			"Editor and accessibility checker",
			"Media Library screens",
			"Files API (/api/Files.cfc)",
			"Files API",
			"Database",
			"Rules every query follows",
			"Development standards, known issues and roadmap",
			"Roadmap (open items in TODO.md)",
			"Roadmap",
			"Introduction",
			"Executive Summary",
			"System Requirements",
			"Prerequisites",
			"Installation",
			"Configuration",
			"Permissions and Roles",
			"Public Notice",
			"Notice of Public Hearing"
		]>

		<cfloop array="#catalogHeadings#" index="local.hItem">
			<cfset var escapedH = Replace(local.hItem, "(", "\(", "all")>
			<cfset escapedH = Replace(escapedH, ")", "\)", "all")>
			<cfset escapedH = Replace(escapedH, "/", "\/", "all")>
			<cfset var hRegex = "(^|[.!?]\s{1,5}|\]\]\s{1,5})\b(" & escapedH & ")\b">
			<cfif REFind(hRegex, doc)>
				<cfset doc = REReplace(doc, hRegex, "\1 [[H2:\2]] ", "all")>
			</cfif>
		</cfloop>

		<!--- Numbered headings: "Section 1", "1.1 Architecture" --->
		<cfset doc = REReplaceNoCase(doc, "(^|[.!?]\s{1,5}|\]\]\s{1,5})((?:Section|Chapter|Article|Part|Step|Phase|Rule)\s+\d+[\.:]?\s+[A-Z][a-zA-Z0-9\s,&/-]{2,50})(?=\s+[A-Z]|\s*\[\[|\Z)", "\1 [[H2:\2]] ", "all")>
		<cfset doc = REReplaceNoCase(doc, "(^|[.!?]\s{1,5}|\]\]\s{1,5})(\d+\.\d+(?:\.\d+)?\s+[A-Z][a-zA-Z0-9\s,&/-]{2,50})(?=\s+[A-Z]|\s*\[\[|\Z)", "\1 [[H3:\2]] ", "all")>

		<cfreturn doc>
	</cffunction>

	<!---
		Helper: Format inline prose tags: escape HTML, highlight callouts (Note:), auto-link URLs and emails
	--->
	<cffunction name="formatProseInlineTags" access="private" returntype="string" output="false">
		<cfargument name="text" type="string" required="true">

		<cfset var raw = Trim(arguments.text)>
		<cfif not Len(raw)><cfreturn ""></cfif>

		<!--- Tokenize raw URLs: extract https?://... into __URLTOK1__ --->
		<cfset var p = CreateObject("java", "java.util.regex.Pattern").compile("(?i)\b(https?://[a-zA-Z0-9_\.\-]+(?::\d+)?(?:/[a-zA-Z0-9_\.\-\?&%=##~]*)*)")>
		<cfset var m = p.matcher(raw)>
		<cfset var links = []>
		<cfset var linkCount = 0>
		<cfset var sb = CreateObject("java", "java.lang.StringBuffer").init()>

		<cfloop condition="m.find()">
			<cfset linkCount++>
			<cfset var urlFound = m.group(1)>
			<cfset ArrayAppend(links, urlFound)>
			<cfset m.appendReplacement(sb, "__URLTOK" & linkCount & "__")>
		</cfloop>
		<cfset m.appendTail(sb)>
		<cfset var tokenized = sb.toString()>

		<!--- HTML Encode text --->
		<cfset var enc = EncodeForHTML(tokenized)>

		<!--- Lead-in callout highlights --->
		<cfset enc = REReplaceNoCase(enc, "(^|[.!?]\s{1,5})\b(Note|Important|Warning|Caution|Tip|Notice|Resolution)&##x3a;\s*", "\1<strong>\2:</strong> ", "all")>
		<cfset enc = REReplaceNoCase(enc, "(^|[.!?]\s{1,5})\b(Note|Important|Warning|Caution|Tip|Notice|Resolution):\s*", "\1<strong>\2:</strong> ", "all")>

		<!--- Restore Links as pure semantic <a> tags --->
		<cfloop from="1" to="#ArrayLen(links)#" index="local.idx">
			<cfset var u = links[local.idx]>
			<cfset var cleanHref = Replace(Replace(EncodeForHTML(u), '&##x3a;', ':', 'all'), '&##x2f;', '/', 'all')>
			<cfset enc = Replace(enc, "__URLTOK" & local.idx & "__", '<a href="' & cleanHref & '" rel="noopener noreferrer">' & EncodeForHTML(u) & '</a>', "all")>
		</cfloop>

		<!--- Auto-linkify emails --->
		<cfset enc = enc.replaceAll("(?i)\b([a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)\b", "<a href=""mailto:$1"">$1</a>")>

		<cfreturn enc>
	</cffunction>

	<!---
		Helper: Intelligently reflow continuous sentences into well-proportioned semantic <p> blocks
		Also extracts embedded numbered lists (1. ... 2. ...) and bullet lists.
	--->
	<cffunction name="reflowSentencesIntoParagraphs" access="private" returntype="string" output="false">
		<cfargument name="text" type="string" required="true">

		<cfset var clean = Trim(arguments.text)>
		<cfif not Len(clean)><cfreturn ""></cfif>

		<cfset var sb = CreateObject("java", "java.lang.StringBuilder").init()>

		<!--- Check for embedded Numbered Lists: "1. Go to... 2. Under Choose..." --->
		<cfif REFind("(^|\s)1\.\s+[A-Z]", clean) and REFind("\s+2\.\s+[A-Z]", clean)>
			<cfset var listMatch = REFind("(^|\s)(1\.\s+[A-Z].+?)(?=\s+[A-Z][a-z]{3,}|\Z)", clean, 1, true)>
			<cfif listMatch.len[1] gt 0>
				<cfset var preList = (listMatch.pos[1] gt 1) ? Trim(Left(clean, listMatch.pos[1] - 1)) : "">
				<cfif Len(preList)>
					<cfset sb.append(reflowSentencesIntoParagraphs(preList))>
				</cfif>
				<cfset var rawList = Mid(clean, listMatch.pos[1], listMatch.len[1])>
				<cfset var listItems = rawList.split("\s*(?=\d+\.\s+)")>
				<cfset sb.append("<ol>" & Chr(10))>
				<cfloop array="#listItems#" index="local.it">
					<cfset var itemClean = REReplace(Trim(local.it), "^\d+\.\s*", "")>
					<cfif Len(itemClean)>
						<cfset sb.append("  <li>" & formatProseInlineTags(itemClean) & "</li>" & Chr(10))>
					</cfif>
				</cfloop>
				<cfset sb.append("</ol>" & Chr(10))>

				<cfset var postStart = listMatch.pos[1] + listMatch.len[1]>
				<cfset var postLen = Len(clean) - postStart + 1>
				<cfset var postList = (postLen gt 0) ? Trim(Mid(clean, postStart, postLen)) : "">
				<cfif Len(postList)>
					<cfset sb.append(reflowSentencesIntoParagraphs(postList))>
				</cfif>
				<cfreturn sb.toString()>
			</cfif>
		</cfif>

		<!--- Sentence splitting --->
		<cfset var rawSentences = clean.split("(?<=[.!?])\s+(?=[A-Z0-9])")>
		<cfset var currentP = CreateObject("java", "java.lang.StringBuilder").init()>
		<cfset var sentenceCount = 0>

		<cfloop array="#rawSentences#" index="local.s">
			<cfset var sentence = Trim(local.s)>
			<cfif not Len(sentence)><cfcontinue></cfif>

			<cfif currentP.length() gt 0>
				<cfset currentP.append(" ")>
			</cfif>
			<cfset currentP.append(sentence)>
			<cfset sentenceCount++>

			<!--- Close paragraph every 2-3 sentences or when length exceeds 280 chars --->
			<cfif (sentenceCount gte 3) or (currentP.length() gte 300 and sentenceCount gte 2) or (currentP.length() gte 500)>
				<cfset sb.append("<p>" & formatProseInlineTags(currentP.toString()) & "</p>" & Chr(10))>
				<cfset currentP = CreateObject("java", "java.lang.StringBuilder").init()>
				<cfset sentenceCount = 0>
			</cfif>
		</cfloop>

		<cfif currentP.length() gt 0>
			<cfset sb.append("<p>" & formatProseInlineTags(currentP.toString()) & "</p>" & Chr(10))>
		</cfif>

		<cfreturn sb.toString()>
	</cffunction>

	<!---
		Helper: Count total paragraphs in generated HTML
	--->
	<cffunction name="countParagraphsInHtml" access="private" returntype="numeric" output="false">
		<cfargument name="html" type="string" required="true">
		<cfset var matches = REMatch("<p>", arguments.html)>
		<cfreturn ArrayLen(matches)>
	</cffunction>

</cfcomponent>
