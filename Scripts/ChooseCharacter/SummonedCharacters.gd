extends Control

@onready var rootNode = $".."

func summon_characters():
	await get_tree().create_timer(0.7).timeout
	Audio.play_sound(UID.SFX_SUMMON_CHARACTERS)
	show()
	var childrenList = get_children()
	var childCount = get_child_count()
	for i in range(childCount):
		var animatedSprite = childrenList[i]
		animatedSprite.speed_scale = 2
		animatedSprite.play()
		if i+1 == childCount:
			animatedSprite.animation_finished.connect(animations_finished)

func animations_finished():
	rootNode.canSelectCharacter = true
	create_tween().tween_property(rootNode.moveReminder, "modulate:a", 1, 1)
