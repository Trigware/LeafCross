extends Node

const control_characters := ["#", "?", "|", '!', '*']
const control_flow_statements := ["if", "endcf", "else", "elif"]

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
var macros_control_flow_nesting_level : Array[int] = []
var encountered_color_in_current_text : Array[bool] = []

func parse(original_text : String, variables, parsing_macro := false) -> String:
	previous_nesting_level = 0
	if macros_control_flow_nesting_level.size() > 0:
		previous_nesting_level = macros_control_flow_nesting_level[macros_control_flow_nesting_level.size()-1]
	encountered_color_in_current_text.append(false)
	
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
	
	var current_nesting_level = nested_conditions_results.size()
	var nesting_diff = current_nesting_level - previous_nesting_level
	for i in range(nesting_diff): parse_end_control_flow()
	var encountered_color = encountered_color_in_current_text.pop_back()
	if encountered_color: modified_text += "{#/}"
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
	macros_control_flow_nesting_level = []

func parse_end_bracket_content():
	if not in_bracket:
		push_error("Found closing bracket which doesn't have an associated opening one!")
		return
	in_bracket = false
	if check_for_control_flow(): return
	if latest_condition == false: return
	if check_for_macro(): return
	if check_for_expression(): return
	
	if check_if_bracket_is_portrait_symbol(): return
	var bracket_control_type = is_bracket_content_control_segment()
	if bracket_control_type != BracketControlOptions.Variable:
		if bracket_control_type == BracketControlOptions.Placeholder: add_placeholder_text()
		return
	
	if check_for_semicolon_statement(): return
	if check_for_variable_assignment(): return
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
	if bracket_content == "&!": macro_key = latest_text_key
	
	if not Localization.text_exists(macro_key): push_error("Macro statement attempted to refererence a non-existent key " + macro_key + " in " + latest_text_key)
	macros_control_flow_nesting_level.append(nested_conditions_results.size())
	modified_text = Localization.get_text(macro_key, inserted_variable_dict, true)
	macros_control_flow_nesting_level.pop_back()
	return true

func check_for_semicolon_statement() -> bool:
	var first_semicolon_occurence = bracket_content.find(':')
	if first_semicolon_occurence == -1: return false
	var before_semicolon_contents = bracket_content.substr(0, first_semicolon_occurence)
	var first_space_index = bracket_content.find(' ')
	var semicolon_keyword = bracket_content.substr(0, first_space_index)
	var instruction_param = bracket_content.substr(first_space_index+1, first_semicolon_occurence - first_space_index - 1)
	var param_value = ExpressionEval.evaluate_expression(instruction_param)
	var instruction_contents = bracket_content.substr(first_semicolon_occurence+1)
	var split_args = instruction_contents.replace(" ", "").split(',')
	
	if semicolon_keyword in ["count", "enum"] and not param_value is int:
		push_error("The " + semicolon_keyword + " statement parameter must be only of type int!")
		return true
	
	match semicolon_keyword:
		"count":
			var count_statement_result = split_args[get_count_statement_index(split_args, param_value)]
			modified_text += count_statement_result
		"enum":
			if param_value < 0 and param_value >= split_args.size():
				push_error("The enum parameter value must be in range 0 to " + str(split_args.size()-1) + "!")
				return true
			var enum_statement_result = split_args[param_value]
			modified_text += enum_statement_result
	return true

const ENG_SINGULAR = 0
const ENG_PLURAL = 1
const CZE_SINGULAR = 0
const CZE_FEW = 1
const CZE_PLURAL = 2

func get_count_statement_index(count_statement_options, expr_result):
	if not expr_result is int:
		push_error("The count statement expression must evaluate to type int.")
		return null
	var value_abs = abs(expr_result)
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

func check_for_variable_assignment():
	var first_occurrence_of_equals = bracket_content.find('=')
	if first_occurrence_of_equals == -1: return false
	var assignment_expression_str = bracket_content.substr(first_occurrence_of_equals+1)
	var assignment_expr = ExpressionEval.evaluate_expression(assignment_expression_str)
	var variable_name_including_spaces = bracket_content.substr(0, first_occurrence_of_equals)
	var first_non_spaceindex = -1
	for i in range(variable_name_including_spaces.length() - 1, -1, -1):
		var ch = variable_name_including_spaces[i]
		if ch != ' ':
			first_non_spaceindex = i
			break
	var variable_name = bracket_content.substr(0, first_non_spaceindex+1)
	inserted_variable_dict.set(variable_name, assignment_expr)
	return true

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
	if control_symbol == '#': encountered_color_in_current_text[encountered_color_in_current_text.size()-1] = true
	
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
	
	match statement:
		"if": parse_conditional(remainder)
		"endcf": parse_end_control_flow()
		"else": parse_else_statement()
		"elif":
			parse_else_statement()
			parse_conditional(remainder)

func parse_conditional(remainder):
	latest_statement_else = false
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
	latest_statement_else = false
	
	var size_after_pop = nested_conditions_results.size()
	if size_after_pop == 0:
		latest_condition = true
		return
	
	latest_condition = nested_conditions_results[size_after_pop - 1]

func parse_else_statement():
	var depth = nested_conditions_results.size()
	if latest_statement_else:
		for i in range(depth-1): parse_end_control_flow()
		depth = nested_conditions_results.size()
	
	latest_statement_else = true
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
