extends RigidBody3D

var speed = 512
var boost_speed_multiplier = 2

var controller_camera_sensitivity = 2.2

var move_x = 0
var move_y = 0

var boosting = false
var boosting_last_process = false

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("ship_left", "ship_right", "move_forward", "move_backwards")
	move_x = input_dir.x
	move_y = input_dir.y
	
	if boosting:
		move_y = -1
		
	if boosting != boosting_last_process:
		boosting_last_process = boosting
		
		if boosting:
			$Boost.play()
		else:
			$Boost.stop()
	
	var direction := (transform.basis * Vector3(0, 0, move_y)).normalized()
	if direction:
		if boosting:
			linear_velocity.x = direction.x * speed * boost_speed_multiplier
			linear_velocity.y = direction.y * speed * boost_speed_multiplier
			linear_velocity.z = direction.z * speed * boost_speed_multiplier
		else:
			linear_velocity.x = direction.x * speed
			linear_velocity.y = direction.y * speed
			linear_velocity.z = direction.z * speed
