extends RigidBody3D

var speed = 64
var boost_speed_multiplier = 2

var controller_camera_sensitivity = 2.2

var move_x = 0
var move_y = 0

var flares = 0
var boost = 100
var boost_cooldown = 0
var health = 100
var shield = 0
var damage = 10
var laser_color = Color(1, 1, 1)

var boosting = false
var boosting_last_process = false

const laser_scene = preload("res://scenes/laser.tscn")

var firing = true
var firing_delay = 0

var firing_target = null

func _physics_process(delta: float) -> void:
	if boosting and (boost_cooldown <= 0):
		move_y = -1
		boost -= delta * (100/5)
		
		if boost < 0:
			boost_cooldown = 2.5
	else:
		boosting = false
		boost += delta * (100/5)
		
		if boost > 100:
			boost = 100
			
		boost_cooldown -= delta
	
	if firing:
		firing_delay -= delta
		
		if firing_delay < 0:
			firing_delay = 0.25
			
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
			
			var laser_mesh = laser.get_node("Mesh").mesh
			
			laser_mesh = laser_mesh.duplicate()
			var new_material = StandardMaterial3D.new()
			new_material.albedo_color = Color(0, 0, 0)
			new_material.emission = laser_color
			new_material.emission_enabled = true
			
			laser.get_node("Mesh").set_surface_override_material(0, new_material)
			
			laser.linear_velocity = direction * 256
			
			laser.damage = damage
			
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
