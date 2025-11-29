extends Node2D

@onready var background = $Background
@onready var logo = $Logo
@onready var stars = $Background/Stars
@onready var choose_lang_root = $"Choose Language"
@onready var eye = $Logo/Eye
@onready var options_tree = $"Options Tree"
@onready var labels_root = $"Extra Info Labels"
@onready var version_label = $"Extra Info Labels/Version"
@onready var developers_label = $"Extra Info Labels/Developers"
@onready var selector = $"Options Tree/Selector"

const destination_background_y := 400
const on_flash_background_y := 300
const logo_destination_y := -8
const hide_labels_position_y := 100
const show_labels_duration := 0.75

var wmt_easter_egg_active = false
var wmt_easter_egg_key_progress = 0
const wmtale_easter_egg_keyinputs := [KEY_W, KEY_M, KEY_T]

func _ready():
	Player.in_title_screen = true
	setup_title_screen()
	logo.after_flash.connect(after_flash)
	choose_lang_root.language_selected.connect(main_menu_initialize)
	stars_visibility_logic()
	await options_tree.moving_option_tree
	setup_labels_text()

func setup_labels_text():
	version_label.text = Localization.get_text("mainmenu_version_number")
	developers_label.text = Localization.get_text("mainmenu_developers")

const lowewst_stars_alpha := 0.2
const star_speed = 15
const stars_maximum_x = 144
const minimum_star_move_speed = 7

func _process(delta):
	move_stars(delta)

const main_menu_logo_scale = 0.55
const main_menu_logo_position = Vector2(340, -20)
const main_menu_logo_tween_duration := 0.75

func main_menu_initialize():
	var logo_move_tween = create_tween().tween_property(logo, "position", main_menu_logo_position, main_menu_logo_tween_duration)
	logo_move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var scale_tween = create_tween().tween_property(logo, "scale", Vector2(main_menu_logo_scale, main_menu_logo_scale), main_menu_logo_tween_duration)
	scale_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await wait(0.4)
	options_tree.options_tree_move_tween()
	labels_tween()

func labels_tween():
	var labels_move_tween = create_tween().tween_property(labels_root, "position:y", 0, show_labels_duration)
	labels_move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)

func move_stars(delta):
	var x_change = delta * star_speed
	var new_x = stars.position.x + x_change
	if new_x > stars_maximum_x:
		new_x = -stars_maximum_x + (new_x - stars_maximum_x)
	stars.position.x = new_x

func stars_visibility_logic():
	while true:
		await wait(4)
		var hide_tween = create_tween().tween_property(stars, "modulate:a", lowewst_stars_alpha, 1)
		await hide_tween.finished
		await wait(0.5)
		var show_tween = create_tween().tween_property(stars, "modulate:a", 1, 1)
		await show_tween.finished

const initial_logo_scale = 0.785
const initial_logo_position = Vector2(-15, 95)
const initial_background_position_y = 250

func setup_title_screen():
	background.hide()
	background.position.y = initial_background_position_y
	logo.scale = Vector2(initial_logo_scale, initial_logo_scale)
	logo.position = initial_logo_position
	labels_root.position.y = hide_labels_position_y
	background.texture = UID.IMG_MAIN_MENU_BG

const background_move_duration := 0.6

func after_flash():
	background.show()
	stars.show()
	selector.show()
	background.position.y = on_flash_background_y
	var background_move_tween = create_tween().tween_property(background, "position:y", destination_background_y, background_move_duration)
	background_move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	eye_glow_logic()
	if SaveData.language_chosen: main_menu_initialize()
	else: start_choose_language_sequence()

func eye_glow_logic():
	while true:
		await eye.glowing_eye_tween()

func wait(wait_time: float):
	await get_tree().create_timer(wait_time).timeout

const logo_move_duration := 0.5
const sequence_start_wait_time := 0.2

func start_choose_language_sequence():
	var logo_move_tween = create_tween().tween_property(logo, "position:y", logo_destination_y, logo_move_duration)
	logo_move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	await logo_move_tween.finished
	await wait(0.2)
	choose_lang_root.show_choose_lang_ui()

func _input(event):
	if not event is InputEventKey or not event.pressed: return
	if wmt_easter_egg_active: return
	
	var wanted_key_for_wmt_easter_egg = wmtale_easter_egg_keyinputs[wmt_easter_egg_key_progress]
	if event.keycode == wanted_key_for_wmt_easter_egg:
		wmt_easter_egg_key_progress += 1
		if wmt_easter_egg_key_progress == wmtale_easter_egg_keyinputs.size():
			wmt_easter_egg_active = true
			Audio.play_sound(UID.SFX_WMTALE_EASTER_EGG)
	else:wmt_easter_egg_key_progress = 0
