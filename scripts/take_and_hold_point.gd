extends Node3D

@onready var game = get_parent().get_parent()
@onready var player = game.get_node("Player")
@onready var enemies = game.get_node("Enemies")

var active = false
var completed = false
var loadout_state = false

var timer = 35

var layers_left = 1
var layers = 1
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
	$HoldArea.position.y += 9999
	
func _process(delta: float) -> void:
	if active:
		if !has_node("HoldArea"): return
		
		$HoldArea/Mesh.visible = !scanning
		
		time_until_next_spawn -= delta
		
		if time_until_next_spawn <= 0:
			if scanning:
				time_until_next_spawn = 12
			else:
				time_until_next_spawn = 8
			
			for n in enemies.get_children(): if n.phase == n.AI_PHASE.DEAD_AS_FUCK: n.queue_free()
			
			var spawns = $SpawnAreas.get_children()
			var spawn = spawns[randi_range(0, spawns.size() - 1)]
			
			var i = 0
			while i < floori(((layers - 1) * 0.5) + 2):
				if enemies.get_children().size() >= (layers * 2) + 1:  
					time_until_next_spawn = 12
					break
				
				var enemy = enemy_scene.instantiate()
				
				enemy.body_texture = load("res://textures/enemy_ground_1.png")
				
				enemy.memory_point = player.global_position
				enemy.phase = enemy.AI_PHASE.PURSUE
				enemy.state = enemy.AI_STATE.PURSUE_CHASE
				enemy.always_knows_player_position = true
				enemy.state_timer = 99999
				
				enemies.add_child(enemy)
				
				enemy.global_position = spawn.global_position
				
				await get_tree().create_timer(1).timeout
				
				i += 1
				
				print(str(i) +"/"+str(layers + 1))
		
		if scanning:
			timer -= delta
				
			if timer <= 0:
				scanning = false
				timer = 30
				time_until_next_spawn = 5
				
				_obliterate_enemies()
				
				var hold_spawns = $HoldSpawns.get_children()
				
				$HoldArea.global_position = hold_spawns[randi_range(0, hold_spawns.size() - 1)].global_position
				
			$HoldArea/Label.text = "SCANNING\n" + timer_string()
		
		if !scanning:
			$HoldArea/Label.text = "HOLD THIS POINT\n" + timer_string()
			
			if $HoldArea.get_overlapping_bodies().has(player):
				timer -= delta
				
				if timer < 0:
					_obliterate_enemies()
					
					layers_left -= 1
					
					if layers_left <= 0:
						completed = true
						active = false
						
						$HoldArea.position.y = 999999
						$Barriers.queue_free()
					else:
						scanning = true
						timer = 45

func _on_hold_area_body_entered(body: Node3D) -> void:
	if completed: return
	if active: return
	
	if body == player:
		$HoldArea/Mesh.visible = false
		$HoldArea.monitoring = false
		
		$HoldArea/Label.no_depth_test = true
		
		$Barriers.position.y = 0
		
		active = true
		
		_obliterate_enemies()
