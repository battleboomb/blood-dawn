extends Control
## 첫 화면: 배너, START 버튼, 조작 안내, 오른쪽 위 언어 전환(F1)
## START(클릭·스페이스·엔터)를 누르면 게임 장면으로 넘어간다.
##
## 게임은 640x400으로 그려 2배로 키우지만(도트용), 배너(1280x800)는 원본 해상도 그대로 보여야 하므로
## 이 화면에 있는 동안만 창 해상도로 그리는 방식(canvas_items)으로 바꾸고, 나갈 때 되돌린다.

const BANNER := preload("res://assets/imgs/banner/banner2.png")
const GAME_SCENE := "res://scenes/main.tscn"
const BOLD := preload("res://assets/fonts/Galmuri11-Bold.ttf")
const GOLD := Color(0.69, 0.55, 0.23)
const CRIMSON := Color(0.77, 0.12, 0.18)
const PALE := Color(0.85, 0.8, 0.85)
const MUTED := Color(0.6, 0.56, 0.62)
## 배너 양옆 여백을 채우는 색 (배너의 어두운 붉은 하늘과 비슷하게)
const BACKDROP := Color(0.09, 0.0, 0.02)
const START_SIZE := Vector2(120, 26)
const START_BOTTOM := 62.0   # 화면 아래에서 START 버튼 아래쪽까지
const LINE_HEIGHT := 16.0
const SHADE_HEIGHT := 96.0   # 바닥 그라데이션 높이 (제목 글자 아래 흘러내리는 부분부터)

var _start: Button
var _controls_move: Label
var _controls_pick: Label
var _goal: Label
var _lang_button: Button
var _starting := false
var _time := 0.0


func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	# 배너는 화면과 같은 16:10이라 화면을 꽉 채운다 (창이 1280x800이면 픽셀이 1:1로 맞는다)
	var banner := TextureRect.new()
	banner.texture = BANNER
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(banner)

	# 아래쪽 글씨가 잘 읽히도록 바닥으로 갈수록 서서히 어둡게 (제목 글자는 가리지 않는다)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.8)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	var shade := TextureRect.new()
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	shade.offset_top = -SHADE_HEIGHT
	add_child(shade)

	_start = Button.new()
	_start.focus_mode = Control.FOCUS_NONE
	_start.add_theme_font_override("font", BOLD)
	_start.add_theme_font_size_override("font_size", 12)
	_start.add_theme_color_override("font_color", PALE)
	_start.add_theme_color_override("font_hover_color", Color.WHITE)
	_start.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.02, 0.05, 0.9), CRIMSON.darkened(0.2)))
	_start.add_theme_stylebox_override("hover", _button_style(Color(0.3, 0.03, 0.08, 0.95), CRIMSON.lightened(0.2)))
	_start.add_theme_stylebox_override("pressed", _button_style(Color(0.45, 0.05, 0.1, 1.0), GOLD))
	_start.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_start.size = START_SIZE
	_start.position = Vector2(-START_SIZE.x / 2.0, -START_BOTTOM - START_SIZE.y)
	_start.pivot_offset = START_SIZE / 2.0
	_start.pressed.connect(_start_game)
	add_child(_start)

	# START 아래 조작 안내 3줄
	_controls_move = _bottom_label(PALE.darkened(0.15), 3)
	_controls_pick = _bottom_label(PALE.darkened(0.15), 2)
	_goal = _bottom_label(MUTED, 1)

	_lang_button = Button.new()
	_lang_button.flat = true
	_lang_button.focus_mode = Control.FOCUS_NONE
	_lang_button.add_theme_color_override("font_color", GOLD)
	_lang_button.add_theme_color_override("font_hover_color", PALE)
	_lang_button.add_theme_font_override("font", BOLD)
	_lang_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lang_button.position = Vector2(-72, 6)
	_lang_button.size = Vector2(64, 18)
	_lang_button.pressed.connect(_toggle_language)
	add_child(_lang_button)

	_apply_texts()


func _exit_tree() -> void:
	# 게임 화면은 다시 640x400 도트 해상도로 그린다
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT


func _process(delta: float) -> void:
	# START 버튼이 은은하게 숨 쉬듯 밝아졌다 어두워진다
	_time += delta
	_start.modulate = Color(1, 1, 1, 0.8 + 0.2 * sin(_time * 3.0))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_F1:
			_toggle_language()
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			_start_game()


func _start_game() -> void:
	if _starting:
		return
	_starting = true
	Sfx.play("select", 0.0, 0.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.BLACK, 0.35)
	tw.tween_callback(func(): get_tree().change_scene_to_file(GAME_SCENE))


func _toggle_language() -> void:
	Loc.toggle()
	_apply_texts()


func _apply_texts() -> void:
	_start.text = Loc.t("start")
	_controls_move.text = Loc.t("controls_move")
	_controls_pick.text = Loc.t("controls_pick")
	_goal.text = Loc.t("controls_goal")
	_lang_button.text = Loc.t("lang_toggle")


## 화면 아래에서 lines_from_bottom 번째 줄에 놓이는 가운데 정렬 글줄
func _bottom_label(color: Color, lines_from_bottom: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_top = -4.0 - LINE_HEIGHT * lines_from_bottom
	l.offset_bottom = l.offset_top + LINE_HEIGHT
	add_child(l)
	return l


func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_content_margin_all(4)
	return s
