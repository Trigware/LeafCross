extends CanvasLayer

const base_selector_position_y = 275
const space_between_options = 65

var can_choose = false
var selected_option = 0
var can_change_option = true
var can_reset_battle = false
var selected_color = Color("67A868")

@onready var leaf = $Leaf
@onready var image = $Image
@onready var selector = $Selector
@onready var options = $Options
@onready var retry = $Options/Retry
@onready var reset_battle = $"Options/Restart Battle"

func _process(_delta):
	if not can_choose or not can_change_option: return
	if Input.is_action_just_pressed("continue"):
		can_choose = true
		after_choice_selected()
		return
	var old_selected_option = selected_option
	if Input.is_action_just_pressed("move_up"):
		selected_option = 0
	if Input.is_action_just_pressed("move_down") and can_reset_battle:
		selected_option = 1
	if selected_option == old_selected_option: return
	tween_node(selector, "position:y", base_selector_position_y + selected_option * space_between_options, 0.2)
	var selected_label = retry if selected_option == 0 else reset_battle
	var white_label = retry if selected_option == 1 else reset_battle
	var used_selected_color = selected_color
	if selected_option: used_selected_color = Color.RED
	tween_node(selected_label, "modulate", used_selected_color, 0.2)
	tween_node(white_label, "modulate", Color.WHITE, 0.2)
	tween_node(selector, "modulate", used_selected_color, 0.2)
	Audio.play_sound(UID.SFX_MENU_CHANGED_CHOICE, 0.2)

func _ready():
	LeafMode.stamina_root.hide()
	LeafMode.health_root.hide()
	setup()
	leaf.position += get_viewport().get_visible_rect().size / 2
	await get_tree().create_timer(1).timeout
	LeafMode.game_over = false
	Audio.play_sound(UID.SFX_LEAF_BREAK)
	leaf.play()
	await get_tree().create_timer(1.5).timeout
	tween_node(image)
	await TextMethods.print_sequence("GameOver", {
		"first_death": SaveData.death_counter == 1
	})
	show_options()

func show_options():
	await get_tree().create_timer(0.5).timeout
	tween_node(selector)
	tween_node(options)
	can_choose = true

func setup():
	PresetSystem.fallback = PresetSystem.Preset.GameOver
	Overworld.disable()
	Overlay.set_alpha(0)
	image.modulate.a = 0
	selector.modulate.a = 0
	options.modulate.a = 0
	selector.position.y = base_selector_position_y
	retry.text = Localization.get_text("GameOver_Option_Continue")
	reset_battle.text = Localization.get_text("GameOver_Option_ResetBattle")
	if not can_reset_battle: reset_battle.hide()

func tween_node(node: Node, property = "modulate:a", final = 1, duration = 0.5):
	var tween = create_tween()
	tween.tween_property(node, property, final, duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func after_choice_selected():
	can_choose = false
	if selected_option == 0:
		agreement_option()
		return

func agreement_option():
	Audio.play_sound(UID.SFX_RELIGIOUS_SPAWN)
	SaveData.load_game(SaveData.loaded_save_file)
	LeafMode.restore_all_health()
	respawn_cleanup()
	await Overlay.hide_scene(2)
	await get_tree().create_timer(2).timeout
	Overlay.show_scene()
	Overworld.enable()
	get_tree().change_scene_to_packed(UID.SCN_EMPTY)

func respawn_cleanup():
	Player.leaf_flash_disabled = false
	Player.is_sinking = false
	LeafMode.stamina_root.show()
	LeafMode.health_root.show()
	Player.set_uniform("sink_progression", 0)
	Player.camera.offset = Player.initial_camera_offset
