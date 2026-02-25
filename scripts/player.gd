extends CharacterBody3D

@export var walk_speed = 5.0
@export var gravity = 9.8

@export var mouse_sensitivity = 0.002
@export var controller_camera_sensitivity = 2.2

@onready var camera = $Camera
@onready var raycast = $Camera/Raycast

var damage = 25

var bullet_trail_scene = preload("res://scenes/bullet_fire_line.tscn")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		camera.rotation.x = clamp((camera.rotation.x - (event.relative.y * mouse_sensitivity)), -PI/2, PI/2)

func _handle_controller_camera_input(delta):
	var input_dir = Input.get_vector("camera_left", "camera_right", "camera_down", "camera_up")
	
	rotate_y(-input_dir.x * controller_camera_sensitivity * delta)
	
	camera.rotation.x = clamp((camera.rotation.x - (-input_dir.y * controller_camera_sensitivity * delta)), -PI/2, PI/2)
	

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 4
		
	_handle_controller_camera_input(delta)

	var input_dir = Input.get_vector("move_backwards", "move_forward", "move_left", "move_right")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	move_and_slide()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("fire"):
		var bullet_trail = bullet_trail_scene.instantiate()
		
		bullet_trail.origin = $Camera/TrailOrigin.global_position
		bullet_trail.target = raycast.get_collision_point()
		
		get_parent().add_child(bullet_trail)
		
		$Gunshot1.play()
		
		var collider = raycast.get_collider()
		
		if collider: 
			print(collider)
			
			if "health" in collider:
				collider.health -= damage
			elif collider.has_meta("owner"):
				if collider.name == "head":
					collider.get_meta("owner").health -= damage * 2
				elif collider.name == "torso":
					collider.get_meta("owner").health -= damage
				else:
					collider.get_meta("owner").health -= damage * 0.66
			
