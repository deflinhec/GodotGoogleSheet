extends Reference

# google API service
# pros: reliable
# cons: redundant bytes, unpredictable bytes length
class Host extends Reference:
	var port = 443
	var field = "dict"
	var use_ssl = true
	var api_key = "REQUIRE FIELD FOR v4 API"
	var address = "sheets.googleapis.com"
	var uri = "/v4/spreadsheets/%s/values/%s?key=%s"
	func _init(new_api_key: String = ""):
		api_key = new_api_key
	func duplicate():
		var obj = Host.new(self.api_key)
		obj.port = self.port
		obj.field = self.field
		obj.use_ssl = self.use_ssl
		obj.address = self.address
		obj.uri = self.uri
		return obj

# gsx2json API service
# pros: less bytes, predictable bytes length, existing host
# cons: might be unavailable
# https://github.com/55sketch/gsx2json
class Gsx2JsonHost extends Host:
	func _init(new_api_key: String = ""):
		._init(new_api_key)
		port = 80
		address = "gsx2json.com"
		use_ssl = false
		field = "rows"
		uri = "/api?id=%s&sheet=%s&api_key=%s&columns=false"

# gsx2jsonpp API service
# pros: less bytes, predictable bytes length, meta info, cache
# cons: self-host only, extra configuration
# https://github.com/deflinhec/gsx2json-go
class Gsx2JsonGoHost extends Host:
	func _init(new_api_key: String, new_address: String, new_port: int):
		._init(new_api_key)
		port = new_port
		use_ssl = false
		address = new_address
		uri = "/api?id=%s&sheet=%s&api_key=%s&columns=false&rows=false"
