extends Node2D
## 성의 괴물 생성·추적·밀어내기·접촉 피해와 보스 행동을 한곳에서 처리한다.
## (PRD #4-P0-3, #4-P0-6, #4-P1-1, #4-P1-3, #7)
## 수백 마리를 다루기 위해 물리 엔진 대신 칸 나누기(공간 해시)로 가까운 적끼리만 비교한다.

signal enemy_killed(position: Vector2, xp: int)
signal boss_killed(position: Vector2)
signal boss_hp_changed(hp: float, max_hp: float)
## 공격에 맞아 깨진 소품(램프)
signal prop_destroyed(prop: Enemy)

## 적 종류별 능력치 (4-6~4-8). speed는 [최소, 최대].
const KINDS := {
	"skeleton": { "tex": preload("res://assets/sprites/skeleton.png"), "offset": -8.0, "hp": 10.0,
		"speed": [26.0, 34.0], "damage": 8.0, "xp": 1, "radius": 5.0, "fps": 4.0, "pack": 1 },
	"bat": { "tex": preload("res://assets/sprites/bat.png"), "offset": -12.0, "hp": 4.0,
		"speed": [58.0, 70.0], "damage": 5.0, "xp": 1, "radius": 4.0, "fps": 10.0, "pack": 4 },
	"knight": { "tex": preload("res://assets/sprites/knight.png"), "offset": -9.0, "hp": 45.0,
		"speed": [16.0, 20.0], "damage": 15.0, "xp": 4, "radius": 7.0, "fps": 2.5, "pack": 1 },
	"ghoul": { "tex": preload("res://assets/sprites/ghoul.png"), "offset": -7.0, "hp": 14.0,
		"speed": [36.0, 42.0], "damage": 10.0, "xp": 2, "radius": 5.0, "fps": 6.0, "pack": 6 },
}
## 시간대별 등장 비율 (4-9): [이 시간(초)부터, {종류: 비율}]
const SCHEDULE := [
	[0.0, { "skeleton": 1 }],
	[30.0, { "skeleton": 70, "bat": 30 }],
	[60.0, { "skeleton": 50, "bat": 25, "ghoul": 15, "knight": 10 }],
	[120.0, { "skeleton": 35, "bat": 25, "ghoul": 20, "knight": 20 }],
]
const BOSS_PHASE_MIX := { "skeleton": 50, "bat": 30, "ghoul": 20 }

const BOSS_TEX := preload("res://assets/sprites/boss_flesh.png")
const CHUNK_TEX := preload("res://assets/sprites/corpse_chunk.png")

const GRID := 16.0
const SEPARATION := 10.0     # 적끼리 이 거리보다 가까우면 서로 밀어낸다
const SEPARATION_FORCE := 40.0
# 성능: 적이 한곳에 빽빽하게 몰리면 밀어내기 비교가 (몰린 수)^2 로 늘어난다.
# 그래서 한 적이 살피는 이웃 수에 상한을 두고, 밀어내는 힘은 3프레임에 한 번씩 나눠 계산한다.
const MAX_NEIGHBORS := 8
const SEPARATION_EVERY := 3
const CONTACT_RANGE := 5.0   # 플레이어 몸 크기. 적의 radius에 더해 닿았는지 본다.
const PACK_SPREAD := 14.0

# 타격감 (5-3, 5-4)
const KNOCK_DECAY := 600.0
const BOSS_KNOCK_SCALE := 0.08
## 맞은 적은 이 시간 동안 몸 둘레에 1px 흰 테두리가 깜빡인다
const FLASH_TIME := 0.15
const HIT_STROKE_SHADER := preload("res://shaders/hit_stroke.gdshader")

# 시간에 따른 난이도 (2-3, 3-9). 이후 전체 난이도 약 30% 상향:
# 생성 수 ×1.15, 적 체력 ×1.15 (합쳐서 처리해야 할 양 ≈ 1.3배), 보스 체력 ×1.3
const SPAWN_RATE_START := 1.15   # 초당 생성 수
const SPAWN_RATE_GROWTH := 0.0575 # 1초마다 늘어나는 초당 생성 수
const HP_SCALE := 1.15
const HP_GROWTH_FROM := 60.0    # 이 시간까지는 기본 체력 그대로
const HP_DOUBLE_TIME := 60.0    # 그 뒤로 이 시간마다 체력이 기본 값만큼 늘어난다

