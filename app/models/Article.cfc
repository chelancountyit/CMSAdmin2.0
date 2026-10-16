component extends="Model" {

	function config() {
		table("articles");
		belongsTo(name="category", modelName="ArticleCategory", foreignKey="category_id");
		validatesPresenceOf(properties="title,content_html");
	}

}

