extends Control

@export var texture : Texture2D

@onready var filebox = $"Filebox Texture"
@onready var labels = $"Labels"
@onready var playerName = $Labels/playerName
@onready var playTime = $Labels/PlayTime
@onready var currentRoom = $Labels/currentRoom

func _ready():
	if texture == null: return
	filebox.texture = texture

func set_player_name(text):
	playerName.text = str(text)

func set_playtime(text):
	playTime.text = str(text)

func set_current_room(text):
	currentRoom.text = str(text)
