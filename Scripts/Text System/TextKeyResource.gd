extends RefCounted
class_name TextKey

enum Attribute {
	Unknown,
	Copy,
	Comment
}

@export var key_contents: String
@export var attribute_list: Array[Attribute]

const string_to_attributes: Dictionary[String, Attribute] = {
	"cpy": Attribute.Copy,
	"comment": Attribute.Comment
}

static func ctor(key_content: String, attributes: Array[Attribute]) -> TextKey:
	var text_key = TextKey.new()
	text_key.key_contents = key_content
	text_key.attribute_list = attributes
	return text_key
