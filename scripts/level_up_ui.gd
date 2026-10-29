extends CanvasLayer
## 레벨업 선택창 (PRD #4-P0-4, #4-P1-5, #6)
## 화면이 핏빛으로 어두워지고, 고딕 장식 카드 3장이 하나씩 떨어진다.
## 고른 카드는 빛나며 피를 튀기고, 나머지 카드는 두 동강 나 떨어진다.
## 조작: 좌우 이동키 + 스페이스/엔터, 숫자키 1·2·3, 마우스

signal chosen(id: String)

const BOLD := preload("res://assets/fonts/Galmuri11-Bold.ttf")
const GOLD := Color(0.69, 0.55, 0.23)
const GOLD_DARK := Color(0.42, 0.33, 0.13)
const CRIMSON := Color(0.77, 0.12, 0.18)
const PALE := Color(0.85, 0.8, 0.85)
const MUTED := Color(0.6, 0.56, 0.62)
const DIM_COLOR := Color(0.12, 0.0, 0.03)
const DIM_ALPHA := 0.82
const CARD_SIZE := Vector2(150, 116)
const CARD_GAP := 14.0
## 카드 묶음(제목 포함)을 화면 세로 가운데에서 이만큼 아래에 둔다
const CARD_CENTER_OFFSET := 20.0
const TITLE_ABOVE_CARDS := 48.0
const HINT_ABOVE_CARDS := 26.0
const DROP_TIME := 0.35
const DROP_STAGGER := 0.12

const ICONS := {
	"claw_damage": [preload("res://assets/sprites/claw_slash.png"), Rect2(32, 0, 32, 32)],
	"claw_speed": [preload("res://assets/sprites/claw_slash.png"), Rect2(0, 0, 32, 32)],
	"claw_area": [preload("res://assets/sprites/claw_slash.png"), Rect2(32, 0, 32, 32)],
	"max_hp": [preload("res://assets/sprites/vampire.png"), Rect2(0, 0, 20, 28)],
	"move_speed": [preload("res://assets/sprites/vampire.png"), Rect2(40, 0, 20, 28)],
	"pickup": [preload("res://assets/sprites/blood_drop.png"), Rect2(0, 0, 5, 7)],
	"claw_count": [preload("res://assets/sprites/claw_slash.png"), Rect2(32, 0, 32, 32)],
	"claw_pierce": [preload("res://assets/sprites/claw_slash.png"), Rect2(64, 0, 32, 32)],
	"bats": [preload("res://assets/sprites/blood_bat.png"), Rect2(0, 0, 12, 10)],
	"spear": [preload("res://assets/sprites/blood_spear.png"), Rect2(0, 0, 20, 5)],
}

var _choices: Array = []
var _cards: Array[Card] = []
var _selected := 0
var _locked := true
var _dim: ColorRect
var _root: Control
var _title: Label
var _hint: Label
var _lang_button: Button


