extends Node2D

@onready var ghost = $Ghost
@onready var options_root = $Options
@onready var respawn_option = $"Options/Respawn"
@onready var goto_title = $"Options/Go to Title"
@onready var selector = $Options/Selector
@onready var book = $Options/Book
@onready var tomb = $Tomb
@onready var game_over = $GameOver

const position_y_tween_duration = 0.8
const ghost_tween_duration = 1.5
const ghost_float_duration = 0.75
const ghost_float_destination_offset = 10

func _ready():
	initialize_options()
	var final_pos_y = position.y
	position.y += get_viewport_rect().size.y / 2
	modulate.a = 0
	ghost.modulate.a = 0
	Helper.tween(self, "position:y", final_pos_y, position_y_tween_duration)
	await Helper.tween(self, "modulate:a", 1, position_y_tween_duration)
	Helper.tween(ghost, "modulate:a", 1, ghost_tween_duration)
	Helper.tween(ghost, "position:y", ghost.position.y - ghost_float_destination_offset, ghost_float_duration)
	await Audio.play_sound(UID.SFX_SWOOSH, 0.2, 5, true)
	make_options_show_up()

const options_x_offset = 85
const options_root_final_y = 72
const options_root_tween_duration = 0.5

func make_options_show_up():
	await Helper.wait(0.5)
	Audio.play_sound(UID.SFX_SHOW_GAME_OVER_OPTIONS, 0.2, 10, true)
	await Helper.tween(options_root, "position:y", options_root_final_y, options_root_tween_duration)
	can_change_option = true

enum Options {
	Respawn = -1,
	GoToTitle = +1
}

var current_selected_option = Options.Respawn
var can_change_option := false

func initialize_options():
	respawn_option.position.x = -options_x_offset
	goto_title.position.x = options_x_offset
	var text_node_path = "Root/Text"
	respawn_option.get_node(text_node_path).text = Localization.get_text("GameOver_PlayerRespawn")
	goto_title.get_node(text_node_path).text = Localization.get_text("GameOver_GotoTitle")
	selector.position.x = get_selector_x_position()

func get_selector_x_position(): return options_x_offset * int(current_selected_option)

const selector_option_change_duration = 0.35

var option_selected = false

func _unhandled_input(_event):
	if not can_change_option: return
	var previous_option = current_selected_option
	if Input.is_action_just_pressed("continue"):
		select_option()
		return
	if Input.is_action_just_pressed("move_left"): current_selected_option = Options.Respawn
	if Input.is_action_just_pressed("move_right"): current_selected_option = Options.GoToTitle
	if previous_option == current_selected_option: return
	can_change_option = false
	Audio.play_sound(UID.SFX_MENU_CHANGED_CHOICE, 0.2, 5, true)
	await Helper.tween(selector, "position:x", get_selector_x_position(), selector_option_change_duration)
	can_change_option = true

func select_option():
	if option_selected: return
	option_selected = true
	can_change_option = false
	if current_selected_option == Options.Respawn: respawn_player()
	if current_selected_option == Options.GoToTitle: redirect_to_title()
	Audio.music_tween(Overworld.music.volume_db, -24)
	Audio.loop_music()

const multiple_object_tween_modulate_duration = 0.5
const camera_max_zoom = 3
const camera_zoom_tween_duration = 3
const pre_flash_duration = 0.75
const flash_intensity := 215
const after_flash_tween_end_delay = 0.5

var regular_camera_zoom: Vector2
var regular_camera_position: Vector2

func respawn_player():
	await confirmation_overlay_transition()
	handle_general_game_over_option()
	handle_player_respawning_to_overworld()
	queue_free()

func redirect_to_title():
	await confirmation_overlay_transition()
	handle_general_game_over_option()
	await handle_player_redirection_to_title()
	queue_free()

func handle_player_respawning_to_overworld():
	SaveData.load_game(SaveData.loaded_save_file)
	LeafMode.restore_all_health()
	Overworld.load_room(Overworld.currentRoom, Vector2.ZERO)
	Overworld.music.play()
	TextSystem.lockAction = false

func handle_general_game_over_option():
	Player.camera.zoom = regular_camera_zoom
	Player.camera.global_position = regular_camera_position
	book.modulate.a = 0
	game_over.modulate.a = 0
	Overlay.alpha_tween(0)
	Player.update_game_over_rect(0)
	Player.in_water = false
	LeafMode.game_over = false
	Player.is_sinking = false
	Player.leafNode.show()
	Player.leafNode.scale = Player.initial_leaf_scale
	Player.leafNode.position = Player.initial_leaf_position
	Player.animNode.show()
	Player.set_uniform("hide_progression", 0)

func confirmation_overlay_transition():
	regular_camera_zoom = Player.camera.zoom
	regular_camera_position = Player.camera.global_position
	Player.camera.global_position = book.global_position
	await Helper.tween_multiple([ghost, tomb, respawn_option, goto_title, selector], "modulate:a", 0, multiple_object_tween_modulate_duration)
	Audio.play_sound(UID.SFX_RELIGIOUS_SPAWN, 0, 5, true)
	Helper.tween(Player.camera, "zoom", Vector2(camera_max_zoom, camera_max_zoom), camera_zoom_tween_duration)
	await Helper.wait(pre_flash_duration)
	var color_component_value = float(flash_intensity) / 255
	var final_overlay_color = Color(color_component_value, color_component_value, color_component_value)
	await Overlay.overlay_tween(final_overlay_color)
	await Helper.wait(after_flash_tween_end_delay)
	await Overlay.overlay_tween(Color.BLACK, 1, false)

const before_displaying_title_delay = 0.75

func handle_player_redirection_to_title():
	Overworld.disable()
	await Helper.wait(before_displaying_title_delay)
	get_tree().change_scene_to_packed(UID.SCN_TITLE_SCREEN)
