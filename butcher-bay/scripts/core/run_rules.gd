class_name RunRules
extends RefCounted

enum Kind {
	HOOK,
	SAW,
	CORPSE,
	PUDDLE,
	GUT_WALL,
	SHIELD,
	SPEED,
	AMBUSH,
	SQUEEZE,
}

const LANE_COUNT := 3
const PLAYER_X := 420.0
const LANE_Y := [575.0, 520.0, 470.0]
const LANE_SCALE := [2.35, 2.05, 1.75]
const LANE_Z := [30, 20, 10]


static func shift_lane(lane: int, dir: int) -> int:
	return clampi(lane + dir, 0, LANE_COUNT - 1)


static func lane_y(lane: int) -> float:
	return LANE_Y[clampi(lane, 0, 2)]


static func lane_scale(lane: int) -> float:
	return LANE_SCALE[clampi(lane, 0, 2)]


static func lane_z(lane: int) -> int:
	return LANE_Z[clampi(lane, 0, 2)]


static func butcher_x(chase_distance: float) -> float:
	# 100 = far left offscreen-ish, 0 = overlapping the player.
	return lerpf(-80.0, PLAYER_X - 70.0, 1.0 - clampf(chase_distance, 0.0, 100.0) / 100.0)


static func tick_chase(distance: float, dt: float, slowed: bool, boosting: bool) -> float:
	var delta := -2.4 * dt
	if slowed:
		delta -= 16.0 * dt
	elif boosting:
		delta += 18.0 * dt
	else:
		delta += 1.2 * dt
	return clampf(distance + delta, 0.0, 100.0)


static func can_smash(slowed: bool, boosting: bool, speed_ratio: float) -> bool:
	if slowed:
		return false
	if boosting:
		return true
	return speed_ratio >= 0.92


static func resolve_hit(kind: int, jumping: bool, sliding: bool, in_vent: bool, smash: bool, shielded: bool) -> String:
	if in_vent and kind != Kind.SQUEEZE:
		return "clear"
	match kind:
		Kind.HOOK:
			if sliding:
				return "clear"
			return "shield" if shielded else "kill"
		Kind.SAW, Kind.CORPSE:
			if jumping:
				return "clear"
			return "shield" if shielded else "kill"
		Kind.PUDDLE:
			if jumping:
				return "clear"
			return "slow"
		Kind.GUT_WALL:
			if smash:
				return "smash"
			return "shield" if shielded else "block"
		Kind.SHIELD:
			return "pickup_shield"
		Kind.SPEED:
			return "pickup_speed"
		Kind.AMBUSH:
			return "shield" if shielded else "kill"
		Kind.SQUEEZE:
			return "kill"
	return "clear"


static func kind_from_name(name: String) -> int:
	match name:
		"hook":
			return Kind.HOOK
		"saw":
			return Kind.SAW
		"corpse":
			return Kind.CORPSE
		"puddle":
			return Kind.PUDDLE
		"gut_wall":
			return Kind.GUT_WALL
		"shield":
			return Kind.SHIELD
		"speed":
			return Kind.SPEED
		"ambush":
			return Kind.AMBUSH
		"squeeze":
			return Kind.SQUEEZE
	return Kind.CORPSE