## 카드 앞면. 카드를 두 동강 낼 수 있도록 같은 그림을 왼쪽·오른쪽 반쪽에서 각각 그린다.
class Face extends Control:
	var upgrade: Dictionary
	var level := 0
	var index := 0
	var selected := false

	func _draw() -> void:
		var w := CARD_SIZE.x
		var h := CARD_SIZE.y
		var font := get_theme_default_font()
		draw_rect(Rect2(0, 0, w, h), Color(0.06, 0.03, 0.06))
		draw_rect(Rect2(0.5, 0.5, w - 1, h - 1), CRIMSON if selected else CRIMSON.darkened(0.5), false, 1.0)
		draw_rect(Rect2(3.5, 3.5, w - 7, h - 7), GOLD if selected else GOLD_DARK, false, 1.0)
		# 고딕풍 모서리 장식과 위쪽 마름모
		for c in [Vector2(3, 3), Vector2(w - 4, 3), Vector2(3, h - 4), Vector2(w - 4, h - 4)]:
			var sx := 1.0 if c.x < w / 2 else -1.0
			var sy := 1.0 if c.y < h / 2 else -1.0
			draw_rect(Rect2(c.x, c.y, 6 * sx, 2 * sy).abs(), GOLD)
			draw_rect(Rect2(c.x, c.y, 2 * sx, 6 * sy).abs(), GOLD)
		draw_colored_polygon(PackedVector2Array([Vector2(w / 2, 0), Vector2(w / 2 + 4, 4), Vector2(w / 2, 8), Vector2(w / 2 - 4, 4)]), GOLD if selected else GOLD_DARK)
		# 아이콘
		var box := Rect2(w / 2 - 14, 12, 28, 28)
		draw_rect(box, Color(0.02, 0.01, 0.02))
		draw_rect(box.grow(-0.5), CRIMSON.darkened(0.4), false, 1.0)
		_draw_icon(box.grow(-3))
		draw_string(font, Vector2(9, 22), "%d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
		draw_string(BOLD, Vector2(0, 56), Upgrades.display_name(upgrade), HORIZONTAL_ALIGNMENT_CENTER, w, 12, PALE if selected else PALE.darkened(0.15))
		draw_multiline_string(font, Vector2(8, 72), Upgrades.describe(upgrade, level), HORIZONTAL_ALIGNMENT_CENTER, w - 16, 12, 2, MUTED)
		var is_new: bool = upgrade.get("weapon", false) and level == 0
		draw_string(font, Vector2(0, h - 9), Loc.t("new_weapon") if is_new else "Lv %d → %d" % [level, level + 1], HORIZONTAL_ALIGNMENT_CENTER, w, 12, CRIMSON if is_new else GOLD)

	func _draw_icon(area: Rect2) -> void:
		if upgrade.id == "aura":
			draw_circle(area.get_center(), 9.0, Color(0.45, 0.02, 0.08))
			draw_arc(area.get_center(), 9.0, 0.0, TAU, 24, CRIMSON, 1.0)
			return
		var icon: Array = ICONS.get(upgrade.id, [])
		if icon.is_empty():
			return
		var src: Rect2 = icon[1]
		var scale := floorf(minf(area.size.x / src.size.x, area.size.y / src.size.y))
		scale = maxf(scale, 1.0)
		var size := src.size * scale
		draw_texture_rect_region(icon[0], Rect2((area.get_center() - size / 2.0).floor(), size), src)


## 카드 한 장: 왼쪽·오른쪽 반쪽(각자 잘려 보이는 앞면)으로 이루어진다.
class Card extends Control:
	var halves: Array[Control] = []
	var faces: Array[Face] = []

	func setup(upgrade: Dictionary, level: int, index: int) -> void:
		size = CARD_SIZE
		pivot_offset = CARD_SIZE / 2.0
		mouse_filter = Control.MOUSE_FILTER_STOP
		for side in 2:
			var half := Control.new()
			half.clip_contents = true
			half.mouse_filter = Control.MOUSE_FILTER_IGNORE
			half.position = Vector2(CARD_SIZE.x / 2.0 * side, 0)
			half.size = Vector2(CARD_SIZE.x / 2.0, CARD_SIZE.y)
			half.pivot_offset = half.size / 2.0
			var face := Face.new()
			face.upgrade = upgrade
			face.level = level
			face.index = index
			face.size = CARD_SIZE
			face.position = Vector2(-CARD_SIZE.x / 2.0 * side, 0)
			face.mouse_filter = Control.MOUSE_FILTER_IGNORE
			half.add_child(face)
			add_child(half)
			halves.append(half)
			faces.append(face)

	func set_selected(value: bool) -> void:
		for f in faces:
			f.selected = value
			f.queue_redraw()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(DIM_COLOR, 0.0)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_title = _label("", CRIMSON, BOLD, 24, 70)
	_hint = _label("", MUTED, null, 12, 92)

	# 오른쪽 위 언어 전환 버튼 (F1 키로도 바꾼다)
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
	_root.add_child(_lang_button)
	_apply_texts()


## 레벨업 직전, 느려지는 동안 화면을 핏빛으로 물들인다.
func show_dim(seconds: float) -> void:
	visible = true
	_title.visible = false
	_hint.visible = false
	_lang_button.visible = false
	_clear_cards()
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_dim, "color:a", DIM_ALPHA, seconds)


