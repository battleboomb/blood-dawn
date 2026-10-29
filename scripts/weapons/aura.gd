extends Node2D
## 무기 "혈무 오라": 뱀파이어 주변의 적을 피안개로 계속 태운다. (PRD #4-P1-2)
## 레벨마다 범위 +6, 피해 +2. 원은 캐릭터 몸 가운데를 중심으로 그리고, 캐릭터보다 아래 층에 깔린다.
## 오라 안에 들어온 적은 약 25% 느려진다 (EnemyManager.SLOW_FACTOR).

const TICK := 0.5
## 발 위치에서 몸 가운데까지 (주인공 그림 24x24, 발이 원점)
const BODY_CENTER := Vector2(0, -11)
const MIST_DOTS := 14
const FILL := Color(0.45, 0.02, 0.08, 0.16)
const EDGE := Color(0.75, 0.1, 0.15, 0.5)
const MIST := Color(0.8, 0.12, 0.18, 0.7)

var level := 0
var player: Node2D
var enemies: Node
var effects: Node2D
var _timer := TICK
var _time := 0.0


func level_up() -> void:
	level += 1


func _radius() -> float:
	return 38.0 + 6.0 * (level - 1)


func _process(delta: float) -> void:
	_time += delta
	global_position = (player.global_position + BODY_CENTER).floor()
	enemies.slow_center = global_position
	enemies.slow_radius = _radius()
	_timer -= delta
	if _timer <= 0.0:
		_timer = TICK
		var damage := 3.0 + 2.0 * (level - 1)
		for e in enemies.find_all_in_radius(global_position, _radius()):
			enemies.damage_enemy(e, damage)
	queue_redraw()


func _draw() -> void:
	var r := _radius()
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	draw_circle(Vector2.ZERO, r, Color(FILL, FILL.a + 0.06 * pulse))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, EDGE, 1.0)
	# 안쪽에서 맴도는 피안개 점
	for i in MIST_DOTS:
		var a := _time * 0.6 + TAU * i / MIST_DOTS
		var d := r * (0.3 + 0.65 * fmod(i * 0.37 + _time * 0.25, 1.0))
		draw_rect(Rect2((Vector2.from_angle(a) * d).floor(), Vector2.ONE), MIST)
