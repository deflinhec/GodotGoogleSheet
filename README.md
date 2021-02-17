![Tests](https://github.com/deflinhec/GodotGoogleSheet/workflows/Run%20GUT%20Tests/badge.svg?branch=master)
[![GitHub license](https://img.shields.io/github/license/deflinhec/GodotGoogleSheet.svg)](https://github.com/deflinhec/GodotGoogleSheet/blob/master/LICENSE) 
[![GitHub release](https://img.shields.io/github/release/deflinhec/GodotGoogleSheet.svg)](https://github.com/deflinhec/GodotGoogleSheet/releases/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/deflinhec/GodotGoogleSheet/graphs/commit-activity)
# GodotGoogleSheet - Google Spreadsheet download plugin for GDScript.

A plugin written in GDScript which downloads google spreadsheet with HTTP protocol.

## :coffee: [Buy me a coffee](https://ko-fi.com/deflinhec) 

## :label: Spreadsheet configuration

First, you must publish your spreadsheet to the web, using `File -> Publish To Web` in your Google Spreadsheet.

![](https://raw.githubusercontent.com/deflinhec/GodotGoogleSheet/master/screenshots/step01.png) ![](https://raw.githubusercontent.com/deflinhec/GodotGoogleSheet/master/screenshots/step02.png)<img src="https://raw.githubusercontent.com/deflinhec/GodotGoogleSheet/master/screenshots/step03.png" width="250" />

Second, locate to your spreadsheet id and sheet number.

```
https://docs.google.com/spreadsheets/d/[SPREADSHEET_ID]/edit#gid=[SHEET_NUMBER]
```

![](https://raw.githubusercontent.com/deflinhec/GodotGoogleSheet/master/screenshots/step04.png)

Finally, defined an array which contains all spreadsheets and preload script.

```
const SPREADSHEETS: Array = [
    ["res://datas/test.json", "1-DGS8kSiBrPOxvyM1ISCxtdqWt-I7u1Vmcp-XksQ1M4", 1],
]
const GSheet = preload("res://addons/google_sheet/gsheet.gd")

const GConfig = preload("res://addons/google_sheet/config.gd")

const GVersion = preload("res://addons/google_sheet/gversion.gd")
```

## :bookmark: Examples

- ### Load sheets from file.

  Assuming files are already exist within your local filesystem.
  ```
  var gsheet: GSheet = null
  var datas: Dictionary = {}
  func _ready():
    gsheet = GSheet.new(SPREADSHEETS)
    gsheet.connect("allset", self, "_on_allset")
    gsheet.connect("complete", self, "_on_complete")
    gsheet.start([GSheet.JOB.LOAD])
    
  func _on_complete(name: String, data: Dictionary):
    datas[name] = data
    
  func _on_allset():
    pass # do some extra logic after completion
  ```

- ### Download sheets from google service api.
  
  Download gsx format and convert it to json format locally.
  ``` 
  var gsheet: GSheet = null
  var datas: Dictionary = {}
  func _ready():
    gsheet = GSheet.new(SPREADSHEETS)
    gsheet.connect("allset", self, "_on_allset")
    gsheet.connect("complete", self, "_on_complete")
    gsheet.start([GSheet.JOB.LOAD, GSheet.JOB.HTTP])
    
  func _on_complete(name: String, data: Dictionary):
    datas[name] = data
    
  func _on_allset():
    pass # do some extra logic after completion
  ```

- ### Download sheets from google service api through [gsx2json](http://gsx2json.com/). [Optional]
  Addition layer bridges between client and google service, converting gsx format to json remotely and also reduces significant large amount of bytes.
  ```
  var gsheet: GSheet = null
  var datas: Dictionary = {}
  func _ready():
    var host = GConfig.Gsx2JsonHost.new("gsx2json.com", 80)
    gsheet = GSheet.new(SPREADSHEETS, host)
    gsheet.connect("complete", self, "_on_complete")
    gsheet.connect("allset", self, "_on_allset")
    gsheet.start([GSheet.JOB.LOAD, GSheet.JOB.HTTP])
    
  func _on_complete(name: String, data: Dictionary):
    datas[name] = data
    
  func _on_allset():
    pass # do some extra logic after completion
  ```


- ### Download missing sheet only through [gsx2jsonpp](https://github.com/deflinhec/gsx2jsonpp/). [Optional]
  Dedicate service implements with snapshot and meta info query feature.
  ```
  var host = GConfig.Gsx2JsonppHost.new("localhost", 5000)
  var gsheet: GSheet = null
  var datas: Dictionary = {}
  var sheets: Array = []
  func _ready():
    var gversion: GVersion = GVersion.new(host)
    gversion.connect("download", self, "_on_download")
    yield(gversion.start(), "completed")
    gsheet = GSheet.new(sheets, host)
    gsheet.start([GSheet.JOB.LOAD, GSheet.JOB.HTTP])
	
  func _on_complete(name: String, data: Dictionary):
    datas[name] = data
    
  func _on_allset():
    pass # do some extra logic after completion
    
  func _on_download(array: Array):
    sheets = array
  ```

## :clipboard: TODO-List

- :white_check_mark: Patch file versioning
