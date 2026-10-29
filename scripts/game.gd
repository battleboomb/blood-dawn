extends Node2D
## 한 판의 흐름: 3분 생존 → 새벽 종과 보스 → 승리/패배, 경험치와 레벨업, 타격감 (PRD #4-P0, #4-P1)

enum State { RUN, BOSS, WON, LOST }

const RUN_TIME := 180.0
const BOSS_SPAWN_DISTANCE := 170.0
## 보스전 중 일반 적 생성 비율과 최대 수 (3-10)
const BOSS_PHASE_SPAWN_SCALE := 0.35
const BOSS_PHASE_MAX_ALIVE := 120
const BANNER_TIME := 3.5
const WEAPON_SCRIPTS := {
	"bats": preload("res://scripts/weapons/bats.gd"),
	"spear": preload("res://scripts/weapons/spear.gd"),
	"aura": preload("res://scripts/weapons/aura.gd"),
}
## 레벨업 직전 느려지는 시간(실제 초)과 그때의 속도 (5-9)
const LEVEL_UP_SLOWMO := 0.3
const LEVEL_UP_SLOWMO_SCALE := 0.15
## 히트스톱 중 게임 속도
const HITSTOP_SCALE := 0.05
const HITSTOP_MIN_GAP_MS := 400
## 보스가 쓰러진 뒤 결과 화면까지 기다리는 시간 (피 폭발을 보여 준다)
const BOSS_DEATH_DELAY := 1.8
## 평소 성 안의 어둠과 보스 등장 순간의 어둠 (5-8, 5-14)
const DARKNESS := Color(0.42, 0.38, 0.5)
const DARKNESS_BOSS := Color(0.1, 0.06, 0.1)
## 깨진 램프는 반드시 하나를 떨어뜨린다: 50% 큰 핏방울, 나머지 50% 회복 고기
const LAMP_BLOOD_CHANCE := 0.5
const LAMP_BLOOD_XP := 3
const MEAT_HEAL := 25.0
const LAMP_SPARK_COLORS := [Color("ffe9a8"), Color("e89a3c"), Color("b08d3a"), Color("d8d0c0")]

@onready var player: Node2D = $World/Player
@onready var claw: Node2D = $World/Player/Claw
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var enemies: Node2D = $World/Enemies
@onready var gems: Node2D = $Gems
@onready var effects: Node2D = $Effects
@onready var gore: Node2D = $Gore
@onready var darkness: CanvasModulate = $Darkness
@onready var hud: Control = $HUD/Hud
@onready var level_up: CanvasLayer = $LevelUp
@onready var result: CanvasLayer = $Result
@onready var pause: CanvasLayer = $Pause

var state := State.RUN
var elapsed := 0.0
var boss_time := 0.0
var kills := 0
var level := 1
var xp := 0
var xp_to_next := 0
var upgrade_levels := {}  # 강화 id -> 레벨
var _pending_level_ups := 0
var _opening_level_up := false
var _banner_left := 0.0
var _weapons := {}  # 무기 id -> 노드
var _hitstop_until := 0
var _last_hitstop := -100000


func _ready() -> void:
	Engine.time_scale = 1.0
	darkness.color = DARKNESS
	enemies.player = player
	enemies.gore = gore
	enemies.fx = self
	gems.player = player
	claw.enemies = enemies
	claw.effects = effects
	gore.floor_layer = $BloodFloor
	enemies.enemy_killed.connect(_on_enemy_killed)
	enemies.boss_killed.connect(_on_boss_killed)
	enemies.boss_hp_changed.connect(_on_boss_hp_changed)
	gems.collected.connect(_on_xp_collected)
	gems.meat_collected.connect(_on_meat_collected)
	$World/Decor.enemies = enemies
	$World/Decor.lamp_broken.connect(_on_lamp_broken)
	enemies.prop_destroyed.connect($World/Decor.on_prop_destroyed)
	player.hp_changed.connect(_on_hp_changed)
	player.hurt.connect(_on_player_hurt)
	player.died.connect(_on_player_died)
	level_up.chosen.connect(_on_upgrade_chosen)
	pause.can_pause = func(): return (state == State.RUN or state == State.BOSS) and not level_up.visible and not _opening_level_up
	xp_to_next = _xp_required(level)
	_refresh_hud()


