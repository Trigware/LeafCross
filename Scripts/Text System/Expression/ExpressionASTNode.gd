extends RefCounted
class_name ExpressionNode

var children: Array[ExpressionNode] = []
var node_type := ExpressionToken.TokenType.Unknown
var operator_type := ExpressionToken.Operator.Unknown
var runtime_value

func _to_string() -> String:
	var result = ExpressionToken.TokenType.find_key(node_type)
	var operator_type = ExpressionToken.Operator.find_key(operator_type)
	if runtime_value == null: result += '(' + operator_type + ')'
	else: result += '(' + str(runtime_value) + ')'
	return result
