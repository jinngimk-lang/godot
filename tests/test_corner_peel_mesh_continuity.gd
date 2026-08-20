extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var scene := Node3D.new()
	var cup := MeshInstance3D.new()
	cup.name = "Cup"
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.49
	cup_mesh.bottom_radius = 0.415
	cup_mesh.height = 1.40
	cup.mesh = cup_mesh
	cup.position.y = 0.05
	scene.add_child(cup)
	var label := LabelVisual.new()
	label.name = "PeelLabel"
	label.label_width = 0.76
	label.label_height = 0.60
	label.label_y = 0.16
	scene.add_child(label)
	label.call("_ready")
	var print_view := LabelPrint.new()
	print_view.name = "LabelPrint"
	scene.add_child(print_view)
	print_view.call("_ready")
	var corner := CornerPeelPresentation.new()
	corner.name = "CornerPeelPresentation"
	scene.add_child(corner)
	corner.call("_bind")
	var progress := 0.38
	corner.call("_rebuild",progress,Vector3(0.16,0.035,0.12))
	var visible := corner.get_node_or_null("CornerPeelLabel") as MeshInstance3D
	if visible == null or visible.mesh == null:
		failures.append("PAPER_CONTINUITY_RED: mid-peel paper mesh was not built")
	else:
		var mesh := visible.mesh as ArrayMesh
		var printed_surfaces: Array[int] = []
		for surface_index in range(mesh.get_surface_count()):
			var material := mesh.surface_get_material(surface_index)
			if material != null and material.resource_name == "CornerPeelPrintedPaper":
				printed_surfaces.append(surface_index)
		if printed_surfaces.size() != 1:
			failures.append("PAPER_CONTINUITY_RED: printed front must be one continuous sheet, not %d split triangle surfaces" % printed_surfaces.size())
		else:
			var arrays := mesh.surface_get_arrays(printed_surfaces[0])
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var expected := corner.U_SEGMENTS*corner.V_SEGMENTS*6
			if indices.size() != expected:
				failures.append("PAPER_CONTINUITY_RED: continuous printed sheet must cover every grid cell; got %d of %d indices" % [indices.size(),expected])
			var max_edge_length := 0.0
			var max_edge := Vector2i.ZERO
			for index_offset in range(0,indices.size(),3):
				var triangle := [indices[index_offset],indices[index_offset+1],indices[index_offset+2]]
				for edge_index in range(3):
					var first: int = triangle[edge_index]
					var second: int = triangle[(edge_index+1)%3]
					var edge_length := vertices[first].distance_to(vertices[second])
					if edge_length > max_edge_length:
						max_edge_length = edge_length
						max_edge = Vector2i(first,second)
			if max_edge_length > 0.095:
				failures.append("PAPER_STRETCH_RED: mid-peel paper cells must stay bounded; max edge %.3f m at %s reads like elastic film" % [max_edge_length,max_edge])
	if not corner.has_method("set_release_settle"):
		failures.append("PAPER_SETTLE_RED: corner peel presentation needs released-label settle control")
	else:
		var grip_before_settle: Vector3 = corner.get_visual_grip_world_position()
		corner.call("set_release_settle",0.5,0)
		if visible.position.length() < 0.15:
			failures.append("PAPER_SETTLE_RED: released label should visibly move away from the hero")
		if corner.get_visual_grip_world_position().distance_to(grip_before_settle) < 0.15:
			failures.append("PAPER_SETTLE_RED: visible grip position should follow the settling paper mesh")
		if not visible.visible:
			failures.append("released label should remain visible during its settle motion")
		corner.call("set_release_settle",1.0,0)
		if visible.visible:
			failures.append("PAPER_SETTLE_RED: resolved label should stop blocking the hero")
		corner.call("set_release_settle",0.0,0)
		if not visible.visible:
			failures.append("resetting settle progress should restore the paper presentation")
		if visible.position.length() > 0.001:
			failures.append("resetting settle progress should restore the paper origin")
	scene.free()
	return failures
