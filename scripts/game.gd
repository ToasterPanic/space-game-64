extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 0.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Sunlight.look_at($Player/Camera.global_position)
