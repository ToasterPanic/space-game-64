extends Sprite3D

@export var target: Node3D
@export var scale_size_with_distance: bool = true
@export var stealth_suspicion: bool = true
@export var free_on_target_destroyed: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target:
		visible = true
		
		look_at(target.global_position)
		
		if stealth_suspicion:
			scale.x = target.suspicion
		
		if "health" in target:
			if target.health <= 0:
				queue_free()
	else:
		visible = false
		
		if free_on_target_destroyed:
			queue_free()
