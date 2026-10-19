extends CanvasLayer

@onready var score_label: Label
@onready var chase_fill: ColorRect
@onready var banner: Label
@onready var buffs: Label
@onready var hint: Label

var _banner_time: float = 0.0
var _vignette: TextureRect
var _flash_rect: ColorRect


func _ready() -> void:
	layer = 20
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_vignette = TextureRect.new()
	_vignette.texture = load("res://assets/sprites/ui/vignette.png")
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(_vignette)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(0.85, 0.12, 0.1, 0.0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash_rect)

	score_label = Label.new()
	score_label.position = Vector2(36, 24)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.text = "0 м"
	root.add_child(score_label)

	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(36, 64)
	bar_bg.size = Vector2(280, 16)
	bar_bg.color = Color(0.08, 0.04, 0.04, 0.9)
	root.add_child(bar_bg)

	chase_fill = ColorRect.new()
	chase_fill.position = Vector2(38, 66)
	chase_fill.size = Vector2(276, 12)
	chase_fill.color = Color(0.75, 0.12, 0.14)
	root.add_child(chase_fill)

	var chase_caption := Label.new()
	chase_caption.position = Vector2(36, 82)
	chase_caption.text = "МЯСНИК"
	chase_caption.add_theme_font_size_override("font_size", 14)
	root.add_child(chase_caption)

	buffs = Label.new()
	buffs.position = Vector2(36, 108)
	buffs.add_theme_font_size_override("font_size", 18)
	root.add_child(buffs)

	banner = Label.new()
	banner.position = Vector2(340, 80)
	banner.size = Vector2(600, 80)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 36)
	banner.modulate = Color(1, 0.85, 0.7)
	root.add_child(banner)

	var hint_bg := ColorRect.new()
	hint_bg.position = Vector2(24, 672)
	hint_bg.size = Vector2(1232, 36)
	hint_bg.color = Color(0.02, 0.01, 0.01, 0.72)
	root.add_child(hint_bg)
	hint = Label.new()
	hint.position = Vector2(36, 676)
	hint.size = Vector2(1200, 28)
	hint.text = "Свайп / A-D: полоса    W или пробел: прыжок / вентиляция    S: подкат"
	hint.add_theme_font_size_override("font_size", 16)
	hint.modulate = Color(1, 1, 1, 0.85)
	root.add_child(hint)


func _process(delta: float) -> void:
	if _banner_time > 0.0:
		_banner_time -= delta
		if _banner_time <= 0.0:
			banner.text = ""


func set_score(meters: int) -> void:
	score_label.text = "%d м" % meters


func set_chase(distance: float) -> void:
	var t := clampf(distance / 100.0, 0.0, 1.0)
	chase_fill.size.x = 276.0 * t
	chase_fill.color = Color(0.85, 0.12, 0.12).lerp(Color(0.2, 0.7, 0.35), t)


func set_buffs(shielded: bool, boosting: bool, slowed: bool) -> void:
	var parts: PackedStringArray = []
	if shielded:
		parts.append("ЩИТ")
	if boosting:
		parts.append("УСКОРЕНИЕ")
	if slowed:
		parts.append("ЗАМЕДЛЕНИЕ")
	buffs.text = "  ".join(parts)


func flash(text: String, time: float = 1.2) -> void:
	banner.text = text
	_banner_time = time


func set_vignette(threat: float) -> void:
	if _vignette:
		_vignette.modulate.a = clampf(threat, 0.0, 1.0) * 0.85


func set_flash(amount: float) -> void:
	if _flash_rect:
		_flash_rect.color.a = clampf(amount, 0.0, 1.0) * 0.45
