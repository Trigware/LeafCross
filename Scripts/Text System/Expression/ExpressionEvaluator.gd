extends Node

var token_list : Array[ExpressionToken] = []
var last_type := ExpressionToken.TokenType.Unknown
var current_token: ExpressionToken
var string_contents := ""
var is_in_string: bool
var not_equal_op_progress := NotEqualOperatorProgress.None
var parsing_expression := false
var current_expr: String

func initialize_expression():
	token_list = []
	current_token = ExpressionToken.new()
	last_type = ExpressionToken.TokenType.Unknown
	not_equal_op_progress = NotEqualOperatorProgress.None
	is_in_string = false
	parsing_expression = true

func parse_expression_char(ch):
	var is_current_special = is_special_ch(ch)
	if ch == '"':
		end_current_token(is_current_special, ch)
		if not is_in_string:
			string_contents = ""
			is_in_string = true
		else: end_string_token()
		return
	if is_in_string:
		string_contents += ch
		return
	
	if ch == ' ':
		end_current_token(is_current_special, ch)
		return
	if current_token.token_contents == "": current_token.is_special = is_current_special
	if current_token.is_special == is_current_special:
		current_token.token_contents += ch
		return
	end_current_token(is_current_special, ch)

func end_expression():
	end_current_token(false, "")
	var evaluated_node = ExpressionAST.evaluate(ExpressionAST.build_tree())
	parsing_expression = false
	return evaluated_node.runtime_value

func evaluate_expression(expr_as_str: String):
	current_expr = expr_as_str
	initialize_expression()
	for ch in expr_as_str:
		parse_expression_char(ch)
	return end_expression()

func in_string(): return parsing_expression and is_in_string

func end_string_token():
	add_token(ExpressionToken.ctor(ExpressionToken.TokenType.StringLiteral, string_contents))
	string_contents = ""
	current_token.actual_type = ExpressionToken.TokenType.Unknown
	current_token.token_contents = ""
	is_in_string = false

func end_current_token(is_current_special, ch):
	if current_token.token_contents == "": return
	identify_token()
	current_token = ExpressionToken.new()
	current_token.is_special = is_current_special
	current_token.token_contents = "" if ch == " " else ch

const numbers_start = 48
const numbers_end = 57
const upper_case_letters_start = 65
const upper_case_letters_end = 90
const lower_case_letters_start = 97
const lower_case_letters_end = 122

func is_special_ch(ch: String):
	return not is_number(ch) and not is_letter(ch) and ch != ' ' and ch != '_'

func is_number(ch: String) -> bool:
	var unicode_code = ch.unicode_at(0)
	return unicode_code >= numbers_start and unicode_code <= numbers_end

func is_str_num(str: String) -> bool:
	for ch in str:
		if not is_number(ch): return false
	return true

func is_letter(ch: String) -> bool:
	var unicode_code = ch.unicode_at(0)
	return unicode_code >= upper_case_letters_start and unicode_code <= upper_case_letters_end or\
		unicode_code >= lower_case_letters_start and unicode_code <= lower_case_letters_end

func identify_token():
	var is_token_number = is_str_num(current_token.token_contents)
	if is_token_number and last_type == ExpressionToken.TokenType.FloatLiteral:
		var integer_part = token_list.pop_back().token_contents
		var full_number_token = integer_part + "." + current_token.token_contents
		var token = ExpressionToken.ctor(last_type, full_number_token)
		add_token(token)
		return
	if is_token_number and current_token.actual_type == ExpressionToken.TokenType.Unknown:
		current_token.actual_type = ExpressionToken.TokenType.IntegerLiteral
	if current_token.token_contents == "." and last_type == ExpressionToken.TokenType.IntegerLiteral:
		last_type = ExpressionToken.TokenType.FloatLiteral
		current_token.actual_type = last_type
		return
	if not current_token.is_special and current_token.actual_type == ExpressionToken.TokenType.Unknown:
		parse_regular_token()
		return
	if current_token.actual_type == ExpressionToken.TokenType.Unknown:
		parse_operator()
		return
	add_token(current_token)

func add_token(token: ExpressionToken):
	token_list.append(token)
	last_type = token.actual_type
	not_equal_op_progress = NotEqualOperatorProgress.None

