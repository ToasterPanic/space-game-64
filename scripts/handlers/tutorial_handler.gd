extends Node3D


@onready var game: Node3D = get_parent()
@onready var player: CharacterBody3D = game.get_node("Player")

var step := 0
var capture_timer := 20.0

var enemy_scene = preload("res://scenes/ground_enemy.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if step == 0:
		if game.get_node("Enemies/Enemy").health <= 0:
			step = 1
			game.get_node("World/Door1").queue_free()
	elif step == 1:
		if game.get_node("Enemies/Enemy2").health <= 0:
			step = 2
			game.get_node("World/Door2").queue_free()
	elif step == 2:
		if game.get_node("HoldArea").get_overlapping_bodies().has(game.get_node("Player")):
			step = 3
			game.get_node("World/Door3").queue_free()
			game.get_node("HoldArea").queue_free()
	elif (step == 3) or (step == 4) or (step == 5):
		game.get_node("HoldArea2/Label").text = "" + str(floori(capture_timer / 60)) + ":" + str(floori(capture_timer) % 60) + "." + str(floori((capture_timer / 0.01)) % 100).pad_zeros(2)
		
		if game.get_node("HoldArea2").get_overlapping_bodies().has(game.get_node("Player")):
			capture_timer -= delta
			
		if ((capture_timer <= 15.0) and (step == 3)) or ((capture_timer <= 8.0) and (step == 3)):
			step += 1
			
			var enemy = enemy_scene.instantiate()
			
			enemy.body_texture = load("res://textures/enemy_ground_1.png")
				
			enemy.memory_point = player.global_position
			enemy.phase = enemy.AI_PHASE.PURSUE
			enemy.state = enemy.AI_STATE.PURSUE_CHASE
			enemy.always_knows_player_position = true
			enemy.state_timer = 99999
			
			enemy.global_position = [game.get_node("SpawnArea"), game.get_node("SpawnArea2")][randi_range(0, 1)].global_position
			
			game.get_node("Enemies").add_child(enemy)
			
		if capture_timer <= 0:
			step = 6
			game.get_node("World/Door4").queue_free()
			game.get_node("HoldArea2").queue_free()
			
	elif step == 6:
		if game.get_node("TeleArea").get_overlapping_bodies().has(game.get_node("Player")):
			game_state.ground_location = "takenhold"
			get_tree().change_scene_to_file("res://scenes/ground.tscn")
