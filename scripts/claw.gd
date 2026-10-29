extends Node2D
## 기본 무기 "핏빛 발톱": 가장 가까운 적을 향해 손톱 모양 발톱 자국을 날린다. (PRD #4-P0-2)
## 발톱 자국은 날아가며 적을 몇 마리까지 꿰뚫고, 같은 적은 두 번 맞히지 않는다.
## 개수 강화를 받으면 한 번에 여러 줄기가 부채꼴로 날아간다.

const SHOT_TEX := preload("res://assets/sprites/claw_slash.png")
const SEARCH_RANGE := 190.0
const SPEED := 240.0
const LIFETIME := 0.8      # 날아가는 거리 = SPEED * LIFETIME
const BASE_RADIUS := 7.0   # 맞는 범위 (크기 배율이 곱해진다)
const BASE_SCALE := 0.75
const SPREAD := 0.22       # 여러 줄기일 때 사이 각도(라디안)
const BODY_HEIGHT := 8.0   # 발 위치가 아니라 몸통 높이에서 날아간다
const KNOCKBACK := 90.0

# 강화로 바뀌는 값
var damage := 10.0
var cooldown := 0.9
var area := 1.0
var count := 1    # 한 번에 날리는 발톱 수
var pierce := 2   # 한 발이 맞힐 수 있는 적 수

var enemies: Node  # EnemyManager
var effects: Node2D
var _timer := 0.3
var _shots: Array[Shot] = []


class Shot extends Sprite2D:
	var velocity := Vector2.ZERO
	var life := 0.0
	var hits_left := 0
	var hit: Array[Enemy] = []
	## 판정은 발 높이(적 위치 기준)에서 한다.
	var ground := Vector2.ZERO


func _process(delta: float) -> void:
	_move_shots(delta)
	_timer -= delta
	if _timer > 0.0 or enemies == null:
		return
	var target: Enemy = enemies.get_nearest(global_position, SEARCH_RANGE)
	if target == null:
		return
	_timer = cooldown
	var aim := (target.position - global_position).angle()
	for i in count:
		_fire(Vector2.from_angle(aim + (i - (count - 1) / 2.0) * SPREAD))
	Sfx.play("attack", -4.0)


func _fire(dir: Vector2) -> void:
	var s := Shot.new()
	s.texture = SHOT_TEX
	s.hframes = 3
	s.frame = 1
	s.rotation = dir.angle()
	s.scale = Vector2.ONE * BASE_SCALE * area
	s.velocity = dir * SPEED
	s.life = LIFETIME
	s.hits_left = pierce
	s.ground = global_position
	s.position = s.ground - Vector2(0, BODY_HEIGHT)
	effects.add_child(s)
	_shots.append(s)


func _move_shots(delta: float) -> void:
	var radius := BASE_RADIUS * area
	for i in range(_shots.size() - 1, -1, -1):
		var s := _shots[i]
		s.life -= delta
		s.ground += s.velocity * delta
		s.position = s.ground - Vector2(0, BODY_HEIGHT)
		if s.life < 0.15:
			s.frame = 2  # 사라지기 직전에는 흐려진 그림
		var e: Enemy = enemies.find_overlap(s.ground, radius, s.hit)
		if e != null:
			s.hit.append(e)
			s.hits_left -= 1
			enemies.damage_enemy(e, damage, s.velocity.normalized() * KNOCKBACK)
			Sfx.play("hit", -6.0)
		if s.life <= 0.0 or s.hits_left <= 0:
			_shots.remove_at(i)
			s.queue_free()
