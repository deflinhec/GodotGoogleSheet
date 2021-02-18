extends Reference

#warning-ignore:unused_signal
signal complete(path, dict)
#warning-ignore:unused_signal
signal request(list, bytes)
#warning-ignore:unused_signal
signal allset
#warning-ignore:unused_signal
signal stage_changed
#warning-ignore:unused_signal
signal steps_changed
#warning-ignore:unused_signal
signal max_steps_changed

const Host = preload("config.gd").Host

const headers = ["User-Agent: Pirulo/1.0 (Godot)","Accept: */*"]

# Debugger is not capable of debugging thread process.
const use_thread: bool = true

enum STAGE { NONE, QUERY, COMPLETE }

var host : Host = null
var stage: int = STAGE.NONE setget _set_stage, _get_stage
var steps: int = 0 setget _set_steps, _get_steps
var max_steps: int = 0 setget _set_max_steps, _get_max_steps

var _sem: Semaphore
var _mutex: Mutex
var _thread: Thread
var _queue: Array
var _files: Array


func start() -> void:
	if not use_thread:
		call_deferred("_thread_func", 0)
	elif not _thread.is_active():
		_thread.start(self, "_thread_func", 0)
	yield(self, "allset")
	if use_thread and _thread.is_active():
		_thread.wait_to_finish()


func get_progress() -> float:
	var progress: float = 0.0
	_lock("get_progress")
	if max_steps != 0 and steps != 0:
		progress = float(max_steps) / float(steps)
	_unlock("get_progress")
	return progress


func _lock(_caller) -> void:
	if not use_thread:
		return
	_mutex.lock()


func _unlock(_caller) -> void:
	if not use_thread:
		return
	_mutex.unlock()


func _post(_caller) -> void:
	if not use_thread:
		return
	_sem.post()


func _wait(_caller) -> void:
	if not use_thread:
		return
	_sem.wait()


func _init(files: Array, new_host: Host) -> void:
	host = new_host.duplicate()
	host.uri += "&meta=true"
	if use_thread:
		_mutex = Mutex.new()
		_sem = Semaphore.new()
		_thread = Thread.new()
	_init_queue(files)


func _init_queue(files: Array) -> void:
	for info in files:
		var http = HTTPClient.new()
		http.set_meta("path", info[0])
		http.set_meta("id", info[1])
		http.set_meta("sheet", info[2])
		http.set_meta("info", info)
		_queue.push_back(http)
		
		var file = File.new()
		if file.file_exists(info[0]):
			file.set_meta("path", info[0])
			file.set_meta("id", info[1])
			file.set_meta("sheet", info[2])
			file.open(info[0], File.READ)
			_files.push_back(file)


func _thread_func(_u) -> void:
	self.stage = STAGE.QUERY
	_http_process()
	self.stage = STAGE.COMPLETE
	call_deferred("emit_signal", "allset")


func _http_process() -> void:
	var checksums: Dictionary
	while not _files.empty():
		var file: File = _files[0]
		var buffer: String = file.get_as_text()
		var json = JSON.parse(buffer)
		var path = file.get_meta("path")
		checksums[path] = JSON.print(json.result).md5_text()
		call_deferred("emit_signal", "complete", path, json.result)
		print("INFO: %s : %s" % [path, String.humanize_size(buffer.length())])
		_files.erase(file)
		file.close()
	var queue: Array
	self.steps = 0
	self.max_steps = 0
	while not _queue.empty():
		var http: HTTPClient = _queue[0]
		match http.get_status():
			HTTPClient.STATUS_DISCONNECTED:
				if http.connect_to_host(host.address, host.port) != OK:
					print("WARN: STATUS_DISCONNECTED %s:%d"
						% [host.address, host.port])
					_queue.erase(http)
			HTTPClient.STATUS_CONNECTING:
				http.poll()
			HTTPClient.STATUS_RESOLVING:
				http.poll()
			HTTPClient.STATUS_CONNECTED:
				var id: String = http.get_meta("id")
				var sheet: int = http.get_meta("sheet")
				var uri: String = host.uri % [id, sheet]
				if http.request(HTTPClient.METHOD_GET, uri, headers) != OK:
					print("WARN: STATUS_CONNECTION_ERROR %s:%d"
						% [host.address, host.port])
					_queue.erase(http)
			HTTPClient.STATUS_REQUESTING:
				http.poll()
			HTTPClient.STATUS_BODY:
				_queue.erase(http)
				if not http.is_response_chunked():
					self.max_steps += http.get_response_body_length()
				if http.has_response():
					queue.push_back(http)
			_:
				print("ERRR: HTTP status %d %s:%d"
						% [http.get_status(), host.address, host.port])
				_queue.erase(http)
	_queue = queue
	var bytes: int = 0
	var outdated: Array
	while not _queue.empty():
		var binaries: PoolByteArray
		var http: HTTPClient = _queue[0]
		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			# Get a chunk.
			var chunk = http.read_response_body_chunk() 
			if http.is_response_chunked():
				self.max_steps += chunk.size()
			self.steps += chunk.size()
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
		if json.result.has("meta") and json.result["meta"].has("dict"):
			var dict = json.result["meta"]["dict"]
			var checksum: String
			if checksums.has(path):
				checksum = checksums[path]
			checksum = checksum.to_lower()
			dict["md5"] = dict["md5"].to_lower()
			if checksum != dict["md5"]:
				var info: Array = http.get_meta("info")
				bytes += dict["bytes"] as int
				info.push_back(dict["bytes"])
				outdated.push_back(info)
		else:
			print("WARN: %s %s" % [path, json.result])
		_queue.erase(http)
	call_deferred("emit_signal", "request", outdated, bytes)


func _set_stage(new_value: int) -> void:
	_lock("_set_stage")
	if stage != new_value:
		call_deferred("emit_signal", "stage_changed", new_value)
	stage = new_value
	_unlock("_set_stage")


func _get_stage() -> int:
	var value: int = 0
	_lock("_get_stage")
	value = stage
	_unlock("_get_stage")
	return value


func _set_steps(new_value: int) -> void:
	_lock("_set_steps")
	if steps != new_value:
		call_deferred("emit_signal", "steps_changed", new_value)
	steps = new_value
	_unlock("_set_steps")


func _get_steps() -> int:
	var value: int = 0
	_lock("_get_steps")
	value = steps
	_unlock("_get_steps")
	return value


func _set_max_steps(new_value: int) -> void:
	_lock("_set_max_steps")
	if max_steps != new_value:
		call_deferred("emit_signal", "max_steps_changed", new_value)
	max_steps = new_value
	_unlock("_set_max_steps")


func _get_max_steps() -> int:
	var value: int = 0
	_lock("_get_max_steps")
	value = max_steps
	_unlock("_get_max_steps")
	return value
