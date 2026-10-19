extends Node2D

var player: RunnerPlayer
var butcher: Butcher
var chase: ChaseController
var scroller: WorldScroller
var spawner: ObstacleSpawner
var vent: VentEvent
var hud: CanvasLayer

var elapsed: float = 0.0
var dead: bool = false
var shake_mag: float = 0.0
var _saw_loop: AudioStreamPlayer
var _drone: AudioStreamPlayer
var _pending_ambush_hazard: Hazard
var _squeeze_hazard: Hazard
var _base_speed := 250.0


func _ready() -> void:
	randomize()
	var modulate_n := CanvasModulate.new()
	modulate_n.color = Color(0.82, 0.64, 0.6)
	add_child(modulate_n)

	scroller = WorldScroller.new()
	add_child(scroller)
	scroller.setup()

	var world := Node2D.new()
	world.name = "World"
	add_child(world)

	player = RunnerPlayer.new()
	player.game = self
	add_child(player)
	player.died.connect(_on_player_died)
	player.buff_changed.connect(_refresh_buffs)

	butcher = Butcher.new()
	add_child(butcher)

	chase = ChaseController.new()
	add_child(chase)
	chase.reset()
	chase.caught.connect(func() -> void: _on_player_died("caught"))
	chase.vanish_requested.connect(_on_butcher_vanish)
	chase.ambush_ready.connect(_on_ambush_strike)
	chase.returned.connect(func() -> void: butcher.return_to_chase())

	vent = VentEvent.new()
	add_child(vent)
	vent.window_opened.connect(func() -> void: hud.flash("СВАЙП ВВЕРХ — ВЕНТИЛЯЦИЯ", 1.2))
	vent.window_closed.connect(func() -> void: _squeeze_hazard = null)
	vent.crushed.connect(func() -> void: _on_player_died("squeeze"))

	spawner = ObstacleSpawner.new()
	add_child(spawner)
	spawner.world = world
	spawner.speed_fn = Callable(self, "current_speed")
	spawner.reset()
	spawner.squeeze_spawned.connect(_on_squeeze)
	spawner.ambush_prop_spawned.connect(_on_ambush_prop)

	hud = load("res://scenes/hud.tscn").instantiate()
	add_child(hud)

	_drone = AudioStreamPlayer.new()
	_drone.stream = load("res://assets/audio/music_drone.wav")
	_drone.autoplay = true
	add_child(_drone)
	_drone.finished.connect(func() -> void:
		if not dead:
			_drone.play()
	)
	_saw_loop = AudioStreamPlayer.new()
	_saw_loop.stream = load("res://assets/audio/sfx_saw.wav")
	_saw_loop.volume_db = -8.0
	add_child(_saw_loop)
	_saw_loop.finished.connect(func() -> void:
		if not dead:
			_saw_loop.play()
	)
	_saw_loop.play()

	hud.set_chase(chase.distance)
	hud.set_score(0)


func current_speed() -> float:
	var t := clampf(elapsed / 80.0, 0.0, 1.0)
	var spd := lerpf(_base_speed, 430.0, t)
	if player.is_slowed():
		spd *= 0.58
	if player.is_boosting():
		spd *= 1.32
	return spd


func speed_ratio() -> float:
	return current_speed() / lerpf(_base_speed, 430.0, clampf(elapsed / 80.0, 0.0, 1.0))


func try_enter_vent(p: RunnerPlayer) -> bool:
	return vent.try_enter(p)


func shake(mag: float) -> void:
	shake_mag = maxf(shake_mag, mag)


func _process(delta: float) -> void:
	if dead:
		return
	elapsed += delta
	scroller.speed = current_speed()
	scroller.scroll(delta)
	spawner.tick(delta)
	chase.tick(delta, player.is_slowed(), player.is_boosting(), elapsed)
	if _squeeze_hazard and is_instance_valid(_squeeze_hazard) and not vent.active:
		if _squeeze_hazard.position.x < RunRules.PLAYER_X + 390.0:
			vent.begin(_squeeze_hazard, 1.25)
	vent.tick(delta)
	butcher.follow_chase(chase.distance, player.lane, player.position.y)

	var amb := spawner.live_ambush()
	if amb and chase.phase == ChaseController.Phase.VANISHED:
		if amb.position.x < RunRules.PLAYER_X + 280.0:
			chase.begin_telegraph(amb.lane)
			hud.flash("ОН ЗДЕСЬ", 0.6)
			shake(8.0)

	hud.set_score(int(scroller.distance_run))
	hud.set_chase(chase.distance)

	if shake_mag > 0.0:
		position = Vector2(randf_range(-shake_mag, shake_mag), randf_range(-shake_mag, shake_mag))
		shake_mag = maxf(0.0, shake_mag - delta * 40.0)
	else:
		position = Vector2.ZERO


func _refresh_buffs() -> void:
	hud.set_buffs(player.shielded, player.is_boosting(), player.is_slowed())


func _on_squeeze(hazard: Hazard) -> void:
	_squeeze_hazard = hazard


func _on_ambush_prop(hazard: Hazard) -> void:
	_pending_ambush_hazard = hazard


func _on_butcher_vanish() -> void:
	butcher.vanish()
	spawner.pending_ambush = true
	hud.flash("ТИШИНА...", 0.8)


func _on_ambush_strike() -> void:
	var h := spawner.live_ambush()
	var lane := chase.ambush_lane
	var at := Vector2(RunRules.PLAYER_X + 40.0, RunRules.lane_y(lane))
	if h:
		lane = h.lane
		at = h.global_position
		h.consumed = true
	butcher.strike(at, lane)
	shake(18.0)
	if player.lane == lane and not player.is_in_vent():
		if player.shielded:
			player.consume_shield()
		else:
			_on_player_died("ambush")
			return
	await get_tree().create_timer(0.7).timeout
	if dead:
		return
	chase.finish_ambush()
	butcher.return_to_chase()


func _on_player_died(cause: String) -> void:
	if dead:
		return
	dead = true
	GameState.record_run(int(scroller.distance_run), cause)
	shake(22.0)
	await get_tree().create_timer(0.55).timeout
	get_tree().change_scene_to_file("res://scenes/death_screen.tscn")
