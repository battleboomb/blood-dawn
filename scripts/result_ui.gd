extends CanvasLayer
## 승리/패배 결과 화면과 재시작 (PRD #4-P0-6)

const BOLD := preload("res://assets/fonts/Galmuri11-Bold.ttf")
const GOLD := Color(0.69, 0.55, 0.23)
const CRIMSON := Color(0.77, 0.12, 0.18)
const PALE := Color(0.85, 0.8, 0.85)
const MUTED := Color(0.6, 0.56, 0.62)

var _title: Label
var _sub: Label
var _stats: Label
var _hint: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.0, 0.02, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)
	_title = _label(BOLD, 24)
	_sub = _label(null, 12)
	_stats = _label(null, 12)
	_stats.add_theme_color_override("font_color", PALE)
	column.add_child(_title)
	column.add_child(_sub)
	column.add_child(_stats)
	_hint = _label(null, 12)
	_hint.add_theme_color_override("font_color", GOLD)
	column.add_child(_hint)


func show_result(won: bool, survived: float, boss_time: float, level: int, kills: int) -> void:
	_title.text = Loc.t("result_won" if won else "result_lost")
	_title.add_theme_color_override("font_color", GOLD if won else CRIMSON)
	_sub.text = Loc.t("result_won_sub" if won else "result_lost_sub")
	_sub.add_theme_color_override("font_color", MUTED)
	var lines := [Loc.t("stat_survived") % _clock(survived)]
	if boss_time > 0.0:
		lines.append(Loc.t("stat_boss") % _clock(boss_time))
	lines.append(Loc.t("stat_level") % level)
	lines.append(Loc.t("stat_kills") % kills)
	_stats.text = "\n".join(lines)
	_hint.text = Loc.t("restart_hint")
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_tree().paused = false
		get_tree().reload_current_scene()


func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func _label(font: Font, font_size: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	return l
