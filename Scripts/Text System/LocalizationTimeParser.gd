extends Node

const control_characters := ["#", "?", "|", '!']
const control_flow_statements := ["if", "endcf", "else"]

var modified_text : String
var in_bracket : bool
var bracket_content : String
var inserted_variable_dict : Dictionary
var seen_first_variable : bool
var parsed_variables
var nested_conditions_results : Array[bool] = []
var latest_condition : bool
var latest_statement_else : bool
var used_portrait_statement : bool

func parse(original_text : String, variables) -> String:
	if not original_text.contains("{") and not original_text.contains("}"):
		return original_text
	parse_segment_setup(variables)
	
	for i in original_text.length():
		var ch = original_text[i]
		if ch in TextParser.control_brackets and is_previous_character("\\", i, original_text):
			parse_default_character(ch)
			continue
		match ch:
			"{":
				in_bracket = true
				bracket_content = ""
			"}":
				parse_end_bracket_content()
			_:
				parse_default_character(ch)
	
	if in_bracket: push_error("An openning bracket doesn't have an associated closing one!")
	return modified_text

func is_previous_character(ch, index, text):
	if index <= 0: return false
	var previous_character = text[index - 1]
	return previous_character == ch

func parse_default_character(ch):
	if in_bracket:
		bracket_content += ch
		return
	if latest_condition == false: return
	modified_text += ch

func parse_segment_setup(variables):
	modified_text = ""
	in_bracket = false
	bracket_content = ""
	inserted_variable_dict = {}
	seen_first_variable = false
	latest_condition = true
	latest_statement_else = false
	if variables is Dictionary:
		inserted_variable_dict = variables
	parsed_variables = variables
	used_portrait_statement = false
	nested_conditions_results = []

func parse_end_bracket_content():
	if not in_bracket:
		push_error("Found closing bracket which doesn't have an associated opening one!")
		return
	in_bracket = false
	if check_for_control_flow(): return
	if latest_condition == false: return
	
	if check_if_bracket_is_portrait_symbol(): return
	var bracket_control_type = is_bracket_content_control_segment()
	if bracket_control_type != BracketControlOptions.Variable:
		if bracket_control_type == BracketControlOptions.Placeholder: add_placeholder_text()
		return
	
	modified_text += str(get_variable(bracket_content))

func get_variable(variable_name):
	if variable_name in inserted_variable_dict:
		var dict_cache_var_content = inserted_variable_dict[variable_name]
		return dict_cache_var_content
	
	if variable_name.begins_with("await"): return "{" + variable_name + "}"
	var var_err_placeholder = "{#red}{" + variable_name + "}{#/}"
	if parsed_variables is Dictionary:
		if parsed_variables == {}: push_error("Expecting variable '" + variable_name + "' even though no variables were passed!")
		else: push_error("Wanted variable '" + variable_name + "' doesn't exist in the input dictionary!")
		return var_err_placeholder
	
	if seen_first_variable:
		push_error("Unable to get wanted variable '" + variable_name + "' because a singular variable was passed in!")
		return var_err_placeholder
	
	seen_first_variable = true
	var variable_contents = parsed_variables
	if parsed_variables is Array: variable_contents = parsed_variables[0]
	inserted_variable_dict = {variable_name: variable_contents}
	return variable_contents

func add_placeholder_text(text = null):
	if text == null: text = bracket_content
	var placeholder_text = '{' + text + '}'
	modified_text += placeholder_text

func is_bracket_content_control_segment() -> BracketControlOptions:
	if bracket_content == "p":
		add_placeholder_text(str(TextSystem.default_pause_duration))
		return BracketControlOptions.Replaced
	
	if bracket_content.is_valid_float(): return BracketControlOptions.Placeholder
	if bracket_content.length() == 0: return BracketControlOptions.Placeholder
	
	var control_symbol = bracket_content[0]
	var is_control_segment = control_symbol in control_characters
	
	if is_control_segment: return BracketControlOptions.Placeholder
	return BracketControlOptions.Variable

func check_for_control_flow() -> bool:
	for statement in control_flow_statements:
		if bracket_content.begins_with(statement):
			parse_control_flow(statement)
			return true
	return false

