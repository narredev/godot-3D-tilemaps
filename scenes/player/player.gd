extends CharacterBody3D

const SPEED = 5.0
const ROT_SPEED = 150
const JUMP_VELOCITY = 4.5

@onready var cam: Camera3D = $Camera3D
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (cam.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	var rot_input := Input.get_axis("rotate_right", "rotate_left")
	cam.rotation.y = wrapf(cam.rotation.y + rot_input * deg_to_rad(ROT_SPEED) * delta, 
		deg_to_rad(-360), deg_to_rad(360))
	
	move_and_slide()
