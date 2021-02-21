extends CanvasLayer

const GConfig = preload("res://addons/google_sheet/src/config.gd")

const GSheet = preload("res://addons/google_sheet/src/gsheet.gd")

const GVersion = preload("res://addons/google_sheet/src/gversion.gd")

const SPREADSHEETS: Array = [
		["res://datas/test.json", 
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1],
	]

var gsx2jsonpp: GConfig.Host = GConfig.Gsx2JsonppHost.new("localhost", 5000)

var gversion: GVersion = GVersion.new(SPREADSHEETS, gsx2jsonpp)

var gsheet: GSheet = GSheet.new(gversion, gsx2jsonpp)

var datas: Dictionary = {}

func _ready():
	$Button.connect("pressed", self, "_on_Button_pressed")
	gsheet.connect("allset", self, "_on_allset")
	gsheet.connect("complete", self, "_on_complete")
	gsheet.connect("stage_changed", self, "_on_download_stage_changed")
	gsheet.connect("steps_changed", self, "_on_steps_changed")
	gsheet.connect("max_steps_changed", self, "_on_max_steps_changed")
	gversion.connect("complete", self, "_on_complete")
	gversion.connect("request", self, "_on_request")
	gversion.connect("stage_changed", self, "_on_version_stage_changed")
	gversion.connect("steps_changed", self, "_on_steps_changed")
	gversion.connect("max_steps_changed", self, "_on_max_steps_changed")


func _on_version_stage_changed(stage: int):
	match stage:
		GVersion.STAGE.LOAD:
			$Status.set_text("Loading...")
		GVersion.STAGE.QUERY:
			$Status.set_text("Checking...")
		GVersion.STAGE.COMPLETE:
			$Status.set_text("Complete")
	$Status.add_color_override("font_color", Color.black)
	$Button.disabled = GSheet.STAGE.COMPLETE != stage


func _on_download_stage_changed(stage: int):
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


func _on_request(outdated: Array, bytes: int):
	gsheet.start([GSheet.JOB.DOWNLOAD])


func _on_complete(path: String, data: Dictionary):
	datas[path] = data


func _on_allset():
	$Status.add_color_override("font_color", Color.green)


func _on_Button_pressed():
	if gsheet.stage == GSheet.STAGE.COMPLETE and \
		gversion.stage == GSheet.STAGE.COMPLETE:
		gversion = GVersion.new(SPREADSHEETS, gsx2jsonpp)
		gsheet = GSheet.new(gversion, gsx2jsonpp)
		_ready()
	gversion.start()
		
