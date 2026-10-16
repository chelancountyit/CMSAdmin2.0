component extends="Model" {

	function config() {
		table("cms_settings");
		validatesPresenceOf(properties="setting_key");
		validatesUniquenessOf(properties="setting_key");
	}

}
