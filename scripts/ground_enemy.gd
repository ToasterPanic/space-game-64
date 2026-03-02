extends CharacterBody3D

# Exports for easy in-editor editing
@export var health := 100.0
@export var body_texture: Texture2D = load("res://textures/character_test.png")

@export var sight_max_distance: int = 256.0

@export var points: Array[Node3D] = [ ]
@export var point_delay_time := 5.0

# Internal values
var dead := false
var firing := false

var phase: AI_PHASE = AI_PHASE.IDLE
var state: AI_STATE = AI_STATE.IDLE_WALK_TO_POINT
var state_timer := 0.0

var current_point := 0

var suspicion := 0.0

var memory_point = null # Are nullable typed vars a thing? If they are I couldn't figure it out
var can_see_player := false

var ai_tick_timer = randf_range(0.0, 0.05)

# Nodes for quick use
@onready var rotation_target := $RotationTarget
@onready var mesh := $Mesh
@onready var animator := $Animator
@onready var fire_point := $Mesh/Skeleton3D/right_arm_2
@onready var sight := $Sight
@onready var raycast := $Raycast
@onready var navigator := $Navigator
@onready var hearing := $Hearing

@onready var game = get_parent().get_parent()
@onready var player = game.get_node("Player")

# Enums!!!
enum AI_PHASE { IDLE, INVESTIGATE, ATTACK, PURSUE, DEAD_AS_FUCK }

enum AI_STATE { 
	IDLE_WALK_TO_POINT, IDLE_WAIT_AT_POINT,
	INVESTIGATE_APPROACH, INVESTIGATE_SOLVE_DISTRACTION, INVESTIGATE_WAIT,
	ATTACK,
	PURSUE_CHASE, PURSUE_SEARCH,
	DEAD_AS_FUCK_IDLE, DEAD_AS_FUCK_DRAGGED
}

func _ready() -> void:
	# Create a point at the enemy's position if there isn't one already
	if points == [ ]:
		var point = Node3D.new()
		point.global_position = global_position
		
		game.add_child(point)
		
		points = [ point ]
		
func _set_look_target(value: Vector3):
	if rotation_target.global_position != value:
		rotation_target.look_at(value)
		
		
func _is_player_in_fov() -> bool:
	var angle_difference = rad_to_deg(abs(sight.rotation.x) + abs(sight.rotation.y))
	return (abs(rad_to_deg(sight.rotation.y)) < 75) and (abs(rad_to_deg(sight.rotation.x)) < 35)
		
func _can_shoot_player() -> bool:
	raycast.look_at(player.get_node("Camera").global_position)
	raycast.force_raycast_update()
	
	return _is_player_in_fov() and (raycast.get_collider() == player)
		
func _can_see_player() -> bool:
	sight.look_at(player.get_node("Camera").global_position)
	sight.force_raycast_update()
			
	var angle_difference = rad_to_deg(abs(sight.rotation.x) + abs(sight.rotation.y))
	return _is_player_in_fov() and (sight.get_collider() == player)

