extends RigidBody3D

@onready var light_node = get_node_or_null("OmniLight3D")
@onready var tube_mesh1 = get_node_or_null("MeshInstance3D")
@onready var tube_mesh2 = get_node_or_null("MeshInstance3D2")

# This function will be called by the earthquake script
func drop_from_wall() -> void:
	# Unfreeze mounted objects
	freeze = false
	
	# Apply a tiny random push outward
	apply_central_impulse(Vector3(randf_range(-1.0, 1.0), 0, randf_range(0.5, 1.5)))
	
	# (For Falling Lights)
	# Turn off light source
	if light_node != null:
		light_node.visible = false
	
	# Turn off emission on glowing meshes
	if tube_mesh1 != null:
		var current_mat = tube_mesh1.get_active_material(0)
	
		if current_mat != null:
			# Duplicate the material
			var broken_mat = current_mat.duplicate()
			# Turn off emission on the duplicated material
			broken_mat.emission_enabled = false
			# Apply material to the mesh on the ceilling lights
			tube_mesh1.set_surface_override_material(0, broken_mat)
			if tube_mesh2 != null:
				tube_mesh2.set_surface_override_material(0, broken_mat)
