extends Node3D

@onready var game = get_parent()
@onready var player = game.get_node("Player")
@onready var hold_points = game.get_node("HoldPoints")

@onready var hold_direction = $HoldDirection

var enemy_scene = preload("res://scenes/ground_enemy.tscn")

var current_hold = null
var timer = 0.25

var layer = 1

func _pick_hold() -> void:
	var valids = []
	for n in hold_points.get_children():
		if n.active or n.completed: continue
		
		valids.push_front(n)
		
	if valids.size() == 0: return
		
	current_hold = valids[randi_range(0, valids.size() - 1)]
	
	hold_direction.target = current_hold.get_node("HoldArea")
	current_hold.get_node("HoldArea").position.y -= 9999
	
func _generate_inbetween_enemies() -> void:
	var valids = []
	for n in game.get_node("AINodes").get_children():
		$Cast.global_position = n.global_position
		$Cast.look_at(player.global_position)
		$Cast.force_raycast_update()
		
		if $Cast.get_collider() != player:
			valids.push_front(n)
	
	var i = 0
	while i < 4:
		var index = randi_range(0, valids.size() - 1)
		var picked_spot = valids[index]
		valids.remove_at(index)
		
		print(picked_spot)
		
		var enemy = enemy_scene.instantiate()
		
		var nodes: Array[Node] = picked_spot.get_children()
		nodes.push_back(picked_spot)
		
		enemy.global_position = picked_spot.global_position
		for n in nodes: enemy.points.push_front(n)
		
		game.get_node("Enemies").add_child(enemy)
		
		i += 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	remove_child(hold_direction)
	player.get_node("StealthIndicator").add_child(hold_direction)
	hold_direction.position = Vector3()
	
	_pick_hold()
	_generate_inbetween_enemies()
	
	print(current_hold)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer -= delta
	
	if timer <= 0:
		timer = 0.25
		
		if current_hold.completed:
			layer += 1
			
			_pick_hold()
			_generate_inbetween_enemies()
			
			if current_hold:
				current_hold.layers = layer
				current_hold.layers_left = layer
