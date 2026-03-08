extends Node3D

@onready var current_panel := $UILayer/UI/Main

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(2).timeout
	
	var i = 0
	while i < 10:
		await get_tree().create_timer(0.1).timeout
		$UILayer/UI/Splash.modulate.a -= 0.1
		
		i += 1
		
	$UILayer/UI/Splash.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Camera.rotation.x += delta * 0.05


func _set_panel(name) -> void:
	var panel = $UILayer/UI.get_node(name)
	
	if !panel:
		return
		
	for n in current_panel.find_children("*"):
		if n is Button:
			n.disabled = true
	
	var i = 0
	while i < 10:
		await get_tree().create_timer(0.1).timeout
		current_panel.modulate.a -= 0.1
		
		i += 1
		
	current_panel.visible = false
	
	current_panel = panel
		
	current_panel.visible = true
	
	current_panel.modulate.a = 0
		
	for n in current_panel.find_children("*"):
		if n is Button:
			n.disabled = true
	
	i = 0
	while i < 10:
		await get_tree().create_timer(0.1).timeout
		current_panel.modulate.a += 0.1
		
		i += 1
		
		
	for n in current_panel.find_children("*"):
		if n is Button:
			n.disabled = false

func _on_return_to_main_pressed() -> void:
	$UiBack.play()
	_set_panel("Main")

func _on_play_pressed() -> void:
	$UiSelect.play()
	_set_panel("Scenarios")

func _on_play_take_and_hold_pressed() -> void:
	$UiSelect.play()
	
	_set_panel("Goodbye")
	
	await get_tree().create_timer(2.5).timeout
	
	get_tree().change_scene_to_file("res://scenes/ground.tscn")
