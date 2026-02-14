extends Node
var current_index: int
var parenthesis_nesting_level: int

func build_tree() -> ExpressionNode:
	current_index = 0
	parenthesis_nesting_level = 0
	var resulting_tree = parse_expression(0)
	return resulting_tree

func parse_expression(minimum_precedence: int) -> ExpressionNode:
	var left_hand_side: ExpressionNode = parse_nud()
	while not is_out_of_range():
		var current_token = get_current()
		if current_token.actual_type == ExpressionToken.TokenType.RightParenthesis:
			if parenthesis_nesting_level == 0: push_error("Encountered closing parenthesis which doesn't have a pair!")
			break
		if current_token.actual_type == ExpressionToken.TokenType.TernaryELSE:
			break
		var is_ternary_if = current_token.actual_type == ExpressionToken.TokenType.TernaryIF
		var is_token_invalid = current_token.actual_type != ExpressionToken.TokenType.BinaryOperator and not is_ternary_if
		if is_token_invalid:
			push_error("Expected to encounter a binary or ternary operator, instead encountered '" + current_token.token_contents + "'!")
			break
		
		var used_precedence = 0
		if current_token.operator_info != null:
			used_precedence = current_token.operator_info.precedence_level
			if not current_token.operator_info.has_left_associavity: used_precedence -= 1
		if current_token.operator_info != null and current_token.operator_info.precedence_level <= minimum_precedence: break
		
		advance()
		var right_hand_side = parse_expression(used_precedence)
		if is_ternary_if:
			advance()
			var value_if_false = parse_expression(0)
			left_hand_side = create_ternary(left_hand_side, right_hand_side, value_if_false)
			continue
		left_hand_side = create_node(current_token.as_node(), left_hand_side, right_hand_side)
	return left_hand_side

func advance():
	current_index += 1
	if is_out_of_range(): return null
	return get_current()

func get_current() -> ExpressionToken: return ExpressionEval.token_list[current_index]

func is_out_of_range(): return current_index < 0 or current_index >= ExpressionEval.token_list.size()

func create_node(operator_node: ExpressionNode, left_hand_side: ExpressionNode, right_hand_side: ExpressionNode):
	operator_node.children.append_array([left_hand_side, right_hand_side])
	return operator_node

func create_ternary(value_if_true: ExpressionNode, condition: ExpressionNode, value_if_false: ExpressionNode):
	var ternary_node = ExpressionNode.new()
	ternary_node.node_type = ExpressionToken.TokenType.TernaryOperator
	ternary_node.children.append_array([condition, value_if_true, value_if_false])
	return ternary_node

func parse_nud() -> ExpressionNode:
	if is_out_of_range():
		push_error("Expected either an operand, unary operator or left parenthesis in an expression!")
		return
	var current_token = get_current()
	if current_token.actual_type == ExpressionToken.TokenType.UnaryOperator: return parse_unary_operator(current_token.as_node())
	if current_token.actual_type == ExpressionToken.TokenType.LeftParenthesis: return parse_sub_expression()
	advance()
	return current_token.as_node()

func parse_unary_operator(initial_node: ExpressionNode) -> ExpressionNode:
	var deepest_node = initial_node
	var last_token_paren = false
	while true:
		var current_token = advance()
		var current_node = current_token.as_node()
		if current_token.actual_type == ExpressionToken.TokenType.LeftParenthesis:
			last_token_paren = true
			break
		deepest_node.children.append(current_node)
		deepest_node = current_node
		if current_token.actual_type != ExpressionToken.TokenType.UnaryOperator: break
	if last_token_paren: deepest_node.children.append(parse_sub_expression())
	else: advance()
	return initial_node

func parse_sub_expression():
	advance()
	parenthesis_nesting_level += 1
	var sub_expression = parse_expression(0)
	parenthesis_nesting_level -= 1
	var last_token = ExpressionEval.token_list[ExpressionEval.token_list.size()-1]
	if is_out_of_range() and last_token.actual_type != ExpressionToken.TokenType.RightParenthesis:
		push_error("Expected to encounter a closing parenthesis!")
	advance()
	return sub_expression

