extends Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.03, 0.035)
	add_child(bg)

	var saw := TextureRect.new()
	saw.texture = load("res://assets/sprites/ui/logo_saw.png")
	saw.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	saw.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	saw.position = Vector2(520, 40)
	saw.size = Vector2(240, 240)
	add_child(saw)

	var title := Label.new()
	title.text = "BUTCHER BAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(140, 250)
	title.size = Vector2(1000, 80)
	title.add_theme_font_size_override("font_size", 64)
	title.modulate = Color(0.86, 0.16, 0.18)
	add_child(title)

	var sub := Label.new()
	sub.text = "Бухта мясника"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(140, 320)
	sub.size = Vector2(1000, 40)
	sub.add_theme_font_size_override("font_size", 24)
	sub.modulate = Color(0.78, 0.7, 0.62)
	add_child(sub)

	var rec := Label.new()
	rec.text = "Рекорд: %d м" % GameState.best_score
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rec.position = Vector2(140, 370)
	rec.size = Vector2(1000, 40)
	rec.add_theme_font_size_override("font_size", 22)
	add_child(rec)

	var play := Button.new()
	play.text = "ИГРАТЬ"
	play.position = Vector2(490, 440)
	play.size = Vector2(300, 64)
	play.add_theme_font_size_override("font_size", 28)
	play.pressed.connect(_on_play)
	add_child(play)

	var help := Label.new()
	help.text = "Жертва в подвале. Беги вперёд. Три полосы, прыжок, подкат.\nМясник догонит, если замешкаешься."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.position = Vector2(140, 530)
	help.size = Vector2(1000, 80)
	help.add_theme_font_size_override("font_size", 18)
	help.modulate = Color(0.7, 0.62, 0.58)
	add_child(help)

	var drone := AudioStreamPlayer.new()
	drone.stream = load("res://assets/audio/music_drone.wav")
	drone.autoplay = true
	add_child(drone)


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		_on_play()
