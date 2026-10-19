class_name Hazard
extends Area2D

var kind_name: String = "corpse"
var lane: int = 1
var consumed: bool = false
var is_ambush_prop: bool = false
var ambush_armed: bool = false
var prop_name: String = ""

var _sprite: Sprite2D
var _anim: AnimatedSprite2D
var _whistled: bool = false
var _t: float = 0.0
var _base_scale: Vector2 = Vector2.ONE


func setup(p_kind: String, p_lane: int, at_x: float, p_prop: String = "") -> void:
	kind_name = p_kind
	lane = p_lane
	prop_name = p_prop
	position = Vector2(at_x, RunRules.lane_y(lane))
	scale = Vector2.ONE * RunRules.lane_scale(lane)
	z_index = RunRules.lane_z(lane) + 2
	collision_layer = 2 if p_kind not in ["shield", "speed"] else 4
	collision_mask = 1
	monitoring = true
	monitorable = true

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = _hit_size()
	col.shape = shape
	col.position = Vector2(0, 4)
	add_child(col)

	if kind_name == "saw":
		_anim = AnimatedSprite2D.new()
		_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var sf := SpriteFrames.new()
		sf.add_animation("spin")
		sf.set_animation_speed("spin", 14.0)
		sf.set_animation_loop("spin", true)
		for i in range(4):
			sf.add_frame("spin", load("res://assets/sprites/obstacles/saw_%d.png" % i))
		_anim.sprite_frames = sf
		_anim.play("spin")
		add_child(_anim)
	else:
		_sprite = Sprite2D.new()
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.texture = load(_texture_path())
		add_child(_sprite)

	if kind_name == "hook":
		position.y = RunRules.lane_y(lane) - 70.0 * RunRules.lane_scale(lane)
	elif kind_name == "puddle":
		position.y = RunRules.lane_y(lane) + 28.0
		z_index = RunRules.lane_z(lane) - 2
	elif kind_name == "squeeze":
		position.y = 360.0
		scale = Vector2(2.2, 2.0)
		z_index = 50
	_base_scale = scale


func _texture_path() -> String:
	match kind_name:
		"hook":
			return "res://assets/sprites/obstacles/hook.png"
		"corpse":
			return "res://assets/sprites/obstacles/corpse.png"
		"puddle":
			return "res://assets/sprites/obstacles/puddle.png"
		"gut_wall":
			return "res://assets/sprites/obstacles/gut_wall.png"
		"shield":
			return "res://assets/sprites/obstacles/amulet_shield.png"
		"speed":
			return "res://assets/sprites/obstacles/amulet_speed.png"
		"ambush":
			if prop_name == "trash":
				return "res://assets/sprites/obstacles/trash.png"
			if prop_name == "wall_burst":
				return "res://assets/sprites/obstacles/wall_burst.png"
			return "res://assets/sprites/obstacles/corpse.png"
		"squeeze":
			return "res://assets/sprites/obstacles/squeeze.png"
	return "res://assets/sprites/obstacles/corpse.png"


func _hit_size() -> Vector2:
	match kind_name:
		"hook":
			return Vector2(28, 70)
		"saw":
			return Vector2(70, 36)
		"corpse":
			return Vector2(70, 28)
		"puddle":
			return Vector2(72, 18)
		"gut_wall":
			return Vector2(40, 96)
		"shield", "speed":
			return Vector2(32, 32)
		"ambush":
			return Vector2(50, 50)
		"squeeze":
			return Vector2(140, 160)
	return Vector2(40, 40)


func _process(delta: float) -> void:
	_t += delta
	if kind_name == "hook" and _sprite:
		_sprite.rotation = sin(_t * 5.2) * 0.38
		if not _whistled and position.x < RunRules.PLAYER_X + 280.0:
			_whistled = true
			GameAudio.play("sfx_hook", -6.0, randf_range(0.92, 1.08))
	elif kind_name == "puddle" and _sprite:
		var gleam := 0.72 + 0.28 * sin(_t * 6.0)
		_sprite.modulate = Color(1.15, gleam, gleam, 1.0)
	elif kind_name == "saw" and _anim:
		_anim.scale = Vector2.ONE * (1.0 + 0.06 * sin(_t * 18.0))
	elif kind_name == "gut_wall":
		var p := get_tree().get_first_node_in_group("player") as RunnerPlayer
		var smash := false
		if p and p.game:
			smash = RunRules.can_smash(p.is_slowed(), p.is_boosting(), p.game.speed_ratio())
		if smash:
			modulate = Color(1.25, 0.95, 0.95)
			scale = _base_scale * (1.0 + 0.04 * sin(_t * 10.0))
		else:
			modulate = Color(0.62, 0.4, 0.4)
			scale = _base_scale
	elif kind_name == "shield" or kind_name == "speed":
		if _sprite:
			_sprite.position.y = sin(_t * 4.0) * 6.0


func on_player_hit(player: RunnerPlayer) -> void:
	if consumed:
		return
	if player.lane != lane and kind_name != "squeeze":
		return
	if kind_name == "ambush":
		return  # resolved by chase ambush strike, not contact
	if kind_name == "squeeze":
		return  # resolved by vent window
	var kind := RunRules.kind_from_name(kind_name)
	var smash := RunRules.can_smash(player.is_slowed(), player.is_boosting(), 1.0 if player.game == null else player.game.speed_ratio())
	var result := RunRules.resolve_hit(
		kind,
		player.is_jumping(),
		player.is_sliding(),
		player.is_in_vent(),
		smash,
		player.shielded
	)
	_apply_result(player, result)


func _apply_result(player: RunnerPlayer, result: String) -> void:
	match result:
		"clear":
			return
		"slow":
			consumed = true
			player.apply_slow()
			GameAudio.play("sfx_puddle", -2.0)
			modulate.a = 0.4
		"smash":
			consumed = true
			GameAudio.play("sfx_smash", 0.0)
			queue_free()
			if player.game:
				player.game.shake(10.0)
		"pickup_shield":
			consumed = true
			player.apply_shield()
			queue_free()
		"pickup_speed":
			consumed = true
			player.apply_speed()
			if player.game:
				player.game.chase.apply_boost(16.0)
			queue_free()
		"shield":
			consumed = true
			player.consume_shield()
			GameAudio.play("sfx_hit", -1.0)
			queue_free()
		"block":
			consumed = true
			GameAudio.play("sfx_hit", 0.0)
			if player.game:
				player.game.chase.apply_penalty(32.0)
				player.game.shake(14.0)
			player.apply_slow(0.8)
			modulate = Color(0.6, 0.3, 0.3)
		"kill":
			consumed = true
			player.kill(kind_name)


