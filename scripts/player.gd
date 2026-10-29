extends Node2D
## 뱀파이어: 8방향 이동, 체력과 피격 (PRD #4-P0-1, #4-P0-3)

signal hp_changed(hp: float, max_hp: float)
signal hurt(amount: float)
signal died

@export var max_speed := 90.0
## 가속과 감속을 일부러 낮춰 묵직하게 움직인다.
@export var acceleration := 700.0
@export var friction := 900.0
@export var max_hp := 100.0
## 핏방울이 끌려오기 시작하는 거리
@export var pickup_radius := 36.0

## 한 번 맞은 뒤 연속으로 맞지 않는 시간
const HURT_IFRAMES := 0.5
const HURT_FLASH := 0.1

var velocity := Vector2.ZERO
var hp := 0.0
var _iframes := 0.0
## 바라보는 방향: south / north / west / east. 멈춰도 마지막 방향을 유지한다.
var _facing := "south"

## 방향별 idle_<방향>(4프레임)/walk_<방향>(6프레임) 애니메이션은 scenes/player.tscn의 SpriteFrames에 들어 있다
## (assets/imgs/hero/alucard/alucard_sheet.png, 24x24 칸, tools/gen_hero_frames.gd 가 만든다).
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	hp = max_hp
	$Light.texture = LightTex.get_texture()


func _process(delta: float) -> void:
	# get_vector는 대각선 입력을 길이 1로 맞춰 주므로 대각선이 더 빠르지 않다.
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		velocity = velocity.move_toward(input * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	position += velocity * delta

	if input != Vector2.ZERO:
		# 가로·세로 중 더 크게 누른 쪽을 바라본다. 대각선은 좌우를 우선한다.
		if absf(input.x) >= absf(input.y):
			_facing = "east" if input.x > 0.0 else "west"
		else:
			_facing = "south" if input.y > 0.0 else "north"
	sprite.play(StringName(("walk_" if input != Vector2.ZERO else "idle_") + _facing))

	_iframes = maxf(_iframes - delta, 0.0)
	if HURT_IFRAMES - _iframes < HURT_FLASH and _iframes > 0.0:
		sprite.modulate = Color(2.5, 0.4, 0.4)  # 맞은 순간 붉게 번쩍
	else:
		sprite.modulate = Color(1, 1, 1, 0.35 if _iframes > 0.0 and int(_iframes * 20.0) % 2 == 0 else 1.0)


func take_damage(amount: float) -> void:
	if _iframes > 0.0 or hp <= 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	_iframes = HURT_IFRAMES
	hp_changed.emit(hp, max_hp)
	hurt.emit(amount)
	if hp <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	if amount <= 0.0 or hp <= 0.0 or hp >= max_hp:
		return
	hp = minf(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)
