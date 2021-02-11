extends "res://addons/gut/test.gd"

class DataManager extends Reference:
	var datas: Dictionary
	
	func _on_complete(name: String, data: Dictionary):
		datas[name] = data
		
	func _on_allset():
		pass

const GSheet = preload("res://addons/google_sheet/src/gsheet.gd")

func before_each():
	var dir = Directory.new()
	dir.remove("res://datas/test.json")


func test_file_download():
	var gsheet = GSheet.new()
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.queue("res://datas/test.json",
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1)
	gsheet.start()
	gsheet.download()
	yield(gsheet, "allset")
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	var file = File.new()
	assert_true(file.file_exists("res://datas/test.json"), 
			"file should write to filesystem")


func test_minimum_file_download():
	var host = GSheet.Gsx2JsonHost.new("gsx2json.com", 80)
	var gsheet = GSheet.new(host)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.queue("res://datas/test.json",
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1)
	gsheet.start()
	gsheet.download()
	yield(gsheet, "allset")
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should exist within filesystem")
			"file should exist within filesystem")


func test_load_exist_file():
	yield(test_file_download(), "completed")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should already exist within filesystem")
	var gsheet = GSheet.new()
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.queue("res://datas/test.json",
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1)
	gsheet.start()
	yield(gsheet, "allset")
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
