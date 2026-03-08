extends CharacterBody3D

@export var walk_speed := 5.0
@export var gravity := 9.8

@export var mouse_sensitivity := 0.002
@export var controller_camera_sensitivity := 2.2

@onready var camera := $Camera
@onready var raycast := $Camera/Raycast

@onready var game = get_parent()

var damage := 40
var crouching := false
var busy := false

var health := 100.0
var health_regen_check := 100.0
var health_regen_timer := 2.0

var bullet_trail_scene := preload("res://scenes/bullet_fire_line.tscn")
var sound_alert_scene := preload("res://scenes/sound_alert.tscn")
var stealth_indicator_scene := preload("res://scenes/ground_direction.tscn")

var camera_shake := 0.0

var viewmodel_offset: Vector3 

var dead = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	viewmodel_offset = $Camera/Viewmodel.global_position - $Camera/Viewmodel/camera.global_position
	
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
		
	if dead:
		velocity.x = 0
		velocity.z = 0
		
		move_and_slide()
		
		return
	
	
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
		
	camera.h_offset = randf_range(camera_shake, -camera_shake)
	camera.v_offset = randf_range(camera_shake, -camera_shake)
	
	$Camera/Viewmodel.position = viewmodel_offset + Vector3(camera.h_offset, camera.v_offset, 0)
	
	camera_shake -= delta / 3
	if camera_shake < 0: camera_shake = 0

	move_and_slide()

func _process(delta: float) -> void:
	if dead:
		camera.position.y += (0.2 - camera.position.y) / (5 - ((1/delta)/60))
		$StealthIndicator.modulate.a += (0.0 - $StealthIndicator.modulate.a) / (5 - ((1/delta)/60))
		
		camera.rotation.x = 0
		camera.rotation_degrees.z = -20.0
		
		health = 0
		
		AudioServer.set_bus_effect_enabled(1, 0, true)
		AudioServer.set_bus_effect_enabled(2, 0, true)
		
		return
		
	if health <= 0:
		dead = true
	
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
		$StealthIndicator.modulate.a += (0.5 - $StealthIndicator.modulate.a) / (5 - ((1/delta)/60))
		
		for n in game.get_node("Enemies").get_children():
			if ((n.global_position - global_position).length() < 24) and (n.health > 0):
				var has_indicator = false
				
				for o in $StealthIndicator.get_children():
					if o.target == n: 
						has_indicator = true
						break
						
				if has_indicator: continue
				
				var indicator = stealth_indicator_scene.instantiate() 
				
				indicator.texture = load("res://textures/direction_enemy.png")
				indicator.stealth_suspicion = true
				indicator.free_on_target_destroyed = true
				indicator.target = n
				
				$StealthIndicator.add_child(indicator)
	else:
		camera.position.y += (2.15 - camera.position.y) / (5 - delta)
		$StealthIndicator.modulate.a += (0.0 - $StealthIndicator.modulate.a) / (5 - ((1/delta)/60))
		
	if Input.is_action_just_pressed("melee") and !busy:
		$Camera/Viewmodel/AnimationPlayer.stop()
		$Camera/Viewmodel/AnimationPlayer.play("melee")
		
		busy = true
		
		await get_tree().create_timer(0.25).timeout
		
		var collider = raycast.get_collider()
		
		if collider and (($Camera.global_position - raycast.get_collision_point()).length() < 2):
			camera_shake = 0.03
			
			if "health" in collider:
				collider.health -= damage
			elif collider.has_meta("owner"):
				var collider_owner = collider.get_meta("owner")
				
				if collider.name == "head":
					if (collider_owner.phase == collider_owner.AI_PHASE.ATTACK) or (collider_owner.phase == collider_owner.AI_PHASE.PURSUE):
						collider_owner.health -= damage * 2
					else:
						collider_owner.health -= damage * 60000
				elif collider.name.contains("leg"):
					collider_owner.health -= damage * 0.66
				else:
					collider_owner.health -= damage
					
				if (collider_owner.health <= 0) or (collider_owner.phase != collider_owner.AI_PHASE.DEAD_AS_FUCK):
					collider_owner.phase = collider_owner.AI_PHASE.ATTACK
					collider_owner.state = collider_owner.AI_STATE.ATTACK_DECIDE
				
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
		var spread = 1
		
		raycast.rotation += Vector3(deg_to_rad(randf_range(-spread, spread)), deg_to_rad(randf_range(-spread, spread)), 0.0)
		raycast.force_raycast_update()
		
		var bullet_trail = bullet_trail_scene.instantiate()
		
		bullet_trail.origin = $Camera/TrailOrigin.global_position
		bullet_trail.target = raycast.get_collision_point()
		
		get_parent().add_child(bullet_trail)
		
		var sound_alert = sound_alert_scene.instantiate()
		
		sound_alert.radius = 16
		sound_alert.aggravate_enemies = true
		
		get_parent().add_child(sound_alert)
		
		sound_alert.global_position = camera.global_position
		
		$Gunshot1.play()
		
		camera_shake = 0.05
		
		$Camera/Viewmodel/AnimationPlayer.stop()
		$Camera/Viewmodel/AnimationPlayer.play("fire")
		
		var collider = raycast.get_collider()
		
		if collider:
			game.handle_hit_particle_effect(collider, raycast.get_collision_point(), raycast.get_collision_normal())
			
			if "health" in collider:
				collider.health -= damage
			elif collider.has_meta("owner"):
				var collider_owner = collider.get_meta("owner")
				
				collider_owner.memory_point = global_position
				
				if collider.name == "head":
					collider_owner.health -= damage * 2
				elif collider.name == "torso":
					collider_owner.health -= damage
				else:
					collider_owner.health -= damage * 0.66
					
				if (collider_owner.health <= 0) or (collider_owner.phase != collider_owner.AI_PHASE.DEAD_AS_FUCK):
					collider_owner.phase = collider_owner.AI_PHASE.ATTACK
					collider_owner.state = collider_owner.AI_STATE.ATTACK_DECIDE
		
		raycast.rotation = Vector3()
			
			
