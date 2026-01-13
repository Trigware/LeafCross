extends "res://Scripts/Overworld/BaseRoom.gd"

@onready var nixie = $Nixie
@onready var leaves_emitter = $"Detailed Tree/Bottom/Leaves"

func _ready():
	SaveMenu.game_saved.connect(on_game_saved)
	SaveMenu.game_saved_menu_closed.connect(on_save_menu_closed_when_game_saved)

func on_game_saved():
	if CutsceneManager.is_cutscene_finished(CutsceneManager.Cutscene.Nixie_Introductory): return
	nixie.play_current()

func on_save_menu_closed_when_game_saved():
	var cutscene_nodes = {
		"nixie": nixie
	}
	CutsceneManager.let_cutscene_play_out(CutsceneManager.Cutscene.Nixie_Introductory, cutscene_nodes)
	await CutsceneManager.nixie_jumps
	leaves_emitter.emitting = false
