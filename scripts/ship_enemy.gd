extends "res://scripts/ship.gd"


@onready var player = get_parent().get_node("Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	laser_color = Color(1, 0, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if health < 0:
		queue_free()
		return
	
	$Health.text = str(floori(health))
	
	var target_direction = global_position.direction_to(player.global_position)
	
	if (player.global_position - position).length() < 32:
		target_direction *= -1

	var current_dir = -global_transform.basis.z
	var target_dir = (player.global_transform.origin - global_transform.origin).normalized()

	var rotation_axis = current_dir.cross(target_dir)
	var angle = acos(current_dir.dot(target_dir))
	
	var torque = rotation_axis.normalized() * angle * 100.0
	
	move_y = -0.5
	
	if (player.linear_velocity.length() < 32) and ((player.global_position - position).length() < 128):
		print(delta)
		torque = rotation_axis.normalized() * angle * 300.0
		
		move_y = 0
	if (player.global_position - position).length() < 32:
		torque = rotation_axis.normalized() * angle * 600.0
		
		move_y = -0.25
	elif (player.global_position - position).length() < 64:
		torque *= 3
		move_y = -0.25
		
	apply_torque(torque)
	
	super(delta)
