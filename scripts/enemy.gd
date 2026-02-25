extends CharacterBody3D

var health = 100
var texture = load("res://textures/character_test.png")

@onready var mesh = $Mesh
@onready var animator = $Animator

var weapon_equipped = false

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

func _physics_process(delta: float) -> void:
	velocity -= Vector3(0, 9.8 * delta, 0)
	
	move_and_slide()

func _process(delta: float) -> void:
	if $Label:
		$Label.text = "Health: " + str(health)
