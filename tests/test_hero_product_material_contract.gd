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
	var fill_ratio := float(jar.get("fill_height_ratio",0.0))
	if fill_ratio < 0.78 or fill_ratio > 0.88:
		failures.append("HERO_JAR_RED: sauce should fill most of the jar while preserving visible headspace")
	if float(jar.get("headspace_ratio",0.0)) < 0.08:
		failures.append("HERO_JAR_RED: glass jar needs visible clear headspace above sauce")
	if float(jar.get("sauce_radius_ratio",1.0)) > 0.90:
		failures.append("HERO_JAR_RED: sauce volume must sit visibly inside the glass wall")
	if float(jar.get("base_thickness",0.0)) < 0.020:
		failures.append("HERO_JAR_RED: glass jar needs a readable thick base")
	if int(jar.get("highlight_count",0)) < 2:
		failures.append("HERO_JAR_RED: jar needs asymmetric glass reflection bands")
	if String(jar.get("lid_finish","")) != "aged_metal":
		failures.append("HERO_JAR_RED: jar lid must read as metal, not brown plastic")
	if int(jar.get("lid_flute_count",0)) < 16:
		failures.append("HERO_JAR_RED: metal twist lid needs fine vertical grip flutes")
	var sauce_color: Color = jar.get("sauce_color",Color.BLACK)
	if sauce_color.r < 0.48 or sauce_color.g > 0.10:
		failures.append("HERO_JAR_RED: sauce should read warm tomato red rather than a black-red solid")

	var tin: Dictionary = hero.call("material_contract_for_kind","tin_can")
	if String(tin.get("finish","")) != "brushed_tin":
		failures.append("HERO_TIN_RED: tin target needs a readable brushed-tin finish")
	if float(tin.get("body_value",0.0)) < 0.94:
		failures.append("HERO_TIN_RED: tin body must be bright enough to read silver under the warm pantry lights")
	if float(tin.get("metallic",1.0)) > 0.08:
		failures.append("HERO_MATERIAL_RED: tin must not collapse into black metal without an HDR reflection probe")
	if float(tin.get("roughness",1.0)) > 0.24:
		failures.append("HERO_TIN_RED: brushed tin needs a sharper asymmetric highlight than grey cement")
	if float(tin.get("rim_value",1.0)) > 0.90 or float(tin.get("rim_value",0.0)) < 0.70:
		failures.append("HERO_TIN_RED: rolled seams should read as mid-silver metal, not white plastic hoops")
	if int(tin.get("highlight_count",0)) < 3:
		failures.append("HERO_TIN_RED: cylindrical tin needs at least three reflection bands")
	if int(tin.get("brush_band_count",0)) < 5:
		failures.append("HERO_TIN_RED: bare tin needs subtle circumferential manufacturing bands")
	if String(tin.get("brush_band_geometry","")) != "open_shell":
		failures.append("HERO_TIN_RED: brush bands must be uncapped shell rings; capped cylinders become stacked plates")

	var can: Dictionary = hero.call("material_contract_for_kind","soda_can")
	if String(can.get("finish","")) != "bare_aluminum":
		failures.append("HERO_CAN_RED: target can is bare aluminum beneath the yellow paper label, not teal paint")
	var body_color: Color = can.get("body_color",Color.BLACK)
	var channel_span := maxf(body_color.r,maxf(body_color.g,body_color.b))-minf(body_color.r,minf(body_color.g,body_color.b))
	if minf(body_color.r,minf(body_color.g,body_color.b)) < 0.92 or channel_span > 0.04:
		failures.append("HERO_CAN_RED: aluminum body must be bright near-neutral so warm/cool lights cannot turn it blue")
	if float(can.get("metallic",1.0)) > 0.12:
		failures.append("HERO_CAN_RED: aluminum body must remain readable without an HDR reflection probe")
	if float(can.get("roughness",1.0)) > 0.19:
		failures.append("HERO_CAN_RED: beverage can needs a crisp coated-aluminum highlight")
	if int(can.get("highlight_count",0)) < 3:
		failures.append("HERO_CAN_RED: can needs multiple neutral reflection strips to read metallic")
	if not bool(can.get("top_structure",false)):
		failures.append("HERO_CAN_RED: bare can needs visible top disk, rolled rim and pull-tab structure")
	if not bool(can.get("condensation",false)):
		failures.append("HERO_CAN_RED: cold beverage can target requires visible condensation")
	hero.free()
	return failures
