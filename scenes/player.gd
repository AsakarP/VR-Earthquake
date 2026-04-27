extends XROrigin3D

@onready var camera = $XRCamera3D 
@export var fall_limit := -3.0 

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
func _process(_delta: float) -> void:
	if camera != null:
		if camera.global_position.y < fall_limit:
			get_tree().reload_current_scene()

func _on_left_hand_button_pressed(name: String) -> void:
	if name == "grip_click":
		var player_menu = get_tree().root.find_child("PlayerMenu", true, false)
		
		if player_menu:
			if player_menu.visible == true:
				player_menu.visible = false
				player_menu.process_mode = Node.PROCESS_MODE_DISABLED
			else:
				player_menu.visible = true
				player_menu.process_mode = Node.PROCESS_MODE_INHERIT
