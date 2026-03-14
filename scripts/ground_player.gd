extends CharacterBody3D

@export var walk_speed := 6.0
@export var gravity := 9.8

@export var mouse_sensitivity := 0.002
@export var controller_camera_sensitivity := 2.2

@onready var camera := $Camera
@onready var raycast := $Camera/Raycast

@onready var game = get_parent()

var crouching := false
var busy := false

var health := 100.0
var health_regen_check := 100.0
var health_regen_timer := 2.0

var fire_delay := 0.0
var ammo_in_mag := 0

var bullet_trail_scene := preload("res://scenes/bullet_fire_line.tscn")
var sound_alert_scene := preload("res://scenes/sound_alert.tscn")
var stealth_indicator_scene := preload("res://scenes/ground_direction.tscn")

var camera_shake := 0.0

var weapon = "pistol"
var weapon_stats = {}

var viewmodel_offset: Vector3 

var viewmodel = null

var dead = false

func _set_viewmodel(name: String) -> void:
	if viewmodel: viewmodel.queue_free()
	
	viewmodel = load("res://scenes/viewmodels/" + name + ".tscn").instantiate()
	viewmodel.set_name("Viewmodel")
	
	for n in viewmodel.find_children("*"):
		if "cast_shadow" in n:
			n.cast_shadow = false
	
	viewmodel.global_position = $Camera.global_position
	
	print(viewmodel.get_node("camera").position)
	
	var old_rotation = camera.rotation
	
	camera.rotation_degrees = Vector3(0, -90, 0)
	
	viewmodel_offset = -viewmodel.get_node("camera").position * 0.1
	
	$Camera.add_child(viewmodel)
	
	viewmodel.scale = Vector3(0.1, 0.1, 0.1)
	
	camera.rotation = old_rotation
	
	viewmodel.position = viewmodel_offset

	print(viewmodel_offset)
	
