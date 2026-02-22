extends "res://scripts/ship.gd"

func _handle_controller_rotation_input(delta):
	var input_dir = Input.get_vector("camera_left", "camera_right", "camera_down", "camera_up")
	
	rotate_object_local(Vector3.RIGHT, input_dir.y * controller_camera_sensitivity * delta)
	rotate_object_local(Vector3.UP, -input_dir.x * controller_camera_sensitivity * delta)
	
func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	boosting = Input.is_action_pressed("boost")
	firing = Input.is_action_pressed("fire")
	
	if Input.is_action_just_released("boost"):
		$BoostFinish.play()
	
	var input_dir := Input.get_vector("ship_left", "ship_right", "move_forward", "move_backwards")
	move_x = input_dir.x
	move_y = input_dir.y
	
	var window_size = get_viewport().get_visible_rect().size
	
	var crosshair_screen_pos = Vector2(window_size.x/2, window_size.y/2)  # crosshair position on screen

	var ray_origin = $Camera.project_ray_origin(crosshair_screen_pos)
	var ray_direction = $Camera.project_ray_normal(crosshair_screen_pos)

	# Cast a ray into the world to find the target point
	var space_state = get_world_3d().direct_space_state
	var ray_length = 5000  # max distance for shooting

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	var result = space_state.intersect_ray(query)
	
	var target_point: Vector3 = ray_origin + ray_direction * ray_length
	if result:
		firing_target = result.position
	
	super(delta)
	
	_handle_controller_rotation_input(delta)
