extends Node2D

@onready var subtractiveLight = $Light
@onready var health_root = $CanvasLayer/Health
@onready var health_bar = $"CanvasLayer/Health/Green Health Bar"
@onready var damage_bar = $"CanvasLayer/Health/Damage Bar"
@onready var playerHealth = $"CanvasLayer/Health/Player Health"
@onready var playerHead = $"CanvasLayer/Health/Player Head"
@onready var staminaCircle = $"CanvasLayer/Stamina/Stamina Circle"
@onready var staminaRect = $"CanvasLayer/Stamina/Stamina Rect"
@onready var staminaLabel = $"CanvasLayer/Stamina/Stamina Label"
@onready var staminaLeaf = $"CanvasLayer/Stamina/Stamina Leaf"
@onready var stamina_root = $"CanvasLayer/Stamina"
@onready var gui_root = $CanvasLayer
@onready var timer = $"Not Hit Timer"

const screen_shake_offset = 12
const screen_shake_duration = 0.15
const invincibility_duration = 0.35
const ui_tween_duration = 0.7
const minimal_stamina_light_matter_point = 0.225

var cannot_start_hp_tween = false
var invincibility = false
var health_bar_tween
var damage_bar_tween
const initial_light_multiplier := 0.75
var light_multiplier := initial_light_multiplier
var last_health_change = 0
var game_over = false

signal game_over_triggered

func _process(_delta):
	var light_scale = max(minimal_stamina_light_matter_point, Player.stamina / Player.maxStamina)
	Player.light.texture_scale = light_scale

func enabled():
	return stamina_root.position.x > -300

