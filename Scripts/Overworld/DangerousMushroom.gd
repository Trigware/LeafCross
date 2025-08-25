extends Area2D

enum MushroomType {
	RED,
	GREEN,
	BROWN,
	BLACK,
	PINK,
	YELLOW,
	GRAY
}

@export var mushroom_type : MushroomType
@export var effect_radius := 35.0

@onready var sprite = $Mushroom
@onready var light = $Light
@onready var trigger = $Collider
@onready var staticbody = $"Static Body"
@onready var fire = $Fire
@onready var particles = $"Effect Particle"

var during_cooldown = false
var pink_mushroom_uses = 0
var disabled = false

var particle_mushrooms = [MushroomType.GREEN]
var mushrooms_without_staticbody = [MushroomType.GRAY]

const cooldown_duration = 3.5
const max_pink_mushroom_uses = 3

const max_blast_damage = 30
const max_blast_damage_distance = 45

func _ready():
	LeafMode.game_over_triggered.connect(on_game_over)
	sprite.frame_coords.x = mushroom_type
	light.color = get_light_color()
	light.texture_scale = effect_radius / 120.0
	fire.show()
	if mushroom_type in mushrooms_without_staticbody: staticbody.queue_free()
	else: fire.queue_free()
	var scale_size = effect_radius / 40.0
	trigger.scale = Vector2(scale_size, scale_size)
	if mushroom_type in particle_mushrooms:
		particles.set_image("Poison")

func on_game_over():
	disabled = true

func get_light_color():
	var base_color = Color.RED
	match mushroom_type:
		MushroomType.GREEN: base_color = Color.GREEN
		MushroomType.BROWN: base_color = Color.DARK_ORANGE
		MushroomType.BLACK: base_color = Color.DARK_RED
		MushroomType.PINK: base_color = Color.PINK
		MushroomType.YELLOW: base_color = Color.YELLOW
		MushroomType.GRAY: base_color = Color.ORANGE
	return base_color

func _process(_delta):
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if not body.is_in_group("Player"): continue
		if not during_cooldown: mushroom_damage_behaviour()
		during_cooldown = true
		return
	during_cooldown = false

func mushroom_damage_behaviour():
	if disabled or Overworld.trigger_blocked(): return
	match mushroom_type:
		MushroomType.RED:
			LeafMode.modify_hp_with_id(LeafMode.HPChangeID.RedMushroom)
			await get_tree().create_timer(cooldown_duration).timeout
			during_cooldown = false
		MushroomType.GREEN: Effects.activate(Effects.ID.Poison, 5)
		MushroomType.BROWN: brown_mushroom_behavior()
		MushroomType.BLACK: Effects.activate(Effects.ID.Blindness, 15)
		MushroomType.PINK: pink_mushroom_behavior()
		MushroomType.YELLOW: yellow_mushroom_behavior()

func brown_mushroom_behavior():
	disabled = true
	await mushroom_tween(0.5, 0.25)
	Audio.play_sound(UID.SFX_EXPLOSION, 0.2)
	var explosion_instance = UID.SCN_EXPLOSION.instantiate()
	
	sprite.add_child(explosion_instance)
	explosion_instance.play()
	var damage_from_blast = damage_after_blast()
	LeafMode.modify_hp_with_label(damage_from_blast)
	await get_tree().create_timer(0.8).timeout
	
	if not LeafMode.game_over:
		explosion_instance.queue_free()
		await mushroom_tween(1, 0.25)
		disabled = false
		during_cooldown = false

func mushroom_tween(final, duration):
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", final, duration)
	await tween.finished
	var final_light = 0
	if final == 1: final_light = 1
	create_tween().tween_property(light, "color:a", final_light, 1)

func pink_mushroom_behavior():
	LeafMode.modify_hp_with_id(LeafMode.HPChangeID.PinkMushroom)
	if LeafMode.last_health_change == 0: return
	pink_mushroom_uses += 1
	if pink_mushroom_uses >= max_pink_mushroom_uses:
		mushroom_decay()

func mushroom_decay():
	disabled = true
	await get_tree().create_timer(0.5).timeout
	rotation = PI / 2
	Audio.play_sound(UID.SFX_MUSHROOM_PETRIFY, 0.2)
	await tween_energy(1)
	var alpha_tween = create_tween()
	await alpha_tween.tween_property(self, "modulate:a", 0, 1).finished
	queue_free()

func tween_energy(duration):
	var light_tween = create_tween()
	await light_tween.tween_property(light, "energy", 0, duration).finished

func damage_after_blast():
	var distance_to_player = Player.node.global_position.distance_to(global_position)
	var min_blast_damage_distance = effect_radius * 2.5
	if distance_to_player < max_blast_damage_distance: return -max_blast_damage
	if distance_to_player > min_blast_damage_distance: return 0
	
	var lerp_weight = (distance_to_player - max_blast_damage_distance) / (min_blast_damage_distance - max_blast_damage_distance)
	var damage = -lerp(max_blast_damage, 0, lerp_weight)
	return roundi(damage)

func yellow_mushroom_behavior():
	if Effects.get_ongoing_effects_count() == 0: return
	Audio.play_sound(UID.SFX_ANTIDOTE_MUSHROOM, 0.2)
	Effects.end_all_effects()
