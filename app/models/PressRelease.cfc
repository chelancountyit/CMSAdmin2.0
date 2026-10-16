component extends="Model" {

	function config() {
		table("press_releases");
		validatesPresenceOf(properties="title,content_html");
	}

}

