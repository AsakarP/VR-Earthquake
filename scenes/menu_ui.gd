extends Control

@export_file("*.tscn") var target_scene : String

@onready var camera_fade = $"../../../XROrigin3D/XRCamera3D/Fade"

func _on_start_button_pressed() -> void:
	var fade_material = camera_fade.get_active_material(0)
	
	var tween = create_tween()
	tween.tween_property(fade_material, "albedo_color:a", 1.0, 1.5)
	
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/classroom.tscn")

func _on_admin_button_pressed() -> void:
	var fade_material = camera_fade.get_active_material(0)
	
	var tween = create_tween()
	tween.tween_property(fade_material, "albedo_color:a", 1.0, 1.5)
	
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/classroom_admin.tscn")

func _on_exit_button_pressed() -> void:
	var fade_material = camera_fade.get_active_material(0)
	
	var tween = create_tween()
	tween.tween_property(fade_material, "albedo_color:a", 1.0, 1.5)
	
	await tween.finished
	get_tree().quit()
