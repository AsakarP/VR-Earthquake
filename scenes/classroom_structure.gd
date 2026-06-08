# Skrip Ruangan Kelas (Pengendali Gempa)
extends AnimatableBody3D

# Mode Admin
# Jika true, simulasi tidak akan mulai secara otomatis.
@export var admin_mode := false

@export var baseline_magnitude := 5.0

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
@onready var dust_particles: GPUParticles3D = $DustParticles
@onready var ground_dust_particles: GPUParticles3D = $GroundDustParticles

var time_passed := 0.0
var is_quaking := false
var initial_position: Vector3
var has_quake_started := false
var is_evacuation_ready := true
var exact_time_survived := 0.0
var player_was_hit := false

func _ready() -> void:
	initial_position = global_position
	
	# If in normal scene, start automatically.
	# If in admin mode, script does nothing.
	if not admin_mode:
		# Generate random decimal 1.0 to 5.0
		var rand_mag = randf_range(4.0, 4.9)
		# Starts simulation
		begin_simulation(rand_mag)
		

func begin_simulation(custom_magnitude: float) -> void:
	# Update the magnitude
	magnitude = custom_magnitude
	
	var player_node = get_node_or_null("../../../../XROrigin3D")
	var eews_node = get_node_or_null("../../../../XROrigin3D/XRCamera3D/EEWSUI")
	
	if player_node and player_node.has_method("lock_menu"):
		player_node.lock_menu()
	
	# Start the main master countdown for the earthquake
	var timer = get_tree().create_timer(start_delay)
	
	# Calculate exactly how many seconds the EEWS warning will be on screen
	var countdown_seconds = start_delay / 2.0
	
	# Wait for the first half of the delay before sounding the alarm
	await get_tree().create_timer(countdown_seconds).timeout
	
	# Call UI Label
	if eews_node:
		# --- UPDATED: Pass BOTH the magnitude AND the countdown_seconds! ---
		eews_node.trigger_warning(magnitude, countdown_seconds)
	
	if player_node:
		player_node.start_reaction_timer()
	
	# Wait for main timer to finish the remaining time
	await timer.timeout
	
	# Start the earthquake
	trigger_earthquake()

# Starts earthquake
func trigger_earthquake() -> void:
	if not is_quaking:
		is_quaking = true
		time_passed = 0.0
		has_quake_started = false
		
		# Start dust particle
		dust_particles.emitting = true
		ground_dust_particles.emitting = true
		# Start Rumbling audio
		# Very low rumble sound
		if magnitude < 3:
			rumble_audio.volume_db = -50
		# Low rumble sound
		elif magnitude >= 3 and magnitude < 4:
			rumble_audio.volume_db = -30
		# Normal rumble sound
		elif magnitude >= 4:
			rumble_audio.volume_db = 0
		rumble_audio.play()
		
# This will be called by your player.gd script!
func end_simulation_early() -> void:
	if is_quaking and not player_was_hit:
		print("PLAYER WAS HIT! Recording timestamp: ", time_passed)
		player_was_hit = true
		exact_time_survived = time_passed # Lock in the exact moment they got hit

func _physics_process(delta: float) -> void:
	if is_quaking:
		time_passed += delta
		
		# Trigger the S-Wave damage phase
		if not has_quake_started and time_passed > s_wave_delay:
			
			# Call the new function and pass the magnitude variable right into it!
			get_tree().call_group("drop_objects", "check_earthquake_stress", magnitude)
			
			has_quake_started = true

		# 1. The Envelope: Controls the build-up and decay of the quake (0.0 to 1.0)
		var envelope := 0.0
		if time_passed < 2.0:
			envelope = time_passed / 2.0 # 2-second build-up
		elif time_passed < total_duration - 5.0:
			envelope = 1.0 # Full intensity
		else:
			envelope = max(0.0, (total_duration - time_passed) / 5.0) # 5-second decay at the end
		
		# Shaking Stops
		if time_passed >= total_duration:
			is_quaking = false
			global_position = initial_position
			
			rumble_audio.stop()
			dust_particles.emitting = false
			ground_dust_particles.emitting = false
			
			# If they were never hit throughout the whole simulation, give them full survival time
			if not player_was_hit:
				exact_time_survived = total_duration
			
			# Trigger evacuation
			var structure_node = get_node_or_null("../../../../Zones") 
			if structure_node and structure_node.has_method("call_exit_area"):
				structure_node.call_exit_area()
			
			var results_node = get_node_or_null("../../../../XROrigin3D/XRCamera3D/Results")
			var player_node = get_node_or_null("../../../../XROrigin3D")
			if results_node and player_node:
				player_node.unlock_menu()
				DataLogging.save_session_data(
					magnitude,
					player_node.obj_count,
					player_node.hit_history,
					exact_time_survived, # Use the locked-in time!
					player_node.reaction_time,
					player_node.entered_zone,
					player_node.entered_safe,
					player_node.entered_hazard
				)
				
				DataLogging.advance_to_next_subject()
				
				results_node.show_results(player_node.hit_history, player_node.obj_count)
				
			return
		
		# Converts linear slider to Exponential Curve
		var raw_multiplier = pow(10, magnitude - baseline_magnitude)
		
		# Physics safety net (Clamp Multiplier)
		var realistic_multiplier = clamp(raw_multiplier, 0.0001, 8.0)
		
		# 2. P-Wave Math: Fast, primarily vertical (Y-axis)
		var p_wave_y = sin(time_passed * p_wave_freq) * p_wave_amp * realistic_multiplier * envelope

		# 3. S-Wave Math: Slower, heavy horizontal rolling (X and Z axes)
		var s_wave_x := 0.0
		var s_wave_z := 0.0
		
		# S-Waves arrive later, so we fade them in after the delay
		var s_wave_envelope = clamp((time_passed - s_wave_delay) / 2.0, 0.0, 1.0) 
		
		if time_passed > s_wave_delay:
			# We add two sine waves with slightly offset frequencies to make it unpredictable
			s_wave_x = (sin(time_passed * s_wave_freq) + sin(time_passed * s_wave_freq * 0.73)) * 0.5 * s_wave_amp * realistic_multiplier * envelope * s_wave_envelope
			s_wave_z = (cos(time_passed * s_wave_freq * 0.8) + sin(time_passed * s_wave_freq * 1.1)) * 0.5 * s_wave_amp * realistic_multiplier * envelope * s_wave_envelope

		# Apply the final mathematical position
		global_position = initial_position + Vector3(s_wave_x, p_wave_y, s_wave_z)
