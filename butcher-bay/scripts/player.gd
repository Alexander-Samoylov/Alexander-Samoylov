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


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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

	lane_visual = lerpf(lane_visual, float(lane), clampf(delta * 14.0, 0.0, 1.0))
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
	elif state == State.SLIDE:
		slide_left -= delta
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
			_sfx("sfx_step")


func _on_swipe(direction: Vector2i) -> void:
	if state == State.DEAD:
		return
	if direction.x != 0:
		lane = RunRules.shift_lane(lane, direction.x)
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
	_sfx("sfx_jump")


func start_slide() -> void:
	if state == State.JUMP or state == State.VENT or state == State.DEAD:
		return
	state = State.SLIDE
	slide_left = SLIDE_TIME
	_set_hitbox(true)
	_play("slide")
	_sfx("sfx_slide")


func enter_vent() -> void:
	state = State.VENT
	vent_left = VENT_TIME
	_play("vent")
	_sfx("sfx_jump")


func apply_slow(duration: float = 1.4) -> void:
	slow_left = maxf(slow_left, duration)
	buff_changed.emit()


func apply_shield() -> void:
	shielded = true
	buff_changed.emit()
	_sfx("sfx_pickup")


func apply_speed(duration: float = 3.0) -> void:
	speed_boost_left = maxf(speed_boost_left, duration)
	buff_changed.emit()
	_sfx("sfx_pickup")


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
	_sfx("sfx_death")
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


func _sfx(name: String) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = load("res://assets/audio/%s.wav" % name)
	p.bus = "Master"
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
