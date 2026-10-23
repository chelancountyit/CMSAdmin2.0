<cfscript>
	/*
		Use this file to set variables for the Application.cfc's "this" scope.

		Examples:
		this.name = "MyAppName";
		this.sessionTimeout = CreateTimeSpan(0,0,5,0);
	*/
	this.name = "CMSAdmin_" & Hash(this.wheels.rootPath);
	this.sessionTimeout = CreateTimeSpan(0,1,0,0); // 1 hour session timeout

	// CLI-Appends-Here
</cfscript>
