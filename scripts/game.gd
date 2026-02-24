extends Node3D

@onready var player = $Player
var crosshair_size = 0.125
var crosshair_color = Color(1, 1, 1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 0.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Sunlight.look_at($Player/Camera.global_position)
	$UILayer/FPS.text = "FPS: " + str(Engine.get_frames_per_second())
	
	if player.lock_on_target:
		crosshair_size += (0.25 - crosshair_size) / 1.5
		
		if !player.get_node("Camera").is_position_behind(player.lock_on_target.global_position):
			var screen_pos = player.get_node("Camera").unproject_position(player.lock_on_target.global_position)
				
			var window_size = get_viewport().get_visible_rect().size
		
			var crosshair_pos = window_size / 2
			
			var distance_from_crosshair = (screen_pos - crosshair_pos).length()
			
			if distance_from_crosshair < 128:
				crosshair_color = Color(1.0, 0.353, 0.0, 1.0)
			else:
				crosshair_color = Color(1, 1, 1)
		else:
			crosshair_color = Color(1, 1, 1)
	else:
		crosshair_size += (0.125 - crosshair_size) / 1.5
		crosshair_color = Color(1, 1, 1)
		
		for n in $Enemies.get_children():
			if n.health <= 0: return
			
			var screen_pos = player.get_node("Camera").unproject_position(n.global_position)
				
			var window_size = get_viewport().get_visible_rect().size
		
			var crosshair_pos = window_size / 2
			
			var distance_from_crosshair = (screen_pos - crosshair_pos).length()
			
			if distance_from_crosshair < 64:
				crosshair_color = Color(0.0, 0.684, 0.687, 1.0)
		
		
		
	$UILayer/Crosshair.material.set_shader_parameter("circle_radius", crosshair_size)
	$UILayer/Crosshair.material.set_shader_parameter("circle_color_main", crosshair_color)
	$UILayer/Crosshair.material.set_shader_parameter("dot_color", crosshair_color)
	$UILayer/Crosshair.material.set_shader_parameter("cross_color_main", crosshair_color)