## 혈무 오라 안의 적은 이 배율로 느려진다
const SLOW_FACTOR := 0.75

# 보스 "시체 육괴" (3-3, 4-10~4-12)
const BOSS_HP := 1040.0
const BOSS_SPEED := 24.0
const BOSS_DAMAGE := 25.0
const BOSS_RADIUS := 24.0
const BOSS_FPS := 3.0
const BOSS_PATTERN_INTERVAL := 4.0
const CHARGE_WINDUP := 0.8
const CHARGE_TIME := 0.7
const CHARGE_SPEED := 220.0
const CHARGE_RECOVER := 0.6
const CHUNK_COUNT := 5
const CHUNK_SPREAD := 0.45   # 라디안, 양쪽으로 퍼지는 각
const CHUNK_SPEED := 110.0
const CHUNK_LIFE := 3.5
const CHUNK_DAMAGE := 12.0
const CHUNK_HEIGHT := 14.0
const SPEW_COUNT := 6

enum BossState { CHASE, WINDUP, CHARGE, RECOVER }

class Chunk extends Sprite2D:
	var velocity := Vector2.ZERO
	var life := 0.0
	var ground := Vector2.ZERO

var player: Node2D
var gore: Node2D   # gore.gd: 피 분출과 사망 연출
var fx: Node       # game.gd: 히트스톱과 화면 흔들림
var enemies: Array[Enemy] = []
## 공격 대상이 되는 소품(램프). 움직이지 않으며 장식 배치기(decor_spawner)가 만들고 없앤다.
var props: Array[Enemy] = []
var boss: Enemy
## 적을 느리게 하는 원 (혈무 오라). 반지름 0이면 없음.
var slow_center := Vector2.ZERO
var slow_radius := 0.0
## 보스전에서는 생성 속도와 최대 수를 줄인다 (3-10).
var spawn_rate_scale := 1.0
var max_alive := 400
var _grid := {}
var _frame := 0
var _spawn_budget := 0.0
var _elapsed := 0.0
var _boss_state := BossState.CHASE
var _boss_timer := 0.0
var _boss_pattern := 0
var _charge_dir := Vector2.ZERO
var _chunks: Array[Chunk] = []
## 맞은 적들이 함께 쓰는 흰 테두리 재질
var _hit_stroke := ShaderMaterial.new()


func _ready() -> void:
	_hit_stroke.shader = HIT_STROKE_SHADER


func spawn_tick(delta: float, elapsed: float) -> void:
	_elapsed = elapsed
	_spawn_budget += (SPAWN_RATE_START + elapsed * SPAWN_RATE_GROWTH) * spawn_rate_scale * delta
	while _spawn_budget >= 1.0 and enemies.size() < max_alive:
		var kind := _pick_kind()
		var pack: int = KINDS[kind].pack
		var at := _random_offscreen_point()
		for i in pack:
			spawn(kind, at + Vector2(randf_range(-PACK_SPREAD, PACK_SPREAD), randf_range(-PACK_SPREAD, PACK_SPREAD)))
		_spawn_budget -= pack


func spawn(kind: String, pos: Vector2) -> void:
	var def: Dictionary = KINDS[kind]
	var e := Enemy.new()
	e.texture = def.tex
	e.hframes = 2
	e.offset = Vector2(0, def.offset)
	e.position = pos
	e.hp = def.hp * HP_SCALE * (1.0 + maxf(_elapsed - HP_GROWTH_FROM, 0.0) / HP_DOUBLE_TIME)
	e.max_hp = e.hp
	e.speed = randf_range(def.speed[0], def.speed[1])
	e.damage = def.damage
	e.xp = def.xp
	e.radius = def.radius
	e.anim_fps = def.fps
	e.anim_time = randf()
	add_child(e)
	enemies.append(e)


