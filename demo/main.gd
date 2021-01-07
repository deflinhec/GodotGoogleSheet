extends CanvasLayer

var GSheet = preload("res://addons/google_sheet/src/gsheet.gd")

var gsheet = GSheet.new()

var datas: Dictionary = {}

func _ready():
	gsheet.connect("allset", self, "_on_allset")
	gsheet.connect("complete", self, "_on_complete")
	gsheet.connect("total_bytes_changed", self, "_on_total_bytes_changed")
	gsheet.connect("downloaded_bytes_changed", self, "_on_downloaded_bytes_changed")
	gsheet.connect("total_files_changed", self, "_on_total_files_changed")
	gsheet.connect("loaded_files_changed", self, "_on_loaded_files_changed")
	gsheet.queue("res://datas/test.json",
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1)
	gsheet.start()


func _on_total_bytes_changed(bytes: int):
	$Status.set_text("Downloading...")
	$ProgressBar.max_value = bytes


func _on_downloaded_bytes_changed(bytes: int):
	$ProgressBar.value = bytes


func _on_total_files_changed(count: int):
	$Status.set_text("Loading...")
	$ProgressBar.max_value = count


func _on_loaded_files_changed(count: int):
	$ProgressBar.value = count


func _on_complete(path: String, data: Dictionary):
		datas[path] = data


func _on_allset():
	$Status.set_text("All set")


func _on_Button_pressed():
	gsheet.download()
