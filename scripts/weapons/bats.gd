extends Node2D
## 무기 "박쥐 떼": 몸 주위를 도는 박쥐가 닿는 적을 물어뜯는다. (PRD #4-P1-2)
## 레벨마다 박쥐 +1, 피해 +2

const TEX := preload("res://assets/sprites/blood_bat.png")
const ORBIT_RADIUS := 54.0   # 몸 가운데를 중심으로 도는 정원 궤도
const ORBIT_SPEED := 2.8     # 초당 라디안
## 발 위치에서 몸 가운데까지. 박쥐는 몸 높이에서 돌고, 물기 판정은 그 아래 발 높이에서 한다.
const BODY_CENTER := Vector2(0, -11)
const HIT_RADIUS := 7.0
const HIT_INTERVAL := 0.5    # 같은 적을 다시 물기까지 걸리는 시간
const FLAP_FPS := 10.0

var level := 0
var player: Node2D
var enemies: Node
var effects: Node2D
var _angle := 0.0
var _time := 0.0
var _bats: Array[Sprite2D] = []
var _last_hit := {}  # 적 instance id -> 마지막으로 문 시간


func level_up() -> void:
	level += 1
	while _bats.size() < 1 + level:
		var b := Sprite2D.new()
		b.texture = TEX
		b.hframes = 2
		effects.add_child(b)
		_bats.append(b)


func _process(delta: float) -> void:
	_time += delta
	_angle = fmod(_angle + ORBIT_SPEED * delta, TAU)
	var damage := 6.0 + 2.0 * level
	var center := player.global_position
	for i in _bats.size():
		var a := _angle + TAU * i / _bats.size()
		var ground := center + Vector2.from_angle(a) * ORBIT_RADIUS
		var b := _bats[i]
		b.position = ground + BODY_CENTER
		b.frame = int(_time * FLAP_FPS + i) % 2
		b.flip_h = sin(a) > 0.0  # 도는 방향을 향한다
		for e in enemies.find_all_in_radius(ground, HIT_RADIUS):
			var id: int = e.get_instance_id()
			if _time - _last_hit.get(id, -INF) >= HIT_INTERVAL:
				_last_hit[id] = _time
				enemies.damage_enemy(e, damage, (e.position - center).normalized() * 60.0)
	if _last_hit.size() > 600:
		_last_hit.clear()