func parse_control_flow(statement: String):
	var remainder = TextParser.remove_instruction_char(bracket_content, statement.length() + 1)
	match statement:
		"if": parse_conditional(remainder)
		"endcf": parse_end_control_flow()
		"else": parse_else_statement()
	latest_statement_else = statement == "else"

func parse_conditional(remainder):
	var condition = get_variable(remainder)
	if not condition is bool:
		push_error("Condition must be of type boolean!")
		condition = false
	if latest_condition == false: condition = false
	nested_conditions_results.append(condition)
	latest_condition = condition

func parse_end_control_flow():
	if nested_conditions_results.size() == 0:
		push_error("END CONTROL FLOW instruction doesn't have anything to close!")
		return
	nested_conditions_results.pop_back()
	
	var size_after_pop = nested_conditions_results.size()
	if size_after_pop == 0:
		latest_condition = true
		return
	
	latest_condition = nested_conditions_results[size_after_pop - 1]

func parse_else_statement():
	var depth = nested_conditions_results.size()
	
	var error_message = ""
	if depth == 0:
		if latest_statement_else: error_message = "More than 1 ELSE in a row is not allowed due to causing unexpected behaviour!"
		else: error_message = "ELSE instruction needs to have an associated IF instruction!"
	elif latest_statement_else: error_message = "More than 1 ELSE in a row is not allowed. Break out of the IFELSE statement with ENDCF first, before using ELSE!"
	if error_message != "":
		push_error(error_message)
		return
	
	for checked_depth in range(depth-1):
		var checked_depth_result = nested_conditions_results[checked_depth]
		if checked_depth_result == false: return
	
	latest_condition = not latest_condition
	nested_conditions_results[depth - 1] = latest_condition

const portrait_statements := ['$', '/']

func check_if_bracket_is_portrait_symbol():
	if bracket_content == "": return
	var bracket_symbol = bracket_content[0]
	var statement_parameter = bracket_content.substr(1)
	if not bracket_symbol in portrait_statements: return false
	
	if used_portrait_statement:
		push_error("Cannot have more than one portrait statement per a translation of a textkey!")
		return
	used_portrait_statement = true
	
	match bracket_symbol:
		"$": parse_character_portrait_statement(statement_parameter)
		"/": parse_portrait_emotion(statement_parameter, TextSystem.get_speaker_name(TextSystem.current_speaking_character))
	return true

func convert_speaker_to_enum(speaker_name: String):
	if not speaker_name in TextSystem.SpeakingCharacter:
		return null
	return TextSystem.SpeakingCharacter[speaker_name]

func parse_character_portrait_statement(statement_parameter : String):
	if statement_parameter == "":
		reset_portrait_state()
		return
	
	var arguments := statement_parameter.split("/")
	if arguments.size() > 2:
		push_error("Portrait statement cannot have more than 2 arguments.")
		return
	
	var speaker_as_str = arguments[0]
	var speaker = convert_speaker_to_enum(speaker_as_str)
	if speaker == null:
		push_error("Invalid speaking character '" + speaker_as_str + "'! Check again if it isn't a typo.")
		return
	TextSystem.current_speaking_character = speaker
	
	var possible_emotion = "Default" if arguments.size() == 1 else arguments[1]
	parse_portrait_emotion(possible_emotion, speaker_as_str)

func parse_portrait_emotion(possible_emotion, speaker_as_str):
	if speaker_as_str == TextSystem.get_speaker_name(TextSystem.SpeakingCharacter.Narrator):
		push_error("Attempted to change emotion to '" + possible_emotion +  "' implicitly but there is no current speaking character!")
		return
	if possible_emotion == "": possible_emotion = "Default"
	var possible_image_path = "res://Character Portraits/" + speaker_as_str + "/" + possible_emotion + ".png"
	if not FileAccess.file_exists(possible_image_path):
		push_error("The speaker '" + speaker_as_str + "' doesn't have an associated texture for the '" + possible_emotion + "' emotion!")
		return
	
	TextSystem.character_portrait_texture = load(possible_image_path)

func reset_portrait_state():
	TextSystem.current_speaking_character = TextSystem.SpeakingCharacter.Narrator
	TextSystem.character_portrait_texture = null

enum BracketControlOptions {
	Variable,
	Placeholder,
	Replaced
}
