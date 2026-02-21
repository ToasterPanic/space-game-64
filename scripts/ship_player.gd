extends "res://scripts/ship.gd"

func _handle_controller_rotation_input(delta):
	var input_dir = Input.get_vector("camera_left", "camera_right", "camera_down", "camera_up")
	
	rotate_object_local(Vector3.RIGHT, input_dir.y * controller_camera_sensitivity * delta)
	rotate_object_local(Vector3.UP, -input_dir.x * controller_camera_sensitivity * delta)
	
func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	boosting = Input.is_action_pressed("boost")
	
	if Input.is_action_just_released("boost"):
		$BoostFinish.play()
	
	var input_dir := Input.get_vector("ship_left", "ship_right", "move_forward", "move_backwards")
	move_x = input_dir.x
	move_y = input_dir.y
	
	super(delta)
	
	_handle_controller_rotation_input(delta)
