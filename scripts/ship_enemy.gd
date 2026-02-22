extends "res://scripts/ship.gd"


@onready var player = get_parent().get_node("Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var target_direction = global_position.direction_to(player.global_position)

	var current_dir = -global_transform.basis.z
	var target_dir = (player.global_transform.origin - global_transform.origin).normalized()

	# Calculate rotation axis and angle between current and target direction
	var rotation_axis = current_dir.cross(target_dir)
	var angle = acos(current_dir.dot(target_dir))

	# If angle is very small, no need to rotate
	if angle < 0.01:
		return

	# Apply torque proportional to angle and axis, scaled by rotation speed
	# Torque = axis * angle * speed
	var torque = rotation_axis.normalized() * angle * 100.0

	apply_torque(torque)
	
	move_y = -0.5
	
	super(delta)
