component extends="Model" {

	function config() {
		table("article_categories");
		hasMany(name="articles", modelName="Article", foreignKey="category_id");
		validatesPresenceOf(properties="name,slug");
	}

}

