extends "res://Scripts/Globals/PointOnLine.gd"

var directions = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]
const eyes_position_when_dir_right = 30

func _ready():
	initialize_line()
	create_logs()

var exit_log: StaticBody2D
var exit_log_eyes: AnimatedSprite2D
var exit_log_facing_dir: Vector2

func create_logs():
	exit_log_facing_dir = sign(path_as_points[1] - path_as_points[0])
	exit_log = create_log(exit_log_facing_dir, path_as_points[0])
	exit_log_eyes = exit_log.get_node("Eyes")
	var exit_log_collider = exit_log.get_node("Collider")
	initialize_eyes()
	var enter_log_facing_dir = sign(path_as_points[-2] - path_as_points[-1])
	create_log(enter_log_facing_dir, path_as_points[-1])

func create_log(dir, log_position):
	var log = UID.SCN_CATERPILLAR_LOG.instantiate()
	log.position = log_position
	log.get_node("Sprite").frame_coords.x = directions.find(dir)
	add_child(log)
	return log

const hidden_eyes_show_player_dist = 175
var can_play = true

func _process(_delta):
	var distance_component_index = 0
	if exit_log_facing_dir in [Vector2.RIGHT, Vector2.LEFT]: distance_component_index = 1
	var player_dist = abs(exit_log.global_position[distance_component_index] - Player.get_global_pos()[distance_component_index])
	if player_dist < hidden_eyes_show_player_dist:
		if can_play: exit_log_eyes.play()
		can_play = false
	else: can_play = true

func initialize_eyes():
	if exit_log_facing_dir == Vector2.DOWN: return
	if exit_log_facing_dir == Vector2.UP:
		exit_log_eyes.hide()
		return
	var direction_is_right = 1 if exit_log_facing_dir == Vector2.RIGHT else -1
	exit_log_eyes.position = Vector2(eyes_position_when_dir_right * direction_is_right, 0)
	match exit_log_facing_dir:
		Vector2.RIGHT: exit_log_eyes.rotation_degrees = 270
		Vector2.LEFT: exit_log_eyes.rotation_degrees = 90
