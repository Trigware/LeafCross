extends Area2D

@export var bible_stand : Node2D

var bible_destination_point : Marker2D

func _ready():
	if bible_stand == null:
		push_error("Bible stand node is not initialized!")
		return
	
	for child in bible_stand.get_children():
		if not child is Marker2D: continue
		bible_destination_point = child
	
	if bible_destination_point == null:
		push_error("Bible destination point doesn't exist")

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player") or Overworld.trigger_blocked() or BibleOverworld.activated: return
	Audio.play_sound(UID.SFX_BIBLE_BALL_APPEARS, 0.2)
	BibleOverworld.activated = true
	await BibleOverworld.show_bible()
	BibleOverworld.go_towards_stand(bible_destination_point)
