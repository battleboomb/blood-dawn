extends CanvasLayer
## ESC 일시정지 화면 (PRD #4-P1-6)

const BOLD := preload("res://assets/fonts/Galmuri11-Bold.ttf")
const GOLD := Color(0.69, 0.55, 0.23)
const MUTED := Color(0.6, 0.56, 0.62)

## 일시정지해도 되는지 알려 주는 함수 (레벨업 중이나 결과 화면에서는 막는다)
var can_pause: Callable
var _title: Label
var _hint: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.0, 0.02, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	center.add_child(column)
	_title = _label("", GOLD, BOLD, 24)
	_hint = _label("", MUTED, null, 12)
	column.add_child(_title)
	column.add_child(_hint)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_ESCAPE:
		if visible:
			visible = false
			get_tree().paused = false
		elif can_pause.is_valid() and can_pause.call():
			_title.text = Loc.t("paused")
			_hint.text = Loc.t("pause_hint")
			visible = true
			get_tree().paused = true
		get_viewport().set_input_as_handled()
	elif visible and event.physical_keycode == KEY_R:
		get_tree().paused = false
		get_tree().reload_current_scene()


func _label(text: String, color: Color, font: Font, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	if font:
		l.add_theme_font_override("font", font)
	return l
