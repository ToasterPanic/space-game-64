extends RigidBody3D

var speed = 64
var boost_speed_multiplier = 2

var controller_camera_sensitivity = 2.2

var move_x = 0
var move_y = 0

var boosting = false
var boosting_last_process = false

const laser_scene = preload("res://scenes/laser.tscn")

var firing = true
var firing_delay = 0

var firing_target = null

func _physics_process(delta: float) -> void:
	if boosting:
		move_y = -1
		
	
	if firing:
		firing_delay -= delta
		
		if firing_delay < 0:
			firing_delay = 0.5
			
			# Make sure that the firing target isn't behind the ship
			if firing_target:
				var forward = -transform.basis.z.normalized()
				
				var to_position = (firing_target - global_transform.origin).normalized()
				
				var dot = forward.dot(to_position)
				
				if dot < 0:
					firing_target = null
			
			if !firing_target:
				firing_target = position + ((transform.basis * Vector3(0, 0, -1)).normalized() * 9999999999)
			
			var laser = laser_scene.instantiate()
			
			laser.rotation = rotation
			
			laser.position = position + ((transform.basis * Vector3(0, 0, -1)).normalized() * 8)
			var direction = (firing_target - position).normalized()
			
			laser.linear_velocity = direction * 256
			
			if has_node("Fire"):
				$Fire.play()
			
			get_parent().add_child(laser)
			
			firing_target = null
	else:
		firing_delay = 0
		
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
