extends "res://scripts/ship.gd"

@onready var player = get_parent().get_parent().get_node("Player")

var is_dead = false

func _ready() -> void:
	laser_color = Color(1, 0, 0)

func _physics_process(delta: float) -> void:
	if (health <= 0):
		if is_dead: return
		
		is_dead = true
		
		$Thrusters.visible = false
		$BoostParticles.visible = false
		
		$Mesh.visible = false
		$LockedOn.visible = false
		$Health.queue_free()
		
		$CollisionShape.queue_free()
		
		$Explode.play()
		for n in $ExplosionEffect.get_children():
			n.emitting = true
		
		await get_tree().create_timer(16).timeout
		
		queue_free()
		return
	
	$Health.text = str(floori(health))
	
	var target_position = player.global_position
	if player.linear_velocity.length() < 32:
		target_position += (player.linear_velocity * 0.1)
	
	var target_direction = global_position.direction_to(target_position)
	
	if (player.global_position - position).length() < 32:
		target_direction *= -1

	var current_dir = -global_transform.basis.z
	var target_dir = (player.global_transform.origin - global_transform.origin).normalized()

	var rotation_axis = current_dir.cross(target_dir)
	var angle = acos(current_dir.dot(target_dir))
	
	var base_turn_speed = 100.0 + (clamp(32 - (player.global_position - position).length(), 0, 32) * 8)
	
	var torque = rotation_axis.normalized() * angle * base_turn_speed
	
	move_y = -0.5
	
	if (player.linear_velocity.length() < 32) and ((player.global_position - position).length() < 128):
		torque = rotation_axis.normalized() * angle * base_turn_speed
		
		move_y = 0
	if (player.global_position - position).length() < 32:
		firing_target = player.global_position + (player.linear_velocity * 0.1)
		torque = rotation_axis.normalized() * angle * base_turn_speed
		
		move_y = -0.25
	elif (player.global_position - position).length() < 64:
		torque *= 3
		move_y = -0.25
		
	apply_torque(torque)
	
	super(delta)
