extends Node2D
## 무기 "피의 창": 가장 단단한 적(보스 우선)에게 모든 적을 꿰뚫는 창을 던진다. (PRD #4-P1-2)
## 레벨마다 피해 +8, 더 자주 던지고, 3·5레벨에 창이 하나씩 늘어난다.

const TEX := preload("res://assets/sprites/blood_spear.png")
const SEARCH_RANGE := 220.0
const SPEED := 300.0
const LIFETIME := 1.0
const HIT_RADIUS := 6.0
const SPREAD := 0.18         # 창이 여러 개일 때 사이 각도
const BODY_HEIGHT := 8.0

var level := 0
var player: Node2D
var enemies: Node
var effects: Node2D
var _timer := 0.5
var _spears: Array[Spear] = []


class Spear extends Sprite2D:
	var velocity := Vector2.ZERO
	var life := 0.0
	var ground := Vector2.ZERO
	var hit: Array[Enemy] = []


func level_up() -> void:
	level += 1


func _process(delta: float) -> void:
	_move_spears(delta)
	_timer -= delta
	if _timer > 0.0:
		return
	var from := player.global_position
	var target: Enemy = enemies.boss if enemies.boss != null and from.distance_to(enemies.boss.position) < SEARCH_RANGE else enemies.get_toughest(from, SEARCH_RANGE)
	if target == null:
		return
	_timer = 2.2 - 0.15 * (level - 1)
	var count := 1 + int(level >= 3) + int(level >= 5)
	var aim := (target.position - from).angle()
	for i in count:
		_throw(from, aim + (i - (count - 1) / 2.0) * SPREAD)


func _throw(from: Vector2, angle: float) -> void:
	var s := Spear.new()
	s.texture = TEX
	s.rotation = angle
	s.velocity = Vector2.from_angle(angle) * SPEED
	s.life = LIFETIME
	s.ground = from
	s.position = from - Vector2(0, BODY_HEIGHT)
	effects.add_child(s)
	_spears.append(s)


func _move_spears(delta: float) -> void:
	var damage := 25.0 + 8.0 * (level - 1)
	for i in range(_spears.size() - 1, -1, -1):
		var s := _spears[i]
		s.life -= delta
		s.ground += s.velocity * delta
		s.position = s.ground - Vector2(0, BODY_HEIGHT)
		for e in enemies.find_all_in_radius(s.ground, HIT_RADIUS):
			if not s.hit.has(e):
				s.hit.append(e)
				enemies.damage_enemy(e, damage, s.velocity.normalized() * 140.0)
				Sfx.play("hit", -6.0, 0.2)
		if s.life <= 0.0:
			_spears.remove_at(i)
			s.queue_free()
