extends Node3D

@onready var player = $Player
@onready var interact_cast = $Player/Camera/InteractCast

@onready var viewport = get_viewport()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var collider = interact_cast.get_collider()
	
	var screen_size = viewport.size
	
	$UILayer/Crosshair.position.x = (screen_size.x / 2) - 128 + ($Player/Camera.h_offset * 32.0)
	$UILayer/Crosshair.position.y = (screen_size.y / 2) - 128 + ($Player/Camera.v_offset * 32.0)
	
	if collider and ("action_id" in collider) and ((collider.global_position - player.global_position).length() < collider.interact_range):
		$UILayer/InteractFlow.visible = true
		$UILayer/InteractFlow/Label.text = collider.action_text
	else:
		$UILayer/InteractFlow.visible = false
		
	$UILayer/Damage.material.set_shader_parameter("radius", 1.0 - (player.health/100.0))