func spawn_boss(pos: Vector2) -> void:
	var e := Enemy.new()
	e.texture = BOSS_TEX
	e.hframes = 2
	e.offset = Vector2(0, -26)
	e.position = pos
	e.hp = BOSS_HP
	e.max_hp = BOSS_HP
	e.speed = BOSS_SPEED
	e.damage = BOSS_DAMAGE
	e.radius = BOSS_RADIUS
	e.anim_fps = BOSS_FPS
	e.xp = 0
	e.is_boss = true
	add_child(e)
	enemies.append(e)
	boss = e
	_boss_state = BossState.CHASE
	_boss_timer = BOSS_PATTERN_INTERVAL
	boss_hp_changed.emit(e.hp, e.max_hp)


func add_prop(p: Enemy) -> void:
	p.is_prop = true
	props.append(p)


func remove_prop(p: Enemy) -> void:
	props.erase(p)


## 몸 가장자리까지의 거리가 가장 가까운 적 (램프 포함)
func get_nearest(from: Vector2, max_dist: float) -> Enemy:
	var best: Enemy = null
	var best_d := max_dist
	for list in [enemies, props]:
		for e in list:
			var d: float = from.distance_to(e.position) - e.radius
			if d < best_d:
				best_d = d
				best = e
	return best


## max_dist 안에서 남은 체력이 가장 많은 적
func get_toughest(from: Vector2, max_dist: float) -> Enemy:
	var best: Enemy = null
	for e in enemies:
		if from.distance_to(e.position) - e.radius <= max_dist and (best == null or e.hp > best.hp):
			best = e
	return best


## center 반경 안(몸 크기 포함)에 겹친 적 하나 (램프 포함). exclude에 든 적은 건너뛴다.
func find_overlap(center: Vector2, radius: float, exclude: Array[Enemy]) -> Enemy:
	for e in _candidates(center, radius):
		if not is_instance_valid(e) or e.hp <= 0.0:
			continue
		var reach: float = radius + e.radius
		if e.position.distance_squared_to(center) <= reach * reach and not exclude.has(e):
			return e
	return null


## center 반경 안(몸 크기 포함)에 겹친 모든 적 (램프 포함)
func find_all_in_radius(center: Vector2, radius: float) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for e in _candidates(center, radius):
		if not is_instance_valid(e) or e.hp <= 0.0:
			continue
		var reach: float = radius + e.radius
		if e.position.distance_squared_to(center) <= reach * reach:
			found.append(e)
	return found


## push: 밀어내는 방향과 세기 (넉백, 피가 튀는 방향)
func damage_enemy(e: Enemy, amount: float, push := Vector2.ZERO) -> void:
	if e.hp <= 0.0:
		return
	if e.is_prop:
		# 램프는 한 번 맞으면 깨진다. 없애는 일은 장식 배치기가 맡는다.
		e.hp = 0.0
		props.erase(e)
		prop_destroyed.emit(e)
		return
	e.hp -= amount
	e.flash = FLASH_TIME
	e.knock += push * (BOSS_KNOCK_SCALE if e.is_boss else 1.0)
	if e.is_boss:
		boss_hp_changed.emit(maxf(e.hp, 0.0), e.max_hp)
	if e.hp > 0.0:
		gore.spurt(e.position, push.normalized(), 3, 0.7, -e.offset.y)
		return
	enemies.erase(e)
	if e.is_boss:
		boss = null
		gore.boss_explosion(e)
		boss_killed.emit(e.position)
	else:
		gore.kill_effect(e, push.normalized())
		Sfx.play("kill", -4.0)
		if e.xp >= 4:
			fx.hitstop(0.03)  # 단단한 적은 쓰러뜨릴 때 손맛을 더 준다
		fx.shake(0.06)
		enemy_killed.emit(e.position, e.xp)
	e.queue_free()


