extends Area2D

@onready var sprite = $Sprite
var laser_color: Enum.LeverColor
var laser_active := false
var lever_dict: Dictionary
var negated_laser := false

func _ready():
	sprite.modulate = Enum.lever_colors[laser_color]

func handle_pulling_of_lever():
	var turned_on_laser_v = turned_on_laser()
	sprite.sprite_frames = UID.SPF_NEGATED_LASER if negated_laser else UID.SPF_LADDER_LASER
	sprite.play("on" if turned_on_laser_v else "off")

func turned_on_laser():
	var lever = lever_dict[laser_color]
	laser_active = lever.lever_on
	if negated_laser: laser_active = not laser_active
	return laser_active

const electricution_final_y_destination = 40

func _on_body_entered(body):
	if not body.is_in_group("Player"): return
	if not laser_active: return
	if Player.climbing_ladder_index == -1: return
	
	Player.set_shader_material(UID.SHD_ELECTICUTION)
	var laser_color_v = Enum.lever_colors[laser_color]
	var color_vector = Vector4(laser_color_v.r, laser_color_v.g, laser_color_v.b, laser_color_v.a)
	Player.set_uniform("outline_color", color_vector)
	LeafMode.modify_hp_with_id(LeafMode.HPChangeID.LeverPuzzleElectricution)
	Audio.play_sound(UID.SFX_ELECTRIC_SHOCK, 0.2, -4)
	
	CutsceneManager.action_lock = true
	var y_dir = sign(global_position.y - Player.get_global_pos().y)
	var distance = (electricution_final_y_destination - position.y * -y_dir) * -y_dir
	await MovingNPC.move_player_by(0, distance)
	
	Player.set_shader_material(UID.SHD_HIDE_SPRITE)
	CutsceneManager.action_lock = false
