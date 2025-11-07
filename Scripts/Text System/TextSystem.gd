extends Control

@onready var textNode = $CanvasLayer/Text
@onready var typewritterTimer = $TypewritterTimer
@onready var textboxNode = $CanvasLayer/Textbox
@onready var choicerNode = $CanvasLayer/Textbox/Choicer

@onready var choicer_leaf = $CanvasLayer/Textbox/Choicer/Leaf
@onready var waitLeaf = $"CanvasLayer/Textbox/Wait Leaf"
@onready var choice_label_options := {
	Vector2.LEFT: $"CanvasLayer/Textbox/Choicer/Choice A",
	Vector2.RIGHT: $"CanvasLayer/Textbox/Choicer/Choice B",
	Vector2.UP: $"CanvasLayer/Textbox/Choicer/Choice C",
	Vector2.DOWN: $"CanvasLayer/Textbox/Choicer/Choice D"
}

@onready var true_text_node = textNode
@onready var true_outlined_text = $"CanvasLayer/Outlined Text"
@onready var canvasLayer = $CanvasLayer
@onready var portrait_bg = $CanvasLayer/Textbox/Portrait
@onready var character_portrait_node = $CanvasLayer/Textbox/Portrait/Character

const silentCharacters := [',', '.', '!', '?', ' ', '\n', '\t']

var currentCharacterIndex := 0
var printedText = ""
var fontSize = 0

var character_colors := {}

var delayed = false
var currentColor := "#FFFFFF"
var textCanBeSkipped = false
var originalSpeed
var currentTextAudio : AudioStream
var currentPitchRange = 0

var overwriteSkippable = false
var lockAction = false
var v_text_finished = false
var currentOverlappingSoundsValue := false
var canInteract = true
var init_color
var end_latest_text_automatically := false
var end_latest_text_externally := false
var current_line_choicer = false
var latest_printed_character : String
var time_since_textbox_closed : float
var wait_leaf_position_at_start : Vector2
var textbox_y_scale_at_ready : float
var textbox_previously_shown := false
var linked_variables := {}

const default_pause_duration := 0.5
const textbox_show_duration := 0.15
const new_textbox_duration := 0.02
const textbox_show_offset := -Vector2(35, 20)
const y_scale_multiplier_at_show := 0.875
const waitleaf_show_duration := 0.35
const waitleaf_show_x_offset := -15

const full_hide_portrait_progression := 0.5
const full_show_portrait_progression := -0.06
const portrait_show_duration := 0.45

signal text_finished
signal want_next_text
signal want_choicer

func _ready():
	typewritterTimer.timeout.connect(print_next_char)
	want_next_text.connect(on_wanting_new_text)
	wait_leaf_position_at_start = waitLeaf.position
	waitLeaf.modulate.a = 0
	textbox_y_scale_at_ready = textboxNode.scale.y
	textboxNode.hide()
	choicerNode.hide()
	textNode.text = ""
	PresetSystem.preset_variations()
	hide_portrait()

func _process(delta):
	time_since_textbox_closed += delta

func print_text(text, speed, textSize, textPosition, lineLength,
				centerAlign, allowTextSkip, talkAudio, pitchRange,
				textbox, overlappingSounds, outline, initial_color,
				end_automatically, end_externally, linked_vars):
	linked_variables = linked_vars
	var regularText = TextParser.record_control_text(text)
	TextSystem.textNode.show()
	Player.node.animationNode.stop()
	lockAction = true
	
	if overwriteSkippable: allowTextSkip = false
	delayed = false
	if current_line_choicer: await get_tree().process_frame
	v_text_finished = false
	fontSize = textSize
	textNode.modulate.a = 1
	if outline: textNode = true_outlined_text
	else: textNode = true_text_node
	
	end_latest_text_automatically = end_automatically
	end_latest_text_externally = end_externally
	init_color = initial_color
	currentColor = TextParser.color_to_hex(initial_color)
	textNode.scale = Vector2(fontSize, fontSize) / 48
	textNode.position = textPosition
	textNode.text = ""
	originalSpeed = speed
	currentTextAudio = talkAudio
	currentPitchRange = pitchRange
	textboxNode.visible = textbox
	textbox_previously_shown = textbox
	
	waitLeaf.modulate.a = 0
	if time_since_textbox_closed > new_textbox_duration and textbox:
		show_textbox()
	
	update_portrait()
	currentOverlappingSoundsValue = overlappingSounds
	
	printedText = split_text_by_lines(regularText, lineLength)
	textCanBeSkipped = allowTextSkip
	if centerAlign:
		align_to_center(regularText)
	
	currentCharacterIndex = 0
	if speed > 0 and (regularText != "" or TextParser.functions_called_during_text.size() > 0):
		typewritterTimer.start(speed)
		return
	
	textNode.text = printedText
	if does_player_no_choices():
		await get_tree().process_frame
		finish_text()
		if not Localization.is_latest_textkey_empty: emit_signal("want_next_text")
		return
	await give_choice_from_print_text(regularText == "")

