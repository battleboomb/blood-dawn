extends Node2D
## 바닥에 남는 핏자국 (PRD #4-P1-4, #6). 캐릭터보다 아래에 그리고, 일정 시간이 지나면 흐려지며 사라진다.
## 바닥에 떨어진 시체 조각도 이 노드의 자식으로 옮겨져 캐릭터 아래에 깔린다.

const MAX_STAINS := 600
const LIFETIME := 10.0
const FADE := 2.5

var _pos := PackedVector2Array()
var _size := PackedFloat32Array()
var _age := PackedFloat32Array()
var _color := PackedColorArray()


func add_stain(p: Vector2, size: float, color: Color) -> void:
	if _pos.size() >= MAX_STAINS:
		_remove_oldest()
	_pos.append(p.floor())
	_size.append(size)
	_age.append(0.0)
	_color.append(color)


## 반지름 r 안에 핏자국 여러 개를 뿌려 웅덩이를 만든다.
func add_pool(center: Vector2, r: float, count: int) -> void:
	for i in count:
		var p := center + Vector2.from_angle(randf() * TAU) * randf() * r * Vector2(1.0, 0.6)
		add_stain(p, randf_range(1.0, 3.0), Color(0.35, 0.02, 0.05).lerp(Color(0.55, 0.04, 0.08), randf()))


func _process(delta: float) -> void:
	for i in _age.size():
		_age[i] += delta
	while _age.size() > 0 and _age[0] >= LIFETIME:
		_remove_oldest()
	queue_redraw()


func _draw() -> void:
	for i in _pos.size():
		var a := clampf((LIFETIME - _age[i]) / FADE, 0.0, 1.0) * 0.9
		draw_rect(Rect2(_pos[i], Vector2(_size[i], _size[i] * 0.7).ceil()), Color(_color[i], a))


func _remove_oldest() -> void:
	_pos.remove_at(0)
	_size.remove_at(0)
	_age.remove_at(0)
	_color.remove_at(0)
