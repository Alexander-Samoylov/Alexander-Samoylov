extends Node

const POOL := 10

var saw: AudioStreamPlayer
var drone: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _cursor: int = 0


func _ready() -> void:
	drone = AudioStreamPlayer.new()
	drone.stream = _stream("music_drone")
	drone.volume_db = -6.0
	add_child(drone)
	drone.finished.connect(func() -> void:
		if is_inside_tree() and drone.stream != null:
			drone.play()
	)

	saw = AudioStreamPlayer.new()
	saw.stream = _stream("sfx_saw")
	saw.volume_db = -16.0
	add_child(saw)
	saw.finished.connect(func() -> void:
		if is_inside_tree() and saw.get_meta("keep", false):
			saw.play()
	)

	for i in range(POOL):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)


func play(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var p := _pool[_cursor]
	_cursor = (_cursor + 1) % POOL
	p.stop()
	p.stream = _stream(sfx_name)
	p.volume_db = volume_db
	p.pitch_scale = clampf(pitch, 0.7, 1.4)
	p.play()


func start_menu() -> void:
	_keep_saw(false)
	saw.stop()
	if not drone.playing:
		drone.play()


func start_run() -> void:
	if not drone.playing:
		drone.play()
	_keep_saw(true)
	set_saw_distance(72.0, false)
	if not saw.playing:
		saw.play()


func start_death() -> void:
	drone.stop()
	_keep_saw(true)
	saw.volume_db = -2.0
	if not saw.playing:
		saw.play()
	play("sfx_saw", -4.0, 0.85)


func stop_all() -> void:
	_keep_saw(false)
	saw.stop()
	drone.stop()


func set_saw_distance(distance: float, vanished: bool) -> void:
	saw.volume_db = RunRules.saw_volume_db(distance, vanished)


func _keep_saw(on: bool) -> void:
	saw.set_meta("keep", on)


func _stream(sfx_name: String) -> AudioStream:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var path := "res://assets/audio/%s.wav" % sfx_name
	var stream: AudioStream = load(path)
	_cache[sfx_name] = stream
	return stream
