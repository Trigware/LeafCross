extends CPUParticles2D

func _ready(): emitting = false

func set_image(particle_name):
	emitting = true
	var particle_path = "res://Textures/Effects/Particles/" + particle_name + ".png"
	var particle_texture = load(particle_path)
	texture = particle_texture
