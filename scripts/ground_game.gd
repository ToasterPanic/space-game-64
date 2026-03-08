extends Node3D

@onready var player = $Player
@onready var interact_cast = $Player/Camera/InteractCast

@onready var crosshair = $UILayer/HUD/Crosshair 
@onready var interact_flow = $UILayer/HUD/InteractFlow
@onready var damage_overlay = $UILayer/HUD/DamageOverlay
@onready var fps_counter = $UILayer/HUD/FPSCounter

@onready var viewport = get_viewport()

var current_music = null

var in_combat = false

var bullethole_scene = preload("res://scenes/effects/bullethole.tscn")
var blood_hit_scene = preload("res://scenes/blood_hit.tscn")

func play_music(track: AudioStreamPlayer):
	if current_music:
		current_music.stop()
		
	current_music = track
	
	track.play()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("hide_hud"): $UILayer/HUD.visible = !$UILayer/HUD.visible
	
func create_decal(decal, position, normal) -> void:
	decal.global_position = position
	$EffectDecals.add_child(decal)
	
	decal.look_at(position + Vector3(0, normal.y, 0))
	
	# This gets it looking the right way + with a random rotation. Don't ask how it scares me
	decal.rotate_object_local(Vector3.UP, deg_to_rad(randi_range(-180, 180)))
	
	if (normal == Vector3.FORWARD) or (normal == Vector3.BACK):
		decal.rotate_x(deg_to_rad(90))
	else:
		decal.rotate_z(deg_to_rad(90))
		
	if $EffectDecals.get_children().size() > 128:
		$EffectDecals.get_children()[0].queue_free()
	
func handle_hit_particle_effect(target, position, normal) -> void:
	var scene = null
	
	if !target: return
	
	if ("health" in target) or (target.has_meta("owner")):
		scene = blood_hit_scene
		
	if scene:
		var effect = scene.instantiate()
		
		effect.global_position = position
		
		add_child(effect)
		
		effect.play()
		
	if target is CSGShape3D:
		var bullethole = bullethole_scene.instantiate()
		
		create_decal(bullethole, position, normal)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var collider = interact_cast.get_collider()
	
	fps_counter.text = str(Engine.get_frames_per_second()) + " FPS"
	
	var screen_size = viewport.size
	
	crosshair.position.x = (screen_size.x / 2) - 128 + ($Player/Camera.h_offset * 32.0)
	crosshair.position.y = (screen_size.y / 2) - 128 + ($Player/Camera.v_offset * 32.0)
	
	if collider and ("action_id" in collider) and ((collider.global_position - player.global_position).length() < collider.interact_range):
		interact_flow.visible = true
		interact_flow.get_node("Label").text = collider.action_text
	else:
		interact_flow.visible = false
		
	damage_overlay.material.set_shader_parameter("radius", 1.0 - (player.health/100.0))
	
	if in_combat:
		if !current_music or (current_music.get_parent() != $CombatMusic):
			var tracks = $CombatMusic.get_children()
			play_music(tracks[randi_range(0, tracks.size() - 1)])
			
		var unsafe = false
		
		for n in $Enemies.get_children():
			if (n.phase == n.AI_PHASE.ATTACK) or (n.phase == n.AI_PHASE.PURSUE) or (n.phase == n.AI_PHASE.INVESTIGATE):
				unsafe = true
				break
				
		if has_node("HoldPoints"):
			for n in $HoldPoints.get_children():
				if n.active:
					unsafe = true
				
		if !unsafe:
			in_combat = false
			current_music.stop()
			current_music = null
	else:
		for n in $Enemies.get_children():
			if (n.phase == n.AI_PHASE.ATTACK) or (n.phase == n.AI_PHASE.PURSUE):
				in_combat = true
				
		if has_node("HoldPoints"):
			for n in $HoldPoints.get_children():
				if n.active:
					in_combat = true
