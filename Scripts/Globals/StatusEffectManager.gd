extends Node

enum ID {
	Uninitialized,
	Poison,
	Blindness,
	Burning
}

var effect_durations : Dictionary[ID, float] = {}
var processed_effects : Dictionary[ID, float] = {}
var sorted_effects : Array[ID] = []

const blidness_color_component := 90

signal order_all_effects

func _ready():
	order_all_effects.connect(order_effects)

func has_effect(effect: ID): return effect in processed_effects

func activate(effect: ID, duration):
	if LeafMode.game_over: return
	var previous_duration = effect_durations.get(effect, 0)
	var effect_instance = UID.SCN_STATUS_EFFECT.instantiate()
	effect_instance.effect = effect
	var new_duration = previous_duration + duration
	if previous_duration == 0 and new_duration > 0:
		add_child(effect_instance)
	else: return
	effect_durations[effect] = new_duration
	emit_signal("order_all_effects")
	if not effect in processed_effects:
		effect_processing_loop(effect)
	Audio.play_sound(UID.SFX_STATUS_EFFECT, 0.2)

func order_effects():
	sorted_effects = effect_durations.keys()
	sorted_effects.sort_custom(
		func(a, b):
			return effect_durations[a] < effect_durations[b]
	)

func get_effect_name(id: ID) -> String:
	return ID.find_key(id)

func wait(duration):
	await get_tree().create_timer(duration).timeout

func _process(delta: float):
	for effect_time_key in effect_durations.keys():
		var current_time = get_effect_time_left(effect_time_key)
		var new_time = max(current_time - delta, 0)
		effect_durations[effect_time_key] = new_time

func effect_processing_loop(effect: ID):
	processed_effects[effect] = 0
	var effect_name = get_effect_name(effect).to_lower()
	var start_effect_func = effect_name + "_start"
	if has_method(start_effect_func): call(start_effect_func)
	effect_start(effect)
	
	while get_effect_time_left(effect) > 0:
		processed_effects[effect] += 1
		var times_processed_since_start = processed_effects[effect]
		var effect_func = effect_name + "_effect"
		if has_method(effect_func): await call(effect_func, times_processed_since_start)
		else: await wait(0.01)
	
	effect_end(effect)

func get_effect_time_left(effect: ID):
	if not effect in effect_durations: return 0
	return effect_durations[effect]

func poison_effect(times_processed_since_start):
	await wait(1)
	var health_change = -min(2 * times_processed_since_start, 10)
	var new_health = Player.playerHealth + health_change
	if new_health < 1:
		health_change = -(Player.playerHealth - 1)
	health_change = roundi(health_change)
	if health_change > 0: return
	LeafMode.modify_hp_with_label(health_change)

const max_burning_damage = 14
const burning_damage_multiplier = 3

func burning_effect(times_processed_since_start):
	var river_manager = Overworld.activeRoom.get_node_or_null("River Manager")
	if river_manager != null and river_manager.shallow_water != null: TextMethods.create_centered_text("CatchingOnFire_ExtinguishWithWater")
	var damage = min(times_processed_since_start * burning_damage_multiplier, max_burning_damage)
	LeafMode.modify_hp_with_label(-damage)
	await wait(1)

func blindness_start():
	blindness_tween(0.25)
	tween_base_light(get_effect_colors(ID.Blindness))

func blindness_end():
	blindness_tween(LeafMode.initial_light_multiplier)
	tween_base_light(Overworld.base_light_color)

func blindness_tween(final): create_tween().tween_property(LeafMode, "light_multiplier", final, 1).set_ease(Tween.EASE_IN_OUT)

func get_effect_colors(effect: ID):
	var blidness_component_float = blidness_color_component / 255.0
	var blidness_color = Color(blidness_component_float, blidness_component_float, blidness_component_float)
	
	if effect_ongoing(ID.Blindness): return blidness_color
	var color = Overworld.base_light_color
	match effect:
		ID.Poison: color = Color.GREEN_YELLOW
		ID.Blindness: color = blidness_color
		ID.Burning: color = Color.DARK_ORANGE
	return color

func effect_start(effect: ID):
	if not effect_ongoing(ID.Blindness):
		tween_base_light(get_effect_colors(effect))

func effect_end(effect: ID):
	var effect_name = get_effect_name(effect).to_lower()
	processed_effects.erase(effect)
	effect_durations.erase(effect)
	emit_signal("order_all_effects")
	var end_effect_func = effect_name + "_end"
	if has_method(end_effect_func): call(end_effect_func)
	if not effect_ongoing(ID.Blindness):
		tween_base_light(get_effect_color_with_most_time())
	if effect == ID.Burning: TextMethods.delete_centered_text("CatchingOnFire_ExtinguishWithWater")

func tween_base_light(final):
	create_tween().tween_property(Overworld.baseLight, "color", final, 1).\
		set_trans(Tween.TRANS_SINE).\
		set_ease(Tween.EASE_IN_OUT)

func effect_ongoing(effect: ID):
	return effect in effect_durations

func get_effect_color_with_most_time():
	if sorted_effects.size() == 0: return Overworld.base_light_color
	return get_effect_colors(sorted_effects[0])

func get_ongoing_effects_count():
	return effect_durations.size()

func get_ongoing_effects():
	return effect_durations.keys()

func end_all_effects():
	for effect in Effects.get_ongoing_effects():
		Effects.effect_end(effect)
