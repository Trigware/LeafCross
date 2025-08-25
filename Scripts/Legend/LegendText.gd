extends Control

@onready var eventsTimer = $PanelTimer
@onready var skipNode = $"Skip Prompt"
var can_end_cutscene = false

var legendDialog := [
	Localization.get_text("legend_panel1_whisper"),
	Localization.get_text("legend_panel1_nation_unity"),
	Localization.get_text("legend_panel1_wise_mystical"),
	Localization.get_text("legend_panel1_wmtale"),
	"next panel",

	Localization.get_text("legend_panel2_peace"),
	Localization.get_text("legend_panel2_equality"),
	"next panel",
	
	Localization.get_text("legend_panel3_revolt"),
	"next panel",
	
	Localization.get_text("legend_panel4_wilbur"),
	Localization.get_text("legend_panel4_yapp"),
	Localization.get_text("legend_panel4_smurfcat"),
	Localization.get_text("legend_panel4_rotten"),
	Localization.get_text("legend_panel4_lastdays"),
	"next panel",
	
	Localization.get_text("legend_panel5_religion"),
	Localization.get_text("legend_panel5_god"),
	"next panel",
	
	Localization.get_text("legend_characters_rabbitek"),
	Localization.get_text("legend_characters_xdaforge"),
	Localization.get_text("legend_characters_gertofin"),
	"next panel",
	
	Localization.get_text("legend_panel6_treefall"),
	Localization.get_text("legend_panel6_balance"),
	Localization.get_text("legend_panel6_treegrow"),
	Localization.get_text("legend_panel6_revolution"),
	"next panel",
	
	Localization.get_text("legend_panel7_mayor"),
	Localization.get_text("legend_panel7_punishment"),
	Localization.get_text("legend_panel7_lost"),
	"next panel",
	
	Localization.get_text("legend_panel8_fired"),
	"end_cutscene"
]

var currentPrintedTextIndex = -1
const lastTextBeforeBigPanel = 8

func _ready():
	PresetSystem.fallback = PresetSystem.Preset.LegendSmallPanel

	eventsTimer.timeout.connect(print_next_text)
	TextSystem.text_finished.connect(on_text_finished)
	print_next_text()

func print_next_text():
	currentPrintedTextIndex += 1
	eventsTimer.stop()
	if currentPrintedTextIndex == 3:
		skipNode.skipEnabled = false
		skipNode.fade_label(0)
	var currentText = legendDialog[currentPrintedTextIndex]
	if currentText == "end_cutscene":
		if can_end_cutscene: skipNode.end_cutscene()
		can_end_cutscene = true
		return
	if currentText == "next panel":
		$Panels.transparency_tween(0, 0.5, true)
		return
	PresetSystem.print_preset(currentText)

func on_text_finished():
	if not (eventsTimer and eventsTimer.is_inside_tree()): return
	eventsTimer.start()
	$Protagonists.show_hero_panel(currentPrintedTextIndex)
	if currentPrintedTextIndex >= lastTextBeforeBigPanel:
		PresetSystem.fallback = PresetSystem.Preset.LegendBigPanel
