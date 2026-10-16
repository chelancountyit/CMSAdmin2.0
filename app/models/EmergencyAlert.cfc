component extends="Model" {

	function config() {
		table("emergency_alerts");
		validatesPresenceOf(properties="title,message");
	}

}

