extends Node2D
## 잔혹 연출 (PRD #4-P1-4, #4-P1-1, #6): 피 분출, 몸이 두 동강 나는 사망 연출, 보스의 거대한 피 폭발.
## 피 방울은 높이(z)를 가지고 날다가 바닥에 닿으면 핏자국(blood_floor)이 된다.

const GRAVITY := 380.0
const MAX_DROPS := 900
const MAX_PIECES := 90
const PIECE_REST := 3.0   # 바닥에 떨어진 조각이 남아 있는 시간
const PIECE_FADE := 1.0
const DROP_COLORS := [Color("8f1020"), Color("c41e2e"), Color("5c0d18")]
const CHUNK_TEX := preload("res://assets/sprites/corpse_chunk.png")

var floor_layer: Node2D  # blood_floor.gd

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _z := PackedFloat32Array()
var _vz := PackedFloat32Array()
var _size := PackedFloat32Array()
var _color := PackedColorArray()
var _pieces: Array[Piece] = []


class Piece extends Sprite2D:
	var ground := Vector2.ZERO
	var velocity := Vector2.ZERO
	var z := 0.0
	var vz := 0.0
	var spin := 0.0
	var rest := -1.0  # 바닥에 닿은 뒤 지난 시간. 날고 있으면 음수


## 피 분출: 맞은 방향(dir)으로 피 방울이 튄다. colors를 주면 그 색의 파편(예: 깨진 램프의 불똥)이 된다.
func spurt(at: Vector2, dir: Vector2, count: int, power := 1.0, height := 8.0, colors: Array = DROP_COLORS) -> void:
	for i in count:
		if _pos.size() >= MAX_DROPS:
			return
		var d := dir.rotated(randf_range(-0.7, 0.7)) if dir != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
		_pos.append(at)
		_vel.append(d * randf_range(25.0, 90.0) * power)
		_z.append(height)
		_vz.append(randf_range(30.0, 110.0) * power)
		_size.append(randf_range(1.0, 2.0))
		_color.append(colors.pick_random())


## 일반 적 사망: 몸이 위아래 두 동강 나 날아가고 피가 터진다.
func kill_effect(e: Enemy, dir: Vector2) -> void:
	var tex := e.texture
	var w := tex.get_width() / e.hframes
	var h := tex.get_height()
	var center_height := -e.offset.y
	var half := h / 2
	var away := dir if dir != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
	_add_piece(tex, Rect2(e.frame * w, 0, w, half), e.position, center_height + h / 4.0, away * randf_range(40, 70) + Vector2(randf_range(-15, 15), 0), randf_range(70, 110), e.flip_h)
	_add_piece(tex, Rect2(e.frame * w, half, w, h - half), e.position, center_height - h / 4.0, away * randf_range(5, 20), randf_range(10, 30), e.flip_h)
	spurt(e.position, away, 14, 1.0, center_height)
	floor_layer.add_pool(e.position, 5.0, 8)


## 보스 사망: 몸이 네 조각으로 찢어지고 피와 살덩이가 사방으로 터진다.
func boss_explosion(e: Enemy) -> void:
	var tex := e.texture
	var w := tex.get_width() / e.hframes
	var h := tex.get_height()
	var center_height := -e.offset.y
	for q in 4:
		var qx := q % 2
		var qy := q / 2
		var region := Rect2(e.frame * w + qx * w / 2, qy * h / 2, w / 2, h / 2)
		var dir := Vector2(-1.0 if qx == 0 else 1.0, -0.4 if qy == 0 else 0.4).normalized()
		_add_piece(tex, region, e.position + dir * 8.0, center_height + (h / 4.0 if qy == 0 else -h / 4.0), dir * randf_range(50, 90), randf_range(80, 140), false)
	for i in 14:
		var d := Vector2.from_angle(randf() * TAU)
		_add_piece(CHUNK_TEX, Rect2(0, 0, 8, 8), e.position, center_height, d * randf_range(60, 160), randf_range(100, 220), randf() < 0.5)
	spurt(e.position, Vector2.ZERO, 260, 2.2, center_height)
	floor_layer.add_pool(e.position, 40.0, 160)


func _add_piece(tex: Texture2D, region: Rect2, ground: Vector2, z: float, velocity: Vector2, vz: float, flip: bool) -> void:
	if _pieces.size() >= MAX_PIECES:
		var old: Piece = _pieces.pop_front()
		old.queue_free()
	var p := Piece.new()
	p.texture = tex
	p.region_enabled = true
	p.region_rect = region
	p.flip_h = flip
	p.ground = ground
	p.z = z
	p.vz = vz
	p.velocity = velocity
	p.spin = randf_range(-9.0, 9.0)
	p.position = ground - Vector2(0, z)
	add_child(p)
	_pieces.append(p)


func _process(delta: float) -> void:
	_update_drops(delta)
	_update_pieces(delta)
	queue_redraw()


func _update_drops(delta: float) -> void:
	var i := _pos.size() - 1
	while i >= 0:
		_vz[i] -= GRAVITY * delta
		_z[i] += _vz[i] * delta
		_pos[i] += _vel[i] * delta
		if _z[i] <= 0.0:
			floor_layer.add_stain(_pos[i], _size[i] + 0.5, _color[i].darkened(0.25))
			_remove_drop(i)
		i -= 1


func _remove_drop(i: int) -> void:
	# 순서는 상관없으므로 마지막 것과 바꿔 빠르게 지운다.
	var last := _pos.size() - 1
	_pos[i] = _pos[last]
	_vel[i] = _vel[last]
	_z[i] = _z[last]
	_vz[i] = _vz[last]
	_size[i] = _size[last]
	_color[i] = _color[last]
	_pos.resize(last)
	_vel.resize(last)
	_z.resize(last)
	_vz.resize(last)
	_size.resize(last)
	_color.resize(last)


func _update_pieces(delta: float) -> void:
	for i in range(_pieces.size() - 1, -1, -1):
		var p := _pieces[i]
		if p.rest < 0.0:
			p.vz -= GRAVITY * delta
			p.z += p.vz * delta
			p.ground += p.velocity * delta
			p.rotation += p.spin * delta
			if p.z <= 0.0:
				# 바닥에 떨어졌다: 핏자국을 남기고 캐릭터 아래 층으로 옮긴다.
				p.z = 0.0
				p.rest = 0.0
				floor_layer.add_pool(p.ground, 3.0, 4)
				p.reparent(floor_layer)
			p.position = (p.ground - Vector2(0, p.z)) if p.rest < 0.0 else p.ground
			continue
		p.rest += delta
		if p.rest > PIECE_REST:
			p.modulate.a = 1.0 - (p.rest - PIECE_REST) / PIECE_FADE
			if p.modulate.a <= 0.0:
				_pieces.remove_at(i)
				p.queue_free()


func _draw() -> void:
	for i in _pos.size():
		draw_rect(Rect2((_pos[i] - Vector2(0, _z[i])).floor(), Vector2(_size[i], _size[i]).ceil()), _color[i])
