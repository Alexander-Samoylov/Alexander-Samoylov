extends Control

var _saw: AnimatedSprite2D


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.0, 0.0)
	add_child(bg)

	_saw = AnimatedSprite2D.new()
	_saw.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sf := SpriteFrames.new()
	sf.add_animation("spin")
	sf.set_animation_speed("spin", 10.0)
	sf.set_animation_loop("spin", true)
	for i in range(4):
		sf.add_frame("spin", load("res://assets/sprites/ui/saw_close_%d.png" % i))
	_saw.sprite_frames = sf
	_saw.play("spin")
	_saw.position = Vector2(640, 260)
	_saw.scale = Vector2(1.6, 1.6)
	add_child(_saw)

	var title := Label.new()
	title.text = "ОН ДОГНАЛ ТЕБЯ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(140, 430)
	title.size = Vector2(1000, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.modulate = Color(0.9, 0.15, 0.12)
	add_child(title)

	var cause := Label.new()
	cause.text = _cause_text(GameState.last_cause)
	cause.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cause.position = Vector2(140, 480)
	cause.size = Vector2(1000, 30)
	cause.add_theme_font_size_override("font_size", 18)
	add_child(cause)

	var score := Label.new()
	score.text = "Дистанция: %d м    Рекорд: %d м" % [GameState.last_score, GameState.best_score]
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.position = Vector2(140, 520)
	score.size = Vector2(1000, 30)
	score.add_theme_font_size_override("font_size", 22)
	add_child(score)

	var retry := Button.new()
	retry.text = "ЕЩЁ РАЗ"
	retry.position = Vector2(360, 580)
	retry.size = Vector2(240, 56)
	retry.add_theme_font_size_override("font_size", 24)
	retry.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	)
	add_child(retry)

	var menu := Button.new()
	menu.text = "МЕНЮ"
	menu.position = Vector2(680, 580)
	menu.size = Vector2(240, 56)
	menu.add_theme_font_size_override("font_size", 24)
	menu.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	add_child(menu)

	GameAudio.start_death()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _cause_text(cause: String) -> String:
	match cause:
		"hook":
			return "Крюк разорвал спину"
		"saw":
			return "Пила снизу"
		"corpse":
			return "Спотыкание о труп"
		"caught", "butcher":
			return "Бензопила сзади"
		"ambush":
			return "Мясник вышел из укрытия"
		"squeeze":
			return "Коридор сомкнулся"
		"gut_wall":
			return "Стена из кишок"
		_:
			return "Бухта забрала ещё одну жертву"
