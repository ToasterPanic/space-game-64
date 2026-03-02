extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for n in get_children():
		n.set_meta("owner", get_parent().get_parent().get_parent())
		
		var old_pos = n.global_position
		
		remove_child(n)
		
		get_parent().find_child(n.name + "_2").add_child(n)
		
		n.global_position = old_pos


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
 
