extends "res://addons/gut/test.gd"

class DataManager extends Reference:
	var timeout: int = 0
	var allset: bool = false
	var datas: Dictionary
	var outdated: Array
	var requestbytes: int = 0
	
	func _on_complete(name: String, data: Dictionary):
		datas[name] = data
		
	func _on_allset():
		allset = true
	
	func _on_request(array: Array, bytes: int):
		requestbytes = bytes
		outdated = array

const GConfig = preload("res://addons/google_sheet/src/config.gd")

const GVersion = preload("res://addons/google_sheet/src/gversion.gd")

const GSheet = preload("res://addons/google_sheet/src/gsheet.gd")

const SPREADSHEETS: Array = [
		["res://datas/test.json", 
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1],
	]

var Gsx2JsonHost = GConfig.Gsx2JsonHost.new("gsx2json.com", 80)

var Gsx2JsonppHost = GConfig.Gsx2JsonppHost.new("localhost", 5000)

func before_each():
	var dir = Directory.new()
	dir.remove("res://datas/test.json")


func test_file_download():
	var gsheet = GSheet.new(SPREADSHEETS)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	yield(gsheet.start([GSheet.JOB.LOAD, GSheet.JOB.DOWNLOAD]), "completed")
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should write to filesystem")


func test_minimum_file_download():
	var gsheet = GSheet.new(SPREADSHEETS, Gsx2JsonHost)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	yield(gsheet.start([GSheet.JOB.LOAD, GSheet.JOB.DOWNLOAD]), "completed")
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
	assert_eq(gsheet.stage, GSheet.STAGE.COMPLETE, 
			"file should load into memory")


func test_process_missing_files():
	var gversion = GVersion.new(SPREADSHEETS, Gsx2JsonppHost)
	var manager = DataManager.new()
	gversion.connect("complete", manager, "_on_complete")
	gversion.connect("request", manager, "_on_request")
	yield(gversion.start(), "completed")
	assert_false(manager.datas.has("res://datas/test.json"),
			"file should not load into memory")
	assert_false(File.new().file_exists("res://datas/test.json"), 
			"file should not exist")
	assert_false(manager.outdated.empty(),
			"file should mark as outdated")
	assert_gt(manager.requestbytes, 0,
			"requestbytes should greater than 0")


func test_process_latest_files():
	yield(test_file_download(), "completed")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should exist")
	var gversion = GVersion.new(SPREADSHEETS, Gsx2JsonppHost)
	var manager = DataManager.new()
	gversion.connect("complete", manager, "_on_complete")
	gversion.connect("request", manager, "_on_request")
	yield(gversion.start(), "completed")
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(manager.outdated.empty(),
			"file should not mark as outdated")
	assert_eq(manager.requestbytes, 0,
			"requestbytes should equal to 0")


func test_download_missing_files():
	var gversion = GVersion.new(SPREADSHEETS, Gsx2JsonppHost)
	var manager = DataManager.new()
	gversion.connect("complete", manager, "_on_complete")
	gversion.connect("request", manager, "_on_request")
	yield(gversion.start(), "completed")
	assert_false(manager.outdated.empty(),
			"file should mark as outdated")
	assert_gt(manager.requestbytes, 0,
			"requestbytes should greater than 0")
	var gsheet = GSheet.new(manager.outdated, Gsx2JsonppHost)
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	yield(gsheet.start([GSheet.JOB.DOWNLOAD]), "completed")
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should exist")
