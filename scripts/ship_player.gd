extends "res://scripts/ship.gd"

func _handle_controller_rotation_input(delta):
	var input_dir = Input.get_vector("camera_left", "camera_right", "camera_down", "camera_up")
	
	rotate_object_local(Vector3.RIGHT, input_dir.y * controller_camera_sensitivity * delta)
	rotate_object_local(Vector3.UP, -input_dir.x * controller_camera_sensitivity * delta)
	
func _ready() -> void:
	shield = 100
	
func confirm_kill(victim) -> void:
	await get_tree().create_timer(0.5).timeout
	
	$KillConfirmed.play()

func _process(delta: float) -> void:
	if lock_on_target:
		if lock_on_target.health <= 0:
			lock_on_target = null
			
	
	if Input.is_action_just_pressed("lock_on"):
		var target = null
		var target_distance = 99999
		
		var enemies = get_parent().get_node("Enemies")
		
		for n in enemies.get_children():
			if $Camera.is_position_behind(n.global_position): continue
			if n.health <= 0: continue
			
			var screen_pos = $Camera.unproject_position(n.global_position)
			
			var window_size = get_viewport().get_visible_rect().size
		
			var crosshair_pos = window_size / 2
			
			var distance_from_crosshair = (screen_pos - crosshair_pos).length()
			if (distance_from_crosshair < target_distance) and (distance_from_crosshair < 128):
				target = n
				target_distance = distance_from_crosshair
			
		if (target != null) and (!lock_on_target):
			if lock_on_target:
				lock_on_target.get_node("LockedOn").visible = false
				
			lock_on_target = target
			target.get_node("LockedOn").visible = true
			
			$LockOn.play()
		elif lock_on_target:
			lock_on_target.get_node("LockedOn").visible = false
			
			lock_on_target = null
			$LockOff.play()
		else:
			get_parent().crosshair_size = 0.2
			$LockOnFail.play()

func _physics_process(delta: float) -> void:
	boosting = Input.is_action_pressed("boost")
	firing = Input.is_action_pressed("fire")
	alt_firing = Input.is_action_pressed("fire_alternate")
	
	if Input.is_action_just_released("boost"):
		$BoostFinish.play()
	
	var input_dir := Input.get_vector("ship_left", "ship_right", "move_forward", "move_backwards")
	move_x = input_dir.x
	move_y = input_dir.y
	
	$Health.text = str(floori(health))
	$Shield.text = str(floori(shield))
	$BoostText.text = str(floori(boost))
	
	if lock_on_target:
		if !$Camera.is_position_behind(lock_on_target.global_position):
			var screen_pos = $Camera.unproject_position(lock_on_target.global_position)
				
			var window_size = get_viewport().get_visible_rect().size
		
			var crosshair_pos = window_size / 2
			
			var distance_from_crosshair = (screen_pos - crosshair_pos).length()
			
			if distance_from_crosshair < 128:
				firing_target = lock_on_target.global_position + (lock_on_target.linear_velocity * 0.1)
	else:
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
