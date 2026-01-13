extends RefCounted
class_name OperatorInfo

var operator_type: ExpressionToken.Operator
var precedence_level: int
var has_left_associavity: bool
static func ctor(type: ExpressionToken.Operator, precedence := 0, left_associavity := true) -> OperatorInfo:
	var result := OperatorInfo.new()
	result.operator_type = type
	result.precedence_level = precedence
	result.has_left_associavity = left_associavity
	return result
