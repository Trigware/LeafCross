extends Node

var in_brackets : bool
var bracket_content : String
var parsed_ch_index : int
var resulting_text : String
const control_brackets := ["{", "}"]
var left_bracket_index : int
var contains_text_options : bool
var after_choicer_text_error_pushed : bool
var suffix_instruction_appeared := SuffixType.None
var latest_suffix_instruction = ""

func record_control_text(text: String) -> String:
	setup_control_text_parsing()
	if not text.contains("{") and not text.contains("}"): return text
	for i in range(text.length()):
		var letter = text[i]
		if letter in control_brackets and LocalizationTimeParser.is_previous_character("\\", i, text):
			parse_regular_character(letter, i, text)
			continue
		match letter:
			"{":
				left_bracket_index = i
				bracket_content = ""
				in_brackets = true
			"}":
				if not in_brackets: continue
				parse_control_bracket_end()
			_:
				parse_regular_character(letter, i, text)
	
	return resulting_text

func parse_regular_character(letter, index, text):
	if letter == "\\" and get_next_character(index, text) in control_brackets: return
	bracket_content += letter
	if in_brackets: return
	parsed_ch_index += 1
	resulting_text += letter
	if not after_choicer_text_error_pushed and ChoicerSystem.choicer_options != {}:
		push_error("Anything after the choicer is not allowed!")
	after_choicer_text_error_pushed = true

func get_next_character(index, text):
	var next_index = index + 1
	if next_index >= text.length(): return null
	var next_character = text[next_index]
	return next_character

func setup_control_text_parsing():
	TextSystem.character_delays.clear()
	TextSystem.character_colors.clear()
	in_brackets = false
	bracket_content = ""
	parsed_ch_index = 0
	resulting_text = ""
	contains_text_options = false
	after_choicer_text_error_pushed = false
	suffix_instruction_appeared = SuffixType.None
	ChoicerSystem.choicer_options = {}

func parse_control_bracket_end():
	in_brackets = false
	
	if bracket_content.is_valid_float():
		TextSystem.character_delays.set(parsed_ch_index, float(bracket_content))
		return
	
	if bracket_content.begins_with("#"):
		if Color.html_is_valid(bracket_content): set_character_color(bracket_content)
		else: set_character_color(substitute_for_named_color(bracket_content))
		return
	
	if bracket_content.begins_with("?"):
		ChoicerSystem.parse_control_option()
		return
	
	if bracket_content.begins_with("|"):
		parse_suffix_statement()
		return
	
	var placeholder_variable = "{" + bracket_content + "}"
	resulting_text += placeholder_variable
	parsed_ch_index += placeholder_variable.length()

const analysed_special_suffix_statement_character_count = 2

enum SuffixType {
	None,
	Regular,
	Random
}

var analysed_part : String
var argument_part : String

func parse_suffix_statement():
	suffix_instruction_appeared = SuffixType.Regular
	argument_part = remove_instruction_char(bracket_content)
	analysed_part = argument_part.substr(0, analysed_special_suffix_statement_character_count)
	latest_suffix_instruction = argument_part
	
	if is_special_suffix("R"): suffix_instruction_appeared = SuffixType.Random

func is_special_suffix(special_character):
	var is_special = analysed_part == special_character + " "
	if is_special: latest_suffix_instruction = argument_part.substr(analysed_special_suffix_statement_character_count)
	return is_special

func set_character_color(character_color):
	if character_color == null: return
	TextSystem.character_colors.set(parsed_ch_index, character_color)

func substitute_for_named_color(named_color: String):
	var color_name = remove_instruction_char(named_color).to_lower()
	if color_name == "/" or color_name == "": return TextSystem.init_color
	
	var used_color = Color.from_string(color_name, invalid_color)
	if used_color != invalid_color: return color_to_hex(used_color)
	
	used_color = invalid_color
	match color_name:
		"holy_yellow": used_color = Color("ebc934")
		"blue_fire": used_color = Color("3498eb")
		"tree_green": used_color = Color("5fad28")
		"glow_mushroom": used_color = Color("00c9ca")
	
	if used_color == invalid_color:
		push_error("Attempted to use unknown color '" + color_name + "'!")
		return null
	return color_to_hex(used_color)

const invalid_color = Color(0.123, 0.456, 0.789) # placeholder color used in case, where Color.from_string fails

func color_to_hex(color: Color):
	return color.to_html(false).to_upper()

func remove_instruction_char(original_str, instruction_length = 1):
	return original_str.substr(instruction_length)
