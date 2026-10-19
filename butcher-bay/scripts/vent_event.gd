class_name VentEvent
extends Node

signal window_opened
signal window_closed
signal crushed

var active: bool = false
var succeeded: bool = false
var _time_left: float = 0.0
var _hazard: Hazard = null


func begin(hazard: Hazard, window: float = 1.15) -> void:
	active = true
	succeeded = false
	_hazard = hazard
	_time_left = window
	window_opened.emit()


func try_enter(player: RunnerPlayer) -> bool:
	if not active or succeeded:
		return false
	succeeded = true
	active = false
	player.enter_vent()
	window_closed.emit()
	if _hazard and is_instance_valid(_hazard):
		_hazard.consumed = true
	return true


func tick(dt: float) -> void:
	if not active:
		return
	_time_left -= dt
	if _time_left <= 0.0 and not succeeded:
		active = false
		window_closed.emit()
		crushed.emit()
