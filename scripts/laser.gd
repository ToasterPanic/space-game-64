extends RigidBody3D

var creator = null

var time = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	delta += time
	
	if time > 10:
		queue_free()
	
func _on_body_entered(body: Node) -> void:
	if "health" in body:
		body.health -= 20
	
	queue_free()
