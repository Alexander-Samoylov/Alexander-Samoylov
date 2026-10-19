class_name RunnerPlayer
extends Node2D

signal died(cause: String)
signal buff_changed

const SLIDE_TIME := 0.48
const JUMP_V0 := -620.0
const GRAVITY := 1750.0
const VENT_TIME := 1.15

enum State { RUN, JUMP, SLIDE, VENT, DEAD }

var lane: int = 1
var state: State = State.RUN
var jump_offset: float = 0.0
var jump_vy: float = 0.0
var slide_left: float = 0.0
var vent_left: float = 0.0
var shielded: bool = false
var speed_boost_left: float = 0.0
var slow_left: float = 0.0
var lane_visual: float = 1.0

var game: Node = null
var _sprite: AnimatedSprite2D
var _area: Area2D
var _body_shape: RectangleShape2D
var _shield_fx: Sprite2D
var _step_acc: float = 0.0
var _blood_acc: float = 0.0


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.sprite_frames = _build_frames()
	_sprite.play("run")
	add_child(_sprite)

	_shield_fx = Sprite2D.new()
	_shield_fx.texture = load("res://assets/sprites/obstacles/amulet_shield.png")
	_shield_fx.modulate = Color(0.55, 1.0, 0.95, 0.55)
	_shield_fx.scale = Vector2(2.4, 2.4)
	_shield_fx.visible = false
	add_child(_shield_fx)

	_area = Area2D.new()
	_area.collision_layer = 1
	_area.collision_mask = 2 | 4
	_area.monitoring = true
	_area.monitorable = true
	var col := CollisionShape2D.new()
	_body_shape = RectangleShape2D.new()
	_body_shape.size = Vector2(36, 78)
	col.shape = _body_shape
	col.position = Vector2(0, 8)
	_area.add_child(col)
	add_child(_area)
	_area.area_entered.connect(_on_area_entered)

	add_to_group("player")
	position = Vector2(RunRules.PLAYER_X, RunRules.lane_y(lane))
	scale = Vector2.ONE * RunRules.lane_scale(lane)
	z_index = RunRules.lane_z(lane)
	SwipeInput.swipe.connect(_on_swipe)


func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	_add_anim(sf, "run", "player", "run", 10.0, true)
	_add_anim(sf, "jump", "player", "jump", 8.0, false)
	_add_anim(sf, "slide", "player", "slide", 8.0, true)
	_add_anim(sf, "vent", "player", "vent", 8.0, true)
	return sf


func _add_anim(sf: SpriteFrames, anim: String, folder: String, prefix: String, fps: float, loop: bool) -> void:
	sf.add_animation(anim)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, loop)
	for i in range(4):
		var tex: Texture2D = load("res://assets/sprites/%s/%s_%d.png" % [folder, prefix, i])
		sf.add_frame(anim, tex)


func _process(delta: float) -> void:
	if state == State.DEAD:
		return
	if speed_boost_left > 0.0:
		speed_boost_left = maxf(speed_boost_left - delta, 0.0)
		if speed_boost_left == 0.0:
			buff_changed.emit()
	if slow_left > 0.0:
		slow_left = maxf(slow_left - delta, 0.0)
		if slow_left == 0.0:
			buff_changed.emit()

	lane_visual = lerpf(lane_visual, float(lane), clampf(delta * 7.0, 0.0, 1.0))
	var base_y := lerpf(RunRules.LANE_Y[0], RunRules.LANE_Y[2], lane_visual / 2.0)
	# Blend across 3 lanes more accurately
	if lane_visual <= 1.0:
		base_y = lerpf(RunRules.LANE_Y[0], RunRules.LANE_Y[1], lane_visual)
	else:
		base_y = lerpf(RunRules.LANE_Y[1], RunRules.LANE_Y[2], lane_visual - 1.0)
	var sc: float
	if lane_visual <= 1.0:
		sc = lerpf(RunRules.LANE_SCALE[0], RunRules.LANE_SCALE[1], lane_visual)
	else:
		sc = lerpf(RunRules.LANE_SCALE[1], RunRules.LANE_SCALE[2], lane_visual - 1.0)

	if state == State.JUMP:
		jump_vy += GRAVITY * delta
		jump_offset += jump_vy * delta
		if jump_offset >= 0.0:
			jump_offset = 0.0
			jump_vy = 0.0
			state = State.RUN
			_play("run")
			GameAudio.play("sfx_land", -2.0, randf_range(0.92, 1.08))
			_puff()
	elif state == State.SLIDE:
		slide_left -= delta
		_blood_acc += delta
		if _blood_acc > 0.07:
			_blood_acc = 0.0
			if game and game.has_method("spawn_streak"):
				game.spawn_streak(global_position + Vector2(-18, 28))
		if slide_left <= 0.0:
			state = State.RUN
			_play("run")
			_set_hitbox(false)
	elif state == State.VENT:
		vent_left -= delta
		if vent_left <= 0.0:
			state = State.RUN
			jump_offset = 0.0
			_play("run")

	if state == State.VENT:
		jump_offset = lerpf(jump_offset, -210.0, clampf(delta * 8.0, 0.0, 1.0))

	position.x = RunRules.PLAYER_X
	position.y = base_y + jump_offset
	scale = Vector2.ONE * sc
	z_index = RunRules.lane_z(lane)
	_shield_fx.visible = shielded
	_shield_fx.rotation += delta * 2.5

	if state == State.RUN:
		_step_acc += delta
		if _step_acc > 0.28:
			_step_acc = 0.0
			GameAudio.play("sfx_step", -8.0, randf_range(0.9, 1.12))


