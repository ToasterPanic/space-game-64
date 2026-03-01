extends CharacterBody3D

@export var health = 100
@export var texture: Texture2D = load("res://textures/character_test.png")
@export var sight_distance: int = 256

@onready var mesh = $Mesh
@onready var animator = $Animator

@onready var game = get_parent().get_parent()
@onready var player = game.get_node("Player")
@onready var fire_point = $Mesh/Skeleton3D/right_arm_2
@onready var rotation_target = $Rotator

var spotted = false

var weapon_equipped = false

var ai_tick_timer = 0
var fire_timer = 0
var firing = false

var concentration = 0
var memory_location = null
var search_timer = 5
var pursuing = false
var dead = false

var suspicion = 0

@export var max_spread = 15
@export var min_spread = 3

var bullet_trail_scene = preload("res://scenes/bullet_fire_line.tscn")

func _apply_texture(node: Node, material: StandardMaterial3D):
	for n in node.get_children():
		if n.is_class("MeshInstance3D"):
			n.material_override = material
		else:
			_apply_texture(n, material)

func _ready() -> void:
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		
	_apply_texture(mesh, material)
	
	$Sight.target_position *= sight_distance
	
	for n in $Mesh/Skeleton3D.get_children():
		var body = n.find_child(n.name).get_node("StaticBody3D")
		
		body.name = n.name.get_slice("_2", 0)
		body.set_meta("owner", self)

func _physics_process(delta: float) -> void:
	velocity -= Vector3(0, 9.8 * delta, 0)
	
	move_and_slide()
	

func _process(delta: float) -> void:
	if $Label:
		$Label.text = "Health: " + str(health) + "\nSpotted: " + str(spotted) + "\nSus: " + str(suspicion)
		
	if (health <= 0) and !dead:
		dead = true
		firing = false
		spotted = false
		memory_location = false
		
		$CollisionShape.disabled = true
		
		velocity = Vector3()
		
		animator.set("parameters/dead/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
	ai_tick_timer -= delta
		
	if (ai_tick_timer < 0) and !dead:
		$Sight.look_at(player.get_node("Camera").global_position)
		$Sight.force_raycast_update()
		
		spotted = false
		
		var angle_difference = rad_to_deg(abs($Sight.rotation.x) + abs($Sight.rotation.y))
		if (abs(rad_to_deg($Sight.rotation.y)) < 75) and (abs(rad_to_deg($Sight.rotation.x)) < 35) and ($Sight.get_collider() == player):
			suspicion += delta * 6
			
			if pursuing:
				suspicion += delta * 4
			
			spotted = true
			
		if spotted and (suspicion > 1):
			concentration += (-ai_tick_timer + 0.05) / 2
			memory_location = player.global_position
			
			pursuing = true
			search_timer = 5
			suspicion = 1
		else:
			concentration -= (-ai_tick_timer + 0.05) / 2.5
			
			suspicion -= delta
			if suspicion < 0:
				suspicion = 0
			
		if memory_location:
			$Navigator.target_position = memory_location
			$Navigator.get_next_path_position()
			
			var direction = global_position.direction_to($Navigator.get_next_path_position())
			velocity.x = direction.x * 3.0
			velocity.z = direction.z * 3.0
			
		ai_tick_timer = 0.05
		
		
		if pursuing:
			search_timer -= 0.05 
			
			if search_timer <= 0:
				pursuing = false
				memory_location = null
				
	if memory_location:
		if spotted:
			rotation_target.look_at(player.global_position)
		elif $Navigator.get_next_path_position():
			rotation_target.look_at($Navigator.get_next_path_position())
		else:
			rotation_target.look_at(memory_location)
		
	if !dead:
		global_rotation.y = lerp_angle(global_rotation.y, rotation_target.global_rotation.y, 6.0 * delta)
			
	firing = spotted
	
	animator.set("parameters/walk/blend_amount", clampf(velocity.length() / 4, 0, 1))
	
	if pursuing != animator.get("parameters/pistol_idle/active"):
		if pursuing:
			if !animator.get("parameters/pistol_equip/active"):
				animator.set("parameters/pistol_equip/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			animator.set("parameters/pistol_idle/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		else:
			animator.set("parameters/pistol_idle/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	
	if firing and !dead:
		fire_timer -= delta
		if fire_timer < 0:
			fire_timer = 0.5
			
			$Raycast.look_at(player.get_node("Camera").global_position)
			
			if concentration < 0: concentration = 0
			if concentration > 1: concentration = 1
			
			if concentration > 0.2:
				var spread = min_spread + ((max_spread - min_spread) * (1 - concentration))
			
				$Raycast.rotation += Vector3(deg_to_rad(randi_range(-spread, spread)), deg_to_rad(randi_range(-spread, spread)), 0)
				$Raycast.force_raycast_update()
				
				var bullet_trail = bullet_trail_scene.instantiate() 
				
				bullet_trail.origin = fire_point.global_position
				bullet_trail.target = $Raycast.get_collision_point()
				
				get_parent().get_parent().add_child(bullet_trail)
				
				if $Raycast.get_collider() == player:
					print("HIT" + str(delta))
	else:
		fire_timer = 0.2
