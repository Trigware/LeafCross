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
var functions_called_during_text: Array[Function] = []
var contains_non_wait_function := false

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
	TextSystem.character_colors.clear()
	in_brackets = false
	bracket_content = ""
	parsed_ch_index = 0
	resulting_text = ""
	contains_text_options = false
	after_choicer_text_error_pushed = false
	suffix_instruction_appeared = SuffixType.None
	ChoicerSystem.choicer_options = {}
	functions_called_during_text = []
	contains_non_wait_function = false

func parse_control_bracket_end():
	in_brackets = false
	
	if bracket_content.is_valid_float():
		var wait_func = Function.ctor("wait", true, parsed_ch_index, [float(bracket_content)])
		functions_called_during_text.append(wait_func)
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
	
	if parse_function_call("!") or parse_function_call("await "): return
	
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

func parse_function_call(prefix):
	if not bracket_content.begins_with(prefix): return false
	var content_with_no_prefix = bracket_content.substr(prefix.length())
	var opening_parenthesis_index = content_with_no_prefix.find('(')
	var closing_parethesis_index = content_with_no_prefix.find(')')
	contains_non_wait_function = true
	
	var function_name = content_with_no_prefix.substr(0, opening_parenthesis_index)
	var arguments_as_str = content_with_no_prefix.substr(opening_parenthesis_index+1, closing_parethesis_index-opening_parenthesis_index-1)
	if opening_parenthesis_index == -1: arguments_as_str = ""
	
	current_func_args_list = []
	current_parsed_argument_symbol = ""
	is_current_arg_string = false
	is_parsed_char_argument = false
	is_latest_arg_string = false
	
	parse_function_arguments(arguments_as_str)
	var current_function = Function.ctor(function_name, prefix != "!", parsed_ch_index, current_func_args_list)
	functions_called_during_text.append(current_function)
	return true

var current_func_args_list := []
var current_parsed_argument_symbol := ""
var is_current_arg_string := false
var is_parsed_char_argument := false
var is_latest_arg_string := false

func parse_function_arguments(str_arguments):
	for ch in str_arguments:
		if ch == ' ' and not is_parsed_char_argument and not is_current_arg_string: continue
		if ch == ',' and not is_current_arg_string:
			parse_fn_arg()
			continue
		if ch == '"':
			is_latest_arg_string = true
			is_current_arg_string = !is_current_arg_string
			continue
		current_parsed_argument_symbol += ch
	parse_fn_arg()

func parse_fn_arg():
	if current_parsed_argument_symbol == "": return
	var argument_value
	if is_latest_arg_string: argument_value = current_parsed_argument_symbol
	elif current_parsed_argument_symbol in ["true", "false"]: argument_value = current_parsed_argument_symbol == "true"
	elif current_parsed_argument_symbol.is_valid_float(): argument_value = current_parsed_argument_symbol.to_float()
	elif current_parsed_argument_symbol in TextSystem.linked_variables: argument_value = TextSystem.linked_variables[current_parsed_argument_symbol]
	else: push_error("Unable to find a variable of name '" + current_parsed_argument_symbol + "'!")
	
	current_func_args_list.append(argument_value)
	current_parsed_argument_symbol = ""
	is_latest_arg_string = false

func parse_suffix_statement():
	suffix_instruction_appeared = SuffixType.Regular
	argument_part = remove_instruction_char(bracket_content)
	analysed_part = argument_part.substr(0, analysed_special_suffix_statement_character_count)
	latest_suffix_instruction = argument_part
	
	if is_special_suffix("R"): suffix_instruction_appeared = SuffixType.Random

func is_special_suffix(special_character):
	var is_special = analysed_part == special_character + " "
	if not is_special: return false
	if is_special: latest_suffix_instruction = argument_part.substr(analysed_special_suffix_statement_character_count)
	return true

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
