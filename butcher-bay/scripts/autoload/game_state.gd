extends Node

const SAVE_PATH := "user://butcher_bay.cfg"

var best_score: int = 0
var last_score: int = 0
var last_cause: String = ""


func _ready() -> void:
	_load()


func record_run(score: int, cause: String) -> void:
	last_score = score
	last_cause = cause
	if score > best_score:
		best_score = score
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("run", "best_score", best_score)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	best_score = int(cfg.get_value("run", "best_score", 0))
