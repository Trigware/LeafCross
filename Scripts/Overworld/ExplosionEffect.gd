extends AnimatedSprite2D

func _ready():
	LeafMode.game_over_triggered.connect(pause_animation)

func pause_animation():
	stop()
