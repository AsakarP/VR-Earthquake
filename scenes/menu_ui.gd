extends Control

@export_file("*.tscn") var target_scene : String

@onready var camera_fade = $"../../../XROrigin3D/XRCamera3D/Fade"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	# Skip if no target scene set
	if not target_scene or target_scene == "":
		return
	
	# Find the XRToolsSceneBase
	var scene_base : XRToolsSceneBase = XRTools.find_xr_ancestor(self, "*", "XRToolsSceneBase")
	if not scene_base:
		return
	
	# Start loading the target scene
	scene_base.load_scene(target_scene)

func _on_exit_button_pressed() -> void:
	var fade_material = camera_fade.get_active_material(0)
	
	var tween = create_tween()
	tween.tween_property(fade_material, "albedo_color:a", 1.0, 1.5)
	
	await tween.finished
	get_tree().quit()