func tween_light(final):
	var tween = create_tween()
	tween.tween_property(subtractiveLight, "energy", final, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func tween_ui(final):
	create_tween().tween_property(stamina_root, "position:x", final, ui_tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _ready():
	timer.timeout.connect(hide_health_ui)
	restore_all_health()
	restore_all_stamina()

func update_health(updateTo):
	if game_over: return
	var used_update_to = max(0, updateTo)
	if used_update_to > Player.playerMaxHealth:
		restore_all_health()
		return
	Player.playerHealth = used_update_to
	health_bar.max_value = Player.playerMaxHealth
	health_bar.value = Player.playerHealth
	var labelText = Localization.get_text("character_max_stat")
	if Player.playerHealth != Player.playerMaxHealth: labelText = str(floori(Player.playerHealth))
	playerHealth.text = labelText
	if updateTo <= 0: trigger_new_game_over()

func change_health(by):
	update_health(Player.playerHealth + by)

func restore_all_health():
	update_health(Player.playerMaxHealth)

func update_stamina(update_to):
	if update_to > Player.maxStamina:
		restore_all_stamina()
		return
	Player.stamina = max(0, update_to)
	var circleMax = Player.maxStamina / 100.0 * 65
	staminaCircle.max_value = circleMax
	staminaRect.min_value = circleMax
	staminaRect.max_value = Player.maxStamina
	staminaCircle.value = update_to
	staminaRect.value = update_to
	var staminaText = Localization.get_text("character_max_stat")
	if Player.stamina != Player.maxStamina: staminaText = str(floori(Player.stamina / Player.maxStamina * 100)) + "%"
	staminaLabel.text = staminaText
	var leafAlpha = Player.stamina / Player.maxStamina
	staminaLeaf.modulate.a = leafAlpha

func trigger_game_over():
	emit_signal("game_over_triggered")
	initialize_game_over()
	Overlay.set_alpha(0.4)
	Overlay.kill_tween()
	tween_ui(LeafMode.stamina_ui_hide_x)
	if not enabled():
		Player.light.energy = 1
	await get_tree().create_timer(0.75).timeout
	await Overlay.hide_scene(0.25)
	get_tree().change_scene_to_packed(UID.SCN_GAME_OVER)

func restore_all_stamina():
	update_stamina(Player.maxStamina)

func change_stamina(by):
	update_stamina(Player.stamina + by)

func modify_hp_with_label(by, sound : AudioStream = null, no_sound = false):
	var positive_change = by > 0
	by = roundi(by)
	if not positive_change and invincibility: return
	
	var original_health = Player.playerHealth
	damage_bar.max_value = Player.playerMaxHealth
	damage_bar.value = original_health
	
	change_health(by)
	var health_delta = Player.playerHealth - original_health
	last_health_change = health_delta
	if health_delta == 0: return
	if not positive_change:
		shake_screen_for_damaging()
	
	if Player.playerHealth > 0: health_ui_tween(5, ui_tween_duration/2)
	damage_tween_func(by)
	
	if sound == null:
		sound = UID.SFX_PLAYER_HIT
		if positive_change:
			sound = UID.SFX_PLAYER_HEAL
	if not no_sound: Audio.play_sound(sound, 0.2, 10, true)
	
	var player_color = Color.RED
	if positive_change: player_color = Color.GREEN
	if Player.playerHealth > 0: spawn_health_change_info_particle(health_delta, player_color)
	timer.start()
	invincibility = true
	var previous_player_modulate = Player.animNode.modulate
	
	await create_tween().tween_property(Player.animNode, "modulate", player_color, invincibility_duration/2).finished
	await create_tween().tween_property(Player.animNode, "modulate", previous_player_modulate, invincibility_duration/2).finished
	invincibility = false

func screen_shake_multiple(count, cam = Player.camera, cam_offset = screen_shake_offset, used_screen_shake_dur = screen_shake_duration, power = 1):
	for i in range(count):
		await screen_shake(float(count-i)/count*power, cam, cam_offset, used_screen_shake_dur)

func shake_screen_for_damaging():
	await screen_shake_multiple(3)
	Player.camera.offset = Player.initial_camera_offset

func modify_hp_with_id(id: HPChangeID):
	var health_change = 0
	var no_sound = false
	match id:
		HPChangeID.SinkUnderwater: health_change = randi_range(-30, -20)
		HPChangeID.RedMushroom: health_change = randi_range(-16, -9)
		HPChangeID.PinkMushroom: health_change = randi_range(12, 18)
		HPChangeID.Hedgehog: health_change = randi_range(-16, -10)
		HPChangeID.LeverPuzzleElectricution:
			health_change = get_damage_without_chance_of_game_over(10, 16)
			no_sound = true
	modify_hp_with_label(health_change, null, no_sound)

func get_damage_without_chance_of_game_over(minimum_damage, maximum_damage):
	return -min(Player.playerHealth-1, randf_range(minimum_damage, maximum_damage))

func screen_shake(power = 1, cam = Player.camera, cam_offset = screen_shake_offset, used_screen_shake_dur = screen_shake_duration):
	var original_camera_offset = cam.offset
	var used_offset = cam_offset * power
	var screen_shake_final = Vector2(original_camera_offset.x + used_offset, original_camera_offset.y + used_offset)
	var shake_tween = create_tween()
	await shake_tween.tween_property(cam, "offset",\
		screen_shake_final, used_screen_shake_dur/2).\
		set_trans(Tween.TRANS_SINE).\
		set_ease(Tween.EASE_IN_OUT).finished
	await create_tween().tween_property(cam, "offset", original_camera_offset, used_screen_shake_dur/2).finished
	await get_tree().create_timer(used_screen_shake_dur/2).timeout

func health_ui_tween(final, duration):
	if health_bar_tween != null: health_bar_tween.kill()
	elif cannot_start_hp_tween: return
	cannot_start_hp_tween = true
	var tween = create_tween()
	health_bar_tween = tween
	tween.tween_property(health_root, "position:x", final, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await health_bar_tween.finished
	cannot_start_hp_tween = false

func hide_health_ui():
	health_ui_tween(-425, ui_tween_duration)

func damage_tween_func(damage_taken):
	if damage_bar_tween != null: damage_bar_tween.kill()
	var tween = create_tween()
	damage_bar_tween = tween
	var tween_duration = max(damage_taken / Player.playerMaxHealth, 1.0) * 0.75
	tween.tween_property(damage_bar, "value", Player.playerHealth, tween_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func spawn_health_change_info_particle(health_change, player_color):
	var instance = UID.SCN_HEALTH_CHANGE_INFO.instantiate()
	instance.modulate = player_color
	
	Player.hp_particle_point.add_child(instance)
	instance.set_hp_delta(health_change)
	
func post_river_fail(marker):
	if game_over: return
	Overlay.hide_scene(1)
	await Overlay.finished
	
	Player.animNode.show()
	Player.node.global_position = marker.global_position
	var walkable_lilypads_node = Overworld.activeRoom.get_node("Walkable Lilypads")
	walkable_lilypads_node.queue_free()
	await get_tree().process_frame
	var scene = UID.SCN_LILYPAD_MECHANIC[Overworld.currentRoom].instantiate()
	scene.name = "Walkable Lilypads"
	MovingNPC.create_follower_agents()
	Overworld.activeRoom.add_child(scene)
	
	Player.go_outside_water(true)
	Player.reset_camera_smoothing()
	Overlay.show_scene(1)
	TextSystem.lockAction = false
	LeafMode.restore_all_stamina()
	
	Player.node.stringAnimation = "Down"
	Player.tween_leaf_alpha(1)
	await get_tree().create_timer(0.05).timeout
	Player.is_sinking = false

enum HPChangeID {
	SinkUnderwater,
	RedMushroom,
	PinkMushroom,
	Hedgehog,
	LeverPuzzleElectricution
}

const stamina_ui_hide_x = -425
const stamina_ui_show_x = 150

func initialize_game_over():
	Effects.end_all_effects()
	SaveData.death_counter += 1
	SaveData.save_autosave_file()
	Audio.stop_overworld_music()
	game_over = true
	Player.end_leaf_flashes()
	tween_ui(LeafMode.stamina_ui_hide_x)
	hide_health_ui()

var game_over_overworld_not_shown := false

func trigger_new_game_over():
	if game_over: return
	emit_signal("game_over_triggered")
	Overworld.emit_signal("stop_audio")
	initialize_game_over()
	shake_leaf_multiple_times()
	Overlay.set_alpha(overlay_game_over_alpha)
	Effects.end_all_effects()
	await Player.tween_game_over_rect(final_game_over_rect_size, game_over_rect_tween_size)
	game_over_overworld_not_shown = true
	await end_death_hand
	summon_ess_ghost()

var leaf_shake_on_left := false

signal end_death_hand

func shake_leaf(power: float, duration: float):
	var original_vector = Player.leafNode.position
	var start_range = 0.0 if leaf_shake_on_left else PI
	var end_range = PI if leaf_shake_on_left else 2*PI
	var destination_vector = Helper.get_vec_depending_on_dist_and_rot_of_vec(original_vector, power, randf_range(start_range, end_range))
	var new_leaf_scale = Player.leafNode.scale + Vector2.ONE * scale_update_constant / leaf_shake_count
	Helper.tween(Player.leafNode, "scale", new_leaf_scale, duration)
	Helper.tween(Player.leafNode, "modulate", Color.RED, duration/2)
	await Helper.tween(Player.leafNode, "position", destination_vector, duration/2, Tween.EaseType.EASE_OUT, Tween.TransitionType.TRANS_SPRING)
	Audio.play_sound(UID.SFX_PLAYER_HIT, 0.2, 5, true)
	Helper.tween(Player.leafNode, "modulate", Color.WHITE, duration/2)
	await Helper.tween(Player.leafNode, "position", original_vector, duration/2, Tween.EaseType.EASE_IN, Tween.TransitionType.TRANS_SPRING)

const shake_power_multiplier := 0.3
const shake_duration_muliplier := 0.165
const leaf_shake_count = 8
const shake_power_exponent = 2.5
const scale_update_constant = 0.25
const after_shake_delay := 0.5
const final_game_over_rect_size = 400
const game_over_rect_tween_size = 100
const overlay_game_over_alpha = 0.5

var death_hand_extended_position: Vector2

func shake_leaf_multiple_times():
	for i in range(leaf_shake_count):
		var shake_power = shake_power_multiplier * pow(i+1, shake_power_exponent)
		var shake_duration = shake_duration_muliplier * log(i+1)
		await shake_leaf(shake_power, shake_duration)
		leaf_shake_on_left = !leaf_shake_on_left
	await Helper.wait(after_shake_delay)
	Audio.play_sound(UID.SFX_LIGHT_SWITCH, 0, 10, true)
	var death_hand_instance = UID.SCN_DEATH_HAND.instantiate()
	add_child(death_hand_instance)

func summon_ess_ghost():
	var ess_ghost_instance = UID.SCN_ESS_GHOST.instantiate()
	ess_ghost_instance.global_position = death_hand_extended_position
	add_child(ess_ghost_instance)
