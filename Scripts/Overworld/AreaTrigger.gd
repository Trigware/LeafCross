extends Area2D

@export var is_trigger_vertical := true
@export var area_to_left_or_down := Overworld.OverworldArea.Weird
@export var area_to_right_or_up := Overworld.OverworldArea.Bleak

const initial_area_enter_notice_y_offset = 80
const area_enter_tween_duration := 0.5
const hide_tween_delay_duration := 3

func _ready():
	body_entered.connect(on_walk_into_area_trigger)

func on_walk_into_area_trigger(body: Node2D):
	if not body.is_in_group("Player") or Overworld.area_changed_in_current_room: return
	Overworld.area_changed_in_current_room = true
	var area_enter_notice = UID.SCN_AREA_ENTER_NOTICE.instantiate()
	handle_area_triggered()
	var notice_node = area_enter_notice.get_node("Notice")
	notice_node.modulate = get_modulate_of_notice()
	notice_node.text = Overworld.get_current_area_name_locale()
	add_child(area_enter_notice)
	area_enter_notice.offset.y = initial_area_enter_notice_y_offset
	await Helper.tween(area_enter_notice, "offset:y", 0, area_enter_tween_duration)
	await Helper.wait(hide_tween_delay_duration)
	await Helper.tween(area_enter_notice, "offset:y", initial_area_enter_notice_y_offset, area_enter_tween_duration)

func handle_area_triggered():
	var latest_movement_vec = Player.make_latest_movement_vector()
	var used_dir = latest_movement_vec.x if is_trigger_vertical else latest_movement_vec.y
	Overworld.current_area = area_to_left_or_down if used_dir == -1 else area_to_right_or_up

func get_modulate_of_notice():
	match Overworld.current_area:
		Overworld.OverworldArea.Weird: return Color("894aff")
		Overworld.OverworldArea.Bleak: return Color("bfad99")
	
