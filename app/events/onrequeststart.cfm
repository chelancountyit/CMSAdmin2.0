<cfscript>
// Chelan County CMSAdmin 2.0 — Request Start Lifecycle Event
// Automated Publishing & Expiration Evaluator (Throttled to run at most once every 60 seconds)
if (!structKeyExists(application, "schedulerLock")) {
	application.schedulerLock = false;
}

if (!structKeyExists(application, "lastSchedulerRun") || dateDiff("s", application.lastSchedulerRun, Now()) >= 60) {
	if (!application.schedulerLock) {
		application.schedulerLock = true;
		try {
			if (structKeyExists(variables, "evaluateScheduledTransitions") || structKeyExists(getGlobalScope(), "evaluateScheduledTransitions")) {
				application.lastSchedulerResult = evaluateScheduledTransitions();
				application.lastSchedulerRun = Now();
			}
		} catch (any eSched) {
			writeLog(type="error", file="scheduler", text="Auto-evaluator error: #eSched.message# #eSched.detail#");
		} finally {
			application.schedulerLock = false;
		}
	}
}
if (!structKeyExists(application, "workspaceGuardReadyV6")) {
	try {
		structDelete(application, "cmsWorkspacesList");
		structDelete(application, "fbDepartmentsSeeded");
		if (structKeyExists(application, "wheels")) {
			if (structKeyExists(application.wheels, "controllers")) structClear(application.wheels.controllers);
			if (structKeyExists(application.wheels, "integrationPlans")) structClear(application.wheels.integrationPlans);
		}
		if (structKeyExists(application, "$wheels")) {
			if (structKeyExists(application.$wheels, "controllers")) structClear(application.$wheels.controllers);
			if (structKeyExists(application.$wheels, "integrationPlans")) structClear(application.$wheels.integrationPlans);
		}
		application.workspaceGuardReadyV6 = true;
	} catch (any e) {}
}
</cfscript>
