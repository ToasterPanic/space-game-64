extends Node3D


var time = 0
var origin = Vector3()
var target = Vector3(12, 4, 3)
@onready var mesh = $Mesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mesh.material = mesh.material.duplicate()
	mesh.height = (origin - target).length()
		
	global_position = origin
	
	look_at(target)
	var direction = (transform.basis * Vector3.FORWARD).normalized() * (mesh.height / 2)
		
	global_position += direction
	
	$Mesh/AnimationPlayer.play("fire")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
