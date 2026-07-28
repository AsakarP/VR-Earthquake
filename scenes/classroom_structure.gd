# Skrip Ruangan Kelas (Pengendali Gempa)
extends AnimatableBody3D

# Mode Admin
# Jika true, simulasi tidak akan mulai secara otomatis.
@export var admin_mode := false

# Besaran referensi dimana pengali guncangan fisik sama persis dengan 1.0
@export var baseline_intensity := 5.0

# Waktu & Intensitas Gempa
@export_category("Earthquake Settings")
@export var start_delay := 10.0 # Detik sebelum guncangan fisik mulai
@export var intensity := 1.0 # Intensitas yang disimulasikan
@export var total_duration := 20.0 # Total detik bertahan hidup yang diperlukan
@export var s_wave_delay := 3.0 # Tundaan sebelum s-wave tiba

# Parameter Gelombang Fisika
@export_group("P-Wave (Vertical Jolt)")
@export var p_wave_amp := 0.03
@export var p_wave_freq := 30.0

@export_group("S-Wave (Horizontal Rolling)")
@export var s_wave_amp := 0.20
@export var s_wave_freq := 5.0

# Referensi Node
@onready var rumble_audio: AudioStreamPlayer3D = $RumbleAudio
@onready var dust_particles: GPUParticles3D = $DustParticles
@onready var ground_dust_particles: GPUParticles3D = $GroundDustParticles

# Variabel State
var time_passed := 0.0
var is_quaking := false
var initial_position: Vector3
var has_quake_started := false
var is_evacuation_ready := true
var exact_time_survived := 0.0
var player_was_hit := false

# Noise Gempa
var earthquake_noise := FastNoiseLite.new()

func _ready() -> void:
	# Simpan koordinat spawn asli kelas
	initial_position = global_position
	
	# Konfigurasi Perlin Noise
	earthquake_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	earthquake_noise.seed = randi() # Gempa akan berbeda setiap kali dimainkan
	earthquake_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	earthquake_noise.fractal_octaves = 4 # Menambahkan getaran tajam (micro-jitters) di dalam gelombang besar
	
	# Memulai secara automatis pada mode normal
	if not admin_mode:
		var rand_int = randf_range(4.0, 4.9)
		begin_simulation(rand_int)

# Fungsi memulai simulasi
func begin_simulation(custom_intensity: float) -> void:
	intensity = custom_intensity
	
	var player_node = get_node_or_null("../../XROrigin3D")
	var eews_node = get_node_or_null("../../XROrigin3D/XRCamera3D/EEWSUI")
	
	# Mencegah pengguna keluar melalui menu selama simulasi berlangsung
	if player_node and player_node.has_method("lock_menu"):
		player_node.lock_menu()
	
	var timer = get_tree().create_timer(start_delay)
	var countdown_seconds = start_delay / 2.0
	
	# Menunggu setengah penundaan, lalu memanggil EEWS
	await get_tree().create_timer(countdown_seconds).timeout
	
	if eews_node:
		eews_node.trigger_warning(intensity, countdown_seconds)
	
	# Mulai melacak waktu reaksi pengguna saat alarm berbunyi
	if player_node:
		player_node.start_reaction_timer()
	
	await timer.timeout
	trigger_earthquake()

# Fungsi pemicu gempa
func trigger_earthquake() -> void:
	if not is_quaking:
		is_quaking = true
		time_passed = 0.0
		has_quake_started = false
		
		# Perhitungan debu dinamis
		var final_dust_amount := 1 # Default jumlah partikel

		if intensity >= 4.5:
			# Lakukan perhitungan matematika hanya jika gempa cukup kuat
			var raw_multiplier = pow(10, intensity - baseline_intensity)
			var visual_multiplier = clamp(raw_multiplier, 0.1, 3.0)
			
			# Jumlah debu normal saat intensitas tepat di baseline (5.0)
			var base_dust_amount := 40 
			
			final_dust_amount = clampi(int(base_dust_amount * visual_multiplier), 5, 150)
		else:
			# Intensitas 1.0 - 4.4: Tetapkan ke angka yang sangat kecil
			final_dust_amount = 1

		# Terapkan jumlah ke node partikel
		dust_particles.amount = final_dust_amount
		ground_dust_particles.amount = final_dust_amount
		
		# Aktifkan efek visual debu
		dust_particles.emitting = true
		ground_dust_particles.emitting = true
		
		# Menyesuaikan volume gemuruh berdasarkan besarnya gempa
		if intensity < 4:
			rumble_audio.volume_db = -50
		elif intensity >= 4 and intensity < 5:
			rumble_audio.volume_db = -30
		elif intensity >= 5:
			rumble_audio.volume_db = 0
		rumble_audio.play()
		
