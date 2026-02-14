extends Node

const option_offset_x = 50
const option_offset_y = 10
var default_leaf_position : Vector2
const choice_directions := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
const choicer_input_duration = 0.5

var last_choicer_direction := Vector2.ZERO
var last_choicer_suffix : String

var in_choicer = false
var choice_suffix_dict = {}
var disable_choicer_inputs = false

signal submitted_choice

func _ready():
	await get_tree().process_frame
	default_leaf_position = TextSystem.choicer_leaf.position

func give_choice():
	TextSystem.waitLeaf.modulate.a = 0
	last_choicer_direction = Vector2.ZERO
	TextSystem.lockAction = true
	in_choicer = true
	TextSystem.textboxNode.show()
	TextSystem.choicerNode.show()
	TextSystem.choicer_leaf.position = default_leaf_position
	TextSystem.hide_portrait()
	if TextSystem.wait_leaf_alpha_tween != null: TextSystem.wait_leaf_alpha_tween.kill()
	TextSystem.waitLeaf.modulate.a = 0
	
	choice_suffix_dict = {}
	for direction in choice_directions:
		var choice_node = TextSystem.choice_label_options[direction]
		if not direction in choicer_options:
			choice_node.text = ""
			continue
		var choice_direction_info = choicer_options[direction]
		choice_node.text = choice_direction_info[ChoicerParserMode.Option]
		choice_suffix_dict[direction] = choice_direction_info[ChoicerParserMode.SequenceSuffix]
	
	await submitted_choice

func give_localized_choice(choice_keys: Array):
	for i in range(choice_keys.size()):
		var choice_key = choice_keys[i]
		if choice_key == "": continue
		if i >= choice_directions.size(): break
		var choice_dir = choice_directions[i]
		var choice_text = Localization.get_text(choice_key)
		choicer_options[choice_dir] = {
			ChoicerParserMode.Option: choice_text,
			ChoicerParserMode.SequenceSuffix: choice_key
		}
	await give_choice()

func handle_choicer_inputs():
	if disable_choicer_inputs: return
	
	var direction := Vector2.ZERO
	if can_move_choicer_leaf("move_left", Vector2.LEFT):
		direction = Vector2.LEFT
	if can_move_choicer_leaf("move_right", Vector2.RIGHT):
		direction = Vector2.RIGHT
	if can_move_choicer_leaf("move_up", Vector2.UP):
		direction = Vector2.UP
	if can_move_choicer_leaf("move_down", Vector2.DOWN):
		direction = Vector2.DOWN
	
	if direction != Vector2.ZERO: move_choicer_leaf(direction)

func can_move_choicer_leaf(action: StringName, direction: Vector2):
	return Input.is_action_just_pressed(action) and direction in choicer_options.keys()

func move_choicer_leaf(direction):
	var final_position = Vector2(default_leaf_position.x + direction.x * option_offset_x, default_leaf_position.y + direction.y * option_offset_y)
	var used_duration = choicer_input_duration
	if direction.x == 0 and default_leaf_position == TextSystem.choicer_leaf.position:
		used_duration /= 2
	
	var position_tween = create_tween().tween_property(TextSystem.choicer_leaf, "position", final_position, used_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	choicer_modulation_tweens(final_position, direction, used_duration)
	disable_choicer_inputs = true
	await position_tween.finished
	disable_choicer_inputs = false
	last_choicer_direction = direction

func choicer_modulation_tweens(final_position, direction, used_duration):
	if final_position == TextSystem.choicer_leaf.position: return
	Audio.play_sound(UID.SFX_MENU_CHANGED_CHOICE, 0.1)
	create_tween().tween_property(TextSystem.choice_label_options[direction], "modulate", Color.WEB_GREEN, used_duration)
	if default_leaf_position == TextSystem.choicer_leaf.position:
		create_tween().tween_property(TextSystem.choicer_leaf, "modulate:a", 0, used_duration)
		return
	
	create_tween().tween_property(TextSystem.choice_label_options[last_choicer_direction], "modulate", Color.WHITE, used_duration)
	var show_tween = create_tween().tween_property(TextSystem.choicer_leaf, "modulate:a", 1, used_duration/2)
	await show_tween.finished
	create_tween().tween_property(TextSystem.choicer_leaf, "modulate:a", 0, used_duration/2)

func on_choice_decided():
	if disable_choicer_inputs: return
	if not last_choicer_direction in choice_suffix_dict: return
	last_choicer_suffix = choice_suffix_dict[last_choicer_direction]
	TextMethods.clear_text()
	emit_signal("submitted_choice")

func is_player_choice(wanted_choice):
	if wanted_choice is Vector2:
		return wanted_choice == last_choicer_direction
	if last_choicer_suffix == "":
		push_error("Wanted choice doesn't have a suffix. Please pass in a vector direction.")
		return null
	return last_choicer_suffix == wanted_choice

var choicer_options : Dictionary[Vector2, Dictionary]
var in_choicer_expression: bool
var accumiliated_string: String
var current_choice_index: int

enum ChoicerParserMode {
	Option,
	SequenceSuffix
}

func parse_control_option():
	if TextParser.contains_text_options:
		push_error("Chained choicers after not allowed!")
		return
	
	choicer_options = {}
	TextParser.contains_text_options = true
	in_choicer_expression = false
	TextParser.bracket_content = TextParser.bracket_content.substr(1)
	accumiliated_string = ""
	current_choice_index = 0
	
	if TextParser.bracket_content.length() >= 1 and TextParser.bracket_content[0] == '.':
		in_choicer_expression = true
		TextParser.bracket_content = TextParser.bracket_content.substr(1)
	
	for ch in TextParser.bracket_content:
		handle_choicer_character(ch)
	end_current_choice()
	
	if choicer_options == {}: handle_basic_option_shorthand()

func handle_choicer_character(ch):
	match ch:
		':':
			if accumiliated_string.length() > 0 and accumiliated_string[0] == ' ': accumiliated_string = accumiliated_string.substr(1)
			update_choicer_options(ChoicerParserMode.SequenceSuffix, accumiliated_string)
			accumiliated_string = ""
		',':
			end_current_choice()
		_: accumiliated_string += ch

func end_current_choice():
	if accumiliated_string == "": return
	var displayed_choice = accumiliated_string
	if in_choicer_expression: displayed_choice = str(ExpressionEval.evaluate_expression(accumiliated_string))
	elif accumiliated_string.length() > 0 and accumiliated_string[0] == " ": displayed_choice = accumiliated_string.substr(1)
	
	update_choicer_options(ChoicerParserMode.Option, displayed_choice)
	current_choice_index += 1
	accumiliated_string = ""

func handle_basic_option_shorthand():
	choicer_options = {
		Vector2.LEFT: {
			ChoicerParserMode.Option: Localization.get_text("choicer_agree"),
			ChoicerParserMode.SequenceSuffix: "agree"
		},
		Vector2.RIGHT: {
			ChoicerParserMode.Option: Localization.get_text("choicer_decline"),
			ChoicerParserMode.SequenceSuffix: "decline"
		}
	}

func update_choicer_options(parser_mode: ChoicerParserMode, value: String):
	var current_dir = choice_directions[current_choice_index]
	var current_options = choicer_options.get(current_dir, {})
	current_options.set(parser_mode, value)
	choicer_options.set(current_dir, current_options)

func give_basic_choice():
	await TextMethods.print_wait_localization("basic_choice")
