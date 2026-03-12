extends Node3D

@export var gun = "smg"
@export var infinite = false

var game = null

func interact(action_id: String) -> void:
	if (action_id == "interact"):
		game.get_node("Player")._set_weapon(gun)
		
		if !infinite: queue_free()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite.texture = load("res://textures/weapon_pickups/" + gun + ".png")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Sprite.rotation.y += delta
