# GodotGoogleSheet

![Tests](https://github.com/deflinhec/GodotGoogleSheet/workflows/Run%20GUT%20Tests/badge.svg?branch=master)

A plugin written in GDScript which downloads google spreadsheet with HTTP protocol.
    
## :coffee: Contributors

- Deflinhec ([buy me a coffee](https://ko-fi.com/deflinhec))

## :label: Preparations

First of all, sheets requires download should be publish to web.

    File -> Publish to the web

![](https://raw.githubusercontent.com/deflinhec/GodotGoogleSheet/master/screenshots/step01.png) ![](https://raw.githubusercontent.com/deflinhec/GodotGoogleSheet/master/screenshots/step02.png)
--- 

    Publish entire document

<img src="https://raw.githubusercontent.com/deflinhec/GodotGoogleSheet/master/screenshots/step03.png" width="400" />

Second, locate to your sheet id and sheet table index.

    https://docs.google.com/spreadsheets/d/[SHEET_ID]/edit#gid=[SHEET_TABLE_INDEX]
   
![](https://raw.githubusercontent.com/deflinhec/GodotGoogleSheet/master/screenshots/step04.png)

Third, preload gsheet into your own script.
```
    const GSheet = preload("res://addons/google_sheet/gsheet.gd")
```

### :radio_button: Load sheets from file.
```
    func _ready():
      var gsheet = GSheet.new()
      var save_data_path = "[YOUR_PATH]/[YOUR_FILE_NAME].json"
      gsheet.queue(save_data_path, "[SHEET_ID]", [SHEET_TABLE_INDEX])
      gsheet.start()
      yield(gsheet, "allset")
```

### :radio_button: Download sheets from google service api.
Download gsx format and convert to json format locally.
``` 
    func _ready():
      var gsheet = GSheet.new()
      var save_data_path = "[YOUR_PATH]/[YOUR_FILE_NAME].json"
      gsheet.queue(save_data_path, "[SHEET_ID]", [SHEET_TABLE_INDEX])
      gsheet.start()
      gsheet.download()
      yield(gsheet, "allset")
```
### :radio_button: Download sheets from google service api through [gsx2json](http://gsx2json.com/).
Addition layer bridges between game and google service, reduces significant large amount of bytes.
```
    func _ready():
      var host = GSheet.Gsx2Json.new("gsx2json.com", 80)
      var gsheet = GSheet.new(host)
      var save_data_path = "[YOUR_PATH]/[YOUR_FILE_NAME].json"
      gsheet.queue(save_data_path, "[SHEET_ID]", [SHEET_TABLE_INDEX])
      gsheet.start()
      gsheet.download()
      yield(gsheet, "allset")
```
### :radio_button: Two step download.
Prompt user before download.
```
    var gsheet = GSheet.new()

    func _ready():
      var save_data_path = "[YOUR_PATH]/[YOUR_FILE_NAME].json"
      gsheet.queue(save_data_path, "[SHEET_ID]", [SHEET_TABLE_INDEX])
      gsheet.start()
      gsheet.download_request()
    
    func _on_Button_pressed():
      gsheet.download()
      yield(gsheet, "allset")
```      
