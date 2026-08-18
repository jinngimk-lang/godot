extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/hero_product_detail_presentation.gd"
	if not ResourceLoader.exists(path):
		return ["HERO_MATERIAL_RED: missing HeroProductDetailPresentation"]
	var hero = load(path).new()
	if not hero.has_method("material_contract_for_kind"):
		hero.free()
		return ["HERO_MATERIAL_RED: hero detail layer needs deterministic material contracts"]
	var jar: Dictionary = hero.call("material_contract_for_kind","sauce_jar")
	if float(jar.get("glass_alpha",1.0)) > 0.08:
		failures.append("HERO_MATERIAL_RED: jar glass should read clear, not milky")
	if float(jar.get("fill_height_ratio",0.0)) < 0.80:
		failures.append("HERO_MATERIAL_RED: jar target needs sauce visibly filling most of the vessel")
	var tin: Dictionary = hero.call("material_contract_for_kind","tin_can")
	if float(tin.get("body_value",0.0)) < 0.82:
		failures.append("HERO_MATERIAL_RED: tin body should stay bright silver in GL rendering")
	if float(tin.get("metallic",1.0)) > 0.22:
		failures.append("HERO_MATERIAL_RED: tin must not collapse into black metal without an HDR reflection probe")
	var can: Dictionary = hero.call("material_contract_for_kind","soda_can")
	var paint: Color = can.get("paint_color",Color.BLACK)
	if paint.g <= paint.r or paint.g <= paint.b*0.85:
		failures.append("HERO_MATERIAL_RED: target beverage can should use a distinct green/teal painted body")
	if float(can.get("metallic",1.0)) > 0.22:
		failures.append("HERO_MATERIAL_RED: painted can body should remain readable instead of mirror-black")
	hero.free()
	return failures
