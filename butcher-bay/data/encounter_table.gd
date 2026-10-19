class_name EncounterTable
extends RefCounted

# Each encounter: id, min_elapsed, weight, items[{type, lane_mode, x_offset}]
# lane_mode: "any" | "same" | 0|1|2 | "spread"

static func pick(elapsed: float, avoid_lane_lock: bool = false) -> Dictionary:
	var pool: Array = []
	for e in all():
		if elapsed >= float(e.get("min_elapsed", 0.0)):
			pool.append(e)
	if pool.is_empty():
		pool = all()
	var total := 0.0
	for e in pool:
		total += float(e.get("weight", 1.0))
	var r := randf() * total
	for e in pool:
		r -= float(e.get("weight", 1.0))
		if r <= 0.0:
			return e
	return pool.back()


static func all() -> Array:
	return [
		{"id": "puddle", "min_elapsed": 0.0, "weight": 8.0, "items": [{"type": "puddle", "lane": "any", "x": 0}]},
		{"id": "corpse", "min_elapsed": 1.2, "weight": 10.0, "items": [{"type": "corpse", "lane": "any", "x": 0}]},
		{"id": "hook", "min_elapsed": 2.0, "weight": 10.0, "items": [{"type": "hook", "lane": "any", "x": 0}]},
		{"id": "saw", "min_elapsed": 2.5, "weight": 10.0, "items": [{"type": "saw", "lane": "any", "x": 0}]},
		{"id": "two_lane_corpses", "min_elapsed": 6.0, "weight": 6.0, "items": [
			{"type": "corpse", "lane": 0, "x": 0},
			{"type": "hook", "lane": 2, "x": 40},
		]},
		{"id": "gut", "min_elapsed": 8.0, "weight": 5.0, "items": [{"type": "gut_wall", "lane": "any", "x": 0}]},
		{"id": "shield", "min_elapsed": 5.0, "weight": 3.0, "items": [{"type": "shield", "lane": "any", "x": 0}]},
		{"id": "speed", "min_elapsed": 7.0, "weight": 3.0, "items": [{"type": "speed", "lane": "any", "x": 0}]},
		{"id": "saw_hook", "min_elapsed": 10.0, "weight": 6.0, "items": [
			{"type": "saw", "lane": 1, "x": 0},
			{"type": "hook", "lane": 0, "x": 90},
		]},
		{"id": "squeeze", "min_elapsed": 12.0, "weight": 4.0, "items": [{"type": "squeeze", "lane": 1, "x": 0}]},
		{"id": "triple_choice", "min_elapsed": 14.0, "weight": 4.0, "items": [
			{"type": "hook", "lane": 0, "x": 0},
			{"type": "corpse", "lane": 1, "x": 20},
			{"type": "saw", "lane": 2, "x": 0},
		]},
	]


static func ambush_prop() -> Dictionary:
	var kinds := ["wall_burst", "trash", "corpse"]
	return {
		"id": "ambush",
		"items": [{"type": "ambush", "prop": kinds[randi() % kinds.size()], "lane": "any", "x": 0}],
	}


static func resolve_lane(spec) -> int:
	if spec is int:
		return int(spec)
	if spec is String:
		if spec == "any":
			return randi() % 3
		if spec.is_valid_int():
			return int(spec)
	return 1
