extends Control
## 화면 위 정보: 경험치 바, 레벨, 체력, 남은 시간, 보스 체력, 알림 문구 (PRD #4-P0-5, #4-P0-6)

const BOLD := preload("res://assets/fonts/Galmuri11-Bold.ttf")
const GOLD := Color(0.69, 0.55, 0.23)
const CRIMSON := Color(0.77, 0.12, 0.18)
const PALE := Color(0.85, 0.8, 0.85)
const MUTED := Color(0.6, 0.56, 0.62)
const FRAME := Color(0.04, 0.03, 0.06)
const EMPTY := Color(0.1, 0.05, 0.08)
const BOSS_BAR_WIDTH := 240.0

var level := 1
var xp := 0
var xp_to_next := 1
var hp := 1.0
var max_hp := 1.0
var time_left := 180.0
## 보스가 있으면 남은 시간 대신 보스 이름과 체력바를 보여 준다.
## 문구는 Loc 키로 받아 그릴 때 현재 언어로 바꾼다.
var boss_name_key := ""
var boss_hp := 0.0
var boss_max_hp := 1.0
var banner_title_key := ""
var banner_sub_key := ""
var banner_alpha := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var font := get_theme_default_font()

	# 경험치 바: 화면 맨 위 전체 폭
	draw_rect(Rect2(0, 0, w, 5), FRAME)
	draw_rect(Rect2(1, 1, w - 2, 3), EMPTY)
	draw_rect(Rect2(1, 1, (w - 2) * clampf(float(xp) / xp_to_next, 0.0, 1.0), 3), GOLD)

	# 레벨과 체력
	draw_string(BOLD, Vector2(6, 19), "Lv %d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	_draw_bar(Rect2(44, 11, 90, 7), hp / max_hp, CRIMSON)
	draw_string(font, Vector2(140, 19), "%d / %d" % [ceili(hp), ceili(max_hp)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)

	if boss_name_key != "":
		draw_string(BOLD, Vector2(0, 19), Loc.t(boss_name_key), HORIZONTAL_ALIGNMENT_CENTER, w, 12, CRIMSON)
		_draw_bar(Rect2((w - BOSS_BAR_WIDTH) / 2.0, 24, BOSS_BAR_WIDTH, 7), boss_hp / boss_max_hp, CRIMSON.darkened(0.15))
	else:
		var secs := ceili(time_left)
		var clock := "%d:%02d" % [secs / 60, secs % 60]
		draw_string(BOLD, Vector2(0, 21), clock, HORIZONTAL_ALIGNMENT_CENTER, w, 12, PALE if secs > 30 else CRIMSON)

	if banner_alpha > 0.0 and banner_title_key != "":
		var y := 96.0
		draw_rect(Rect2(0, y - 22, w, 48), Color(0.03, 0.0, 0.02, 0.75 * banner_alpha))
		draw_string(BOLD, Vector2(0, y), Loc.t(banner_title_key), HORIZONTAL_ALIGNMENT_CENTER, w, 24, Color(GOLD, banner_alpha))
		draw_string(font, Vector2(0, y + 18), Loc.t(banner_sub_key), HORIZONTAL_ALIGNMENT_CENTER, w, 12, Color(CRIMSON, banner_alpha))


func _draw_bar(rect: Rect2, ratio: float, color: Color) -> void:
	draw_rect(rect, FRAME)
	draw_rect(rect.grow(-1), EMPTY)
	var fill := rect.grow(-1)
	fill.size.x *= clampf(ratio, 0.0, 1.0)
	draw_rect(fill, color)
