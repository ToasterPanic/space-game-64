extends CharacterBody3D

# Exports for easy in-editor editing
@export var health := 100.0
@export var body_texture: Texture2D = load("res://textures/character_test.png")

@export var min_spread := 4.0
@export var max_spread := 7.0

@export var points: Array[Node3D] = [ ]
@export var point_delay_time := 5.0

# Internal values
#var dead := false
var firing := false

var phase: AI_PHASE = AI_PHASE.IDLE
var state: AI_STATE = AI_STATE.IDLE_WALK_TO_POINT
var state_timer := 0.0
var firing_timer := 0.0

var current_point := 0

var suspicion := 0.0
var concentration := 0.0

var memory_point = null # Are nullable typed vars a thing? If they are I couldn't figure it out
var can_see_player := false

var ai_tick_timer := randf_range(0.0, 0.05)

var rotation_target := Vector3(0.0, 0.0, 0.0)

# Nodes for quick use
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

# Scenes to load
var bullet_trail_scene = preload("res://scenes/bullet_fire_line.tscn")

# Functions
func _set_look_target(value: Vector3) -> void:
	if global_transform.origin == value: return
	
	var new_transform = global_transform.looking_at(value)
	rotation_target = new_transform.basis.get_euler()
		
func _is_player_in_fov() -> bool:
	return (abs(rad_to_deg(sight.rotation.y)) < 75) and (abs(rad_to_deg(sight.rotation.x)) < 50)
		
func _can_shoot_player() -> bool:
	raycast.look_at(player.get_node("Camera").global_position) 
	raycast.force_raycast_update()
	
	return _is_player_in_fov() and (raycast.get_collider() == player)
		
func _can_see_player() -> bool:
	sight.look_at(player.get_node("Camera").global_position)
	sight.force_raycast_update()
			
	return _is_player_in_fov() and (sight.get_collider() == player) 

# Okay the actual script starts here promise!!!!
func _ready() -> void:
	# Create a point at the enemy's position if there isn't one already
	if points == [ ]:
		var point = Node3D.new()
		point.global_position = global_position
		
		game.add_child(point)
		
		points = [ point ]
	
	# Make sure all limb colliders have the enemy set as the owner
	for n in $Mesh/Skeleton3D.get_children():
		var body = n.find_child(n.name).get_node("StaticBody3D")
		
		body.name = n.name.get_slice("_2", 0)
		body.set_meta("owner", self)

func interact(action_id: String) -> void:
	if (action_id == "drag") and (phase == AI_PHASE.DEAD_AS_FUCK):
		if state == AI_STATE.DEAD_AS_FUCK_IDLE:
			state = AI_STATE.DEAD_AS_FUCK_DRAGGED
			player.crouching = true
			
		else:
			state = AI_STATE.DEAD_AS_FUCK_IDLE

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
		
		if (health <= 0) and (phase != AI_PHASE.DEAD_AS_FUCK):
			phase = AI_PHASE.DEAD_AS_FUCK
			state = AI_STATE.DEAD_AS_FUCK_IDLE
		
		if (phase != AI_PHASE.ATTACK) and (phase != AI_PHASE.DEAD_AS_FUCK):
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
			
			if concentration < 0: concentration = 0
			
			if ((player.global_position - global_position).length() > 7.5) or (!_can_shoot_player()):
				if navigator.target_position != player.global_position:
					navigator.target_position = player.global_position
					
				var direction = global_position.direction_to(navigator.get_next_path_position())
				velocity.x = direction.x * 3.0
				velocity.z = direction.z * 3.0
				
				concentration -= tick_delta
			else:
				firing_timer -= tick_delta
				concentration += tick_delta / 4
				
				if (firing_timer < 0) and (concentration > 0.2):
					firing_timer = 0.25
					
					if concentration > 0.8: concentration = 0.8
					
					var spread = randf_range(min_spread, max_spread) * (1 - concentration)
					
					print(spread)
				
					$Raycast.rotation += Vector3(deg_to_rad(randf_range(-spread, spread)), deg_to_rad(randf_range(-spread, spread)), 0.0)
					$Raycast.force_raycast_update()
					
					var bullet_trail = bullet_trail_scene.instantiate() 
					
					bullet_trail.origin = fire_point.global_position
					bullet_trail.target = $Raycast.get_collision_point()
					
					get_parent().get_parent().add_child(bullet_trail)
					
					if $Raycast.get_collider() == player:
						print("HIT" + str(delta))
				
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

	
	if phase == AI_PHASE.DEAD_AS_FUCK:
		animator.set("parameters/dead/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		$CollisionShape.disabled = true
		
		if state == AI_STATE.DEAD_AS_FUCK_DRAGGED:
			_set_look_target(player.global_position)
			
			var distance = (global_position - player.global_position).length()
			
			if distance > 1.5:
				var direction = global_position.direction_to(player.global_position)
				velocity.x = direction.x * (player.velocity.length())
				velocity.z = direction.z * (player.velocity.length())
				
			if !player.crouching:
				state = AI_STATE.DEAD_AS_FUCK_IDLE
	
	global_rotation.y = lerp_angle(global_rotation.y, rotation_target.y, 6.0 * delta)
		
	move_and_slide()
	
	# Handle weapon equip animations
	if (phase == AI_PHASE.ATTACK) or (phase == AI_PHASE.PURSUE):
		if !animator.get("parameters/pistol_idle/active"):
			animator.set("parameters/pistol_equip/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			animator.set("parameters/pistol_idle/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	else:
		if animator.get("parameters/pistol_idle/active"):
			animator.set("parameters/pistol_idle/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	
	# You have to set it after move_and_slide() otherwise it takes unapplied gravity into account
	animator.set("parameters/walk/blend_amount", clampf(velocity.length() / 4, 0, 1))
