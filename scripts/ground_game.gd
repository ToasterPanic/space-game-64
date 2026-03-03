extends Node3D

@onready var player = $Player
@onready var interact_cast = $Player/Camera/InteractCast

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var collider = interact_cast.get_collider()
	
	if collider and ("action_id" in collider):
		$UILayer/InteractFlow.visible = true
		$UILayer/InteractFlow/Label.text = collider.action_text
	else:
		$UILayer/InteractFlow.visible = false
