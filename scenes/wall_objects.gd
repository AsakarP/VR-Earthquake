extends RigidBody3D

# This function will be called by the earthquake script
func drop_from_wall() -> void:
	freeze = false
	
	# Apply a tiny random push outward
	apply_central_impulse(Vector3(randf_range(-1.0, 1.0), 0, randf_range(0.5, 1.5)))
