extends Reference

#warning-ignore:unused_signal
signal complete(name, dict)
#warning-ignore:unused_signal
signal allset
#warning-ignore:unused_signal
signal total_bytes_changed
#warning-ignore:unused_signal
signal downloaded_bytes_changed
#warning-ignore:unused_signal
signal total_files_changed
#warning-ignore:unused_signal
signal loaded_files_changed

# google API service
# pros: reliable
# cons: redundant bytes, unpredictable bytes length
class Host extends Reference:
	var port = 80
	var field = "dict"
	var address = "spreadsheet.google.com"
	var uri = "/feeds/list/%s/%d/public/values?alt=json"

# gsx2json API service
# pros: less bytes, predictable bytes length
# cons: self-host
# https://github.com/deflinhec/gsx2json
class Gsx2JsonHost extends Host:
	func _init(new_address: String, new_port: int):
		port = new_port
		address = new_address
		field = "rows"
		uri = "/api?id=%s&sheet=%d&columns=false"

# gsx2jsonpp API service
# pros: less bytes, predictable bytes length
# cons: self-host
# https://github.com/deflinhec/gsx2jsonpp
class Gsx2JsonppHost extends Host:
	func _init(new_address: String, new_port: int):
		port = new_port
		address = new_address
		uri = "/api?id=%s&sheet=%d&columns=false&rows=false"

const headers = ["User-Agent: Pirulo/1.0 (Godot)","Accept: */*"]

# Debugger is not capable of debugging thread process.
const use_thread: bool = true

var host : Host = Host.new()
var total_files: int = 0 setget _set_total_files
var loaded_files: int = 0 setget _set_loaded_files
var total_bytes: int = 0 setget _set_total_bytes
var downloaded_bytes: int = 0 setget _set_downloaded_bytes
var _requesting: bool = false
var _ternimate: bool = false

var _sem: Semaphore
var _mutex: Mutex
var _thread: Thread
var _queue = []
var _pending = {}
var _cached = {}
var _files = []


func _lock(_caller):
	if not use_thread:
		return
	_mutex.lock()


func _unlock(_caller):
	if not use_thread:
		return
	_mutex.unlock()


func _post(_caller):
	if not use_thread:
		return
	_sem.post()


func _wait(_caller):
	if not use_thread:
		return
	_sem.wait()


func _init(files: Array, new_host: Host = null):
	host = new_host if new_host else host
	if use_thread:
		_mutex = Mutex.new()
		_sem = Semaphore.new()
		_thread = Thread.new()
	_init_queue(files)


func start():
	if not use_thread:
		call_deferred("_thread_func", 0)
		yield(self, "allset")
	elif not _thread.is_active():
		_thread.start(self, "_thread_func", 0)
		yield(self, "allset")


func download() -> void:
	pass

func download_request() -> void:
	pass


func _set_total_bytes(new_value: int):
	if total_bytes != new_value:
		call_deferred("emit_signal", "total_bytes_changed", new_value)
	total_bytes = new_value


func _set_downloaded_bytes(new_value: int):
	if downloaded_bytes != new_value:
		call_deferred("emit_signal", "downloaded_bytes_changed", new_value)
	downloaded_bytes = new_value


func _set_total_files(new_value: int):
	if total_files != new_value:
		call_deferred("emit_signal", "total_files_changed", new_value)
	total_files = new_value


func _set_loaded_files(new_value: int):
	if loaded_files != new_value:
		call_deferred("emit_signal", "loaded_files_changed", new_value)
	loaded_files = new_value


func is_loading() -> bool:
	var state = false
	_lock("is_loading")
	state = _files.size() != 0
	_unlock("is_loading")
	return state


func is_downloading() -> bool:
	var state = false
	_lock("is_downloading")
	state = _queue.size() != 0 and _requesting
	_unlock("is_downloading")
	return state


func get_progress() -> float:
	var progress = 0.0
	_lock("get_progress")
	if total_bytes == 0:
		_unlock("get_progress")
		return progress
	if downloaded_bytes == 0:
		_unlock("get_progress")
		return progress
	progress = float(downloaded_bytes) / float(total_bytes)
	_unlock("get_progress")
	return progress


func _init_queue(files: Array):
	for info in files:
		var http = HTTPClient.new()
		http.set_meta("path", info[0])
		http.set_meta("id", info[1])
		http.set_meta("sheet", info[2])
		_queue.push_back(http)
		
		var file = File.new()
		if file.file_exists(info[0]):
			file.set_meta("path", info[0])
			file.set_meta("id", info[1])
			file.set_meta("sheet", info[2])
			file.open(info[0], File.READ)
			_files.push_back(file)
		else:
			print("INFO: Require download: %s" % [info[0]])


