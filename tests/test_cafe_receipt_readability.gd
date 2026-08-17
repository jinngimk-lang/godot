extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var presentation_path := "res://scripts/presentation/cafe_receipt_readability_presentation.gd"
	if not ResourceLoader.exists(presentation_path):
		failures.append("CAFE_RECEIPT_READABILITY_RED: missing Café receipt readability presentation")
		return failures

	var presentation = load(presentation_path).new()
	if not presentation.has_method("configure_front_material") or not presentation.has_method("get_front_paper_bounce") or not presentation.has_method("is_front_paper_bounce_texture_linked"):
		failures.append("CAFE_RECEIPT_READABILITY_RED: thermal receipt needs bounded texture-linked paper bounce")
		presentation.free()
		return failures

	var image := Image.create(2,2,false,Image.FORMAT_RGBA8)
	image.fill(Color(0.97,0.96,0.90,1.0))
	var print_texture := ImageTexture.create_from_image(image)
	var material := StandardMaterial3D.new()
	material.albedo_texture = print_texture

	var cafe_signature := "thermal_paper/0.940/0.920/0.820"
	presentation.configure_front_material(material,cafe_signature)
	var cafe_bounce := float(presentation.get_front_paper_bounce(cafe_signature))
	if cafe_bounce < 0.10 or cafe_bounce > 0.28:
		failures.append("CAFE_RECEIPT_READABILITY_RED: thermal receipt paper bounce must stay subtle and bounded; got %.3f" % cafe_bounce)
	if not bool(presentation.is_front_paper_bounce_texture_linked(material)):
		failures.append("CAFE_RECEIPT_READABILITY_RED: paper bounce must follow the print texture so dark receipt text stays dark")
	if not material.emission_enabled:
		failures.append("CAFE_RECEIPT_READABILITY_RED: thermal receipt front must enable bounded paper bounce")

	var bar_signature := "uncoated_fiber/0.880/1.220/1.350"
	presentation.configure_front_material(material,bar_signature)
	if float(presentation.get_front_paper_bounce(bar_signature)) > 0.001 or material.emission_enabled:
		failures.append("CAFE_RECEIPT_READABILITY_RED: bar fibrous label must not inherit Café paper bounce")

	var market_signature := "coated_citrus/0.660/0.720/0.580"
	presentation.configure_front_material(material,market_signature)
	if float(presentation.get_front_paper_bounce(market_signature)) > 0.001 or material.emission_enabled:
		failures.append("CAFE_RECEIPT_READABILITY_RED: market coated label must not inherit Café paper bounce")

	presentation.free()
	return failures
