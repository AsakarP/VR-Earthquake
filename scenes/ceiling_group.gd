extends Node3D

@onready var solid_ceiling = $SolidCeiling
@onready var destroyed_ceiling = $DestroyedCeiling
@onready var anim_player = $DestroyedCeiling/AnimationPlayer

func _ready() -> void:
	# This single line forces Godot to generate a new, unique random seed
	# every single time the scene loads.
	randomize()
	# Ensure the correct visibility when the game starts
	solid_ceiling.show()
	destroyed_ceiling.hide()

func start_quake_flicker(quake_intensity: float) -> void:
	if quake_intensity >= 5.0:
		for child in solid_ceiling.get_children():
			if child.name.begins_with("CeilingLight"):
				var light_anim = child.get_node_or_null("AnimationPlayer")
				if light_anim:
					light_anim.play("quake_flicker")

# Your main earthquake script will automatically call this when the S-Waves hit
func check_earthquake_stress(quake_intensity: float) -> void:
	if quake_intensity >= 5.0:
		await get_tree().create_timer(12.0).timeout
		
		# Find all the lights in the solid ceiling and play their flicker animation
		for child in solid_ceiling.get_children():
			if child.name.begins_with("CeilingLight"):
				var light_anim = child.get_node_or_null("AnimationPlayer")
				if light_anim:
					light_anim.play("power_fail")
					
		# Turn off the lights in the Destroyed Ceiling at the same time!
		for piece in destroyed_ceiling.get_children():
			for child in piece.get_children():
				if child.name.begins_with("CeilingLight"):
					var light_anim = child.get_node_or_null("AnimationPlayer")
					if light_anim:
						light_anim.play("power_fail")
						
		# Wait for both light to flicker and die
		await get_tree().create_timer(2.0).timeout
		
		# Instantly swap the meshes so the player doesn't see a seam
		solid_ceiling.hide()
		destroyed_ceiling.show()
		
		if quake_intensity >= 5.5:
			# Total Collapse
			anim_player.play("ceiling_collapse")
		else:
			# Partial Collapse (5.0 to 5.49): Drop only 1 random piece
			var pieces = [
				$DestroyedCeiling/Ceiling1,
				$DestroyedCeiling/Ceiling2,
				$DestroyedCeiling/Ceiling3,
				$DestroyedCeiling/Ceiling4
			]
			
			var random_piece = pieces.pick_random()
			print("THE RANDOM PIECE PICKED IS: ", random_piece.name)
			random_piece.freeze = false
