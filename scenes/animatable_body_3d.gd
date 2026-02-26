extends AnimatableBody3D

# Expose these variables to the Inspector so you can tweak the earthquake easily
@export var max_shake_offset := Vector3(0.5, 0.2, 0.5) # How far it moves (X, Y, Z)
@export var shake_speed := 15.0 # How fast the noise generates
@export var trauma := 0.0 # The current intensity of the earthquake (0.0 to 1.0)

var noise: FastNoiseLite
var time_passed := 0.0
var initial_position: Vector3

func _ready() -> void:
	# Save the starting position so the room doesn't drift away forever
	initial_position = global_position
	
	# Initialize the noise generator
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi() # Randomize the shake pattern every time you play

func _physics_process(delta: float) -> void:
	# Only calculate the math if the earthquake is actually happening
	if trauma > 0.0:
		time_passed += delta * shake_speed
		
		# Calculate the shake intensity (squaring it makes the build-up feel more organic)
		var shake = trauma * trauma
		
		# Generate smooth noise values for each axis (between -1.0 and 1.0)
		# We sample different coordinates in the noise to ensure X, Y, and Z act independently
		var offset_x = max_shake_offset.x * shake * noise.get_noise_2d(time_passed, 0.0)
		var offset_y = max_shake_offset.y * shake * noise.get_noise_2d(0.0, time_passed)
		var offset_z = max_shake_offset.z * shake * noise.get_noise_2d(time_passed, time_passed)
		
		# Apply the new position
		global_position = initial_position + Vector3(offset_x, offset_y, offset_z)
		
		# Optional: Slowly decrease trauma over time so the earthquake naturally stops
		trauma = move_toward(trauma, 0.0, delta * 0.2) 
	else:
		# Snap back to the exact starting position when the quake is completely over
		global_position = initial_position
		time_passed = 0.0