func _process(delta: float) -> void:
	if _hitstop_until > 0 and Time.get_ticks_msec() >= _hitstop_until:
		_hitstop_until = 0
		if not _opening_level_up:
			Engine.time_scale = 1.0
	match state:
		State.RUN:
			elapsed += delta
			if elapsed >= RUN_TIME:
				elapsed = RUN_TIME
				_start_boss()
		State.BOSS:
			boss_time += delta
		_:
			return
	enemies.spawn_tick(delta, elapsed)
	hud.time_left = RUN_TIME - elapsed
	if _banner_left > 0.0:
		_banner_left -= delta
		hud.banner_alpha = clampf(_banner_left, 0.0, 1.0)
	hud.refresh()


# ---------------------------------------------------------------- 타격감 (5-1, 5-2)

## 아주 잠깐 게임을 거의 멈춘다. 이미 더 긴 멈춤이 걸려 있으면 무시한다.
## 너무 자주 멈추면 프레임이 끊기는 것처럼 보이므로, 한 번 멈춘 뒤 HITSTOP_MIN_GAP_MS 동안은 다시 멈추지 않는다.
func hitstop(seconds: float) -> void:
	if _opening_level_up or get_tree().paused:
		return
	var now := Time.get_ticks_msec()
	if now < _hitstop_until or now - _last_hitstop < HITSTOP_MIN_GAP_MS:
		return
	_last_hitstop = now
	_hitstop_until = now + int(seconds * 1000.0)
	Engine.time_scale = HITSTOP_SCALE


func shake(amount: float) -> void:
	camera.add_trauma(amount)


func _on_player_hurt(_amount: float) -> void:
	hitstop(0.04)
	shake(0.35)
	Sfx.play("hurt")
	gore.spurt(player.global_position, Vector2.from_angle(randf() * TAU), 8, 0.9, 12.0)


# ---------------------------------------------------------------- 보스 (5-14, 5-15)

func _start_boss() -> void:
	state = State.BOSS
	enemies.spawn_rate_scale = BOSS_PHASE_SPAWN_SCALE
	enemies.max_alive = BOSS_PHASE_MAX_ALIVE
	# 가던 방향 앞쪽에서 나타나 마주치게 한다.
	var dir: Vector2 = player.velocity.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT.rotated(randf() * TAU)
	enemies.spawn_boss(player.global_position + dir * BOSS_SPAWN_DISTANCE)
	hud.boss_name_key = "boss_name"
	_show_banner("boss_banner_title", "boss_banner_sub")
	# 등장 연출: 성이 어둠에 잠겼다가 천천히 돌아온다
	Sfx.play("bell", 2.0, 0.0)
	Sfx.play("roar", 0.0, 0.0)
	shake(0.7)
	var tw := create_tween()
	tw.tween_property(darkness, "color", DARKNESS_BOSS, 0.35)
	tw.tween_interval(0.9)
	tw.tween_property(darkness, "color", DARKNESS, 1.2)


## 화면 가운데 위에 잠시 뜨는 알림. 문구는 Loc 키로 넘긴다.
func _show_banner(title_key: String, sub_key: String) -> void:
	hud.banner_title_key = title_key
	hud.banner_sub_key = sub_key
	hud.banner_alpha = 1.0
	_banner_left = BANNER_TIME


func _on_boss_hp_changed(hp: float, max_hp: float) -> void:
	hud.boss_hp = hp
	hud.boss_max_hp = max_hp
	hud.refresh()


func _on_boss_killed(_pos: Vector2) -> void:
	kills += 1
	state = State.WON
	Sfx.play("explosion", 2.0, 0.0)
	shake(1.0)
	hitstop(0.35)
	await get_tree().create_timer(BOSS_DEATH_DELAY, true, false, true).timeout
	_show_result(true)


# ---------------------------------------------------------------- 무기와 경험치

