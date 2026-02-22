extends RigidBody3D

var creator = null

var time = 0

var damage = 20

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
		if ("shield" in body) and (body.shield > 0):
			print(body.shield)
			print((1.0 - (body.shield/100.0)))
			
			body.shield -= damage
			
			if body.shield <= 0:
				body.shield = 0
				
				if body.has_node("ShieldBreak"): body.get_node("ShieldBreak").play()
		else:
			body.health -= damage
	
	queue_free()
