extends RigidBody3D

@export var break_intensity_threshold := 4.5 

# Custom push settings
@export_group("Fall Physics")
@export var push_outward_min := 0.1
@export var push_outward_max := 0.5
@export var push_sideways_variance := 0.2

@onready var wall_joint = get_node_or_null("Generic6DOFJoint3D")

var has_fallen := false

# The earthquake script will pass its intensity into this function
func check_earthquake_stress(current_intensity: float) -> void:
	# If the quake is strong enough, snap the joint!
	if current_intensity >= break_intensity_threshold:
		snap_and_fall()

func snap_and_fall() -> void:
	# Prevent this from running multiple times
	if has_fallen:
		return
	has_fallen = true

	# 1. THE SNAP: Destroy the physical joint connecting it to the wall
	if wall_joint != null:
		wall_joint.queue_free() 
	
	# 2. Apply a tiny random push outward so it clears the wall
	var side_push = randf_range(-push_sideways_variance, push_sideways_variance)
	var forward_push = randf_range(push_outward_min, push_outward_max)
	
	apply_central_impulse(Vector3(side_push, 0, forward_push))
