component extends="Controller" {

	function config() {
		super.config();
	}

	function index() {
		variables.pageTitle = "Documentation & Help Center";
	}

	function userGuide() {
		variables.pageTitle = "CMSAdmin 2.0 User Guide (PDF)";
		variables.pdfUrl = "/miscellaneous/docs/CMSAdmin-2.0-User-Guide.pdf";
		variables.systemDocUrl = "/miscellaneous/docs/CMSAdmin-2.0-Documentation.pdf";
	}

	function formBuilder() {
		variables.pageTitle = "Form Builder Guide for Beginners";
	}

	function editor() {
		variables.pageTitle = "Rich Text Editor (JBDEditor) Guide & Demo";
	}

	function ocrCrawler() {
		variables.pageTitle = "Media OCR Content Detection & Folder Auto-Compliance Guide";
	}

	function startup() {
		variables.pageTitle = "Startup & Front-End Styles (jbd-templates.css)";
		var cssPath = expandPath("/stylesheets/jbd-templates.css");
		variables.jbdTemplateCssContent = "";
		if (fileExists(cssPath)) {
			variables.jbdTemplateCssContent = fileRead(cssPath);
		}
	}

}
