extends Node

var game_text : Dictionary = {}
const localization_key_path = "res://Leafcross - Localization.tsv"
var is_latest_textkey_empty : bool
var language_column_index = 0
var language_list := []
var current_language := "english"
var latest_text_contents: String

const ENG = "english"
const CZE = "czech"

func get_text(text_key: String, variables = {}, parsing_macro := false) -> String:
	if not text_exists(text_key) and game_text == {}: load_language(current_language)
	if not text_exists(text_key):
		var error_message = "ERR 0: " + text_key
		push_error(error_message)
		return latest_text_contents + error_message
	
	if variables is Array and variables.size() > 1:
		push_error("On " + text_key + " attempted to use an Array for storing variables. Array variables are deprecated, use a dictionary instead!")
		return latest_text_contents + "ERR 1"
	
	is_latest_textkey_empty = false
	var unsubstituted_text = game_text[text_key]
	if unsubstituted_text == "{}":
		is_latest_textkey_empty = true
		return ""
	
	if not parsing_macro: LocalizationTimeParser.latest_text_key = text_key
	var localized_text = LocalizationTimeParser.parse(unsubstituted_text, variables, parsing_macro)
	latest_text_contents = localized_text
	if localized_text == "" and unsubstituted_text != "":
		is_latest_textkey_empty = true
		return ""
	
	if unsubstituted_text == "": 
		push_error("Missing translation for text key " + text_key + " in the " + current_language + " language!")
		localized_text = latest_text_contents + "ERR 2: " + text_key + " (" + current_language + ")"
	
	if not parsing_macro: latest_text_contents = ""
	return localized_text

func get_key_suffixed(base_key, suffix) -> String:
	return base_key + "_" + str(suffix)

func text_exists(text_key) -> bool:
	return text_key in game_text

func does_suffixed_key_exist(suffixed_key) -> bool:
	for text_key: String in game_text:
		if suffixed_key == text_key: return true
		var hashtag_char_index = text_key.rfind("#")
		if hashtag_char_index == -1: continue
		var key_without_index = text_key.substr(0, hashtag_char_index)
		if key_without_index == suffixed_key: return true
	return false

func load_language(newLanguage):
	current_language = newLanguage
	parse_tsv_file(UID.LOCALIZATION.localization_contents)

var current_text_key := ""
var current_columns: Array
var current_text_contents: String

func parse_tsv_file(file_contents):
	game_text = {}
	language_list.clear()
	current_text_key = ""
	
	var lines = file_contents.replace("\r", "").split("\n")
	for i in range(lines.size()):
		var line = lines[i]
		if line == "": continue
		current_columns = line.split("\t")
		if i == 0:
			if parse_first_tsv_line(current_columns) != 0: return
			continue
		var column_count = current_columns.size()
		if language_column_index >= column_count or column_count == 0:
			push_error("Localization file read error at row " + str(i) + "! (contents: " + line + ")")
			continue
		current_text_key = current_columns[0]
		current_text_contents = unespace_string(current_columns[language_column_index])
		handle_key_attributes()
		game_text[current_text_key] = current_text_contents

func unespace_string(text):
	text = text.replace("\\\\n", "\n")
	text = text.replace("\\t", "\t")
	text = text.replace("\\\\", "\\")
	return text

func parse_first_tsv_line(columns):
	for i in range(columns.size()):
		var column = columns[i]
		if i == 0: continue
		language_list.append(column)
	if current_language in language_list:
		language_column_index = language_list.find(current_language) + 1
		return 0
	load_language("english")
	return 1

var current_key_attributes := []

func handle_key_attributes():
	current_key_attributes = []
	if not current_text_key.contains('&'): return
	var first_attribute_index = current_text_key.find('&')
	var i = first_attribute_index + 1
	var latest_attribute = ""
	while i < current_text_key.length():
		var ch = current_text_key[i]
		if ch == '&':
			current_key_attributes.append(latest_attribute)
			continue
		latest_attribute += ch
		i += 1
	if latest_attribute != "": current_key_attributes.append(latest_attribute)
	current_text_key = current_text_key.substr(0, first_attribute_index)
	if "cpy" in current_key_attributes: handle_copy_attribute()

func handle_copy_attribute():
	var copied_text = ""
	for i in range(1, current_columns.size()):
		var column = current_columns[i]
		if column == "": continue
		if copied_text == "": copied_text = column
		else:
			push_error("Unable to disambiguate which text to use for copying with the copy text attribute!")
			return
	current_text_contents = copied_text