const valid_operators := ["+", "-", "*", "/", "**", ">", "<", ">=", "<=", "mod", "anti", "and", "or", "is", "isn't", "(", ")"]
const last_tokens_for_binary_op := [ExpressionToken.TokenType.BooleanLiteral, ExpressionToken.TokenType.IntegerLiteral, ExpressionToken.TokenType.FloatLiteral,
	ExpressionToken.TokenType.StringLiteral, ExpressionToken.TokenType.Variable, ExpressionToken.TokenType.RightParenthesis]
const boolean_literals := ["false", "true"]

enum NotEqualOperatorProgress {
	None,
	IsnPart,
	ApostrophePart
}

func parse_regular_token():
	if current_token.token_contents in boolean_literals:
		add_token(ExpressionToken.ctor(ExpressionToken.TokenType.BooleanLiteral, current_token.token_contents))
		return
	if current_token.token_contents in valid_operators:
		parse_operator()
		return
	if current_token.token_contents == "isn" and not_equal_op_progress == NotEqualOperatorProgress.None:
		not_equal_op_progress = NotEqualOperatorProgress.IsnPart
		return
	if current_token.token_contents == "t" and not_equal_op_progress == NotEqualOperatorProgress.ApostrophePart:
		current_token.token_contents = "isn't"
		parse_operator()
		return
	var token_type: ExpressionToken.TokenType
	
	match current_token.token_contents:
		"if": token_type = ExpressionToken.TokenType.TernaryIF
		"else": token_type = ExpressionToken.TokenType.TernaryELSE
		_:
			token_type = ExpressionToken.TokenType.Variable
			if last_type == ExpressionToken.TokenType.TernaryIF and current_token.token_contents == "empty":
				token_list.pop_back()
				add_operator(ExpressionToken.TokenType.BinaryOperator, "if empty")
				return
	add_token(ExpressionToken.ctor(token_type, current_token.token_contents))

var type_of_operator := ExpressionToken.TokenType.Unknown

func parse_operator():
	if current_token.token_contents == "'" and not_equal_op_progress == NotEqualOperatorProgress.IsnPart:
		not_equal_op_progress = NotEqualOperatorProgress.ApostrophePart
		return
	
	var longest_valid_op = get_longest_valid_operator()
	type_of_operator = ExpressionToken.TokenType.BinaryOperator if last_type in last_tokens_for_binary_op else ExpressionToken.TokenType.UnaryOperator
	if longest_valid_op == "":
		push_error(get_operator_error_message())
		return
	add_operator(type_of_operator, longest_valid_op)
	
	for i in range(longest_valid_op.length(), current_token.token_contents.length()):
		var unary_op = current_token.token_contents[i]
		if not unary_op in get_operator_info(previous_non_primary_operator_type).keys() and not unary_op in ['(', ')']:
			push_error(get_operator_error_message())
			return
		add_operator(previous_non_primary_operator_type, unary_op)

var previous_non_primary_operator_type := ExpressionToken.TokenType.UnaryOperator

func get_operator_error_message():
	var op_type_as_str = "binary" if type_of_operator == ExpressionToken.TokenType.BinaryOperator else "unary"
	return "Encountered an unknown " + op_type_as_str + " '" + current_token.token_contents + "' while parsing an expression!"

func get_longest_valid_operator() -> String:
	if current_token.token_contents in valid_operators: return current_token.token_contents
	var token_len = current_token.token_contents.length()
	var longest_valid_op = ""
	for i in range(token_len):
		var current_operator = current_token.token_contents.substr(0, i+1)
		if current_operator in valid_operators: longest_valid_op = current_operator
	return longest_valid_op

func add_operator(type, operator_name):
	previous_non_primary_operator_type = ExpressionToken.TokenType.UnaryOperator
	if operator_name == '(': type = ExpressionToken.TokenType.LeftParenthesis
	if operator_name == ')':
		type = ExpressionToken.TokenType.RightParenthesis
		previous_non_primary_operator_type = ExpressionToken.TokenType.BinaryOperator
	
	var expr_token = ExpressionToken.ctor(type, operator_name)
	var used_info = get_operator_info(type)
	if not type in [ExpressionToken.TokenType.LeftParenthesis, ExpressionToken.TokenType.RightParenthesis]:
		expr_token.operator_info = used_info[operator_name]
	add_token(expr_token)

func get_operator_info(type: ExpressionToken.TokenType):
	return ExpressionToken.unary_operator_info if type == ExpressionToken.TokenType.UnaryOperator else ExpressionToken.binary_operator_info
