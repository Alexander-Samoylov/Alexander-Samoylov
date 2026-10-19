class_name WorldScroller
extends Node2D

var speed: float = 240.0
var distance_run: float = 0.0

var _parallax: ParallaxBackground
var _floor_sprites: Array[Sprite2D] = []
var _ceil_sprites: Array[Sprite2D] = []


func setup() -> void:
	_parallax = ParallaxBackground.new()
	add_child(_parallax)

	var far := ParallaxLayer.new()
	far.motion_scale = Vector2(0.25, 0)
	far.motion_mirroring = Vector2(512, 0)
	var far_s := Sprite2D.new()
	far_s.texture = load("res://assets/sprites/env/far.png")
	far_s.centered = false
	far_s.position = Vector2(0, 0)
	far_s.scale = Vector2(2.5, 4.0)
	far.add_child(far_s)
	_parallax.add_child(far)

	var mid := ParallaxLayer.new()
	mid.motion_scale = Vector2(0.55, 0)
	mid.motion_mirroring = Vector2(512, 0)
	for i in range(5):
		var w := Sprite2D.new()
		w.texture = load("res://assets/sprites/env/wall.png")
		w.centered = false
		w.position = Vector2(i * 128, 90)
		w.scale = Vector2(2.0, 3.6)
		w.modulate = Color(0.85, 0.7, 0.7)
		mid.add_child(w)
	_parallax.add_child(mid)

	for i in range(10):
		var fl := Sprite2D.new()
		fl.texture = load("res://assets/sprites/env/floor.png")
		fl.centered = false
		fl.position = Vector2(i * 128, 640)
		fl.scale = Vector2(2, 2.6)
		fl.z_index = 5
		add_child(fl)
		_floor_sprites.append(fl)
		var cl := Sprite2D.new()
		cl.texture = load("res://assets/sprites/env/ceiling.png")
		cl.centered = false
		cl.position = Vector2(i * 128, -8)
		cl.scale = Vector2(2, 2.4)
		cl.z_index = 40
		add_child(cl)
		_ceil_sprites.append(cl)
		if i % 2 == 0:
			var drip := Sprite2D.new()
			drip.texture = load("res://assets/sprites/env/drip.png")
			drip.centered = false
			drip.position = Vector2(40 + i * 90, 70)
			drip.scale = Vector2(2.4, 2.4)
			drip.z_index = 6
			add_child(drip)


func scroll(delta: float) -> void:
	distance_run += speed * delta * 0.06
	if _parallax:
		_parallax.scroll_offset.x -= speed * delta
	for spr in _floor_sprites:
		spr.position.x -= speed * delta
		if spr.position.x < -128:
			spr.position.x += 10 * 128
	for spr in _ceil_sprites:
		spr.position.x -= speed * delta
		if spr.position.x < -128:
			spr.position.x += 10 * 128
