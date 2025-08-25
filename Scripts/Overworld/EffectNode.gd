extends CanvasLayer

var effect : Effects.ID

@onready var icon = $"Effect Root/Effect Icon"
@onready var label = $"Effect Root/Effect Time Left"
@onready var effect_root = $"Effect Root"

const space_between_effects = 150
const effect_tween_duration = 0.5

func _ready():
	Effects.order_all_effects.connect(move_effect)
	effect_root.modulate.a = 0
	tween_root(0.75)
	var effect_name = Effects.get_effect_name(effect)
	var effect_path = "res://Textures/Effects/" + effect_name + ".png"
	icon.texture = load(effect_path)

func _process(_delta: float):
	var time_left = Effects.get_effect_time_left(effect)
	var used_time = ceili(time_left)
	if time_left == INF: used_time = "?"
	label.text = str(used_time)
	if time_left > 0: return
	tween_root(0)
	await get_tree().create_timer(2).timeout
	queue_free()

func tween_root(final):
	create_tween().tween_property(effect_root, "modulate:a", final, effect_tween_duration).set_ease(Tween.EASE_IN_OUT)

func move_effect():
	var effect_position = Effects.sorted_effects.find(effect)
	create_tween().tween_property(effect_root, "position:x", -space_between_effects * effect_position, effect_tween_duration).set_ease(Tween.EASE_IN_OUT)
