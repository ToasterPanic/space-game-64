extends Area3D

@export var radius := 0
@export var aggravate_enemies := false
@export var attract_enemies := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var shape = SphereShape3D.new()
	
	shape.radius = radius
	
	$Collision.shape = shape
	
	await get_tree().create_timer(0.5).timeout
	
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
