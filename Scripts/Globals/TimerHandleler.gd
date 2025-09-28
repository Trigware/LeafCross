extends Control

@onready var progress_bar = $"Progress Bar"
@onready var clock = $Clock
@export var timer_duration : float
var time_remaining : float
var low_time_reached = false

const clock_bar_delta = 50
const timer_y_offset = 65
const low_time = 0.5

signal timeout

func _ready():
	time_remaining = timer_duration
	progress_bar.max_value = timer_duration
	tween_progress_bar(500, 0.6)
	tween_show()

func _process(delta):
	time_remaining = maxf(time_remaining - delta, 0)
	progress_bar.value = time_remaining
	progress_bar.tint_progress.s = get_timer_tint()
	if time_remaining <= low_time: on_reaching_low_time()

func change_progress_bar_size(progress_size: float):
	var screen_size = get_screen_size()
	var progress_x_pos = screen_size.x / 2 - progress_size / 2
	progress_bar.position.x = progress_x_pos
	progress_bar.size.x = progress_size
	clock.position.x = progress_x_pos - clock_bar_delta

func tween_progress_bar(final: float, duration):
	var tween_progress = create_tween().tween_method(
		func(value): change_progress_bar_size(value),
		0,
		final,
		duration
	)
	tween_progress.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)

func get_screen_size(): return get_viewport().get_visible_rect().size
func tween_show(): tween_timer(get_screen_size().y - timer_y_offset, 0.25)
func tween_hide(): tween_timer(get_screen_size().y, low_time)

func tween_timer(final, duration):
	var move_tween = create_tween().tween_property(self, "position:y", final, 0.75)
	move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

const max_saturation = 0.75
const maximum_no_saturation_portion = 0.5

func get_timer_tint():
	var portion = time_remaining / timer_duration
	if portion >= maximum_no_saturation_portion: return 0
	var modified_portion = 1 - portion / maximum_no_saturation_portion
	return modified_portion * max_saturation

func on_reaching_low_time():
	if low_time_reached: return
	low_time_reached = true
	tween_hide()
