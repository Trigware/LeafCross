extends Node

enum AgentType {
	Uninitialized,
	PlayerAgent,
	FollowerAgent,
	CutsceneAgent,
	OverworldHazardAgent
}

enum AgentVariation {
	NoVariation,
	rabbitek,
	xdaforge,
	gertofin,
	ess,
	Nixie,
	Hedgehog
}

enum Chapter {
	WeirdForest
}

enum LeverColor {
	Red,
	Blue,
	Green,
	Yellow,
	Purple,
	Orange
}

const lever_colors : Dictionary[Enum.LeverColor, Color] = {
	Enum.LeverColor.Red: Color("D63636"),
	Enum.LeverColor.Blue: Color("24A4BD"),
	Enum.LeverColor.Green: Color("24BD2E"),
	Enum.LeverColor.Yellow: Color("E0CF2F"),
	Enum.LeverColor.Purple: Color("A103FC"),
	Enum.LeverColor.Orange: Color("F28E3D")
}

func get_lever_color_as_name(color): return LeverColor.find_key(color)
