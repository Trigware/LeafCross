extends Node

const control_characters := ["#", "?", "|", '!', '*']
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
var latest_text_key: String
var encountered_colored_text := false
var macro_trace := []
var macro_nesting_level := []

func parse(original_text : String, variables, parsing_macro := false) -> String:
	if not parsing_macro: parse_segment_setup(variables)
	if not original_text.contains("{") and not original_text.contains("}"):
		return modified_text + original_text
	
	for i in original_text.length():
		var ch = original_text[i]
		if ch in TextParser.control_brackets and is_previous_character("\\", i, original_text):
			parse_default_character(ch)
			continue
		match ch:
			"{":
				in_bracket = true
				bracket_content = ""
			"}": parse_end_bracket_content()
			_: parse_default_character(ch)
	
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
	macro_trace = []
	macro_nesting_level = []
	encountered_colored_text = false

func parse_end_bracket_content():
	if not in_bracket:
		push_error("Found closing bracket which doesn't have an associated opening one!")
		return
	in_bracket = false
	if check_for_control_flow(): return
	if check_for_macro(): return
	if check_for_expression(): return
	if latest_condition == false: return
	
	if check_if_bracket_is_portrait_symbol(): return
	var bracket_control_type = is_bracket_content_control_segment()
	if bracket_control_type != BracketControlOptions.Variable:
		if bracket_control_type == BracketControlOptions.Placeholder: add_placeholder_text()
		return
	
	if check_for_count_statement(): return
	modified_text += str(get_variable(bracket_content))

const regular_macro = 1

func check_for_macro() -> bool:
	if not bracket_content.begins_with("&"): return false
	var macro_key = ""
	var encountered_non_and = false
	var ands_encountered = 0
	
	for ch in bracket_content:
		if ch == "&" and not encountered_non_and: ands_encountered += 1
		if ch != "&": encountered_non_and = true
		if encountered_non_and: macro_key += ch
	if ands_encountered > 2:
		push_error("Unknown macro type specilizer! Encountered " + ands_encountered + " ampersands!")
		return true
	if ands_encountered == regular_macro: macro_key = latest_text_key + "^" + macro_key
	
	macro_trace.append(macro_key)
	macro_nesting_level.append(nested_conditions_results.size())
	if latest_text_key in macro_trace:
		push_error("Found circular dependency in macro expansions! Macro trace: " + str(macro_trace))
		return true
	
	if not Localization.text_exists(macro_key): push_error("Macro statement attempted to refererence a non-existent key " + macro_key + " in " + latest_text_key)
	modified_text = Localization.get_text(macro_key, inserted_variable_dict, true)
	var previous_nesting_level = macro_nesting_level.pop_back()
	var current_nesting_level = nested_conditions_results.size()
	macro_trace.pop_back()
	if encountered_colored_text: modified_text += "{#/}"
	if current_nesting_level > previous_nesting_level: parse_end_control_flow()
	return true

var count_statement_variable := ""
var count_statement_options := []
var current_count_statement_option := ""
var parsing_current_statement := false

func check_for_count_statement() -> bool:
	count_statement_variable = ""
	count_statement_options = []
	var encountered_count_variable = false
	var current_count_statement_option = ""
	var parsing_current_statement = false
	
	for ch in bracket_content:
		if ch == ':' and not encountered_count_variable:
			encountered_count_variable = true
			continue
		if not encountered_count_variable:
			count_statement_variable += ch
			continue
		if ch == ',' and encountered_count_variable:
			count_statement_options.append(current_count_statement_option)
			current_count_statement_option = ""
			parsing_current_statement = false
			continue
		if not ch == ' ': parsing_current_statement = true
		if parsing_current_statement: current_count_statement_option += ch
	if current_count_statement_option != "": count_statement_options.append(current_count_statement_option)
	if encountered_count_variable: modified_text += count_statement_options[get_count_statement_index()]
	return encountered_count_variable

const ENG_SINGULAR = 0
const ENG_PLURAL = 1
const CZE_SINGULAR = 0
const CZE_FEW = 1
const CZE_PLURAL = 2

func get_count_statement_index():
	var variable_value = get_variable(count_statement_variable)
	if not is_valid_variable(count_statement_variable): return null
	var value_abs = abs(variable_value)
	var has_decimal = not is_equal_approx(value_abs, floor(value_abs))
	match Localization.current_language:
		Localization.ENG:
			if count_statement_options.size() != 2:
				push_error("Encountered a count statement in english which is not of form [1, non-1] in key " + latest_text_key + "!")
				return null
			return ENG_SINGULAR if value_abs == 1 else ENG_PLURAL
		Localization.CZE:
			if count_statement_options.size() != 3:
				push_error("Encountered a count statement in czech which is not of form [abs is 1, abs in range 2 to 4, decimal or abs more than 5] in key " + latest_text_key + "!")
				return null
			if has_decimal: return CZE_PLURAL
			if value_abs == 1: return CZE_SINGULAR
			if value_abs >= 2 and value_abs <= 4: return CZE_FEW
			return CZE_PLURAL
	return null

func is_valid_variable(variable_name): return variable_name in inserted_variable_dict

func get_variable(variable_name):
	if variable_name in inserted_variable_dict:
		var dict_cache_var_content = inserted_variable_dict[variable_name]
		return dict_cache_var_content
	
	if variable_name.begins_with("await "): return "{" + variable_name + "}"
	var var_err_placeholder = "{" + variable_name + "}"
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
	if control_symbol == "#": encountered_colored_text = true
	
	if is_control_segment: return BracketControlOptions.Placeholder
	return BracketControlOptions.Variable

func check_for_control_flow() -> bool:
	for statement in control_flow_statements:
		if bracket_content.begins_with(statement):
			parse_control_flow(statement)
			return true
	return false

var previous_nesting_level := 0

func parse_control_flow(statement: String):
	var remainder = TextParser.remove_instruction_char(bracket_content, statement.length() + 1)
	previous_nesting_level = 0
	if macro_nesting_level.size() > 0: previous_nesting_level = macro_nesting_level[macro_nesting_level.size()-1]
	
	match statement:
		"if": parse_conditional(remainder)
		"endcf": parse_end_control_flow()
		"else": parse_else_statement()
	latest_statement_else = statement == "else"

func parse_conditional(remainder):
	var condition = ExpressionEval.evaluate_expression(remainder)
	if not condition is bool:
		push_error("Expected to encounter a condition which evaluates to type boolean!")
		return
	if latest_condition == false: condition = false
	nested_conditions_results.append(condition)
	latest_condition = condition

func parse_end_control_flow():
	if nested_conditions_results.size() == previous_nesting_level:
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
	if depth == previous_nesting_level:
		if latest_statement_else: error_message = "More than 1 ELSE in a row is not allowed due to causing unexpected behaviour!"
		else: error_message = "ELSE instruction needs to have an associated IF instruction!"
	elif latest_statement_else: error_message = "More than 1 ELSE in a row is not allowed."
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

func check_for_expression() -> bool:
	if not bracket_content.begins_with('.'): return false
	var actual_expression = bracket_content.substr(1)
	modified_text += str(ExpressionEval.evaluate_expression(actual_expression))
	return true
