extends Node3D

@onready var solid_ceiling = $SolidCeiling
@onready var destroyed_ceiling = $Destroyed_Ceiling
@onready var anim_player = $Destroyed_Ceiling/AnimationPlayer

func _ready() -> void:
	# Ensure the correct visibility when the game starts
	solid_ceiling.show()
	destroyed_ceiling.hide()

# Your main earthquake script will automatically call this when the S-Waves hit
func check_earthquake_stress(quake_intensity: float) -> void:
	if quake_intensity >= 5.5:
		await get_tree().create_timer(12.0).timeout
		# Find all the lights in the solid ceiling and play their flicker animation
		for child in solid_ceiling.get_children():
			if child.name.begins_with("CeilingLight"):
				# Assuming the AnimationPlayer is a direct child of the CeilingLight scene
				var light_anim = child.get_node_or_null("AnimationPlayer")
				if light_anim:
					light_anim.play("power_fail")
					
		await get_tree().create_timer(2.0).timeout
		
		# Instantly swap the meshes so the player doesn't see a seam
		solid_ceiling.hide()
		destroyed_ceiling.show()
		
		# Trigger your staggered keyframes!
		anim_player.play("ceiling_collapse")
