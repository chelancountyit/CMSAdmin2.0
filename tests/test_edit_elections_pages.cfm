<cfsetting showdebugoutput="false">
<cfcontent type="text/plain; charset=utf-8">
<cfoutput>
======================================================================
  CHELAN COUNTY CMSADMIN 2.0 — ELECTIONS PAGE EDIT INTEGRITY TEST
======================================================================
Time: #DateFormat(Now(), "yyyy-mm-dd")# #TimeFormat(Now(), "HH:mm:ss")#
</cfoutput>

<!--- Query elections pages --->
<cfquery name="qPages" datasource="ChelanCountyWebsite">
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;
    SELECT ContentID, Title, Permalink, SidebarIDs
    FROM pages
    WHERE SiteID = 'elections'
    ORDER BY ContentID ASC
</cfquery>

<cfset passCount = 0>
<cfset failCount = 0>
<cfset authCfid = "">
<cfset authCftoken = "">

<!--- Establish session via check-email and verify-otp --->
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

<cfloop query="qPages">
    <cfhttp method="GET" url="http://127.0.0.1/pages/edit?id=#qPages.ContentID#" result="resEdit" timeout="10">
        <cfhttpparam type="header" name="Host" value="cmsadmin.chelancounty.gov">
        <cfif Len(authCfid)>
            <cfhttpparam type="cookie" name="CFID" value="#authCfid#">
            <cfhttpparam type="cookie" name="CFTOKEN" value="#authCftoken#">
        </cfif>
        <cfhttpparam type="cookie" name="cmsadmin_workspace" value="elections">
    </cfhttp>

    <cfset isOk = (resEdit.statusCode eq "200 OK" and not FindNoCase("Wheels failed to initialize", resEdit.fileContent) and not FindNoCase("Object of type class java.lang.Integer cannot be used as an array", resEdit.fileContent) and FindNoCase("Edit Page", resEdit.fileContent))>
    <cfif isOk>
        <cfset passCount++>
        <cfoutput>[PASS] Page ID #qPages.ContentID# (#qPages.Title#) - HTTP 200 OK#Chr(10)#</cfoutput>
    <cfelse>
        <cfset failCount++>
        <cfoutput>[FAIL] Page ID #qPages.ContentID# (#qPages.Title#) - Status: #resEdit.statusCode#
#Left(resEdit.fileContent, 300)##Chr(10)#</cfoutput>
    </cfif>
</cfloop>

<cfoutput>
======================================================================
  ELECTIONS PAGES EDIT TEST SUMMARY
======================================================================
Total Pages Tested : #qPages.recordCount#
Passed             : #passCount#
Failed             : #failCount#
======================================================================
</cfoutput>
