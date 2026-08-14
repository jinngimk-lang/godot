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
	# Reference frames are hand-and-object closeups: the vessel fills roughly
	# half to two-thirds of frame height and the hands are tactile foreground,
	# while the venue remains contextual rather than the main subject.
	camera.position = Vector3(0.0,0.80,3.55)
	camera.fov = 39.0
	camera.look_at(Vector3(0.0,0.15,0.0),Vector3.UP)