func _is_ternimate() -> bool:
	var state = false
	_lock("_is_ternimate")
	state = _ternimate
	_unlock("_is_ternimate")
	return state


func _thread_func(_u):
	_load_process()
	_http_process()
	call_deferred("emit_signal", "allset")


func _load_process():
	self.loaded_files = 0
	self.total_files = _files.size()
	while not _files.empty():
		var file: File = _files[0]
		var buffer: String = file.get_as_text()
		var json = JSON.parse(buffer)
		var path = file.get_meta("path")
		self.loaded_files += 1
		call_deferred("emit_signal", "complete", path, json.result)
		print("INFO: %s : %s" % [path, String.humanize_size(buffer.length())])
		_files.erase(file)
		file.close()


func _http_process():
	var queue: Array = []
	self._total_bytes = 0
	while not _queue.empty():
		var http: HTTPClient = _queue[0]
		match http.get_status():
			HTTPClient.STATUS_DISCONNECTED:
				var res = http.connect_to_host(host.address, host.port)
				if res != OK:
					print("WARN: STATUS_CONNECTION_ERROR %s:%d"
						% [host.address, host.port])
					_queue.erase(http)
			HTTPClient.STATUS_CANT_CONNECT:
				print("WARN: STATUS_CANT_CONNECT %s:%d"
						% [host.address, host.port])
				_queue.erase(http)
			HTTPClient.STATUS_CONNECTION_ERROR:
				print("WARN: STATUS_CONNECTION_ERROR %s:%d"
						% [host.address, host.port])
				_queue.erase(http)
			HTTPClient.STATUS_CONNECTING:
				http.poll()
			HTTPClient.STATUS_RESOLVING:
				http.poll()
			HTTPClient.STATUS_CONNECTED:
				var path = http.get_meta("path")
				var res = http.request(HTTPClient.METHOD_GET, path, headers)
				if res != OK:
					print("WARN: STATUS_CONNECTION_ERROR %s:%d"
						% [host.address, host.port])
					_queue.erase(http)
			HTTPClient.STATUS_REQUESTING:
				http.poll()
			HTTPClient.STATUS_BODY:
				if not http.is_response_chunked():
					self._total_bytes += http.get_response_body_length()
				if http.has_response():
					queue.push_back(http)
				_queue.erase(http)
	_queue = queue
	while not _queue.empty():
		var http: HTTPClient = _queue[0]
		var binaries = PoolByteArray() 
		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			# Get a chunk.
			var chunk = http.read_response_body_chunk() 
			if http.is_response_chunked():
				self.total_bytes += chunk.size()
			self.downloaded_bytes += chunk.size()
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit.
				OS.delay_usec(1000)
			else:
				# Append to read buffer.
				binaries = binaries + chunk
		var path = http.get_meta("path")
		print("INFO: %s : %s" % [path.get_file(), 
				String.humanize_size(binaries.size())])
		var json = JSON.parse(binaries.get_string_from_utf8())
		json = parse(json)
		if json.result.has("error"):
			print("WARN: %s %s" % [json.result["error"], path])
		elif json.result.has(host.field):
			var file = File.new()
			file.open(path, File.WRITE)
			var dict = array2dict(json.result[host.field])
			call_deferred("emit_signal", "complete", path, dict)
			file.store_string(JSON.print(dict, " "))
			file.close()
		else:
			print("WARN: %s %s" % [path, json.result])
		_queue.erase(http)
		print("INFO: Total bytes downloaded: %s/%s" % [
				String.humanize_size(downloaded_bytes), 
				String.humanize_size(total_bytes)])


# enfroce an array object to dictionary
static func array2dict(array) -> Dictionary:
	if array is Dictionary:
		return array
	var dict: Dictionary = {}
	for row in array:
		var key = row.keys()[0] 
		dict[row[key] as String] = row
	return dict 


# sanitize data if directly response from spreadsheet.google.com
static func parse(json: JSONParseResult) -> JSONParseResult:
	var data : Dictionary = json.result
	if data and data.has("feed") and data["feed"].has("entry"):
		var rows = {}
		var response = {}
		for entry in data["feed"]["entry"]:
			var pkey = 0
			var new_row = {}
			var keys = entry.keys()
			for key in keys:
				if not key.begins_with("gsx$"):
					continue
				var name = key.substr(4)
				var value = entry[key]["$t"]
				if pkey == 0 and value.is_valid_integer():
					pkey = value.to_int()
				if name.begins_with("noex"):
					continue
				new_row[name] = value
				if value.is_valid_integer():
					new_row[name] = value.to_int()
				elif value.empty():
					new_row[name] = 0
			rows[pkey] = new_row
		response["dict"] = rows
		json.result = response
	return json
