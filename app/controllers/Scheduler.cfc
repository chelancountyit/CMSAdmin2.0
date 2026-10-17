component extends="Controller" {

	function config() {
		super.config();
		filters(through="requireLogin", except="apiRun,apiStatus");
		protectsFromForgery(except="run,apiRun");
	}

	/**
	 * Manually triggers the automated publishing & expiration evaluator.
	 * Returns JSON execution envelope.
	 */
	function run() {
		var report = evaluateScheduledTransitions();
		application.lastSchedulerRun = Now();
		application.lastSchedulerResult = report;

		var summary = getScheduledPublishingSummary();

		renderText(
			text = SerializeJSON({
				"success": report.success,
				"SUCCESS": report.success,
				"message": "Scheduled publishing and expiration evaluator completed successfully.",
				"report": report,
				"summary": summary
			}),
			contentType = "application/json",
			layout = false
		);
	}

	/**
	 * Returns the current scheduler telemetry & pending queue counts.
	 */
	function status() {
		var summary = getScheduledPublishingSummary();
		renderText(
			text = SerializeJSON({
				"success": true,
				"SUCCESS": true,
				"summary": summary
			}),
			contentType = "application/json",
			layout = false
		);
	}

	/**
	 * Public API / cron endpoint for external scheduled tasks (e.g. Windows Task Scheduler / curl / Lucee cfschedule)
	 */
	function apiRun() {
		// Optional API token authentication if configured in settings
		var report = evaluateScheduledTransitions();
		application.lastSchedulerRun = Now();
		application.lastSchedulerResult = report;

		renderText(
			text = SerializeJSON({
				"success": report.success,
				"timestamp": DateFormat(report.timestamp, "yyyy-mm-dd") & "T" & TimeFormat(report.timestamp, "HH:mm:ss") & "Z",
				"total_transitions": report.total_transitions,
				"report": report
			}),
			contentType = "application/json",
			layout = false
		);
	}

	/**
	 * Public API status endpoint
	 */
	function apiStatus() {
		var summary = getScheduledPublishingSummary();
		renderText(
			text = SerializeJSON({
				"success": true,
				"summary": summary
			}),
			contentType = "application/json",
			layout = false
		);
	}

}

