component extends="Model" {

	function config() {
		table("page_revisions");
		validatesPresenceOf(properties="page_id,title");
	}

}

