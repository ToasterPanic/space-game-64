extends CharacterBody3D

@export var walk_speed := 5.0
@export var gravity := 9.8

@export var mouse_sensitivity := 0.002
@export var controller_camera_sensitivity := 2.2

@onready var camera := $Camera
@onready var raycast := $Camera/Raycast

var damage := 25
var crouching := false
var busy := false

var health := 100.0
var health_regen_check := 100.0
var health_regen_timer := 2.0

var bullet_trail_scene := preload("res://scenes/bullet_fire_line.tscn")
var sound_alert_scene := preload("res://scenes/sound_alert.tscn")

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
	
	if health != health_regen_check:
		if health < health_regen_check:
			health_regen_timer = 5.0
			
		health_regen_check = health
		
	health_regen_timer -= delta
	
	if (health_regen_timer < 0.0) and (health < 100.0):
		health += delta * 15.0
	
	if Input.is_action_just_pressed("crouch"):
		if crouching and !$CrouchCheck.is_colliding(): crouching = false
		else: crouching = true
		
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
				var collider_owner = collider.get_meta("owner")
				
				if collider.name == "head":
					if (collider_owner.phase == collider_owner.AI_PHASE.ATTACK) or (collider_owner.phase == collider_owner.AI_PHASE.PURSUE):
						collider_owner.health -= damage * 2
					else:
						collider_owner.health -= damage * 60000
				elif collider.name == "torso":
					collider_owner.health -= damage
				else:
					collider_owner.health -= damage * 0.66
					
				collider_owner.phase = collider_owner.AI_PHASE.PURSUE
				collider_owner.state = collider_owner.AI_STATE.PURSUE_CHASE
				collider_owner.memory_point = global_position
		
		await get_tree().create_timer(0.15).timeout
		
		busy = false
		
	if Input.is_action_just_pressed("interact"):
		var collider = $Camera/InteractCast.get_collider()
		
		if collider:
			var collision_point = $Camera/InteractCast.get_collision_point() 
			var distance = (collider.global_position - global_position).length()
					
			if (collider is Area3D) and (distance < collider.interact_range):
				collider.interacted_node.interact(collider.action_id)
	if Input.is_action_just_pressed("fire") and !busy:
		var bullet_trail = bullet_trail_scene.instantiate()
		
		bullet_trail.origin = $Camera/TrailOrigin.global_position
		bullet_trail.target = raycast.get_collision_point()
		
		get_parent().add_child(bullet_trail)
		
		var sound_alert = sound_alert_scene.instantiate()
		
		sound_alert.radius = 16
		
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
				var collider_owner = collider.get_meta("owner")
				
				collider_owner.phase = collider_owner.AI_PHASE.PURSUE
				collider_owner.state = collider_owner.AI_STATE.PURSUE_CHASE
				collider_owner.memory_point = global_position
				
				if collider.name == "head":
					collider_owner.health -= damage * 2
				elif collider.name == "torso":
					collider_owner.health -= damage
				else:
					collider_owner.health -= damage * 0.66
			
			
