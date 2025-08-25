extends Area2D

@export var roomDestination := Overworld.Room.ErrorHandlerer
@export var new_position := Vector2.ZERO
@export var x_player_dependent := false
@export var y_player_dependent := false

const scene_hide_duration := 0.3

func get_enterance_effected_position():
	var playerPos = Player.get_global_pos()
	var anchorPosition = new_position
	var newPlayerPosition = Vector2.ZERO
	if x_player_dependent:
		anchorPosition.y -= 32
		newPlayerPosition.x += playerPos.x
	if y_player_dependent:
		anchorPosition.y -= 32
		newPlayerPosition.y += playerPos.y
	newPlayerPosition += anchorPosition * Overworld.scaleConst
	return newPlayerPosition

func _process(_delta):
	if Overworld.triggerLocked or Overlay.while_transition: return
	for body in get_overlapping_bodies():
		if body.is_in_group("Player"):
			change_rooms()
			break

func change_rooms():
	Overworld.triggerLocked = true
	Overlay.hide_scene(scene_hide_duration)
	await Overlay.finished
	Overworld.load_room(roomDestination, get_enterance_effected_position())
	Overworld.triggerLocked = false
	await Overlay.show_scene(scene_hide_duration)