func _on_swipe(direction: Vector2i) -> void:
	if state == State.DEAD:
		return
	if direction.x != 0:
		var next := RunRules.shift_lane(lane, direction.x)
		if next != lane:
			lane = next
			GameAudio.play("sfx_lane", -4.0, 1.0 + direction.x * 0.06)
			_puff()
		return
	if direction.y < 0:
		_up_action()
	elif direction.y > 0:
		start_slide()


func _up_action() -> void:
	if game and game.has_method("try_enter_vent") and game.try_enter_vent(self):
		return
	start_jump()


func start_jump() -> void:
	if state == State.JUMP or state == State.VENT or state == State.DEAD:
		return
	state = State.JUMP
	jump_vy = JUMP_V0
	jump_offset = -4.0
	_set_hitbox(false)
	_play("jump")
	GameAudio.play("sfx_jump", -1.0, randf_range(0.95, 1.05))


func start_slide() -> void:
	if state == State.JUMP or state == State.VENT or state == State.DEAD:
		return
	state = State.SLIDE
	slide_left = SLIDE_TIME
	_set_hitbox(true)
	_play("slide")
	GameAudio.play("sfx_slide", -2.0)


func enter_vent() -> void:
	state = State.VENT
	vent_left = VENT_TIME
	_play("vent")
	GameAudio.play("sfx_vent", -1.0)


func apply_slow(duration: float = 1.4) -> void:
	slow_left = maxf(slow_left, duration)
	buff_changed.emit()


func apply_shield() -> void:
	shielded = true
	buff_changed.emit()
	GameAudio.play("sfx_pickup", -1.0, 1.05)


func apply_speed(duration: float = 3.0) -> void:
	speed_boost_left = maxf(speed_boost_left, duration)
	buff_changed.emit()
	GameAudio.play("sfx_pickup", -1.0, 1.2)


func consume_shield() -> bool:
	if not shielded:
		return false
	shielded = false
	buff_changed.emit()
	return true


func is_jumping() -> bool:
	return state == State.JUMP


func is_sliding() -> bool:
	return state == State.SLIDE


func is_in_vent() -> bool:
	return state == State.VENT


func is_slowed() -> bool:
	return slow_left > 0.0


func is_boosting() -> bool:
	return speed_boost_left > 0.0


func kill(cause: String) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	GameAudio.play("sfx_death", 0.0)
	died.emit(cause)


func _set_hitbox(sliding: bool) -> void:
	if sliding:
		_body_shape.size = Vector2(52, 36)
	else:
		_body_shape.size = Vector2(36, 78)


func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.play(anim)


func _on_area_entered(area: Area2D) -> void:
	if state == State.DEAD:
		return
	if area.has_method("on_player_hit"):
		area.on_player_hit(self)


func _puff() -> void:
	var dust := Sprite2D.new()
	dust.texture = load("res://assets/sprites/ui/dust.png")
	dust.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dust.position = Vector2(-12, 30)
	dust.z_index = -1
	add_child(dust)
	var tw := create_tween()
	tw.tween_property(dust, "modulate:a", 0.0, 0.32)
	tw.parallel().tween_property(dust, "position:x", -36.0, 0.32)
	tw.finished.connect(dust.queue_free)
