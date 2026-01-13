extends RefCounted
class_name ExpressionToken

enum TokenType {
	Unknown,
	BooleanLiteral,
	IntegerLiteral,
	FloatLiteral,
	StringLiteral,
	Variable,
	UnaryOperator,
	BinaryOperator,
	TernaryOperator,
	LeftParenthesis,
	RightParenthesis,
	TernaryIF,
	TernaryELSE,
	IntermediateRepresentation
}

enum Operator {
	Unknown,
	LogicalOR,
	LogicalAND,
	IFEMPTY,
	CompareEQUAL,
	CompareNOT_EQUAL,
	CompareGREATER,
	CompareLESS,
	CompareGREATER_OR_EQUAL,
	CompareLESSER_OR_EQUAL,
	ArithmeticPLUS,
	ArithmeticMINUS,
	ArithmeticTIMES,
	ArithmeticDIVIDE,
	ArithmeticMODULO,
	ArithmeticEXPONENT,
	UnaryANTI,
	UnaryPLUS,
	UnaryMINUS
}

const operands = [TokenType.BooleanLiteral, TokenType.IntegerLiteral, TokenType.FloatLiteral, TokenType.StringLiteral, TokenType.Variable]
const child_limits := {TokenType.UnaryOperator: 1, TokenType.BinaryOperator: 2, TokenType.TernaryOperator: 3}

static var binary_operator_info : Dictionary[String, OperatorInfo] = {
	"or": OperatorInfo.ctor(Operator.LogicalOR, 1),
	"and": OperatorInfo.ctor(Operator.LogicalOR, 2),
	"if empty": OperatorInfo.ctor(Operator.IFEMPTY, 3, false),
	"is": OperatorInfo.ctor(Operator.CompareEQUAL, 4),
	"isn't": OperatorInfo.ctor(Operator.CompareNOT_EQUAL, 4),
	">": OperatorInfo.ctor(Operator.CompareGREATER, 5),
	"<": OperatorInfo.ctor(Operator.CompareLESS, 5),
	">=": OperatorInfo.ctor(Operator.CompareGREATER_OR_EQUAL, 5),
	"<=": OperatorInfo.ctor(Operator.CompareLESSER_OR_EQUAL, 5),
	"+": OperatorInfo.ctor(Operator.ArithmeticPLUS, 6),
	"-": OperatorInfo.ctor(Operator.ArithmeticMINUS, 6),
	"*": OperatorInfo.ctor(Operator.ArithmeticTIMES, 7),
	"/": OperatorInfo.ctor(Operator.ArithmeticDIVIDE, 7),
	"mod": OperatorInfo.ctor(Operator.ArithmeticMODULO, 7),
	"**": OperatorInfo.ctor(Operator.ArithmeticEXPONENT, 8, false)
}

static var unary_operator_info : Dictionary[String, OperatorInfo] = {
	"anti": OperatorInfo.ctor(Operator.UnaryANTI),
	"+": OperatorInfo.ctor(Operator.UnaryPLUS),
	"-": OperatorInfo.ctor(Operator.UnaryMINUS)
}

var actual_type := TokenType.Unknown
var token_contents := ""
var is_special := false
var operator_info : OperatorInfo = null

static func ctor(type: TokenType, contents := ""):
	var token = ExpressionToken.new()
	token.actual_type = type
	token.token_contents = contents
	return token

func _to_string() -> String:
	var type_as_str = TokenType.find_key(actual_type)
	if token_contents == "": return type_as_str
	return token_contents + " (" + type_as_str + ")"

const parenthesis_tokens := [TokenType.LeftParenthesis, TokenType.RightParenthesis]

func is_operand():
	return actual_type in ExpressionEval.last_tokens_for_binary_op and not actual_type in parenthesis_tokens

func is_operator():
	return not is_operand() and not actual_type in parenthesis_tokens

func as_node() -> ExpressionNode:
	var result = ExpressionNode.new()
	result.node_type = actual_type
	var runtime_value = null
	match actual_type:
		TokenType.BooleanLiteral: runtime_value = token_contents == "true"
		TokenType.IntegerLiteral: runtime_value = int(token_contents)
		TokenType.FloatLiteral: runtime_value = float(token_contents)
		TokenType.StringLiteral: runtime_value = token_contents
		TokenType.Variable: runtime_value = LocalizationTimeParser.get_variable(token_contents)
	
	result.runtime_value = runtime_value
	if operator_info != null: result.operator_type = operator_info.operator_type
	return result
