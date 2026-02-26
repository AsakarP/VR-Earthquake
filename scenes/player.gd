extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002 # Adjust this decimal to make looking faster or slower

# Get the gravity from the project settings.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Grab a reference to your Camera3D node. 
# Make sure the name matches what is in your scene tree!
@onready var camera = $Camera3D

func _ready() -> void:
	# This locks the mouse cursor to the center of the game window and hides it.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Check if the input is a mouse movement
	if event is InputEventMouseMotion:
		# Rotate the entire player body left and right
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# Rotate only the camera up and down
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		
		# Clamp the camera's X rotation so you can't backflip your neck
		# This restricts looking straight up and straight down to 90 degrees
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	# A crucial safety feature: pressing ESC frees your mouse so you can close the game!
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	# --- Keep your previous movement code below ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
