extends Control

@onready var header = $Header
@onready var confirmLabel = $"Confirm Label"
@onready var language_template = $"Language Template"
@onready var move_reminder = $"Move Reminder"
@onready var selector = $Selector
@onready var flag_template = $"Flag Template"

var selected_lang_index = 0
var label_list := []
var flag_list := []
var lock_action = false

const default_selector_y = 256
const label_height = 60
const selector_pos_x = 310


const flag_pos_x = 400
const selection_change_duration = 0.1

func _ready():
	selected_lang_index = get_lang_index()
	set_selector_texture()
	refresh_text()
	Audio.play_music("A Weird File")
	selector.position = get_expected_selector_position()

func set_selector_texture():
	var selector_texture = UID.IMG_NOLEAF_SELECTOR
	if SaveData.seen_leaf:
		selector_texture = UID.IMG_LEAF
	selector.texture = selector_texture

func ctor_labels():
	for lang_index in range(Localization.language_list.size()):
		var label_lang = Localization.language_list[lang_index]
		var label = language_template.duplicate()
		label.text = Localization.get_text("choose_lang_" + label_lang)
		label.position.y += lang_index * label_height
		label.show()
		add_child(label)
		label_list.append(label)
		var flag = flag_template.duplicate()
		flag.position.x = flag_pos_x
		flag.show()
		var flag_texture = UID.get_flag_with_string(label_lang)
		if flag_texture == null: continue
		flag.texture = flag_texture
		flag.position.y += lang_index * label_height
		add_child(flag)

func get_expected_selector_position():
	var pos_y = default_selector_y + selected_lang_index * label_height
	return Vector2(selector_pos_x, pos_y)

func _process(_delta):
	if lock_action: return
	var previous_lang_index = selected_lang_index
	
	if Input.is_action_just_pressed("move_down"):
		selected_lang_index = min(selected_lang_index + 1, label_list.size() - 1)
	if Input.is_action_just_pressed("move_up"):
		selected_lang_index = max(selected_lang_index - 1, 0)
	if Input.is_action_just_pressed("continue"):
		finish_choosing_language()
		return
	
	if previous_lang_index == selected_lang_index: return
	
	Audio.play_sound(UID.SFX_MENU_CHANGED_CHOICE, 0.2)
	var final_position = get_expected_selector_position()
	refresh_text()
	var tween = create_tween()
	lock_action = true
	await tween.tween_property(selector, "position", final_position, selection_change_duration).finished
	lock_action = false

func refresh_text():
	var selected_language = Localization.language_list[selected_lang_index]
	Localization.load_language(selected_language)
	header.text = Localization.get_text("choose_lang_language")
	confirmLabel.text = Localization.get_text("choose_lang_confirm")
	move_reminder.text = Localization.get_text("choose_lang_move")
	dtor_labels()
	ctor_labels()

func dtor_labels():
	for label in label_list:
		label.queue_free()
	label_list.clear()

func finish_choosing_language():
	if Overlay.sceneChangingDisabled: return
	lock_action = true
	Audio.play_sound(UID.SFX_MENU_CANCEL, 0.2)
	var change_scene_duration = 1
	if not SaveData.does_any_save_file_exist():
		Audio.fade_music(2)
		change_scene_duration = 2
	SaveData.language_chosen = true
	SaveData.save_global_file()
	Overlay.change_scene(SaveData.get_next_load_scene(), change_scene_duration, change_scene_duration, change_scene_duration - 1)

func get_lang_index():
	if not SaveData.seen_leaf: return 0
	var current_lang_index = max(0, Localization.language_list.find(Localization.current_language))
	for i in range(Localization.language_list.size()):
		if i != current_lang_index: return i
	return 0
