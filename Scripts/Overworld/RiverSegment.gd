@tool
extends Area2D

@export var after_sink_respawn_marker: Marker2D
@export var tile_amount_multiplier := 1.0

var left_tile = null; var right_tile = null; var up_tile = null; var down_tile = null; var right_up_tile = null; var left_bottom_tile = null; var right_bottom_tile = null
var surrounding_tiles = null
var water_sprite = null

var shallow_water: Area2D = null; var shallow_water_collider : CollisionShape2D = null;
var start_water_sprite_pos: Vector2; var end_water_sprite_pos: Vector2
var audio_area_collider: CollisionShape2D = null

var tile_amount: Vector2

const water_tile_size = 16
const surrounding_tile_offset = 0.5

func _ready():
	Player.lilypad_exited.connect( func(): enter_shallow_water(Player.body, true) )
	Player.lilypad_exited.connect( func(): enter_deep_water(Player.body) )
	update_params()

func _process(_delta):
	if not Engine.is_editor_hint(): return
	update_params()

func setup_nodes():
	left_tile = $"Surrounding Tiles/Left"; right_tile = $"Surrounding Tiles/Right"; up_tile = $"Surrounding Tiles/Up"; down_tile = $"Surrounding Tiles/Down"
	right_up_tile = $"Surrounding Tiles/RightUp"; left_bottom_tile = $"Surrounding Tiles/LeftBottom"; right_bottom_tile = $"Surrounding Tiles/RightBottom"
	surrounding_tiles = $"Surrounding Tiles"
	water_sprite = $WaterSprite
	shallow_water = $"Shallow Water"; shallow_water_collider = $"Shallow Water/Collider"; audio_area_collider = $"Audio Area/Collider"
	shallow_water.body_entered.connect(enter_shallow_water)
	shallow_water.body_exited.connect(exit_shallow_water)
	body_entered.connect(enter_deep_water)
	
	var surrounding_tiles_arr = [left_tile, right_tile, up_tile, down_tile]
	for tile_node in surrounding_tiles_arr:
		tile_node.material = UID.SHD_TILING.duplicate(true)
		tile_node.material.set_shader_parameter("wave_amplitude", 0)
		tile_node.material.set_shader_parameter("apply_tint", false)
		if tile_node.scale.x > tile_node.scale.y: tile_node.material.set_shader_parameter("vertical_tile_amount", 1)
	water_sprite.material = UID.SHD_TILING.duplicate(true)

func update_params():
	if left_tile == null: setup_nodes()
	water_sprite.scale = abs(water_sprite.scale)
	var aspect_ratio = water_sprite.scale.x / water_sprite.scale.y
	tile_amount = Vector2(water_sprite.scale.y * aspect_ratio, water_sprite.scale.y)
	water_sprite.material.set_shader_parameter("aspect_ratio", aspect_ratio)
	water_sprite.material.set_shader_parameter("vertical_tile_amount", tile_amount.y * tile_amount_multiplier)
	
	setup_orthogonal_tiles()
	setup_dialog_tiles()
	surrounding_tiles.position = Vector2(water_sprite.position.x, water_sprite.position.y) + Vector2(water_tile_size/2.0, water_tile_size/2.0)
	setup_collider()
	water_sprite.material.set_shader_parameter("begining_and_end_deep_water", setup_deep_water_collider())

func setup_surrounding_horizontal_tile(used_tile):
	used_tile.scale = Vector2(1, tile_amount.y)
	used_tile.material.set_shader_parameter("vertical_tile_amount", tile_amount.y)
	used_tile.material.set_shader_parameter("aspect_ratio", used_tile.scale.x / used_tile.scale.y)

func setup_orthogonal_tiles():
	down_tile.position = Vector2(-8, water_tile_size * tile_amount.y - surrounding_tile_offset)
	down_tile.material.set_shader_parameter("aspect_ratio", tile_amount.x) 
	down_tile.scale = Vector2(tile_amount.x, 1)
	
	up_tile.scale = Vector2(tile_amount.x, 1)
	up_tile.material.set_shader_parameter("aspect_ratio", tile_amount.x)
	
	setup_surrounding_horizontal_tile(left_tile)
	setup_surrounding_horizontal_tile(right_tile)
	right_tile.position = Vector2(16 * tile_amount.x - surrounding_tile_offset, -8)

func setup_dialog_tiles():
	right_up_tile.position.x = right_tile.position.x
	left_bottom_tile.position.y = down_tile.position.y
	right_bottom_tile.position = Vector2(right_tile.position.x, down_tile.position.y)

func setup_collider():
	start_water_sprite_pos = water_sprite.position
	end_water_sprite_pos = start_water_sprite_pos + tile_amount * water_tile_size
	shallow_water_collider.position = (start_water_sprite_pos + end_water_sprite_pos) / 2
	shallow_water_collider.shape.size = end_water_sprite_pos - start_water_sprite_pos
	audio_area_collider.position = shallow_water_collider.position
	audio_area_collider.shape.size = shallow_water_collider.shape.size

func enter_shallow_water(body: Node2D, enter_through_lilypad = false):
	if not body.is_in_group("Player") or not body in shallow_water.get_overlapping_bodies(): return
	Player.on_entering_shallow_water()

func exit_shallow_water(body: Node2D):
	if not body.is_in_group("Player"): return
	Player.go_outside_water()

func enter_deep_water(body: Node2D):
	if Player.is_sinking or Player.on_lilypad or not Player.in_water or not body.is_in_group("Player") or not body in get_overlapping_bodies(): return
	Player.start_to_sink(after_sink_respawn_marker)

const deep_water_bounds_offset = 1.25;

func setup_deep_water_collider() -> Array:
	var deep_water_collider_node = get_node_or_null("Collider")
	if deep_water_collider_node == null: return [0, 0]
	var collider_halfsize = deep_water_collider_node.shape.size/2
	var start_deep_water_pos = deep_water_collider_node.position - collider_halfsize * deep_water_bounds_offset
	var end_deep_water_pos = deep_water_collider_node.position + collider_halfsize * deep_water_bounds_offset
	var start_sprite_uv = Vector2(inverse_lerp(start_water_sprite_pos.x, end_water_sprite_pos.x, start_deep_water_pos.x), inverse_lerp(start_water_sprite_pos.y, end_water_sprite_pos.y, start_deep_water_pos.y))
	var end_sprite_uv = Vector2(inverse_lerp(start_water_sprite_pos.x, end_water_sprite_pos.x, end_deep_water_pos.x), inverse_lerp(start_water_sprite_pos.y, end_water_sprite_pos.y, end_deep_water_pos.y))
	return [start_sprite_uv, end_sprite_uv]
