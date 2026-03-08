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
var boldness := AI_BOLDNESS.FEARLESS

var memory_point = null # Are nullable typed vars a thing? If they are I couldn't figure it out
var can_see_player := false
var dragged_by_head := true
var has_seen_player_this_peek := false
var ai_state_before_pursuing: AI_STATE = AI_STATE.ATTACK_CHARGE
var current_cover = null

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
	ATTACK_CHARGE, ATTACK_FIND_COVER, ATTACK_COVER, ATTACK_PEEK_COVER, ATTACK_DECIDE,
	PURSUE_CHASE, PURSUE_SEARCH,
	DEAD_AS_FUCK_IDLE, DEAD_AS_FUCK_DRAGGED
}

enum AI_BOLDNESS { 
	PUSSY, NORMAL, BOLD, FEARLESS
}

# Scenes to load
var bullet_trail_scene = preload("res://scenes/bullet_fire_line.tscn")

# Functions
func _set_look_target(value: Vector3) -> void: 
	if global_transform.origin == value: return
	
	var new_transform = global_transform.looking_at(value)
	rotation_target = new_transform.basis.get_euler()
		
func _is_player_in_fov() -> bool:
	sight.look_at(player.get_node("Camera").global_position)
	
	return (abs(rad_to_deg(sight.rotation.y)) < 75) and (abs(rad_to_deg(sight.rotation.x)) < 50)
		
func _can_shoot_player() -> bool:
	raycast.look_at(player.get_node("Camera").global_position) 
	raycast.force_raycast_update()
	
	return _is_player_in_fov() and (raycast.get_collider() == player)
		
func _can_see_player() -> bool:
	sight.look_at(player.get_node("Camera").global_position)
	sight.force_raycast_update()
			
	return _is_player_in_fov() and (sight.get_collider() == player) 

func _apply_texture(node: Node, material: StandardMaterial3D):
	for n in node.get_children():
		if n.is_class("MeshInstance3D"):
			n.material_override = material
		else:
			_apply_texture(n, material)
			
func _sort_cover_points(a: Node3D, b: Node3D):
	return (a.global_position - global_position).length() < (b.global_position - global_position).length()

func on_safe_velocity_computed(safe_velocity: Vector3):
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

# Okay the actual script starts here promise!!!!
func _ready() -> void:
	NavigationServer3D.agent_set_avoidance_callback(navigator.get_rid(), self.on_safe_velocity_computed)
	
	var material = StandardMaterial3D.new()
	material.albedo_texture = body_texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		
	_apply_texture(mesh, material)
	
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
		
	rotation_target = rotation