func _set_weapon(name: String) -> void:
	weapon_stats = weapons.list[name]
	
	ammo_in_mag = weapon_stats["mag_size"]
	
	_set_viewmodel(name)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if LimboConsole.has_command("set_weapon"): LimboConsole.unregister_command("set_weapon")
	
	LimboConsole.register_command(_set_weapon, "set_weapon", "Sets the player's weapon")
	
	_set_weapon("pistol")

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
	
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 4
		
	_handle_controller_camera_input(delta)

	var input_dir = Input.get_vector("move_backwards", "move_forward", "move_left", "move_right")
	
	camera.rotation_degrees.z += ((-input_dir.y) - camera.rotation_degrees.z) / (5 - ((1/delta)/60))
	viewmodel.rotation_degrees.z = -camera.rotation_degrees.z
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var velocity_goal_x = direction.x * walk_speed
	var velocity_goal_z = direction.z * walk_speed
	
	if crouching:
		velocity_goal_x /= 2
		velocity_goal_z /= 2
		
	velocity.x += (velocity_goal_x - velocity.x) / (5 - ((1/delta)/60))
	velocity.z += (velocity_goal_z - velocity.z) / (5 - ((1/delta)/60))
		
	camera.h_offset = randf_range(camera_shake, -camera_shake)
	camera.v_offset = randf_range(camera_shake, -camera_shake)
	
	viewmodel.position = viewmodel_offset + Vector3(camera.h_offset, camera.v_offset, 0)
	
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
	
	if !viewmodel.get_node("AnimationPlayer").current_animation:
		viewmodel.get_node("AnimationPlayer").play("idle")
		
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
		viewmodel.get_node("AnimationPlayer").stop()
		viewmodel.get_node("AnimationPlayer").play("melee")
		
		busy = true
		
		await get_tree().create_timer(0.25).timeout
		
		var collider = raycast.get_collider()
		
		if collider and (($Camera.global_position - raycast.get_collision_point()).length() < 2):
			camera_shake = 0.03
			
			if "health" in collider:
				collider.health -= weapon_stats["damage"]
			elif collider.has_meta("owner"):
				var collider_owner = collider.get_meta("owner")
				
				if collider.name == "head":
					if (collider_owner.phase == collider_owner.AI_PHASE.ATTACK) or (collider_owner.phase == collider_owner.AI_PHASE.PURSUE):
						collider_owner.health -= weapon_stats["damage"] * 2
					else:
						collider_owner.health -= weapon_stats["damage"] * 60000
				elif collider.name.contains("leg"):
					collider_owner.health -= weapon_stats["damage"] * 0.66
				else:
					collider_owner.health -= weapon_stats["damage"]
					
				if (collider_owner.health <= 0) or (collider_owner.phase != collider_owner.AI_PHASE.DEAD_AS_FUCK):
					collider_owner.phase = collider_owner.AI_PHASE.ATTACK
					collider_owner.state = collider_owner.AI_STATE.ATTACK_DECIDE
				
				collider_owner.memory_point = global_position
		
		await get_tree().create_timer(0.15).timeout
		
		busy = false
		
	if Input.is_action_just_pressed("reload") and !busy:
		viewmodel.get_node("AnimationPlayer").stop()
		viewmodel.get_node("AnimationPlayer").play("reload")
		
		if viewmodel.has_node("Reload"): viewmodel.get_node("Reload").play()
		
		busy = true
		
		await get_tree().create_timer(viewmodel.get_node("AnimationPlayer").get_animation("reload").length).timeout
		
		ammo_in_mag = weapon_stats["mag_size"]
		
		busy = false
		
	if Input.is_action_just_pressed("interact"):
		var collider = $Camera/InteractCast.get_collider()
		
		if collider:
			var collision_point = $Camera/InteractCast.get_collision_point() 
			var distance = (collider.global_position - global_position).length()
					
			if (collider is Area3D) and (distance < collider.interact_range):
				collider.interacted_node.interact(collider.action_id)
				
	fire_delay -= delta
	
	if Input.is_action_pressed("fire") and (!busy) and (fire_delay <= 0) and (ammo_in_mag > 0):
		if !weapon_stats.has("automatic") and !Input.is_action_just_pressed("fire"): return
		
		ammo_in_mag -= 1
			
		fire_delay = weapon_stats.firerate
		
		var spread = weapon_stats["spread"]
		
		var bullets_to_fire = weapon_stats["bullets_per_shot"] if weapon_stats.has("bullets_per_shot") else 1
		
		var i = 0
		while i < bullets_to_fire:
			raycast.rotation += Vector3(deg_to_rad(randf_range(-spread, spread)), deg_to_rad(randf_range(-spread, spread)), 0.0)
			raycast.force_raycast_update()
			
			var bullet_trail = bullet_trail_scene.instantiate()
			
			bullet_trail.origin = $Camera/TrailOrigin.global_position
			bullet_trail.target = raycast.get_collision_point()
			
			get_parent().add_child(bullet_trail)
			
			var sound_alert = sound_alert_scene.instantiate()
			
			sound_alert.radius = weapon_stats["firing_sound_radius"] if weapon_stats.has("firing_sound_radius") else 12
			sound_alert.aggravate_enemies = true
			
			sound_alert.global_position = camera.global_position
			
			game.add_child(sound_alert)
			
			sound_alert = sound_alert_scene.instantiate()
			
			sound_alert.radius = weapon_stats["bullet_sound_radius"] if weapon_stats.has("bullet_sound_radius") else 6
			
			sound_alert.global_position = raycast.get_collision_point()
			
			game.add_child(sound_alert)
			
			if viewmodel.has_node("Fire"): viewmodel.get_node("Fire").play() 
			else: $Gunshot1.play()
			
			camera_shake = 0.05
			
			viewmodel.get_node("AnimationPlayer").stop()
			viewmodel.get_node("AnimationPlayer").play("fire")
			
			var collider = raycast.get_collider()
			
			if collider:
				game.handle_hit_particle_effect(collider, raycast.get_collision_point(), raycast.get_collision_normal())
				
				if "health" in collider:
					collider.health -= weapon_stats["damage"]
				elif collider.has_meta("owner"):
					var collider_owner = collider.get_meta("owner")
					
					collider_owner.memory_point = global_position
					
					if collider.name == "head":
						collider_owner.health -= weapon_stats["damage"] * weapon_stats.headshot_multiplier
					elif collider.name.contains("leg"):
						collider_owner.health -= weapon_stats["damage"] * 0.66
					else:
						collider_owner.health -= weapon_stats["damage"]
						
					if (collider_owner.health <= 0) or (collider_owner.phase != collider_owner.AI_PHASE.DEAD_AS_FUCK):
						collider_owner.phase = collider_owner.AI_PHASE.ATTACK
						collider_owner.state = collider_owner.AI_STATE.ATTACK_DECIDE
			
			raycast.rotation = Vector3()
			
			i += 1
			
			
