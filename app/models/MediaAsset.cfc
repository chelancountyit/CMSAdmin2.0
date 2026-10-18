component extends="Model" {

	function config() {
		table("media_assets");
		validatesPresenceOf(properties="site_id,folder,filename,file_path,web_url");
	}

}

