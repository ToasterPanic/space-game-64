extends Sprite3D

@export var target: Node3D
@export var scale_size_with_distance: bool = true
@export var free_on_target_destroyed: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target:
		visible = true
		
		look_at(target.global_position)
		
		var distance = (global_position - target.global_position).length()
		
		if scale_size_with_distance:
			scale.x = 1 - (distance / 256)
			
			if scale.x < 0.25: scale.x = 0.25
		else:
			scale.x = 1
	else:
		visible = false
		
		if free_on_target_destroyed:
			queue_free()
