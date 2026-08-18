extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/hero_product_detail_presentation.gd"
	if not ResourceLoader.exists(path):
		return ["HERO_DETAIL_RED: missing manufactured hero detail presentation"]
	var root := Node3D.new()
	var product := ProductPresentation.new()
	product.name = "ProductPresentation"
	root.add_child(product)
	var hero = load(path).new()
	hero.name = "HeroProductDetailPresentation"
	root.add_child(hero)

	var cases := [
		[{"kind":"sauce_jar"},["JarHeroShell","JarSauceVolume","JarHeroLid","JarThreadBand0"]],
		[{"kind":"tin_can"},["TinHeroBody","TinHeroTopRoll","TinHeroBottomRoll","TinHeroTopDisk"]],
		[{"kind":"soda_can"},["SodaHeroBody","SodaHeroTopRoll","SodaHeroBottomRoll","SodaHeroTopDisk","SodaPullTab"]]
	]
	for pair in cases:
		var profile: Dictionary = pair[0]
		product.apply_profile(profile)
		hero.call("_bind")
		hero.call("_process",0.0)
		var detail_root := hero.get_node_or_null("HeroProductDetails") as Node3D
		if detail_root == null:
			failures.append("HERO_DETAIL_RED: missing HeroProductDetails root")
			continue
		for node_name in pair[1]:
			var node := detail_root.get_node_or_null(String(node_name)) as MeshInstance3D
			if node == null or node.mesh == null or node.material_override == null:
				failures.append("HERO_DETAIL_RED: %s missing manufactured detail %s" % [String(profile.kind),String(node_name)])
		if String(profile.kind) == "sauce_jar":
			var base := product.get_node_or_null("JarGlass") as VisualInstance3D
			if base == null or base.visible:
				failures.append("HERO_DETAIL_RED: primitive JarGlass must be hidden behind the lathed hero jar")
		if String(profile.kind) == "tin_can":
			var base := product.get_node_or_null("TinCanBody") as VisualInstance3D
			if base == null or base.visible:
				failures.append("HERO_DETAIL_RED: primitive TinCanBody must be hidden behind the manufactured tin")
		if String(profile.kind) == "soda_can":
			var base := product.get_node_or_null("SodaCanBody") as VisualInstance3D
			if base == null or base.visible:
				failures.append("HERO_DETAIL_RED: primitive SodaCanBody must be hidden behind the manufactured soda can")

	root.free()
	return failures
