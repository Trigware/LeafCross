extends Sprite2D

@onready var selector = $Selector
@onready var file_select = get_parent().get_node("File Select")

var options_tree_destination := Vector2(165, 320)
const options_tree_hide_position := Vector2(-300, 700)
const options_tree_tween_duration := 0.5
var current_selected_option := Option.Play
var can_change_option = false

signal moving_option_tree

enum Option {
	Play,
	Settings,
	Exit
}

func _ready():
	position = options_tree_hide_position
	selector.modulate.a = 0
	initialize_option_choices()

func initialize_option_choices():
	var first_option = get_child(current_selected_option)
	first_option.modulate = get_color_from_option(current_selected_option)
	selector.texture = UID.IMG_LEAF
	if not SaveData.seen_leaf:
		selector.texture = UID.IMG_NOLEAF_SELECTOR
		selector.flip_h = true

const selector_alpha_duration := 0.35

func options_tree_move_tween():
	emit_signal("moving_option_tree")
	selector.position = get_leaf_position()
	var move_tween = create_tween().tween_property(self, "position", options_tree_destination, options_tree_tween_duration)
	move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await wait(options_tree_tween_duration / 2)
	var selector_alpha_tween = create_tween().tween_property(selector, "modulate:a", 1, selector_alpha_duration)
	await selector_alpha_tween.finished
	can_change_option = true

func wait(wait_time: float):
	await get_tree().create_timer(wait_time).timeout

const leaf_option_x_offset = 50

func get_leaf_position():
	var option_node = get_child(current_selected_option)
	var option_position = option_node.position
	var x_pos = option_position.x + leaf_option_x_offset
	var result_position = Vector2(x_pos, option_position.y)
	return result_position

func _process(_delta):
	if not can_change_option: return
	handle_option_changing()

func handle_option_changing():
	var previous_option = current_selected_option
	if Input.is_action_just_pressed("move_up"):
		@warning_ignore("int_as_enum_without_cast")
		if previous_option > 0: current_selected_option -= 1
	if Input.is_action_just_pressed("move_down"):
		@warning_ignore("int_as_enum_without_cast")
		if previous_option + 1 < Option.size(): current_selected_option += 1
	if previous_option != current_selected_option:
		option_changed(previous_option)
		return
	if Input.is_action_just_pressed("continue"): handle_choice_selected()

const leaf_tween_duration := 0.1

func option_changed(previous_option):
	Audio.play_sound(UID.SFX_MAIN_MENU_CHOICE_CHANGE, 0.2)
	can_change_option = false
	var leaf_destination = get_leaf_position()
	var move_tween = create_tween().tween_property(selector, "position", leaf_destination, leaf_tween_duration)
	option_label_tweens(previous_option)
	move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await move_tween.finished
	can_change_option = true

const option_label_color_tween_duration := 0.5

func option_label_tweens(previous_option):
	var previous_option_node = get_child(previous_option)
	create_tween().tween_property(previous_option_node, "modulate", Color.WHITE, option_label_color_tween_duration) # previous_option_tween
	
	var current_option_node = get_child(current_selected_option)
	var current_option_final_color = get_color_from_option(current_selected_option)
	create_tween().tween_property(current_option_node, "modulate", current_option_final_color, option_label_color_tween_duration) # current_option_tween

func get_color_from_option(option: Option) -> Color:
	var returned_color : Color
	match option:
		Option.Play: returned_color = Color.GREEN
		Option.Settings: returned_color = Color.SKY_BLUE
		Option.Exit: returned_color = Color("e84141")
	return returned_color

func handle_choice_selected():
	Audio.play_sound(UID.SFX_CONFIRM_CHOICE, 0.2)
	can_change_option = false
	match current_selected_option:
		Option.Play: file_select.show_file_select()
		Option.Exit: QuittingNotice.close_game()
