extends Reference

# google API service
# pros: reliable
# cons: redundant bytes, unpredictable bytes length
class Host extends Reference:
	var port = 80
	var field = "dict"
	var address = "spreadsheet.google.com"
	var uri = "/feeds/list/%s/%d/public/values?alt=json"
	func duplicate():
		var obj = Host.new()
		obj.port = self.port
		obj.field = self.field
		obj.address = self.address
		obj.uri = self.uri
		return obj

# gsx2json API service
# pros: less bytes, predictable bytes length, existing host
# cons: might be unavailable
# https://github.com/55sketch/gsx2json
class Gsx2JsonHost extends Host:
	func _init(new_address: String = "gsx2json.com",  new_port: int = 80):
		port = new_port
		address = new_address
		field = "rows"
		uri = "/api?id=%s&sheet=%d&columns=false"

# gsx2jsonpp API service
# pros: less bytes, predictable bytes length, meta info, snapshot
# cons: self-host only, extra configuration
# https://github.com/deflinhec/gsx2jsonpp
class Gsx2JsonppHost extends Host:
	func _init(new_address: String, new_port: int):
		port = new_port
		address = new_address
		uri = "/api?id=%s&sheet=%d&columns=false&rows=false"
