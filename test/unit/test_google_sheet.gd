extends "res://addons/gut/test.gd"

class DataManager extends Reference:
	var timeout: int = 0
	var allset: bool = false
	var datas: Dictionary
	
	func _on_complete(name: String, data: Dictionary):
		datas[name] = data
		
	func _on_allset():
		allset = true

const GSheet = preload("res://addons/google_sheet/src/gsheet_replicate.gd")

const SPREADSHEETS: Array = [
		["res://datas/test.json", 
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1],
	]


func before_each():
	var dir = Directory.new()
	dir.remove("res://datas/test.json")


func test_file_download():
	var gsheet = GSheet.new(SPREADSHEETS)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	yield(gsheet.start([GSheet.JOB.LOAD, GSheet.JOB.HTTP]), "completed")
	assert_true(gsheet.contains(GSheet.JOB.LOAD))
	assert_true(gsheet.contains(GSheet.JOB.HTTP))
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should write to filesystem")


func test_minimum_file_download():
	var host = GSheet.Gsx2JsonHost.new("gsx2json.com", 80)
	var gsheet = GSheet.new(SPREADSHEETS, host)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	yield(gsheet.start([GSheet.JOB.LOAD, GSheet.JOB.HTTP]), "completed")
	assert_true(gsheet.contains(GSheet.JOB.LOAD))
	assert_true(gsheet.contains(GSheet.JOB.HTTP))
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should write to filesystem")


func test_load_exist_file():
	yield(test_file_download(), "completed")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should already exist within filesystem")
	var gsheet = GSheet.new(SPREADSHEETS)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	yield(gsheet.start([GSheet.JOB.LOAD]), "completed")
	assert_true(gsheet.contains(GSheet.JOB.LOAD))
	assert_false(gsheet.contains(GSheet.JOB.HTTP))
	assert_eq(gsheet.stage, GSheet.STAGE.COMPLETE, 
			"file should load into memory")
