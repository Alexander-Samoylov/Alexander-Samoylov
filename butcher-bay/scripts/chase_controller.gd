class_name ChaseController
extends Node

signal caught
signal vanish_requested
signal ambush_ready
signal returned

enum Phase { PRESENT, VANISHED, TELEGRAPH, STRIKE, COOLDOWN }

var distance: float = 72.0
var phase: Phase = Phase.PRESENT
var time_to_vanish: float = 11.0
var ambush_lane: int = 1
var _cooldown: float = 0.0
var _telegraph: float = 0.0


func reset() -> void:
	distance = 72.0
	phase = Phase.PRESENT
	time_to_vanish = 9.0 + randf() * 6.0
	_cooldown = 0.0


func tick(dt: float, slowed: bool, boosting: bool, elapsed: float) -> void:
	if phase == Phase.PRESENT:
		distance = RunRules.tick_chase(distance, dt, slowed, boosting)
		if distance <= 0.0:
			caught.emit()
			return
		time_to_vanish -= dt
		if time_to_vanish <= 0.0 and elapsed > 8.0:
			phase = Phase.VANISHED
			vanish_requested.emit()
	elif phase == Phase.COOLDOWN:
		distance = RunRules.tick_chase(distance, dt, slowed, boosting)
		_cooldown -= dt
		if _cooldown <= 0.0:
			phase = Phase.PRESENT
			time_to_vanish = maxf(7.0, 16.0 - elapsed * 0.05) + randf() * 4.0
	elif phase == Phase.TELEGRAPH:
		_telegraph -= dt
		if _telegraph <= 0.0:
			phase = Phase.STRIKE
			ambush_ready.emit()


func apply_penalty(amount: float) -> void:
	distance = clampf(distance - amount, 0.0, 100.0)
	if distance <= 0.0:
		caught.emit()


func apply_boost(amount: float) -> void:
	distance = clampf(distance + amount, 0.0, 100.0)


func begin_telegraph(lane: int) -> void:
	ambush_lane = lane
	phase = Phase.TELEGRAPH
	_telegraph = RunRules.AMBUSH_TELEGRAPH


func finish_ambush() -> void:
	phase = Phase.COOLDOWN
	_cooldown = 4.5
	returned.emit()
