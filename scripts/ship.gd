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
var damage = 20
var laser_color = Color(1, 1, 1)

var boosting = false
var boosting_last_process = false

const laser_scene = preload("res://scenes/laser.tscn")
const missile_scene = preload("res://scenes/missile.tscn")

var firing = true
var firing_delay = 0

var alt_firing = false
var alt_firing_delay = 0

var firing_target = null
var lock_on_target = null

func _physics_process(delta: float) -> void:
	if boosting and (boost_cooldown <= 0):
		move_y = -1
		boost -= delta * (100/5)
		
		$BoostParticles.emitting = true
		
		if boost < 0:
			boost_cooldown = 2.5
	else:
		boosting = false
		boost += delta * (100/5)
		
		$BoostParticles.emitting = false
		
		if boost > 100:
			boost = 100
			
		boost_cooldown -= delta
	if alt_firing:
		alt_firing_delay -= delta
		
		if alt_firing_delay < 0:
			alt_firing_delay = 1
			
			if lock_on_target:
				var i = 0
				while i < 2:
					var missile = missile_scene.instantiate()
				
					missile.target = lock_on_target
					missile.creator = self
					
					missile.rotation = rotation
					missile.position = position + ((transform.basis * Vector3(0, 0, -1)).normalized() * 6) + ((transform.basis * Vector3(0, -1, 0)).normalized() * 3)
					
					if i == 0:
						missile.position += ((transform.basis * Vector3(-1, 0, 0)).normalized() * 3)
					else:
						missile.position += ((transform.basis * Vector3(1, 0, 0)).normalized() * 3)
					
					var direction = (transform.basis * Vector3(0, 0, move_y)).normalized()
					missile.linear_velocity = direction * 128
					
					get_tree().get_current_scene().add_child(missile)
					
					i += 1
	else:
		alt_firing_delay -= delta

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
			
			laser.creator = self
			
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
			
			laser.linear_velocity = direction * 1024
			
			laser.damage = damage
			
			if has_node("Fire"):
				$Fire.play()
			
			get_tree().get_current_scene().add_child(laser)
			
			firing_target = null
	else:
		firing_delay = 0
		
	if boosting != boosting_last_process:
		boosting_last_process = boosting
		
		if boosting:
			$Boost.play()
		else:
			$Boost.stop()
			
	if move_y > 0:
		move_y = 0
		
	if (move_y != 0) and !boosting:
		$Thrusters.emitting = true
		
		#$Thrusters.amount = 64 + (move_y * -64)
		$Thrusters.initial_velocity_min = move_y * -24
		$Thrusters.initial_velocity_max = $Thrusters.initial_velocity_min 
	else:
		$Thrusters.emitting = false
	
	var direction := (transform.basis * Vector3(0, 0, move_y)).normalized()
	if direction:
		if boosting:
			linear_velocity = direction * speed * boost_speed_multiplier
		else:
			linear_velocity = direction * speed
