extends Label3D

@onready var warning_audio: AudioStreamPlayer = $WarningAudio

func _ready() -> void:
	# Ensure it starts completely invisible
	modulate.a = 0.0
	outline_modulate.a = 0.0

# This function will be called by your earthquake controller
func trigger_warning(magnitude: float) -> void:
	# Update the text dynamically
	text = "⚠\nEarthquake\nEstimated Magnitude: " + str(magnitude)
	
	# Play warning alarm
	warning_audio.play()
	
	# Create a new tween
	var tween = create_tween()
	
	# Tween the alpha (a) channel of the modulate property to 1.0 (fully visible) over 0.5 seconds
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(self, "outline_modulate:a", 1.0, 0.5)
	
	# Keep it on screen for 5 seconds
	tween.tween_interval(5.0)
	
	# Fade it back out to 0.0 over 1 second
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(self, "outline_modulate:a", 0.0, 1.0)
