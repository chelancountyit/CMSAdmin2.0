component extends="Model" {

	function config() {
		table("article_tags");
		validatesPresenceOf(properties="name,slug");
	}

}

