extends Node
class_name CupContentsRuntimeBridge

var _last_kind := ""
var _presentation: CupContentsPresentation
var _product: ProductPresentation
var _cup: MeshInstance3D

func _ready() -> void:
	call_deferred("_sync")

func _process(_delta: float) -> void:
	_sync()

func _sync() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if _presentation == null:
		_presentation = parent.get_node_or_null("CupContentsPresentation") as CupContentsPresentation
	if _product == null:
		_product = parent.get_node_or_null("ProductPresentation") as ProductPresentation
	if _cup == null:
		_cup = parent.get_node_or_null("Cup") as MeshInstance3D
	if _presentation == null or _product == null:
		return

	var kind := _product.get_active_kind()
	if kind != _last_kind:
		var matched := _variant_for_kind(kind)
		_presentation.set_profile(matched)
		_presentation.reset_visual()
		_last_kind = kind

	# Product inspection rotates the base container independently. Keep contained
	# presentation payload in the exact same object space so ice cannot visually
	# lag behind the bottle/cup during RMB inspection.
	var container := _presentation.get_node_or_null("IceContents") as Node3D
	if container != null and _cup != null:
		container.global_transform = _cup.global_transform

func _variant_for_kind(kind: String) -> Dictionary:
	for variant in SessionModel.VARIANTS:
		var container: Dictionary = variant.get("container_profile", {})
		if String(container.get("kind", "paper_cup")) == kind:
			return variant.duplicate(true)
	return SessionModel.VARIANTS[0].duplicate(true)
