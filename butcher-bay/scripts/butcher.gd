class_name Butcher
extends Node2D

enum Mode { CHASE, VANISHED, AMBUSH }

var mode: Mode = Mode.CHASE
var _sprite: AnimatedSprite2D
var _target_x: float = -40.0
var _visible_alpha: float = 1.0


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.sprite_frames = _build_frames()
	_sprite.play("run")
	add_child(_sprite)
	position = Vector2(_target_x, RunRules.lane_y(1))
	z_index = 25


func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	_add(sf, "run", "run", 10.0, true)
	_add(sf, "ambush", "ambush", 12.0, false)
	return sf


func _add(sf: SpriteFrames, anim: String, prefix: String, fps: float, loop: bool) -> void:
	sf.add_animation(anim)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, loop)
	for i in range(4):
		sf.add_frame(anim, load("res://assets/sprites/butcher/%s_%d.png" % [prefix, i]))


func _process(delta: float) -> void:
	position.x = lerpf(position.x, _target_x, clampf(delta * 6.0, 0.0, 1.0))
	_sprite.modulate.a = lerpf(_sprite.modulate.a, _visible_alpha, clampf(delta * 8.0, 0.0, 1.0))


func follow_chase(distance: float, player_lane: int, player_y: float) -> void:
	if mode != Mode.CHASE:
		return
	_target_x = RunRules.butcher_x(distance)
	position.y = lerpf(position.y, player_y, 0.25)
	scale = Vector2.ONE * RunRules.lane_scale(player_lane)
	z_index = RunRules.lane_z(player_lane) - 1
	_visible_alpha = 1.0
	if _sprite.animation != "run":
		_sprite.play("run")


func vanish() -> void:
	mode = Mode.VANISHED
	_visible_alpha = 0.0


func strike(at: Vector2, lane: int) -> void:
	mode = Mode.AMBUSH
	position = at + Vector2(-10, -20)
	scale = Vector2.ONE * RunRules.lane_scale(lane) * 1.15
	z_index = 80
	_visible_alpha = 1.0
	_sprite.play("ambush")
	GameAudio.play("sfx_ambush", 0.0, 0.95)


func return_to_chase() -> void:
	mode = Mode.CHASE
	_sprite.play("run")
	_visible_alpha = 1.0
