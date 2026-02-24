extends RigidBody3D

var creator = null

var time = 0

var damage = 30
var delay_activate = null
var target = null

var stage = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	time += delta
	
	if (time > 0.2) and (stage == 0):
		stage = 1
		
		linear_damp = 0
		
	if stage == 1:
		if target:
			var target_position = target.global_position + ((target.transform.basis * Vector3(0, 2, 0)).normalized() * 1.5)
			
			if ((target.global_position - global_position).length() < 10) or (time > 0.66):
				look_at(target_position)
			else:
				var target_direction = global_position.direction_to(target_position)
				
				if (target.global_position - global_position).length() < 32:
					target_direction *= -1

				var current_dir = -global_transform.basis.z
				var target_dir = (target.global_transform.origin - global_transform.origin).normalized()

				var rotation_axis = current_dir.cross(target_dir)
				var angle = acos(current_dir.dot(target_dir))
				
				var base_turn_speed = 10
				
				var torque = rotation_axis.normalized() * angle * base_turn_speed
				
				apply_torque(torque)
			
			var direction := (transform.basis * Vector3(0, 0, -1)).normalized()
		
			linear_velocity = direction * 192
	
	if time > 4:
		queue_free()
		
func _on_body_entered(body: Node) -> void:
	if body == creator: return
	if body.name == "Missile": return
	
	if "health" in body:
		if ("shield" in body) and (body.shield > 0):
			body.shield -= damage
			
			if body.shield <= 0:
				body.shield = 0
				
				if body.has_node("ShieldBreak"): body.get_node("ShieldBreak").play()
		else:
			body.health -= damage
			if body.health <= 0:
				if creator.name == "Player":
					creator.confirm_kill(self)
	
	$CollisionShape.queue_free()
	$Mesh.queue_free()
	linear_velocity = Vector3()
	
	$RocketExplosion.play()
	$RocketThrustSmall.stop()
	
	await get_tree().create_timer(1.5).timeout
	
	queue_free()