func evaluate(parent_node: ExpressionNode):
	var simplified_operand_list = []
	for child in parent_node.children:
		simplified_operand_list.append(evaluate(child))
	if simplified_operand_list.size() > 0:
		return evaluate_operator(parent_node, simplified_operand_list)
	return parent_node

func evaluate_operator(operator_node: ExpressionNode, operand_list: Array):
	var result_value = null
	match operand_list.size():
		1: result_value = evaluate_unary_operator(operator_node, operand_list[0].runtime_value)
		2: result_value = evaluate_binary_operator(operator_node, operand_list)
		3: result_value = evaluate_ternary_operator(operator_node, operand_list[0].runtime_value, operand_list[1].runtime_value, operand_list[2].runtime_value)
	
	var result_node = ExpressionNode.new()
	result_node.node_type = ExpressionToken.TokenType.IntermediateRepresentation
	result_node.runtime_value = result_value
	return result_node

func evaluate_binary_operator(operator_node: ExpressionNode, operand_list: Array):
	var result_value = null
	var first_operand = operand_list[0].runtime_value; var second_operand = operand_list[1].runtime_value
	match operator_node.operator_type:
		ExpressionToken.Operator.LogicalOR: result_value = first_operand or second_operand
		ExpressionToken.Operator.LogicalAND: result_value = first_operand and second_operand
		ExpressionToken.Operator.IFEMPTY: result_value = first_operand == ""
		ExpressionToken.Operator.CompareEQUAL: result_value = first_operand == second_operand
		ExpressionToken.Operator.CompareNOT_EQUAL: result_value = first_operand != second_operand
		ExpressionToken.Operator.CompareGREATER: result_value = first_operand > second_operand
		ExpressionToken.Operator.CompareLESS: result_value = first_operand < second_operand
		ExpressionToken.Operator.CompareGREATER_OR_EQUAL: result_value = first_operand >= second_operand
		ExpressionToken.Operator.CompareLESSER_OR_EQUAL: result_value = first_operand <= second_operand
		ExpressionToken.Operator.ArithmeticPLUS: result_value = evaluate_arithmetic_plus([first_operand, second_operand])
		ExpressionToken.Operator.ArithmeticMINUS: result_value = first_operand - second_operand
		ExpressionToken.Operator.ArithmeticTIMES: result_value = first_operand * second_operand
		ExpressionToken.Operator.ArithmeticDIVIDE: result_value = first_operand / second_operand
		ExpressionToken.Operator.ArithmeticMODULO: result_value = first_operand % second_operand
		ExpressionToken.Operator.ArithmeticEXPONENT: result_value = first_operand ** second_operand
		_: push_error("Encountered a binary operator without functionality!")
	return result_value

func evaluate_arithmetic_plus(operand_list: Array):
	var non_string_operands = []
	var string_operands = []
	for i in range(operand_list.size()):
		var operand = operand_list[i]
		string_operands.append(str(operand))
		if not operand is String: non_string_operands.append(i)
	if non_string_operands.size() == 2: return operand_list[0] + operand_list[1]
	return string_operands[0] + string_operands[1]

func evaluate_unary_operator(operator_node: ExpressionNode, operand):
	var result_value = null
	match operator_node.operator_type:
		ExpressionToken.Operator.UnaryANTI: result_value = not operand
		ExpressionToken.Operator.UnaryPLUS: result_value = +operand
		ExpressionToken.Operator.UnaryMINUS: result_value = -operand
		_: push_error("Encountered an unary operator without functionality!")
	return result_value

func evaluate_ternary_operator(operator_node: ExpressionNode, condition, value_if_true, value_if_false):
	return value_if_true if condition else value_if_false
