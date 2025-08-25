extends AudioStreamPlayer

@onready var musicTimer = $MusicTimer
@onready var legend_root = get_node("..")
const fadeTime = 5

func _ready():
	play()
	musicTimer.start(stream.get_length() - fadeTime)
	await musicTimer.timeout
	fade_music(fadeTime * 2)
	await get_tree().create_timer(fadeTime).timeout
	var skip_node = get_node("../Skip Prompt")
	if legend_root.can_end_cutscene: skip_node.end_cutscene()
	legend_root.can_end_cutscene = true

func fade_music(duration):
	var tween = create_tween()
	tween.tween_property(self, "volume_db", -80.0, duration).set_trans(Tween.TRANS_EXPO)