func does_player_no_choices():
	return ChoicerSystem.choicer_options == {}

func give_choice_from_print_text(empty_text := false):
	if does_player_no_choices(): return
	current_line_choicer = true
	if not empty_text:
		await want_choicer
	TextMethods.clear_text()
	await ChoicerSystem.give_choice()
	finish_text()
	emit_signal("want_next_text")
	current_line_choicer = false

func skip_text():
	if not textCanBeSkipped or TextParser.contains_non_wait_function: return
	textNode.text = add_color_to_text(printedText)
	currentCharacterIndex = printedText.length()
	await get_tree().process_frame
	if not textboxNode.visible and textbox_previously_shown: TextMethods.clear_text()

func finish_text(show_leaf = true):
	v_text_finished = true
	emit_signal("text_finished")
	if show_leaf: show_wait_leaf()

func on_wanting_new_text():
	v_text_finished = false
	if ChoicerSystem.in_choicer: return
	textboxNode.hide()
	time_since_textbox_closed = 0
	lockAction = false
	TextMethods.clear_text()

var wait_leaf_alpha_tween : Tween = null
var wait_leaf_movement_tween : Tween = null

func show_wait_leaf():
	if not textboxNode.visible: return
	
	if wait_leaf_alpha_tween != null: wait_leaf_alpha_tween.kill()
	if wait_leaf_movement_tween != null: wait_leaf_movement_tween.kill()
	
	waitLeaf.position.x = wait_leaf_position_at_start.x + waitleaf_show_x_offset
	wait_leaf_alpha_tween = create_tween()
	wait_leaf_alpha_tween.tween_property(waitLeaf, "modulate:a", 1, waitleaf_show_duration)
	wait_leaf_movement_tween = create_tween()
	wait_leaf_movement_tween.tween_property(waitLeaf, "position", wait_leaf_position_at_start, waitleaf_show_duration)

func print_next_char():
	if delayed: return
	
	currentColor = character_colors.get(currentCharacterIndex, currentColor)
	delayed = true
	await call_text_event_functions()
	delayed = false
	
	if currentCharacterIndex < printedText.length():
		latest_printed_character = printedText[currentCharacterIndex]
		play_char_audio()
		textNode.text += "[color=" + currentColor + "]" + latest_printed_character + "[/color]"
		currentCharacterIndex += 1
		return
	
	typewritterTimer.stop()
	textCanBeSkipped = false
	
	show_wait_leaf()
	await give_choice_from_print_text()
	finish_text(false)
	if end_latest_text_automatically:
		emit_signal("want_next_text")

func call_text_event_functions():
	for fn in TextParser.functions_called_during_text:
		if fn.text_index == currentCharacterIndex:
			await CutsceneManager.start_text_event(fn)

func play_char_audio():
	var talk_audio = get_talk_audio()
	if latest_printed_character in silentCharacters: return
	if currentOverlappingSoundsValue: Audio.play_stream(talk_audio, currentPitchRange)
	else: Audio.play_awaited_stream(talk_audio, currentPitchRange)