func _physics_process(delta: float) -> void:
	velocity.y -= 9.8 * delta
	
	$Label.text = "Health: " + str(health) + "\nphase: " + str(AI_PHASE.keys()[phase]) + "\nstate: " + str(AI_STATE.keys()[state]) + "\nstate timer: " + str(state_timer)
	
	ai_tick_timer -= delta
	
	if ai_tick_timer < 0:
		# Correct delta for AI ticks - regular delta would be extremely incorrect
		var tick_delta = 0.05 - ai_tick_timer
		
		ai_tick_timer = 0.05
		
		# Stop movement
		velocity.x = 0
		velocity.z = 0
		
		if phase != AI_PHASE.ATTACK:
			# Hearing
			for n in $Hearing.get_overlapping_areas():
				if n.attract_enemies:
					if phase == AI_PHASE.PURSUE:
						state = AI_STATE.PURSUE_CHASE
						state_timer = 2
						
						memory_point = n.global_position
					else:
						phase = AI_PHASE.INVESTIGATE
						state = AI_STATE.INVESTIGATE_APPROACH
						
						state_timer = 2
						
						memory_point = n.global_position
					
			# Sight
			if _can_see_player():
				suspicion += delta * 6
				
				if suspicion > 1:
					suspicion = 1
					
					phase = AI_PHASE.ATTACK
					state = AI_STATE.ATTACK
		
		if phase == AI_PHASE.IDLE:
			if state == AI_STATE.IDLE_WALK_TO_POINT:
				var point = points[current_point]
			
				if navigator.target_position != point.global_position:
					navigator.target_position = point.global_position
					
				var direction = global_position.direction_to(navigator.get_next_path_position())
				velocity.x = direction.x * 2.0
				velocity.z = direction.z * 2.0
				
				_set_look_target(navigator.get_next_path_position())
				
				if navigator.is_navigation_finished():
					state = AI_STATE.IDLE_WAIT_AT_POINT
					state_timer = point_delay_time
					
			elif state == AI_STATE.IDLE_WAIT_AT_POINT:
				state_timer -= tick_delta
				
				if state_timer <= 0:
					state = AI_STATE.IDLE_WALK_TO_POINT
					
					current_point += 1
					
					# DO NOT TRY AND GO TO A POINT THAT DOESN'T EXIST FUCKER
					if current_point >= points.size():
						current_point = 0
						
		elif phase == AI_PHASE.INVESTIGATE:
			if state == AI_STATE.INVESTIGATE_APPROACH:
				if navigator.target_position != memory_point:
					navigator.target_position = memory_point
					
				var direction = global_position.direction_to(navigator.get_next_path_position())
				velocity.x = direction.x * 2.0
				velocity.z = direction.z * 2.0
				
				_set_look_target(navigator.get_next_path_position())
				
				if navigator.is_navigation_finished():
					state = AI_STATE.INVESTIGATE_WAIT
					
			elif state == AI_STATE.INVESTIGATE_WAIT:
				state_timer -= tick_delta
				
				if state_timer <= 0:
					phase = AI_PHASE.IDLE
					state = AI_STATE.IDLE_WALK_TO_POINT
					
		elif phase == AI_PHASE.ATTACK:
			_set_look_target(player.global_position)
			
			memory_point = player.global_position
			
			if ((player.global_position - global_position).length() > 3.5) or (!_can_shoot_player()):
				if navigator.target_position != player.global_position:
					navigator.target_position = player.global_position
					
				var direction = global_position.direction_to(navigator.get_next_path_position())
				velocity.x = direction.x * 3.0
				velocity.z = direction.z * 3.0
				
			if !_can_see_player():
				phase = AI_PHASE.PURSUE
				state = AI_STATE.PURSUE_CHASE
				
		elif phase == AI_PHASE.PURSUE:
			if state == AI_STATE.PURSUE_CHASE:
				if navigator.target_position != memory_point:
					navigator.target_position = memory_point
					
				var direction = global_position.direction_to(navigator.get_next_path_position())
				velocity.x = direction.x * 3.0
				velocity.z = direction.z * 3.0
				
				state_timer = 2
				
				_set_look_target(navigator.get_next_path_position())
				
				if navigator.is_navigation_finished():
					state = AI_STATE.PURSUE_SEARCH
			elif state == AI_STATE.PURSUE_SEARCH:
				state_timer -= tick_delta
				
				if state_timer <= 0:
					phase = AI_PHASE.IDLE
					state = AI_STATE.IDLE_WALK_TO_POINT

	# If the enemy is not dead, rotate the player towards its rotation target
	if !dead:
		global_rotation.y = lerp_angle(global_rotation.y, rotation_target.global_rotation.y, 6.0 * delta)
		
	move_and_slide()
	
	# You have to set it after move_and_slide() otherwise it takes unapplied gravity into account
	animator.set("parameters/walk/blend_amount", clampf(velocity.length() / 4, 0, 1))
