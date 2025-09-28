extends Node

signal finished

var waiting_for_stream = false
var currentMusic := ""

func play_sound(stream : AudioStream, pitch_shift = 0.0, volume = 0.0, ignore_game_over = false):
	if LeafMode.game_over and not ignore_game_over: return
	var player = play_stream(stream, pitch_shift, volume)
	await finished
	return player

func play_stream(stream, pitch_shift = 0.0, volume = 0.0):
	if not stream: return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	
	player.volume_db  = volume
	player.pitch_scale = generate_pitch_scale(pitch_shift)
	
	add_child(player)
	player.play()

	player.finished.connect(func():
		player.queue_free()
		emit_signal("finished")
	)
	
	return player

func generate_pitch_scale(pitch_shift):
	var direction = -1 if randf() < 0.5 else 1
	var shiftAmount = randf_range(0, pitch_shift)
	var randomPitch = 1 + direction * shiftAmount
	return max(0.01, randomPitch)

func play_awaited_stream(stream, pitch_shift = 0.0, volume = 0.0):
	if waiting_for_stream or stream == null: return
	waiting_for_stream = true
	play_stream(stream, pitch_shift, volume)
	await finished
	waiting_for_stream = false

func play_music(music_name, pitch_shift = 0.0, playNoMusic := false, volume := 0.0):
	if LeafMode.game_over: return
	if music_name == currentMusic or (music_name == "" and not playNoMusic): return
	var player = Overworld.music
	player.stop()
	currentMusic = music_name
	if playNoMusic: return
	var music_path = "res://Audio/Music/" + music_name + ".mp3"
	var stream = load(music_path)
	if not stream: 
		printerr("Attempted to play non-existent music with name " + music_name + "!")
		return
	var randomPitch = generate_pitch_scale(pitch_shift)
	player.stream = stream
	player.pitch_scale = randomPitch
	player.volume_db = volume
	player.play()
	await player.finished
	currentMusic = ""
	play_music(music_name, pitch_shift, false, volume)

func fade_music(duration):
	var fade_tween = create_tween()
	await fade_tween.tween_property(Overworld.music, "volume_db", -24, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	Overworld.music.stop()

func stop_overworld_music():
	Overworld.music.stop()

const max_distance = 1000
const minimal_volume := -48.0

func play_sound_from_distance(stream: AudioStream, distance_from_source: float, pitch_shift: float, max_volume := 0.0):
	var modified_distance = min(distance_from_source, max_distance)
	var t = modified_distance / max_distance
	var sound_volume = lerp(max_volume, minimal_volume, t)
	await play_sound(stream, pitch_shift, sound_volume)
