class_name ObstacleSpawner
extends Node

signal squeeze_spawned(hazard: Hazard)
signal ambush_prop_spawned(hazard: Hazard)

var world: Node2D
var speed_fn: Callable
var elapsed: float = 0.0
var pending_ambush: bool = false

var _gap: float = 0.0
var _spawn_x := 1380.0
var _live: Array[Hazard] = []


func reset() -> void:
	elapsed = 0.0
	_gap = 1.1
	pending_ambush = false
	for h in _live:
		if is_instance_valid(h):
			h.queue_free()
	_live.clear()


func tick(dt: float) -> void:
	elapsed += dt
	_gap -= dt
	var spd: float = speed_fn.call() if speed_fn.is_valid() else 240.0
	for h in _live.duplicate():
		if not is_instance_valid(h):
			_live.erase(h)
			continue
		h.position.x -= spd * dt
		if h.position.x < -160.0:
			_live.erase(h)
			h.queue_free()
	if _gap <= 0.0:
		_spawn_next()
		var density := lerpf(1.85, 1.05, clampf(elapsed / 90.0, 0.0, 1.0))
		_gap = density + randf() * 0.35


func _spawn_next() -> void:
	var encounter: Dictionary
	if pending_ambush:
		pending_ambush = false
		encounter = EncounterTable.ambush_prop()
	else:
		encounter = EncounterTable.pick(elapsed)
	for item in encounter.get("items", []):
		var kind: String = String(item.get("type", "corpse"))
		var lane: int = EncounterTable.resolve_lane(item.get("lane", "any"))
		var x: float = _spawn_x + float(item.get("x", 0))
		var prop: String = String(item.get("prop", ""))
		var h := Hazard.new()
		world.add_child(h)
		h.setup(kind, lane, x, prop)
		_live.append(h)
		if kind == "squeeze":
			squeeze_spawned.emit(h)
		if kind == "ambush":
			h.is_ambush_prop = true
			ambush_prop_spawned.emit(h)


func live_ambush() -> Hazard:
	for h in _live:
		if is_instance_valid(h) and h.is_ambush_prop and not h.consumed:
			return h
	return null
