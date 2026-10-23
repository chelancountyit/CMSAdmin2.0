<cfscript>
	/*
		Use this file to set variables for the Application.cfc's "this" scope.

		Examples:
		this.name = "MyAppName";
		this.sessionTimeout = CreateTimeSpan(0,0,5,0);
	*/
	this.name = "CMSAdmin_" & Hash(this.wheels.rootPath);
	this.sessionTimeout = CreateTimeSpan(1,0,0,0); // 24 hour session timeout (plus 30-day Remember Me cookie support)

	// CLI-Appends-Here
</cfscript>
