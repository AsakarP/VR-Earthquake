extends RigidBody3D

# You can change this number in the Inspector for different objects!
# E.g., a heavy TV might need 6.0, but a small picture frame only needs 4.0
@export var break_magnitude_threshold := 4.5 

@onready var light_node = get_node_or_null("OmniLight3D")
@onready var tube_mesh1 = get_node_or_null("MeshInstance3D")
@onready var tube_mesh2 = get_node_or_null("MeshInstance3D2")
@onready var wall_joint = get_node_or_null("Generic6DOFJoint3D")

# The earthquake script will pass its magnitude into this function
func check_earthquake_stress(current_magnitude: float) -> void:
	# If the quake is strong enough, snap the joint!
	if current_magnitude >= break_magnitude_threshold:
		snap_and_fall()

func snap_and_fall() -> void:
	# Prevent this from running multiple times if it already fell
	if not freeze:
		return

	# 1. THE SNAP: Destroy the physical joint connecting it to the wall
	if wall_joint != null:
		wall_joint.queue_free() 
		
	# 2. Unfreeze so gravity takes over
	freeze = false
	
	# 3. Apply a tiny random push outward so it doesn't slide perfectly down the wall
	apply_central_impulse(Vector3(randf_range(-1.0, 1.0), 0, randf_range(0.5, 1.5)))
	
	# 4. Handle the lighting effects
	if light_node != null:
		light_node.visible = false
	
	if tube_mesh1 != null:
		var current_mat = tube_mesh1.get_active_material(0)
		if current_mat != null:
			var broken_mat = current_mat.duplicate()
			broken_mat.emission_enabled = false
			tube_mesh1.set_surface_override_material(0, broken_mat)
			
			if tube_mesh2 != null:
				tube_mesh2.set_surface_override_material(0, broken_mat)
