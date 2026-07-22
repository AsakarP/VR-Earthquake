extends XROrigin3D

@onready var camera = $XRCamera3D 
@export var fall_limit := -3.0 

var hit_history: Array[String] = []
var obj_count := 0
var entered_safe := false
var entered_hazard := false
var entered_zone := ""

var reaction_time := 0.0
var is_timing := false

var is_menu_locked := false

func _ready() -> void:
	# 1. Save the exact global spawn point the moment the scene loads
	# before the VR headset has a chance to move anything!
	var target_spawn_pos = global_position
	
	await get_tree().create_timer(0.1).timeout
	
	if camera != null:
		# 2. Fix the Rotation (Spin the world)
		var camera_yaw = camera.transform.basis.get_euler().y
		rotate_y(-camera_yaw)
		
		# 3. Fix the Position (Using GLOBAL coordinates)
		# Find out exactly where their actual head ended up AFTER the spin
		var current_head_pos = camera.global_position
		
		# Calculate the exact distance between their head and the target spawn
		var offset_x = target_spawn_pos.x - current_head_pos.x
		var offset_z = target_spawn_pos.z - current_head_pos.z
		
		# Slide the Origin by that exact distance on the X and Z axes
		global_position.x += offset_x
		global_position.z += offset_z

# The Fall Boundary (Kill Z) remains the same
func _process(delta: float) -> void:
	if is_timing:
		reaction_time += delta
		
	if camera != null:
		if camera.global_position.y < fall_limit:
			get_tree().reload_current_scene()

func start_reaction_timer() -> void:
	is_timing = true
	reaction_time = 0.0
	entered_safe = false
	entered_hazard = false
	entered_zone = ""

func lock_menu() -> void:
	is_menu_locked = true
	
func unlock_menu() -> void:
	is_menu_locked = false

func _on_left_hand_button_pressed(node_name: String) -> void:
	if node_name == "grip_click":
		if is_menu_locked:
			return
		var player_menu = get_tree().root.find_child("PlayerMenu", true, false)
		
		if player_menu:
			if player_menu.visible == true:
				player_menu.visible = false
				player_menu.process_mode = Node.PROCESS_MODE_DISABLED
			else:
				player_menu.visible = true
				player_menu.process_mode = Node.PROCESS_MODE_INHERIT

func _on_player_head_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		if body.freeze == true:
			return
		var obj_name = body.name
		obj_count += 1
		hit_history.append(obj_name)
		
		var earthquake_node = get_node_or_null("../KelasModel/ClassroomStructure")
		if earthquake_node and earthquake_node.has_method("end_simulation_early"):
			earthquake_node.end_simulation_early()

func _on_under_table_body_entered(body: Node3D) -> void:
	if body is XRToolsPlayerBody:
		if not entered_safe:
			entered_safe = true
			entered_zone = "Under Table"
			is_timing = false
			print("SUCCESS: Player reached cover in ", reaction_time, " seconds.")

func _on_near_window_right_body_entered(body: Node3D) -> void:
	if body is XRToolsPlayerBody:
		if not entered_hazard:
			entered_hazard = true
			entered_zone = "Near Window Right"
			is_timing = false
			print("DANGER: Player entered hazard zone in ", reaction_time, " seconds.")

func _on_near_window_left_body_entered(body: Node3D) -> void:
	if body is XRToolsPlayerBody:
		if not entered_hazard:
			entered_hazard = true
			entered_zone = "Near Window Left"
			is_timing = false
			print("DANGER: Player entered hazard zone in ", reaction_time, " seconds.")

func _on_under_ceiling_lights_body_entered(body: Node3D) -> void:
	if body is XRToolsPlayerBody:
		if not entered_hazard:
			entered_hazard = true
			entered_zone = "Under Ceiling Lights"
			is_timing = false
			print("DANGER: Player entered hazard zone in ", reaction_time, " seconds.")
