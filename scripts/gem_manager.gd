extends Node2D
## 바닥에 떨어진 아이템: 핏방울(경험치)과 회복용 고기. (PRD #4-P0-4)
## 가까이 가면 끌려와 주워진다. 핏방울은 처치한 적과 깨진 램프가, 고기는 깨진 램프가 떨어뜨린다.

signal collected(xp: int)
signal meat_collected

const TEX := preload("res://assets/sprites/blood_drop.png")
const MEAT_TEX := preload("res://assets/sprites/meat.png")
const MAX_GEMS := 500       # 넘으면 새로 만들지 않고 기존 핏방울에 값을 더한다
const PULL_ACCEL := 600.0
const PULL_MAX_SPEED := 260.0
const COLLECT_DIST := 6.0


class Gem extends Sprite2D:
	var xp := 1
	var meat := false
	var pulled := false
	var speed := 40.0


var player: Node2D
var _gems: Array[Gem] = []


func drop(pos: Vector2, xp: int) -> void:
	if _gems.size() >= MAX_GEMS:
		var existing: Gem = _gems.pick_random()
		existing.xp += xp
		return
	var g := Gem.new()
	g.texture = TEX
	g.xp = xp
	if xp >= 3:
		g.scale = Vector2(1.5, 1.5)  # 단단한 적·램프의 큰 핏방울
	_add(g, pos)


func drop_meat(pos: Vector2) -> void:
	var g := Gem.new()
	g.texture = MEAT_TEX
	g.xp = 0
	g.meat = true
	g.offset = Vector2(0, -4)
	_add(g, pos)


func _add(g: Gem, pos: Vector2) -> void:
	g.position = pos + Vector2(randf_range(-3, 3), randf_range(-3, 3))
	add_child(g)
	_gems.append(g)


func _process(delta: float) -> void:
	if player == null:
		return
	var target := player.global_position
	for i in range(_gems.size() - 1, -1, -1):
		var g := _gems[i]
		var to := target - g.position
		var d := to.length()
		if not g.pulled and d < player.pickup_radius:
			g.pulled = true
		if not g.pulled:
			continue
		if d < COLLECT_DIST:
			_gems.remove_at(i)
			if g.meat:
				meat_collected.emit()
			else:
				collected.emit(g.xp)
			g.queue_free()
			continue
		g.speed = minf(g.speed + PULL_ACCEL * delta, PULL_MAX_SPEED)
		g.position += to / d * minf(g.speed * delta, d)
