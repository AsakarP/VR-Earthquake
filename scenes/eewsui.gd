extends Label3D

@onready var warning_audio: AudioStreamPlayer = $WarningAudio

var is_counting_down := false
var time_left := 0.0
var current_magnitude := 0.0

func _ready() -> void:
	# Ensure it starts completely invisible
	modulate.a = 0.0
	outline_modulate.a = 0.0

# This runs every frame to update the text!
func _process(delta: float) -> void:
	if is_counting_down:
		time_left -= delta
		
		if time_left > 0:
			# Update the text with the live countdown.
			# ceil() rounds the decimal up (so 2.1 seconds shows as "3")
			text = "⚠\nGempa Bumi\nPerkiraan Besarnya: %.1f\n\nTiba dalam: %d detik" % [current_magnitude, int(ceil(time_left))]
		else:
			# Time is up! Stop counting and fade out.
			is_counting_down = false
			hide_warning()

# This function will be called by your earthquake controller
func trigger_warning(magnitude: float, countdown_seconds: float) -> void:
	current_magnitude = magnitude
	time_left = countdown_seconds
	is_counting_down = true
	
	warning_audio.play()
	
	# Fade IN smoothly
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(self, "outline_modulate:a", 1.0, 0.5)

# A dedicated function to hide the UI when time is up
func hide_warning() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(self, "outline_modulate:a", 0.0, 1.0)
