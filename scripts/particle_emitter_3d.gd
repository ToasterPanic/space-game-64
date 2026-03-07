extends Node3D
class_name ParticleEmitter3D 

@export var delete_on_end := true
@export var effect_length := 0.0

func play() -> void:
	for n in get_children():
		n.restart()
	
	await get_tree().create_timer(effect_length).timeout
	
	queue_free()
