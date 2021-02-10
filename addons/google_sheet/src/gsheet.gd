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

var _sem
var _mutex
var _thread
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

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if use_thread and _thread.is_active():
			_thread.wait_to_finish()


func _init(new_host: Host = null):
	host = new_host if new_host else host
	connect("allset", self, "_on_allset")
	if not use_thread:
		return
	_mutex = Mutex.new()
	_sem = Semaphore.new()
	_thread = Thread.new()


func start():
	if not _queue.empty():
		if not use_thread:
			call_deferred("_thread_func", 0)
		elif not _thread.is_active():
			_ternimate = false
			_thread.start(self, "_thread_func", 0)
	else:
		call_deferred("emit_signal", "allset")


func _on_allset():
	if not use_thread:
		return
	if not _thread.is_active():
		return
	_thread.wait_to_finish()


func download() -> void:
	_lock("download")
	_requesting = true
	_post("download")
	_unlock("download")
	start()


func download_request() -> void:
	_lock("request")
	_requesting = true
	_unlock("request")


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


func queue(filepath: String, sheet: String, table: int = 1) -> void:
	_lock("queue")
	if filepath in _pending:
		_unlock("queue")
		return

	var http = HTTPClient.new()
	http.set_meta("filepath", filepath)
	_pending[filepath] = host.uri % [sheet, table]
	_queue.push_back(http)
	
	var file = File.new()
	if file.file_exists(filepath):
		file.open(filepath, File.READ)
		file.set_meta("filepath", filepath)
		_files.push_back(file)
		self.total_files += 1
	else:
		print("INFO: Require download: %s" % [filepath])
	_unlock("queue")


func _is_ternimate() -> bool:
	var state = false
	_lock("_is_ternimate")
	state = _ternimate
	_unlock("_is_ternimate")
	return state


func _thread_func(_u):
	while not _is_ternimate():
		_load_process()
		if _is_ternimate():
			break
		_http_process()


func _load_process():
	_lock("process")

	if _files.size() == 0:
		_unlock("process")
		return

	for file in _files:
		if not _cached.has(file):
			_cached[file] = String()
		_cached[file] += file.get_line()
		if not file.eof_reached():
			continue
		file.close()
		_files.erase(file)
		var buffer = _cached[file]
		_cached.erase(file)
		var json = JSON.parse(buffer)
		var dict = json.result
		var filepath = file.get_meta("filepath")
		self.loaded_files += 1
		call_deferred("emit_signal", "complete", filepath, dict)
		print("INFO: %s : %s" % [filepath, String.humanize_size(buffer.length())])
		break
	if _files.size() == 0:
		if not _requesting:
			call_deferred("emit_signal", "allset")
			_ternimate = true
		print("INFO: Total file loaded: %s/%s" % [total_files, loaded_files])
		total_files = 0
		loaded_files = 0
	_unlock("process")


func _http_process():
	_lock("process")

	# Wait until file read.
	if _files.size() != 0:
		_unlock("process")
		return

	if _queue.size() == 0:
		_unlock("process")
		return
	
	if not _requesting:
		_unlock("process")
		return

	var allset = 0
	var bytes = 0
	for http in _queue:
		var filepath = http.get_meta("filepath")
		var path = _pending[filepath]
		# Wait until resolved and connected.
		match http.get_status():
			HTTPClient.STATUS_DISCONNECTED:
				assert(http.connect_to_host(host.address, host.port) == OK)
			HTTPClient.STATUS_CONNECTING:
				http.poll()
			HTTPClient.STATUS_RESOLVING:
				http.poll()
			HTTPClient.STATUS_CONNECTED:
				assert(http.request(HTTPClient.METHOD_GET, path, headers) == OK)
			HTTPClient.STATUS_REQUESTING:
				http.poll()
			HTTPClient.STATUS_BODY:
				if not http.is_response_chunked():
					bytes += http.get_response_body_length()
				assert(http.has_response())
				allset += 1

	_set_total_bytes(bytes)
	# Wait until all client are ready.
	if allset != _queue.size():
		_unlock("process")
		return

	_unlock("process")
	_wait("download")
	_lock("process")

	while _queue.size() > 0:
		var http = _queue[0]
		var filepath = http.get_meta("filepath")
		# Array that will hold the data.
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
		print("INFO: %s : %s" % [filepath.get_file(), 
				String.humanize_size(binaries.size())])
		var text = binaries.get_string_from_utf8()
		_pending.erase(filepath)
		var json = JSON.parse(text)
		json = parse(json)
		var file = File.new()
		file.open(filepath, File.WRITE)
		if json.result.has("error"):
			print("WARN: %s %s" % [json.result["error"], filepath])
		else:
			var dict = array2dict(json.result[host.field])
			file.store_string(JSON.print(dict, " "))
			file.close()
			call_deferred("emit_signal", "complete", filepath, dict)
		_queue.remove(0)
	call_deferred("emit_signal", "allset")
	print("INFO: Total bytes downloaded: %s/%s" % [
			String.humanize_size(downloaded_bytes), 
			String.humanize_size(total_bytes)])
	total_bytes = 0
	downloaded_bytes = 0
	_requesting = false
	_ternimate = true
	_unlock("process")

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
