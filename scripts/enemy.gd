extends CharacterBody3D

@export var health = 100
@export var texture: Texture2D = load("res://textures/character_test.png")
@export var sight_distance: int = 256

@onready var mesh = $Mesh
@onready var animator = $Animator

@onready var game = get_parent().get_parent()
@onready var player = game.get_node("Player")
@onready var fire_point = $Mesh/torso2/right_arm2/FirePoint

var spotted = false

var weapon_equipped = false

var ai_tick_timer = 0
var fire_timer = 0
var firing = false

var concentration = 0
var memory_location = null
var search_timer = 5
var pursuing = false

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

func _physics_process(delta: float) -> void:
	velocity -= Vector3(0, 9.8 * delta, 0)
	
	move_and_slide()

func _process(delta: float) -> void:
	if $Label:
		$Label.text = "Health: " + str(health) + "\nSpotted: " + str(spotted)
		
	ai_tick_timer -= delta
		
	if ai_tick_timer < 0:
		$Sight.look_at(player.get_node("Camera").global_position)
		$Sight.force_raycast_update()
		
		spotted = false
		
		var angle_difference = rad_to_deg(abs($Sight.rotation.x) + abs($Sight.rotation.y))
		if (abs(rad_to_deg($Sight.rotation.y)) < 75) and (abs(rad_to_deg($Sight.rotation.x)) < 35) and ($Sight.get_collider() == player):
			spotted = true
			
		if spotted:
			concentration += (-ai_tick_timer + 0.05) / 2
			memory_location = player.global_position
			
			
			pursuing = true
			search_timer = 5
		else:
			concentration -= (-ai_tick_timer + 0.05) / 2.5
			
		if memory_location:
			$Navigator.target_position = memory_location
			$Navigator.get_next_path_position()
			
			var direction = global_position.direction_to($Navigator.get_next_path_position())
			velocity.x = direction.x * 4.0
			velocity.z = direction.z * 4.0
			
		ai_tick_timer = 0.05
		
		
		if pursuing:
			search_timer -= 0.05 
			
			if search_timer <= 0:
				pursuing = false
				memory_location = null
				
	if memory_location:
		look_at($Navigator.get_next_path_position(),Vector3.UP)
		
		if spotted:
			look_at(player.global_position)
		
		rotation.x = 0
		rotation.z = 0 
			
	firing = spotted
	
	if pursuing != animator.get("parameters/pistol_idle/active"):
		if pursuing:
			animator.set("parameters/pistol_idle/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		else:
			animator.set("parameters/pistol_idle/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	
	if firing:
		fire_timer -= delta
		if fire_timer < 0:
			fire_timer = 0.5
			
			$Raycast.look_at(player.get_node("Camera").global_position)
			
			if concentration < 0: concentration = 0
			if concentration > 1: concentration = 1
			
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