func _process(delta: float) -> void:
	if player == null:
		return
	var target := player.global_position
	var far := _offscreen_half().length() * 1.5
	_rebuild_grid()
	_frame += 1
	for i in enemies.size():
		var e := enemies[i]
		var to_player := target - e.position
		var dist := to_player.length()
		var move := Vector2.ZERO
		if e.is_boss:
			move = _update_boss(delta, to_player, dist)
		else:
			if dist > 0.01:
				move = to_player / dist * e.speed
			if (i + _frame) % SEPARATION_EVERY == 0:
				e.sep = _separation(e)
			move += e.sep * SEPARATION_FORCE
		if slow_radius > 0.0 and e.position.distance_squared_to(slow_center) <= (slow_radius + e.radius) ** 2:
			move *= SLOW_FACTOR
		e.position += (move + e.knock) * delta
		if e.knock != Vector2.ZERO:
			e.knock = e.knock.move_toward(Vector2.ZERO, KNOCK_DECAY * delta)
		if e.flash > 0.0:
			e.flash -= delta
			e.material = _hit_stroke if e.flash > 0.0 else null
		if boss != null and not e.is_boss:
			_push_out_of_boss(e)
		if not e.is_boss or _boss_state == BossState.CHASE:
			e.flip_h = to_player.x < 0.0
		e.anim_time += delta
		e.frame = int(e.anim_time * e.anim_fps) % 2
		if dist < CONTACT_RANGE + e.radius:
			player.take_damage(e.damage)
		elif dist > far and not (e.is_boss and _boss_state == BossState.CHARGE):
			# 너무 멀리 뒤처진 적은 다시 화면 밖 가까운 곳으로 옮겨 압박을 유지한다.
			e.position = _random_offscreen_point()
	_move_chunks(delta, target)


# ---------------------------------------------------------------- 보스 패턴

## 보스의 이번 프레임 이동 속도. 쫓다가 일정 간격으로 돌진 → 투척 → 졸개 토해내기를 번갈아 쓴다.
func _update_boss(delta: float, to_player: Vector2, dist: float) -> Vector2:
	_boss_timer -= delta
	match _boss_state:
		BossState.CHASE:
			if _boss_timer <= 0.0:
				_start_pattern()
			return to_player / dist * boss.speed if dist > 0.01 else Vector2.ZERO
		BossState.WINDUP:
			# 돌진 예고: 붉게 깜빡이며 떤다
			boss.modulate = Color(1.6, 0.6, 0.6) if int(_boss_timer * 12.0) % 2 == 0 else Color.WHITE
			boss.offset.x = randf_range(-1.0, 1.0)
			if _boss_timer <= 0.0:
				_boss_state = BossState.CHARGE
				_boss_timer = CHARGE_TIME
				_charge_dir = to_player / dist if dist > 0.01 else Vector2.RIGHT
				boss.modulate = Color.WHITE
				boss.offset.x = 0.0
			return Vector2.ZERO
		BossState.CHARGE:
			if _boss_timer <= 0.0:
				_boss_state = BossState.RECOVER
				_boss_timer = CHARGE_RECOVER
			fx.shake(0.04)
			return _charge_dir * CHARGE_SPEED
		_:
			if _boss_timer <= 0.0:
				_boss_state = BossState.CHASE
				_boss_timer = BOSS_PATTERN_INTERVAL
			return Vector2.ZERO


func _start_pattern() -> void:
	match _boss_pattern % 3:
		0:
			_boss_state = BossState.WINDUP
			_boss_timer = CHARGE_WINDUP
			Sfx.play("roar")
		1:
			_throw_chunks()
			_boss_timer = BOSS_PATTERN_INTERVAL
			Sfx.play("throw")
		2:
			_spew_minions()
			_boss_timer = BOSS_PATTERN_INTERVAL
			Sfx.play("roar", -3.0, 0.2)
			gore.spurt(boss.position, Vector2.ZERO, 30, 1.2, 20.0)
	_boss_pattern += 1


func _throw_chunks() -> void:
	var aim := (player.global_position - boss.position).angle()
	for i in CHUNK_COUNT:
		var a := aim + lerpf(-CHUNK_SPREAD, CHUNK_SPREAD, float(i) / (CHUNK_COUNT - 1))
		var c := Chunk.new()
		c.texture = CHUNK_TEX
		c.velocity = Vector2.from_angle(a) * CHUNK_SPEED
		c.life = CHUNK_LIFE
		c.ground = boss.position
		c.position = c.ground - Vector2(0, CHUNK_HEIGHT)
		add_child(c)
		_chunks.append(c)


