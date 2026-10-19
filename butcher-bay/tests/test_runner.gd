extends SceneTree

var _failed := 0
var _passed := 0


func _init() -> void:
	_t("lane left clamp", RunRules.shift_lane(0, -1) == 0)
	_t("lane right clamp", RunRules.shift_lane(2, 1) == 2)
	_t("lane mid left", RunRules.shift_lane(1, -1) == 0)
	_t("lane mid right", RunRules.shift_lane(1, 1) == 2)
	_t("hook needs slide", RunRules.resolve_hit(RunRules.Kind.HOOK, false, false, false, false, false) == "kill")
	_t("hook slide clears", RunRules.resolve_hit(RunRules.Kind.HOOK, false, true, false, false, false) == "clear")
	_t("saw needs jump", RunRules.resolve_hit(RunRules.Kind.SAW, false, false, false, false, false) == "kill")
	_t("saw jump clears", RunRules.resolve_hit(RunRules.Kind.SAW, true, false, false, false, false) == "clear")
	_t("corpse jump clears", RunRules.resolve_hit(RunRules.Kind.CORPSE, true, false, false, false, false) == "clear")
	_t("puddle slows", RunRules.resolve_hit(RunRules.Kind.PUDDLE, false, false, false, false, false) == "slow")
	_t("puddle jump clears", RunRules.resolve_hit(RunRules.Kind.PUDDLE, true, false, false, false, false) == "clear")
	_t("gut smash", RunRules.resolve_hit(RunRules.Kind.GUT_WALL, false, false, false, true, false) == "smash")
	_t("gut block", RunRules.resolve_hit(RunRules.Kind.GUT_WALL, false, false, false, false, false) == "block")
	_t("shield saves hook", RunRules.resolve_hit(RunRules.Kind.HOOK, false, false, false, false, true) == "shield")
	_t("vent clears saw", RunRules.resolve_hit(RunRules.Kind.SAW, false, false, true, false, false) == "clear")
	_t("slow cannot smash", RunRules.can_smash(true, false, 1.0) == false)
	_t("boost can smash", RunRules.can_smash(false, true, 0.5) == true)
	_t("fast can smash", RunRules.can_smash(false, false, 0.95) == true)
	var d0 := RunRules.tick_chase(50.0, 1.0, true, false)
	var d1 := RunRules.tick_chase(50.0, 1.0, false, true)
	_t("slow closes gap", d0 < 50.0)
	_t("boost opens gap", d1 > 50.0)
	_t("butcher x at 0 near player", RunRules.butcher_x(0.0) > 250.0)
	_t("butcher x at 100 far", RunRules.butcher_x(100.0) < 50.0)
	_t("kind parse hook", RunRules.kind_from_name("hook") == RunRules.Kind.HOOK)
	print("tests passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _t(name: String, ok: bool) -> void:
	if ok:
		_passed += 1
		print("  ok   ", name)
	else:
		_failed += 1
		printerr("  FAIL ", name)
