extends CharacterBody3D

@export var health := 100
@export var body_texture: Texture2D = load("res://textures/character_test.png")

@export var sight_max_distance: int = 256

var dead := false

var phase: AI_PHASE = AI_PHASE.IDLE
var state: AI_STATE = AI_STATE.IDLE_WALK_TO_POINT

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
	INVESTIGATE_SOUND, INVESTIGATE_BODY, INVESTIGATE_DISTRACTION,
	ATTACK,
	PURSUE_CHASE, PURSUE_SEARCH
}


func _physics_process(delta: float) -> void:
	
	# If the enemy is not dead, rotate the player towards its rotation target.
	if !dead:
		global_rotation.y = lerp_angle(global_rotation.y, rotation_target.global_rotation.y, 6.0 * delta)