func _spew_minions() -> void:
	for i in SPEW_COUNT:
		var a := TAU * i / SPEW_COUNT
		spawn("ghoul", boss.position + Vector2.from_angle(a) * (BOSS_RADIUS + 8.0))


func _move_chunks(delta: float, target: Vector2) -> void:
	for i in range(_chunks.size() - 1, -1, -1):
		var c := _chunks[i]
		c.life -= delta
		c.ground += c.velocity * delta
		c.position = c.ground - Vector2(0, CHUNK_HEIGHT)
		c.rotation += 6.0 * delta
		var hit := c.ground.distance_to(target) < CONTACT_RANGE + 4.0
		if hit:
			player.take_damage(CHUNK_DAMAGE)
		if hit or c.life <= 0.0:
			_chunks.remove_at(i)
			c.queue_free()


# ---------------------------------------------------------------- 내부

func _pick_kind() -> String:
	var mix: Dictionary = BOSS_PHASE_MIX if boss != null else SCHEDULE[0][1]
	if boss == null:
		for entry in SCHEDULE:
			if _elapsed >= entry[0]:
				mix = entry[1]
	var total := 0
	for k in mix:
		total += mix[k]
	var r := randi_range(0, total - 1)
	for k in mix:
		r -= mix[k]
		if r < 0:
			return k
	return "skeleton"


func _push_out_of_boss(e: Enemy) -> void:
	var diff := e.position - boss.position
	var min_d := boss.radius + e.radius
	var d := diff.length()
	if d < min_d and d > 0.01:
		e.position = boss.position + diff / d * min_d


func _rebuild_grid() -> void:
	_grid.clear()
	for e in enemies:
		if e.is_boss:
			continue
		var key := Vector2i((e.position / GRID).floor())
		if _grid.has(key):
			_grid[key].append(e)
		else:
			_grid[key] = [e]


func _separation(e: Enemy) -> Vector2:
	var push := Vector2.ZERO
	var found := 0
	var cell := Vector2i((e.position / GRID).floor())
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var bucket = _grid.get(cell + Vector2i(dx, dy))
			if bucket == null:
				continue
			for o in bucket:
				if o == e:
					continue
				var diff: Vector2 = e.position - o.position
				var d := diff.length()
				if d < SEPARATION:
					push += (diff / d if d > 0.01 else Vector2(randf() - 0.5, randf() - 0.5)) * (1.0 - d / SEPARATION)
					found += 1
					if found >= MAX_NEIGHBORS:
						return push
	return push


## center 반경 안에 있을 수 있는 적 후보: 칸 나누기로 근처 칸만 본다 (보스와 램프는 따로 더한다).
## 칸은 이번 프레임 이동 전 위치 기준이라 한 칸 여유를 두고 살핀다.
func _candidates(center: Vector2, radius: float) -> Array:
	var out := []
	var r := int(ceil((radius + 8.0) / GRID))
	var c := Vector2i((center / GRID).floor())
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var bucket = _grid.get(c + Vector2i(dx, dy))
			if bucket != null:
				out.append_array(bucket)
	if boss != null:
		out.append(boss)
	out.append_array(props)
	return out


func _offscreen_half() -> Vector2:
	return get_viewport_rect().size / 2.0 + Vector2(24, 24)


## 플레이어 기준 화면 바로 바깥 테두리의 임의 지점
func _random_offscreen_point() -> Vector2:
	var half := _offscreen_half()
	var p: Vector2
	if randf() < half.x / (half.x + half.y):
		p = Vector2(randf_range(-half.x, half.x), half.y * (1.0 if randf() < 0.5 else -1.0))
	else:
		p = Vector2(half.x * (1.0 if randf() < 0.5 else -1.0), randf_range(-half.y, half.y))
	return player.global_position + p
