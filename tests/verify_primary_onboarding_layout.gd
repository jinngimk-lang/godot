extends SceneTree

const HUD_WIDTH_LIMIT := 900.0
const VIEWPORT_WIDTH := 1280.0
const RIGHT_MARGIN := 20.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("PRIMARY_ONBOARDING_VERIFY: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	if hud == null:
		push_error("PRIMARY_ONBOARDING_VERIFY: HUD/Instructions missing")
		quit(1)
		return

	if not _check_device_neutral_and_fit(hud, "initial"):
		quit(1)
		return

	scene.call("_update_hud", "EDGE_HOVER", "ATTACHED", 0.0)
	await process_frame
	if not _check_device_neutral_and_fit(hud, "edge hover"):
		quit(1)
		return

	# Pause copy is a separate control-state instruction. Device-neutral onboarding
	# must not overwrite or bloat it, and the existing reset/restart affordances
	# must remain readable.
	scene.set("_paused", true)
	scene.call("_update_hud", "IDLE", "ATTACHED", 0.0)
	await process_frame
	var pause_text := hud.text
	if not pause_text.contains("PAUSED") or not pause_text.contains("Esc Resume") or not pause_text.contains("Shift+R Restart Run"):
		push_error("PRIMARY_ONBOARDING_VERIFY: pause copy regressed: %s" % pause_text)
		quit(1)
		return
	if hud.get_minimum_size().x > HUD_WIDTH_LIMIT or hud.position.x + hud.get_minimum_size().x > VIEWPORT_WIDTH - RIGHT_MARGIN:
		push_error("PRIMARY_ONBOARDING_VERIFY: pause HUD exceeds 1280px baseline: min=%.2f pos=%.2f" % [hud.get_minimum_size().x, hud.position.x])
		quit(1)
		return

	print("PASS: PRIMARY onboarding review covers mouse/touch clarity and 1280x720 HUD fit")
	scene.queue_free()
	await process_frame
	quit(0)

func _check_device_neutral_and_fit(hud: Label, context: String) -> bool:
	var text := hud.text.to_lower()
	if not text.contains("mouse") or not text.contains("touch"):
		push_error("PRIMARY_ONBOARDING_VERIFY: %s copy must mention both mouse and touch: %s" % [context, hud.text])
		return false
	if text.contains("hold left mouse"):
		push_error("PRIMARY_ONBOARDING_VERIFY: %s copy still makes left mouse sound mandatory: %s" % [context, hud.text])
		return false
	var minimum_width := hud.get_minimum_size().x
	if minimum_width > HUD_WIDTH_LIMIT:
		push_error("PRIMARY_ONBOARDING_VERIFY: %s copy exceeds HUD width %.2f > %.2f: %s" % [context, minimum_width, HUD_WIDTH_LIMIT, hud.text])
		return false
	if hud.position.x + minimum_width > VIEWPORT_WIDTH - RIGHT_MARGIN:
		push_error("PRIMARY_ONBOARDING_VERIFY: %s copy exceeds 1280px baseline at x=%.2f width=%.2f" % [context, hud.position.x, minimum_width])
		return false
	print("PRIMARY_ONBOARDING_%s min_width=%.2f text=%s" % [context.to_upper().replace(" ", "_"), minimum_width, hud.text.replace("\n", " | ")])
	return true