# Dipanggil oleh skrip player jika benda yang unfrozen mengenai kepala pengguna
func end_simulation_early() -> void:
	if is_quaking and not player_was_hit:
		print("PLAYER WAS HIT! Recording timestamp: ", time_passed)
		player_was_hit = true
		exact_time_survived = time_passed

func _physics_process(delta: float) -> void:
	if is_quaking:
		time_passed += delta
		
		# Datangnya s-wave, memicu logika yang mematahkan joints dan menjatuhkan objek
		if not has_quake_started and time_passed > s_wave_delay:
			get_tree().call_group("drop_objects", "check_earthquake_stress", intensity)
			has_quake_started = true

		# Memudarkan goyangan masuk dan keluar dengan lancar
		var envelope := 0.0
		if time_passed < 2.0:
			envelope = time_passed / 2.0 # 2 detik build-up linier
		elif time_passed < total_duration - 5.0:
			envelope = 1.0 # Intensitas maksimum yang berkelanjutan
		else:
			envelope = max(0.0, (total_duration - time_passed) / 5.0) # 5 detik decay
		
		# Kondisi berakhir simulasi, timer mencapai durasi total
		if time_passed >= total_duration:
			is_quaking = false
			global_position = initial_position # Mengembalikan ruangan kembali ke pusat sempurna
			
			rumble_audio.stop()
			dust_particles.emitting = false
			ground_dust_particles.emitting = false
			
			if not player_was_hit:
				exact_time_survived = total_duration
			
			# Memicu logika evakuasi
			var structure_node = get_node_or_null("../../../../Zones") 
			if structure_node and structure_node.has_method("call_exit_area"):
				structure_node.call_exit_area()
			
			# Hasil proses & pencatatan data
			var results_node = get_node_or_null("../../../../XROrigin3D/XRCamera3D/Results")
			var player_node = get_node_or_null("../../../../XROrigin3D")
			if results_node and player_node:
				player_node.unlock_menu()
				
				# Menulis variabel uji coba ke file CSV Android lokal
				DataLogging.save_session_data(
					intensity,
					player_node.obj_count,
					player_node.hit_history,
					exact_time_survived,
					player_node.reaction_time,
					player_node.entered_zone,
					player_node.entered_safe,
					player_node.entered_hazard
				)
				
				# Increment subject ID untuk pengguna selanjutnya
				DataLogging.advance_to_next_subject()
				
				# Memunculkan hasil jika pengguna terkena objek
				results_node.show_results(player_node.hit_history, player_node.obj_count)
			
			# Memunculkan menu reset/exit hanya jika dalam mode admin
			if admin_mode:
				var player_menu = get_tree().root.find_child("PlayerMenu", true, false)
				
				if player_menu:
					if player_menu.visible == true:
						player_menu.visible = false
						player_menu.process_mode = Node.PROCESS_MODE_DISABLED
					else:
						player_menu.visible = true
						player_menu.process_mode = Node.PROCESS_MODE_INHERIT
						
			return
		
		# Perhitungan Fisika Menggunakan Perlin Noise
		# Penskalaan Logaritmik: Mengubah besaran linier menjadi gaya eksponensial
		var raw_multiplier = pow(10, intensity - baseline_intensity)
		
		# Jepit pengganda fisika untuk mencegah ruangan merusak game engine
		var realistic_multiplier = clamp(raw_multiplier, 0.0001, 8.0)
		
		# Primary Wave (P-Wave): Guncangan vertikal menggunakan noise pada frekuensi tinggi
		var p_wave_y = earthquake_noise.get_noise_1d(time_passed * p_wave_freq) * p_wave_amp * realistic_multiplier * envelope

		# Secondary Wave (S-Wave): Penggulingan horizontal yang berat
		var s_wave_x := 0.0
		var s_wave_z := 0.0
		
		# S-Waves tiba lebih nanti, memerlukan selubung fade-in yang independen
		var s_wave_envelope = clamp((time_passed - s_wave_delay) / 2.0, 0.0, 1.0) 
		
		if time_passed > s_wave_delay:
			# Mengambil sampel noise pada titik waktu yang sangat berjauhan (+1000, +2000)
			# agar pergerakan sumbu X dan Z benar-benar terpisah dan kacau
			s_wave_x = earthquake_noise.get_noise_1d((time_passed * s_wave_freq) + 1000.0) * s_wave_amp * realistic_multiplier * envelope * s_wave_envelope
			s_wave_z = earthquake_noise.get_noise_1d((time_passed * s_wave_freq) + 2000.0) * s_wave_amp * realistic_multiplier * envelope * s_wave_envelope

		# Menerapkan perhitungan offset akhir pada posisi global ruangan
		global_position = initial_position + Vector3(s_wave_x, p_wave_y, s_wave_z)
