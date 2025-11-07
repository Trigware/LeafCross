class_name Function
extends Resource

var function_name: String
var awaited_function_call: bool
var text_index: int
var arguments: Array

static func ctor(func_name: String, is_awaited: bool, index: int, args: Array) -> Function:
	var instance = Function.new()
	instance.function_name = func_name
	instance.awaited_function_call = is_awaited
	instance.text_index = index
	instance.arguments = args
	return instance
