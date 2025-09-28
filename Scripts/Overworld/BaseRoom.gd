extends Node2D

@export var cutscene := CutsceneManager.Cutscene.None
@export var cutscenePosition := Vector2()
@export var roomMusic := ""
@export var roomMusicPitchRange := 0.1
@export var playNoMusic := false

@onready var environment_layer = get_node("Environment")

func _process(_delta):
	if environment_layer == null: return
	Player.in_leaves = false
	handle_tile_behaviour()

func get_player_environment_coords():
	return environment_layer.local_to_map(environment_layer.to_local(Player.get_global_pos()))

func handle_tile_behaviour():
	var player_coords = get_player_environment_coords()
	var tile_data = environment_layer.get_cell_tile_data(player_coords)
	if tile_data != null:
		var tile_footstep_surface = tile_data.get_custom_data("Footstep")
		handle_footstep_behaviour(tile_footstep_surface)

func handle_footstep_behaviour(tile_footstep_surface):
	match tile_footstep_surface:
		"Leaf": Player.in_leaves = true
