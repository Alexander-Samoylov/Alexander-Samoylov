extends Node

signal swipe(direction: Vector2i)

const THRESHOLD := 42.0

var _pressing := false
var _start := Vector2.ZERO
var _emitted := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_press(event.pressed, event.position)
	elif event is InputEventScreenDrag:
		_handle_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_press(event.pressed, event.position)
	elif event is InputEventMouseMotion and _pressing:
		_handle_drag(event.position)
	elif event.is_action_pressed("lane_left"):
		swipe.emit(Vector2i(-1, 0))
	elif event.is_action_pressed("lane_right"):
		swipe.emit(Vector2i(1, 0))
	elif event.is_action_pressed("jump"):
		swipe.emit(Vector2i(0, -1))
	elif event.is_action_pressed("slide"):
		swipe.emit(Vector2i(0, 1))


func _handle_press(pressed: bool, pos: Vector2) -> void:
	if pressed:
		_pressing = true
		_emitted = false
		_start = pos
	elif _pressing:
		_pressing = false
		if not _emitted:
			_emit_from_delta(pos - _start)


func _handle_drag(pos: Vector2) -> void:
	if not _pressing or _emitted:
		return
	var delta := pos - _start
	if delta.length() >= THRESHOLD:
		_emitted = true
		_pressing = false
		_emit_from_delta(delta)


func _emit_from_delta(delta: Vector2) -> void:
	if delta.length() < THRESHOLD * 0.6:
		return
	if absf(delta.x) > absf(delta.y):
		swipe.emit(Vector2i(-1 if delta.x < 0.0 else 1, 0))
	else:
		swipe.emit(Vector2i(0, -1 if delta.y < 0.0 else 1))
