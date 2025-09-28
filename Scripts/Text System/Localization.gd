extends Node

var game_text : Dictionary = {}
const localization_key_path = "res://Leafcross - Localization.tsv"
var is_latest_textkey_empty : bool
var language_column_index = 0
var language_list := []
var current_language := "english"

func get_text(text_key: String, variables = {}) -> String:
	if not text_exists(text_key) and game_text == {}: load_language(current_language)
	if not text_exists(text_key):
		var error_message = "ERR 0: " + text_key
		push_error(error_message)
		return error_message
	
	if variables is Array and variables.size() > 1:
		push_error("On " + text_key + " attempted to use an Array for storing variables. Array variables are deprecated, use a dictionary instead!")
		return "ERR 1"
	
	is_latest_textkey_empty = false
	var unsubstituted_text = game_text[text_key]
	if unsubstituted_text == "{}":
		is_latest_textkey_empty = true
		return ""
	
	var localized_text = LocalizationTimeParser.parse(unsubstituted_text, variables)
	if unsubstituted_text == "": 
		push_error("Missing translation for text key " + text_key + " in the " + current_language + " language!")
		localized_text = "ERR 2: " + text_key + " (" + current_language + ")"
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
	var file = FileAccess.open(localization_key_path, FileAccess.READ)
	if not file:
		game_text = {}
		return
	var file_contents = file.get_as_text()
	parse_tsv_file(file_contents)

func parse_tsv_file(file_contents):
	game_text = {}
	language_list.clear()
	var lines = file_contents.replace("\r", "").split("\n")
	for i in range(lines.size()):
		var line = lines[i]
		if line == "": continue
		var columns = line.split("\t")
		if i == 0:
			if parse_first_csv_line(columns) != 0: return
			continue
		var column_count = columns.size()
		if language_column_index >= column_count or column_count == 0:
			push_error("Localization file read error at row " + str(i) + "! (contents: " + line + ")")
			continue
		var text_key = columns[0]
		var text_contents = unespace_string(columns[language_column_index])
		game_text[text_key] = text_contents

func unespace_string(text):
	text = text.replace("\\n", "\n")
	text = text.replace("\\t", "\t")
	text = text.replace("\\\\", "\\")
	return text

func parse_first_csv_line(columns):
	for i in range(columns.size()):
		var column = columns[i]
		if i == 0: continue
		language_list.append(column)
	if current_language in language_list:
		language_column_index = language_list.find(current_language) + 1
		return 0
	load_language("english")
	return 1
