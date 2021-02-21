extends CanvasLayer

const GSheet = preload("res://addons/google_sheet/src/gsheet.gd")

const SPREADSHEETS: Array = [
		["res://datas/test.json", 
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1],
	]

var gsheet: GSheet = GSheet.new(SPREADSHEETS)

var datas: Dictionary = {}

func _ready():
	$Button.connect("pressed", self, "_on_Button_pressed")
	gsheet.connect("allset", self, "_on_allset")
	gsheet.connect("complete", self, "_on_complete")
	gsheet.connect("stage_changed", self, "_on_stage_changed")
	gsheet.connect("steps_changed", self, "_on_steps_changed")
	gsheet.connect("max_steps_changed", self, "_on_max_steps_changed")


func _on_stage_changed(stage: int):
	match stage:
		GSheet.STAGE.LOAD:
			$Status.set_text("Loading...")
		GSheet.STAGE.DOWNLOAD:
			$Status.set_text("Downloading...")
		GSheet.STAGE.COMPLETE:
			$Status.set_text("Complete")
	$Status.add_color_override("font_color", Color.black)
	$Button.disabled = GSheet.STAGE.COMPLETE != stage


func _on_steps_changed(value: int) -> void:
	$ProgressBar.value = value


func _on_max_steps_changed(value: int) -> void:
	$ProgressBar.max_value = max(value, 1)


func _on_complete(path: String, data: Dictionary):
	datas[path] = data


func _on_allset():
	$Status.add_color_override("font_color", Color.green)


func _on_Button_pressed():
	if not gsheet.contains(GSheet.JOB.LOAD):
		gsheet.start([GSheet.JOB.LOAD])
	elif not gsheet.contains(GSheet.JOB.DOWNLOAD):
		gsheet.start([GSheet.JOB.DOWNLOAD])
	else:
		gsheet = GSheet.new(SPREADSHEETS)
		gsheet.connect("allset", self, "_on_allset")
		gsheet.connect("complete", self, "_on_complete")
		gsheet.connect("stage_changed", self, "_on_stage_changed")
		gsheet.connect("steps_changed", self, "_on_steps_changed")
		gsheet.connect("max_steps_changed", self, "_on_max_steps_changed")
		gsheet.start([GSheet.JOB.LOAD])
