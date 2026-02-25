extends CharacterBody3D

var health = 100

func _physics_process(delta: float) -> void:
	velocity -= Vector3(0, 9.8 * delta, 0)
	$Label3D.text = "Health: " + str(health)
	
	move_and_slide()