func get_talk_audio():
	if current_speaking_character == SpeakingCharacter.Narrator: return currentTextAudio
	var current_speaker_name = get_speaker_name(current_speaking_character)
	var audio_path = "res://Audio/Talk/" + current_speaker_name + ".mp3"
	return load(audio_path)

func split_text_by_lines(text, lineLength) -> String:
	if lineLength == 0: return text
	var paragraphs := str(text).split("\n")
	var wrapped_text := ""

	for paragraph in paragraphs:
		var words := paragraph.split(" ")
		var line := ""
		
		for word in words:
			var currentLine = line + ("" if line == "" else " ") + word
			var currentWidth = get_text_width(currentLine)
			
			if currentWidth > lineLength and line != "":
				wrapped_text += line + "\n"
				line = word
			else:
				line = currentLine
		
		wrapped_text += line + "\n"

	return wrapped_text.strip_edges()

func get_text_width(text) -> float:
	var font = textNode.get_theme_font("normal_font")
	return (font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize)).x

func align_to_center(text):
	var centerX = get_viewport().get_visible_rect().size.x / 2.0
	textNode.position.x = centerX - get_text_width(text) / 2

func add_color_to_text(text) -> String:
	var resultText = ""
	var addFuncCurrentColor = init_color
	if init_color is Color:
		addFuncCurrentColor = TextParser.color_to_hex(init_color)
	for i in range(text.length()):
		var ch = text[i]
		addFuncCurrentColor = character_colors.get(i, addFuncCurrentColor)
		resultText += "[color=" + addFuncCurrentColor + "]" + ch + "[/color]"
	return resultText

signal dialog_continue_key_pressed

func _unhandled_input(_event: InputEvent):
	if end_latest_text_externally: return
	var skipping_text = Input.is_action_pressed("skip_text")
	var continue_with_dialog_keys_pressed = skipping_text or Input.is_action_just_pressed("continue")
	if continue_with_dialog_keys_pressed: emit_signal("dialog_continue_key_pressed")
	var dialog_continuation_allowed = (Input.is_action_just_pressed("continue") or skipping_text and TextParser.contains_non_wait_function) and (v_text_finished or current_line_choicer)
	if dialog_continuation_allowed:
		var emitted_signal = "want_next_text"
		if current_line_choicer: emitted_signal = "want_choicer"
		emit_signal(emitted_signal)
	if Input.is_action_just_pressed("continue") and ChoicerSystem.in_choicer:
		ChoicerSystem.on_choice_decided()
	if Input.is_action_just_pressed("move_fast") or skipping_text:
		skip_text()
	if ChoicerSystem.in_choicer:
		ChoicerSystem.handle_choicer_inputs()

var current_speaking_character := SpeakingCharacter.Narrator
var character_portrait_texture : Texture2D = null

enum SpeakingCharacter {
	Narrator,
	Nixie
}

func get_speaker_name(speaker: SpeakingCharacter):
	return SpeakingCharacter.find_key(speaker)

func show_textbox():
	textboxNode.scale.y = textbox_y_scale_at_ready * y_scale_multiplier_at_show
	canvasLayer.offset = textbox_show_offset
	var movement_tween = create_tween().tween_property(canvasLayer, "offset", Vector2.ZERO, textbox_show_duration)
	movement_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var scale_tween = create_tween().tween_property(textboxNode, "scale:y", textbox_y_scale_at_ready, textbox_show_duration)
	scale_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func update_portrait():
	if current_speaking_character == SpeakingCharacter.Narrator:
		hide_portrait()
		return
	character_portrait_node.texture = character_portrait_texture
	show_portrait()

func show_portrait():
	portrait_tween(full_show_portrait_progression)

func hide_portrait():
	portrait_tween(full_hide_portrait_progression)

func portrait_tween(final):
	create_tween().tween_method(
		func(progress): set_portrait_progress(progress),
		get_portrait_progress(),
		final,
		portrait_show_duration
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func set_portrait_progress(value):
	portrait_bg.material.set_shader_parameter("hide_progression", value)

func get_portrait_progress():
	return portrait_bg.material.get_shader_parameter("hide_progression")
