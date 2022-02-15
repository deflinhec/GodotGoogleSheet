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

const API_KEY = "YOUR_GOOGLE_SHEET_API_KEY"

const GConfig = preload("res://addons/google_sheet/src/config.gd")

const GSheet = preload("res://addons/google_sheet/src/gsheet.gd")

const SPREADSHEETS: Array = [
		["res://datas/test.json", 
		"1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 
		"工作表1"],
	]

func before_each():
	var dir = Directory.new()
	dir.remove("res://datas/test.json")


func test_file_download():
	var host = GConfig.Host.new(API_KEY)
	var gsheet = GSheet.new(SPREADSHEETS, host)
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
	var host = GConfig.Host.new(API_KEY)
	var gsheet = GSheet.new(SPREADSHEETS, host)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	yield(gsheet.start([GSheet.JOB.LOAD]), "completed")
	assert_eq(gsheet.stage, GSheet.STAGE.COMPLETE, 
			"file should load into memory")


func test_file_download_with_gsx2json():
	var host = GConfig.Gsx2JsonHost.new(API_KEY)
	var gsheet = GSheet.new(SPREADSHEETS, host)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	yield(gsheet.start([GSheet.JOB.LOAD, GSheet.JOB.DOWNLOAD]), "completed")
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(File.new().file_exists("res://datas/test.json"), 
			"file should write to filesystem")
	
	
func test_compatible_with_gsx2json():
	# Download from Google sheet api v4
	var host = GConfig.Host.new(API_KEY)
	var gsheet = GSheet.new(SPREADSHEETS, host)
	var manager = DataManager.new()
	gsheet.connect("complete", manager, "_on_complete")
	gsheet.connect("allset", manager, "_on_allset")
	yield(gsheet.start([GSheet.JOB.DOWNLOAD]), "completed")
	# Download from Gsx2JsonHost
	host = GConfig.Gsx2JsonHost.new(API_KEY)
	gsheet = GSheet.new(SPREADSHEETS, host)
	var manager2 = DataManager.new()
	gsheet.connect("complete", manager2, "_on_complete")
	gsheet.connect("allset", manager2, "_on_allset")
	yield(gsheet.start([GSheet.JOB.DOWNLOAD]), "completed")
	assert_true(manager2.datas.has("res://datas/test.json"),
			"file should load into memory")
	assert_true(manager.datas.has("res://datas/test.json"),
			"file should load into memory")
	var data = JSON.print(manager.datas["res://datas/test.json"])
	var data2 = JSON.print(manager2.datas["res://datas/test.json"])
	assert_eq(data2, data, "download content should be eqaul")



