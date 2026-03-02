extends CharacterBody3D

@export var walk_speed = 5.0
@export var gravity = 9.8

@export var mouse_sensitivity = 0.002
@export var controller_camera_sensitivity = 2.2

@onready var camera = $Camera
@onready var raycast = $Camera/Raycast

var damage = 25
var crouching = false
var busy = false

var bullet_trail_scene = preload("res://scenes/bullet_fire_line.tscn")

var sound_alert_scene = preload("res://scenes/sound_alert.tscn")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var viewmodel_offset = $Camera/Viewmodel.global_position - $Camera/Viewmodel/camera.global_position
	
	$Camera/Viewmodel.position = viewmodel_offset

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
	if Input.is_action_just_pressed("jump"):
		velocity.y = 4
		
	_handle_controller_camera_input(delta)

	var input_dir = Input.get_vector("move_backwards", "move_forward", "move_left", "move_right")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed
	
	if crouching:
		velocity.x /= 2
		velocity.z /= 2

	move_and_slide()

func _process(delta: float) -> void:
	if !$Camera/Viewmodel/AnimationPlayer.current_animation:
		$Camera/Viewmodel/AnimationPlayer.play("idle")
		
	$Stand.disabled = crouching
	
	if Input.is_action_pressed("crouch"):
		crouching = true
	elif !$CrouchCheck.is_colliding():
		crouching = false
		
	if crouching:
		camera.position.y += (1.15 - camera.position.y) / (5 - ((1/delta)/60))
	else:
		camera.position.y += (2.15 - camera.position.y) / (5 - delta)
		
	if Input.is_action_just_pressed("melee") and !busy:
		$Camera/Viewmodel/AnimationPlayer.stop()
		$Camera/Viewmodel/AnimationPlayer.play("melee")
		
		busy = true
		
		await get_tree().create_timer(0.25).timeout
		
		var collider = raycast.get_collider()
		
		if collider and (($Camera.global_position - raycast.get_collision_point()).length() < 2):
			if "health" in collider:
				collider.health -= damage
			elif collider.has_meta("owner"):
				var owner = collider.get_meta("owner")
				
				if collider.name == "head":
					if owner.spotted:
						owner.health -= damage * 2
					else:
						owner.health -= damage * 60000
				elif collider.name == "torso":
					owner.health -= damage
				else:
					owner.health -= damage * 0.66
				
				owner.spotted = true
				owner.memory_location = global_position
				owner.pursuing = true
				owner.search_timer = 5
		
		await get_tree().create_timer(0.15).timeout
		
		busy = false
		
	if Input.is_action_just_pressed("fire") and !busy:
		var bullet_trail = bullet_trail_scene.instantiate()
		
		bullet_trail.origin = $Camera/TrailOrigin.global_position
		bullet_trail.target = raycast.get_collision_point()
		
		get_parent().add_child(bullet_trail)
		
		var sound_alert = sound_alert_scene.instantiate()
		
		sound_alert.radius = 4
		
		get_parent().add_child(sound_alert)
		
		sound_alert.global_position = camera.global_position
		
		$Gunshot1.play()
		
		$Camera/Viewmodel/AnimationPlayer.stop()
		$Camera/Viewmodel/AnimationPlayer.play("fire")
		
		var collider = raycast.get_collider()
		
		if collider:
			if "health" in collider:
				collider.health -= damage
			elif collider.has_meta("owner"):
				var owner = collider.get_meta("owner")
				
				owner.spotted = true
				owner.memory_location = global_position
				owner.pursuing = true
				owner.search_timer = 5
				
				if collider.name == "head":
					owner.health -= damage * 2
				elif collider.name == "torso":
					owner.health -= damage
				else:
					owner.health -= damage * 0.66
			
			
