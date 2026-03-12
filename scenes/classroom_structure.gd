extends AnimatableBody3D

# Variables to tweak the earthquake
@export var max_shake_offset := Vector3(0.5, 0.2, 0.5) # How far it moves (X, Y, Z)
@export var shake_speed := 15.0 # How fast the noise generates
@export var trauma := 0.0 # The current intensity of the earthquake

var noise: FastNoiseLite
var time_passed := 0.0
var initial_position: Vector3
var has_quake_started := false

func _ready() -> void:
	# Save the starting position of the room
	initial_position = global_position
	
	# Initialize noise generator
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi() # Randomize the shake pattern every play

func _physics_process(delta: float) -> void:
	# Only calculate the math if the earthquake is actually happening
	if trauma > 0.0:
		# If quake started, objects on walls will fall
		if not has_quake_started:
			get_tree().call_group("drop_objects", "drop_from_wall")
			has_quake_started = true
			
		time_passed += delta * shake_speed
		
		# Calculate the shake intensity
		var shake = trauma * trauma
		
		# Generate smooth noise values for each axis
		# sample different coordinates in the noise to ensure X, Y, and Z act independently
		var offset_x = max_shake_offset.x * shake * noise.get_noise_2d(time_passed, 0.0)
		var offset_y = max_shake_offset.y * shake * noise.get_noise_2d(0.0, time_passed)
		var offset_z = max_shake_offset.z * shake * noise.get_noise_2d(time_passed, time_passed)
		
		# Apply the new position
		global_position = initial_position + Vector3(offset_x, offset_y, offset_z)
		
		# Slowly decrease trauma over time so the earthquake naturally stops
		trauma = move_toward(trauma, 0.0, delta * 0.2) 
	else:
		# Snap back to the exact starting position when the quake is completely over
		global_position = initial_position
		time_passed = 0.0
		# If planning for multiple earthquake
		# has_quake_started = false
