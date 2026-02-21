extends RigidBody3D

const SPEED = 512
const JUMP_VELOCITY = 4.5

const controller_camera_sensitivity = 2.2

func _handle_controller_rotation_input(delta):
	var input_dir = Input.get_vector("camera_left", "camera_right", "camera_down", "camera_up")
	
	print(rotation_degrees)
	
	rotate_object_local(Vector3.RIGHT, input_dir.y * controller_camera_sensitivity * delta)
	rotate_object_local(Vector3.UP, -input_dir.x * controller_camera_sensitivity * delta)
	
	"""var velocity_average = linear_velocity.length()
	var direction := (transform.basis * Vector3(0, 0, -1)).normalized()
	if direction:
		linear_velocity.x = direction.x * velocity_average
		linear_velocity.y = direction.y * velocity_average
		linear_velocity.z = direction.z * velocity_average"""

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		linear_velocity.y = JUMP_VELOCITY
		
	_handle_controller_rotation_input(delta)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ship_left", "ship_right", "move_forward", "move_backwards")
	var direction := (transform.basis * Vector3(0, 0, input_dir.y)).normalized()
	if direction:
		linear_velocity.x = direction.x * SPEED
		linear_velocity.y = direction.y * SPEED
		linear_velocity.z = direction.z * SPEED
