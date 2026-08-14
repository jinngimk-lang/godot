extends Node
class_name ReferenceComposition

func _ready() -> void:
	call_deferred("_apply")

func _apply() -> void:
	var root := get_parent()
	if root == null:
		return
	var camera := root.get_node_or_null("Camera") as Camera3D
	if camera == null:
		return
	# The reference frames leave breathing room for both forearms and context;
	# the old prototype camera made the vessel fill most of the viewport.
	camera.position = Vector3(0.0,0.82,4.48)
	camera.fov = 40.0
	camera.look_at(Vector3(0.0,0.16,0.0),Vector3.UP)
