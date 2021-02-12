extends "res://addons/gut/test.gd"

class DataManager extends Reference:
	var timeout: int = 0
	var allset: bool = false
	var datas: Dictionary
	
	func _on_complete(name: String, data: Dictionary):
		datas[name] = data
		
	func _on_allset():
		allset = true

const GSheet = preload("res://addons/google_sheet/src/gsheet.gd")

const RGSheet = preload("res://addons/google_sheet/src/gsheet_replicate.gd")

func before_each():
	var dir = Directory.new()
	dir.remove("res://datas/test.json")


func test_file_download():
	var gsheet = GSheet.new()
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	gsheet.queue("res://datas/test.json",
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1)
	gsheet.start()
	gsheet.download()
	while not manager.allset and manager.timeout < 10:
		yield(get_tree().create_timer(1.0), "timeout")
		manager.timeout += 1
	print("INFO: allset %s times %d" % [manager.allset, manager.timeout])
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should write to filesystem")


func test_minimum_file_download():
	var host = GSheet.Gsx2JsonHost.new("gsx2json.com", 80)
	var gsheet = GSheet.new(host)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	gsheet.queue("res://datas/test.json",
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1)
	gsheet.start()
	gsheet.download()
	while not manager.allset and manager.timeout < 10:
		yield(get_tree().create_timer(1.0), "timeout")
		manager.timeout += 1
	print("INFO: allset %s times %d" % [manager.allset, manager.timeout])
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should exist within filesystem")


func test_load_exist_file():
	yield(test_file_download(), "completed")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should already exist within filesystem")
	var gsheet = GSheet.new()
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	gsheet.queue("res://datas/test.json",
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1)
	gsheet.start()
	while not manager.allset and manager.timeout < 10:
		yield(get_tree().create_timer(1.0), "timeout")
		manager.timeout += 1
	print("INFO: allset %s times %d" % [manager.allset, manager.timeout])
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")



func test_file_download_replicate():
	var files: Array = [
		["res://datas/test.json", 
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1],
	]
	var gsheet = RGSheet.new(files)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	gsheet.start()
	while not manager.allset and manager.timeout < 10:
		yield(get_tree().create_timer(1.0), "timeout")
		manager.timeout += 1
	print("INFO: allset %s times %d" % [manager.allset, manager.timeout])
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should write to filesystem")
