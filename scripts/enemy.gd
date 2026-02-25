extends CharacterBody3D

@export var health = 100
@export var texture: Texture2D = load("res://textures/character_test.png")
@export var sight_distance: int = 256

@onready var mesh = $Mesh
@onready var animator = $Animator

@onready var game = get_parent().get_parent()
@onready var player = game.get_node("Player")

var spotted = false

var weapon_equipped = false

var ai_tick_timer = 0

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
		ai_tick_timer = 1/20
		
		$Sight.look_at(player.get_node("Camera").global_position)
		$Sight.force_raycast_update()
		
		spotted = false
		
		var angle_difference = rad_to_deg(abs($Sight.rotation.x) + abs($Sight.rotation.y))
		if (abs(rad_to_deg($Sight.rotation.y)) < 75) and (abs(rad_to_deg($Sight.rotation.x)) < 35) and ($Sight.get_collider() == player):
			spotted = true