func open(choices: Array, levels: Dictionary) -> void:
	visible = true
	_dim.color.a = DIM_ALPHA
	_title.visible = true
	_hint.visible = true
	_lang_button.visible = true
	_apply_texts()
	_choices = choices
	_clear_cards()
	var total := CARD_SIZE.x * choices.size() + CARD_GAP * (choices.size() - 1)
	var left := (_root.size.x - total) / 2.0
	var card_top := floorf((_root.size.y - CARD_SIZE.y) / 2.0 + CARD_CENTER_OFFSET)
	_title.position.y = card_top - TITLE_ABOVE_CARDS - 24
	_hint.position.y = card_top - HINT_ABOVE_CARDS - 12
	for i in choices.size():
		var card := Card.new()
		card.setup(choices[i], levels.get(choices[i].id, 0), i)
		var target := Vector2(left + i * (CARD_SIZE.x + CARD_GAP), card_top)
		card.position = target - Vector2(0, 260)
		card.mouse_entered.connect(_select.bind(i))
		card.gui_input.connect(_on_card_input.bind(i))
		_root.add_child(card)
		_cards.append(card)
		var tw := create_tween().set_ignore_time_scale(true)
		tw.tween_interval(i * DROP_STAGGER)
		tw.tween_callback(Sfx.play.bind("card"))
		tw.tween_property(card, "position", target, DROP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_selected = 0
	_cards[0].set_selected(true)
	_locked = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _locked or _cards.is_empty():
		return
	if event.is_action_pressed("move_left"):
		_select(posmod(_selected - 1, _cards.size()))
	elif event.is_action_pressed("move_right"):
		_select(posmod(_selected + 1, _cards.size()))
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1:
				_toggle_language()
			KEY_1, KEY_KP_1:
				_confirm(0)
			KEY_2, KEY_KP_2:
				_confirm(1)
			KEY_3, KEY_KP_3:
				_confirm(2)
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
				_confirm(_selected)
		return
	else:
		return
	get_viewport().set_input_as_handled()


## 영어 ↔ 한국어. 이 화면의 문구와 카드를 바로 다시 그리고, 다른 화면은 다음에 보일 때 바뀐다.
func _toggle_language() -> void:
	Loc.toggle()
	_apply_texts()
	for c in _cards:
		for f in c.faces:
			f.queue_redraw()


func _apply_texts() -> void:
	_title.text = Loc.t("levelup_title")
	_hint.text = Loc.t("levelup_hint")
	_lang_button.text = Loc.t("lang_toggle")


func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_confirm(index)


func _select(index: int) -> void:
	if _locked or index >= _cards.size():
		return
	_cards[_selected].set_selected(false)
	_selected = index
	_cards[_selected].set_selected(true)


func _confirm(index: int) -> void:
	if _locked or index >= _cards.size():
		return
	_locked = true
	get_viewport().set_input_as_handled()
	_select_visual(index)
	Sfx.play("select")
	var picked: Card = _cards[index]
	var tw := create_tween().set_ignore_time_scale(true).set_parallel(true)
	tw.tween_property(picked, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(picked, "modulate", Color(1.6, 1.3, 1.3), 0.18)
	_spray_blood(picked.position + CARD_SIZE / 2.0)
	for i in _cards.size():
		if i != index:
			_shatter(_cards[i])
	await get_tree().create_timer(0.55, true, false, true).timeout
	var fade := create_tween().set_ignore_time_scale(true)
	fade.tween_property(_dim, "color:a", 0.0, 0.12)
	await fade.finished
	visible = false
	_clear_cards()
	chosen.emit(_choices[index].id)


func _select_visual(index: int) -> void:
	for i in _cards.size():
		_cards[i].set_selected(i == index)


## 선택받지 못한 카드는 두 동강 나 떨어지며 사라진다.
func _shatter(card: Card) -> void:
	for side in 2:
		var half: Control = card.halves[side]
		var dir := -1.0 if side == 0 else 1.0
		var tw := create_tween().set_ignore_time_scale(true).set_parallel(true)
		tw.tween_property(half, "position", half.position + Vector2(dir * randf_range(14, 26), randf_range(50, 80)), 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(half, "rotation", dir * randf_range(0.3, 0.6), 0.45)
		tw.tween_property(half, "modulate", Color(0.6, 0.1, 0.1, 0.0), 0.45)


func _spray_blood(center: Vector2) -> void:
	for i in 22:
		var drop := ColorRect.new()
		drop.size = Vector2(2, 2) if randf() < 0.6 else Vector2(3, 3)
		drop.color = CRIMSON.lerp(Color(0.35, 0.02, 0.05), randf())
		drop.position = center
		drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(drop)
		var out := Vector2.from_angle(randf() * TAU) * randf_range(30, 90)
		var tw := create_tween().set_ignore_time_scale(true)
		tw.tween_property(drop, "position", center + out, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(drop, "position", center + out + Vector2(0, randf_range(30, 60)), 0.3).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(drop, "modulate:a", 0.0, 0.3)
		tw.tween_callback(drop.queue_free)


func _clear_cards() -> void:
	for c in _cards:
		c.queue_free()
	_cards.clear()


func _label(text: String, color: Color, font: Font, font_size: int, y: float) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	if font:
		l.add_theme_font_override("font", font)
	l.set_anchors_preset(Control.PRESET_TOP_WIDE)
	l.position.y = y - font_size
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l
