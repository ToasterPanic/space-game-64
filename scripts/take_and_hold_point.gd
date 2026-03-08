extends Node3D

@onready var game = get_parent().get_parent()
@onready var player = game.get_node("Player")
@onready var enemies = game.get_node("Enemies")

var active = false
var completed = false

var timer = 60

var layers_left = 2
var layers = 2
var time_until_next_spawn = 5
var scanning = true

var enemy_scene = preload("res://scenes/ground_enemy.tscn")

func timer_string() -> String:
	return str(floori(timer / 60)) + ":" + str(floori(timer) % 60) + "." + str(floori((timer / 0.01)) % 100).pad_zeros(2)

func _obliterate_enemies() -> void:
	for n in enemies.get_children(): n.queue_free()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Barriers.position.y = 9999
	
func _process(delta: float) -> void:
	if active:
		timer -= delta
		
		if scanning:
			time_until_next_spawn -= delta
			
			if time_until_next_spawn <= 0:
				time_until_next_spawn = 15
				
				for n in enemies.get_children(): if n.phase == n.AI_PHASE.DEAD_AS_FUCK: n.queue_free()
				
				var spawns = $SpawnAreas.get_children()
				var spawn = spawns[randi_range(0, spawns.size() - 1)]
				
				var i = 0
				while i < 1 + layers:
					if enemies.get_children().size() > layers * 2: return
					
					var enemy = enemy_scene.instantiate()
					
					enemy.body_texture = load("res://textures/enemy_ground_1.png")
					
					enemy.memory_point = player.global_position
					enemy.phase = enemy.AI_PHASE.PURSUE
					enemy.state = enemy.AI_STATE.PURSUE_CHASE
					enemy.always_knows_player_position = true
					enemy.state_timer = 99999
					
					enemies.add_child(enemy)
					
					enemy.global_position = spawn.global_position
					
					await get_tree().create_timer(0.25).timeout
					
					i += 1
				
				
			$HoldArea/Label.text = "SCANNING\n" + timer_string()

func _on_hold_area_body_entered(body: Node3D) -> void:
	if completed: return
	if active: return
	
	if body == player:
		$HoldArea/Mesh.queue_free()
		$HoldArea.monitoring = false
		
		$Barriers.position.y = 0
		
		active = true
		completed = true
		
		_obliterate_enemies()
