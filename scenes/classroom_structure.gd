extends AnimatableBody3D

# Admin Mode
@export var is_admin_mode := false

@export_category("Earthquake Settings")
@export var start_delay := 10.0 # How many seconds before the quake hits
@export var magnitude := 1.0 # Overall intensity multiplier
@export var total_duration := 20.0 # How long the quake lasts in seconds
@export var s_wave_delay := 3.0 # Seconds before the heavy rolling hits

@export_group("P-Wave (Vertical Jolt)")
@export var p_wave_amp := 0.05
@export var p_wave_freq := 30.0

@export_group("S-Wave (Horizontal Rolling)")
@export var s_wave_amp := 0.4
@export var s_wave_freq := 6.0

@onready var rumble_audio: AudioStreamPlayer3D = $RumbleAudio
@onready var exit_to_menu = get_node_or_null("../../../../Menus/ExitToMenu/ExitMenuViewport")

var time_passed := 0.0
var is_quaking := false
var initial_position: Vector3
var has_quake_started := false

func _ready() -> void:
	initial_position = global_position
	
	# If in normal scene, start automatically.
	# If in admin mode, script does nothing.
	if not is_admin_mode:
		begin_simulation(magnitude)

func begin_simulation(custom_magnitude: float) -> void:
	# Update the magnitude
	magnitude = custom_magnitude
	
	# Start countdown
	var timer = get_tree().create_timer(start_delay)
	
	# Trigger EEWS UI
	await get_tree().create_timer(start_delay / 2.0).timeout
	
	# Call UI Label
	var eews_node = get_node_or_null("../../../../XROrigin3D/XRCamera3D/EEWSUI")
	if eews_node:
		eews_node.trigger_warning(magnitude)
	
	# Wait for main timer to finish
	await timer.timeout
	
	# Start the earthquake
	trigger_earthquake()

# Starts earthquake
func trigger_earthquake() -> void:
	if not is_quaking:
		is_quaking = true
		time_passed = 0.0
		has_quake_started = false
		
		# Start Rumbling audio
		rumble_audio.play()

func _physics_process(delta: float) -> void:
	if is_quaking:
		time_passed += delta
		
		# Trigger the wall-mounted objects (like the chalkboard) to fall
		if not has_quake_started and time_passed > s_wave_delay:
			get_tree().call_group("drop_objects", "drop_from_wall")
			has_quake_started = true

		# 1. The Envelope: Controls the build-up and decay of the quake (0.0 to 1.0)
		var envelope := 0.0
		if time_passed < 2.0:
			envelope = time_passed / 2.0 # 2-second build-up
		elif time_passed < total_duration - 5.0:
			envelope = 1.0 # Full intensity
		else:
			envelope = max(0.0, (total_duration - time_passed) / 5.0) # 5-second decay at the end

		if time_passed >= total_duration:
			is_quaking = false
			global_position = initial_position
			
			# Stop rumbling audio
			rumble_audio.stop()
			
			if exit_to_menu:
				exit_to_menu.visible = true
				exit_to_menu.process_mode = Node.PROCESS_MODE_INHERIT
				
				return

		# 2. P-Wave Math: Fast, primarily vertical (Y-axis)
		var p_wave_y = sin(time_passed * p_wave_freq) * p_wave_amp * magnitude * envelope

		# 3. S-Wave Math: Slower, heavy horizontal rolling (X and Z axes)
		var s_wave_x := 0.0
		var s_wave_z := 0.0
		
		# S-Waves arrive later, so we fade them in after the delay
		var s_wave_envelope = clamp((time_passed - s_wave_delay) / 2.0, 0.0, 1.0) 
		
		if time_passed > s_wave_delay:
			# We add two sine waves with slightly offset frequencies to make it unpredictable
			s_wave_x = (sin(time_passed * s_wave_freq) + sin(time_passed * s_wave_freq * 0.73)) * 0.5 * s_wave_amp * magnitude * envelope * s_wave_envelope
			s_wave_z = (cos(time_passed * s_wave_freq * 0.8) + sin(time_passed * s_wave_freq * 1.1)) * 0.5 * s_wave_amp * magnitude * envelope * s_wave_envelope

		# Apply the final mathematical position
		global_position = initial_position + Vector3(s_wave_x, p_wave_y, s_wave_z)
