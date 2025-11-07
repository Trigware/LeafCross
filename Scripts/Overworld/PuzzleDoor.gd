extends Node2D

@onready var left_door = $"Door/Static Body/Left Door"
@onready var right_door = $"Door/Static Body/Right Door"
@onready var room_trigger = $"Room Trigger"
@onready var puzzle_screen_icon = $"Puzzle Screen/Icon"

@export_group("Room Trigger")
@export var roomDestination := Overworld.Room.ErrorHandlerer
@export var new_position := Vector2.ZERO
@export var x_player_dependent := false
@export var y_player_dependent := false

var door_already_opened = false
const opened_door_segment_offset = 25
const camera_tween_duration = 1.5

func _ready():
	room_trigger.roomDestination = roomDestination
	room_trigger.new_position = new_position
	room_trigger.x_player_dependent = x_player_dependent
	room_trigger.y_player_dependent = y_player_dependent
	room_trigger.monitoring = false

func open_door(lever_dict):
	if door_already_opened or not_all_levers_on(lever_dict) or CutsceneManager.action_lock: return
	door_already_opened = true
	CutsceneManager.action_lock = true
	Overworld.puzzles_solved += 1
	if Overworld.puzzles_solved > Overworld.lever_puzzles_playtest.size(): Overworld.puzzles_solved = 0
	
	await Helper.wait(0.65)
	var door_to_player_delta = global_position - Player.get_global_pos()
	var player_horizontal_look_dir = Vector2(sign(door_to_player_delta).x, 0)
	var str_dir = MovingNPC.get_direction_as_string(player_horizontal_look_dir)
	Player.update_animation(str_dir)
	
	await Helper.wait(0.25)
	await Player.move_camera_to(global_position.x, global_position.y, camera_tween_duration)
	await Helper.wait(0.5)
	puzzle_screen_icon.frame_coords.x += 1
	Audio.play_sound(UID.SFX_ITEM_OBTAINED)
	await Helper.wait(0.75)
	open_door_segments()

func open_door_segments():
	Helper.offset_x_tween(left_door, -opened_door_segment_offset, 1)
	Helper.offset_x_tween(right_door, opened_door_segment_offset, 1)
	Audio.play_sound(UID.SFX_OPEN_DOOR, 0.2)
	await Helper.wait(0.5)
	await LeafMode.screen_shake_multiple(5, Player.camera, LeafMode.screen_shake_offset * 2)
	await Helper.wait(0.5)
	await Player.return_camera(camera_tween_duration)
	CutsceneManager.action_lock = false
	room_trigger.monitoring = true

func not_all_levers_on(lever_list):
	for lever in lever_list.values():
		if not lever.lever_on: return true
	return false
