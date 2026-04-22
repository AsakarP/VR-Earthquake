extends Control

# --- HELPER FUNCTION ---
# Both buttons will call this function to handle the screen fade
func fade_to_black() -> void:
	# 1. Ask the absolute root of the game to search every single node 
	# for something named exactly "Fade". 
	# (If your node is named "CameraFade", change the text below!)
	var camera_fade = get_tree().root.find_child("Fade", true, false)
	
	# 2. Check if the search was successful
	if camera_fade != null:
		var fade_material = camera_fade.get_active_material(0)
		
		var tween = create_tween()
		tween.tween_property(fade_material, "albedo_color:a", 1.0, 1.5)
		
		await tween.finished
	else:
		# This will print in red in your debugger if it fails, 
		# saving you from a hard crash!
		push_error("WARNING: Could not find the Fade mesh anywhere in the scene!")
		# A tiny safety delay so it doesn't instantly snap if the fade is missing
		await get_tree().create_timer(0.1).timeout 

# --- BUTTON COMMANDS ---
func _on_reset_button_pressed() -> void:
	# 1. Wait for the screen to go black
	await fade_to_black()
	
	# 2. Reload the exact scene we are currently standing in!
	get_tree().reload_current_scene()

func _on_exit_to_menu_button_pressed() -> void:
	# 1. Wait for the screen to go black
	await fade_to_black()
	
	# 2. Load the main menu
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