## 처음 고르면 무기를 만들고, 이미 있으면 레벨을 올린다.
func level_weapon(id: String) -> void:
	if not _weapons.has(id):
		var w: Node2D = WEAPON_SCRIPTS[id].new()
		w.player = player
		w.enemies = enemies
		w.effects = effects
		add_child(w)
		if id == "aura":
			move_child(w, $World.get_index())  # 바닥 높이: 캐릭터보다 아래에 그린다
		_weapons[id] = w
	_weapons[id].level_up()


## 다음 레벨까지 필요한 핏방울 수. 3분 동안 레벨업 약 10번을 목표로 한 값 (3-8, 4-13).
## 단단한 적이 큰 핏방울을 떨어뜨리므로 4단계에서 조금 올렸다.
func _xp_required(lv: int) -> int:
	return 5 + (lv - 1) * 6


func _on_enemy_killed(pos: Vector2, value: int) -> void:
	kills += 1
	gems.drop(pos, value)


## 램프(촛대)가 깨지면 불똥이 튀고, 확률에 따라 핏방울이나 고기가 떨어진다.
func _on_lamp_broken(pos: Vector2) -> void:
	gore.spurt(pos, Vector2.ZERO, 16, 1.0, 20.0, LAMP_SPARK_COLORS)
	Sfx.play("hit", 0.0, 0.3)
	shake(0.15)
	if randf() < LAMP_BLOOD_CHANCE:
		gems.drop(pos, LAMP_BLOOD_XP)
	else:
		gems.drop_meat(pos)


func _on_meat_collected() -> void:
	Sfx.play("select", -6.0)
	player.heal(MEAT_HEAL)


func _on_xp_collected(value: int) -> void:
	Sfx.play("pickup", -12.0)
	xp += value
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = _xp_required(level)
		_pending_level_ups += 1
	_refresh_hud()
	if _pending_level_ups > 0 and not level_up.visible and not _opening_level_up and (state == State.RUN or state == State.BOSS):
		_open_level_up()


## 레벨업: 게임이 슬로모션처럼 느려지며 화면이 핏빛으로 물든 뒤 멈추고 카드가 나온다 (5-9).
func _open_level_up() -> void:
	var choices := Upgrades.pick(upgrade_levels, 3)
	if choices.is_empty():
		_pending_level_ups = 0
		return
	_opening_level_up = true
	_hitstop_until = 0
	Sfx.play("levelup", 0.0, 0.0)
	level_up.show_dim(LEVEL_UP_SLOWMO)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_method(func(v: float): Engine.time_scale = v, 1.0, LEVEL_UP_SLOWMO_SCALE, LEVEL_UP_SLOWMO)
	await tw.finished
	Engine.time_scale = 1.0
	_opening_level_up = false
	if state != State.RUN and state != State.BOSS:
		return
	get_tree().paused = true
	level_up.open(choices, upgrade_levels)


func _on_upgrade_chosen(id: String) -> void:
	upgrade_levels[id] = upgrade_levels.get(id, 0) + 1
	Upgrades.apply(id, self)
	_pending_level_ups -= 1
	_refresh_hud()
	if _pending_level_ups > 0:
		var choices := Upgrades.pick(upgrade_levels, 3)
		if not choices.is_empty():
			level_up.open(choices, upgrade_levels)
			return
		_pending_level_ups = 0
	get_tree().paused = false


# ---------------------------------------------------------------- 끝

func _on_hp_changed(_hp: float, _max_hp: float) -> void:
	_refresh_hud()


func _on_player_died() -> void:
	if state != State.RUN and state != State.BOSS:
		return
	state = State.LOST
	Sfx.play("bell", 0.0, 0.0)
	gore.spurt(player.global_position, Vector2.ZERO, 60, 1.4, 12.0)
	await get_tree().create_timer(0.8, true, false, true).timeout
	_show_result(false)


func _show_result(won: bool) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = true
	hud.banner_alpha = 0.0
	hud.refresh()
	result.show_result(won, elapsed + boss_time, boss_time, level, kills)


func _refresh_hud() -> void:
	hud.level = level
	hud.xp = xp
	hud.xp_to_next = xp_to_next
	hud.hp = player.hp
	hud.max_hp = player.max_hp
	hud.refresh()