func interact(action_id: String) -> void:
	if (action_id == "drag") and (phase == AI_PHASE.DEAD_AS_FUCK):
		if state == AI_STATE.DEAD_AS_FUCK_IDLE:
			state = AI_STATE.DEAD_AS_FUCK_DRAGGED
			player.crouching = true
			
			dragged_by_head = !_is_player_in_fov()
			
			$DragBody.action_text = "STOP DRAGGING"
		else:
			state = AI_STATE.DEAD_AS_FUCK_IDLE
			
			$DragBody.action_text = "DRAG BODY"

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
						state_timer = 10
						
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
					state = AI_STATE.ATTACK_DECIDE
		
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
				
				if navigator.is_navigation_finished() or ((navigator.target_position - global_position).length() < 2.5):
					state = AI_STATE.INVESTIGATE_WAIT
					
			elif state == AI_STATE.INVESTIGATE_WAIT:
				state_timer -= tick_delta
				
				if state_timer <= 0:
					phase = AI_PHASE.IDLE
					state = AI_STATE.IDLE_WALK_TO_POINT
					
		elif phase == AI_PHASE.ATTACK:
			if state == AI_STATE.ATTACK_DECIDE:
				if boldness == AI_BOLDNESS.FEARLESS:
					state = AI_STATE.ATTACK_CHARGE
				elif boldness == AI_BOLDNESS.BOLD:
					if ((player.global_position - global_position).length() < 8.5) or (randi_range(0, 1) == 0):
						state = AI_STATE.ATTACK_CHARGE
					else:
						state = AI_STATE.ATTACK_FIND_COVER
				elif boldness == AI_BOLDNESS.NORMAL:
					if ((player.global_position - global_position).length() < 6.0) or (randi_range(0, 6) == 0):
						state = AI_STATE.ATTACK_CHARGE
					else:
						state = AI_STATE.ATTACK_FIND_COVER
				elif boldness == AI_BOLDNESS.PUSSY:
					state = AI_STATE.ATTACK_FIND_COVER
			
			if state == AI_STATE.ATTACK_CHARGE:
				_set_look_target(player.global_position)
				
				if current_cover:
					current_cover.remove_meta("occupant")
					current_cover = null
				
				memory_point = player.global_position
				
				if !_can_see_player():
					phase = AI_PHASE.PURSUE
					state = AI_STATE.PURSUE_CHASE
					
					state_timer = 10
					
				if navigator.target_position != player.global_position:
					navigator.target_position = player.global_position
					
				if ((player.global_position - global_position).length() > 2.5):
					var direction = global_position.direction_to(navigator.get_next_path_position())
					velocity.x = direction.x * 3.0
					velocity.z = direction.z * 3.0
			elif state == AI_STATE.ATTACK_COVER:
				state_timer -= tick_delta
				
				raycast.look_at(player.global_position + Vector3(0, 1, 0))
						
				raycast.force_raycast_update()
				
				if raycast.get_collider() == player:
					state = AI_STATE.ATTACK_CHARGE
				elif state_timer <= 0:
					state_timer = 3.0
					state = AI_STATE.ATTACK_PEEK_COVER
			elif state == AI_STATE.ATTACK_FIND_COVER:
				if _can_see_player():
					_set_look_target(player.global_position)
					
					memory_point = player.global_position
				else:
					_set_look_target(memory_point)
				
				if current_cover == null:
					var valids = []
					
					for n in game.get_node("CoverNodes").get_children():
						raycast.global_position = n.global_position
						raycast.look_at(player.global_position + Vector3(0, 1, 0))
						
						raycast.force_raycast_update()
						
						if (raycast.get_collider() != player) and ((n.global_position - global_position).length() > 6) and ((n.global_position - global_position).length() < 28) and (!n.has_meta("occupant")):
							valids.push_front(n)
							
					valids.sort_custom(_sort_cover_points)
							
					if valids.size() > 0:
						var size = valids.size()
						
						current_cover = valids[randi_range(0, size - 1)]
						
						current_cover.set_meta("occupant", self)
						
						print(current_cover)
					else:
						print("NO COVER!")
				
				raycast.position = Vector3(0, 1, 0)
					
				if current_cover:
					if navigator.target_position != current_cover.global_position:
						navigator.target_position = current_cover.global_position
						
					if navigator.is_target_reached():
						state_timer = 3.0
						state = AI_STATE.ATTACK_COVER
						
						has_seen_player_this_peek = false
					else:
						var direction = global_position.direction_to(navigator.get_next_path_position())
						velocity.x = direction.x * 3.0
						velocity.z = direction.z * 3.0
			elif state == AI_STATE.ATTACK_PEEK_COVER:
				if _can_see_player():
					_set_look_target(player.global_position)
					
					memory_point = player.global_position
				else:
					_set_look_target(memory_point)
				
				if current_cover:
					if navigator.target_position != current_cover.get_node("Peek").global_position:
						navigator.target_position = current_cover.get_node("Peek").global_position
						
					if navigator.is_target_reached():
						state_timer -= tick_delta
						
						if _can_shoot_player():
							has_seen_player_this_peek = true
						
						if state_timer <= 0:
							if has_seen_player_this_peek:
								state_timer = 3.0
								state = AI_STATE.ATTACK_FIND_COVER
							else:
								phase = AI_PHASE.PURSUE
								state = AI_STATE.PURSUE_CHASE
								
								state_timer = 10
								
					else:
						var direction = global_position.direction_to(navigator.get_next_path_position())
						velocity.x = direction.x * 3.0
						velocity.z = direction.z * 3.0
				
			if concentration < 0: concentration = 0
			
			if !_can_shoot_player():
				concentration -= tick_delta
			else:
				firing_timer -= tick_delta
				concentration += tick_delta / 4
				
				if (firing_timer < 0) and (concentration > 0.2):
					firing_timer = 0.25
					
					if concentration > 0.8: concentration = 0.8
					
					$Gunshot1.play()
					
					var spread = randf_range(min_spread, max_spread) * (1 - concentration)
				
					$Raycast.rotation += Vector3(deg_to_rad(randf_range(-spread, spread)), deg_to_rad(randf_range(-spread, spread)), 0.0)
					$Raycast.force_raycast_update()
					
					var bullet_trail = bullet_trail_scene.instantiate() 
					
					bullet_trail.origin = fire_point.global_position
					bullet_trail.target = $Raycast.get_collision_point()
					
					var camera_shake_amount = 0.07 - ((player.global_position - global_position).length() * 0.005)
					if player.camera_shake <= camera_shake_amount: player.camera_shake = camera_shake_amount
					
					get_parent().get_parent().add_child(bullet_trail)
					
					game.handle_hit_particle_effect($Raycast.get_collider(), $Raycast.get_collision_point(), $Raycast.get_collision_normal())
					
					if $Raycast.get_collider() == player:
						player.health -= 10
				
		elif phase == AI_PHASE.PURSUE:
			if state == AI_STATE.PURSUE_CHASE:
				if navigator.target_position != memory_point:
					navigator.target_position = memory_point
					
				concentration -= tick_delta
				if concentration < 0.1: concentration = 0.1
					
				var direction = global_position.direction_to(navigator.get_next_path_position())
				velocity.x = direction.x * 3.0
				velocity.z = direction.z * 3.0
				
				_set_look_target(navigator.get_next_path_position())
				
				state_timer -= tick_delta * 0.5
				
				if navigator.is_navigation_finished():
					state = AI_STATE.PURSUE_SEARCH
				
				if state_timer <= 0:
					phase = AI_PHASE.IDLE
					state = AI_STATE.IDLE_WALK_TO_POINT
					
			elif state == AI_STATE.PURSUE_SEARCH:
				state_timer -= tick_delta
				
				if state_timer <= 0:
					phase = AI_PHASE.IDLE
					state = AI_STATE.IDLE_WALK_TO_POINT

		if phase != AI_PHASE.ATTACK:
			if current_cover:
				current_cover.remove_meta("occupant")
				current_cover = null

	if phase == AI_PHASE.DEAD_AS_FUCK:
		animator.set("parameters/dead/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		$CollisionShape.disabled = true
		
		if state == AI_STATE.DEAD_AS_FUCK_DRAGGED:
			_set_look_target(player.global_position)
			
			if dragged_by_head: rotation_target.y += deg_to_rad(180)
			
			var distance = (global_position - player.global_position).length()
			
			if distance > 1.5:
				var direction = global_position.direction_to(player.global_position)
				velocity.x = direction.x * (player.velocity.length())
				velocity.z = direction.z * (player.velocity.length())
				
			if (!player.crouching) or ((player.global_position - global_position).length() > 2.5):
				state = AI_STATE.DEAD_AS_FUCK_IDLE
				$DragBody.action_text = "DRAG BODY"
	
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
	
	NavigationServer3D.agent_set_velocity(navigator.get_rid(), velocity)
