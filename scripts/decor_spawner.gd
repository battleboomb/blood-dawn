extends Node2D
## 고성 장식(기둥·촛대·관·부서진 갑옷)을 대상 주변 칸마다 배치한다. (PRD #6)
## 칸 좌표로 난수를 정하므로 같은 칸에는 언제 돌아와도 같은 장식이 있다.
## 촛대(램프)는 적처럼 공격 대상이라 공격에 맞으면 깨지고, 깨진 칸에는 다시 나오지 않는다.

signal lamp_broken(position: Vector2)

const CELL := 128
const SPAWN_CHANCE := 0.45

# floor.png의 카펫 띠 위치 (tools/gen_placeholder_art.gd 와 같아야 함)
const FLOOR_PERIOD := 512
const CARPET_FROM := 224
const CARPET_TO := 272
const CARPET_CLEARANCE := 20

const DECOR := [
	{ "texture": preload("res://assets/sprites/pillar.png"), "weight": 3 },
	{ "texture": preload("res://assets/sprites/candelabra.png"), "weight": 3 },
	{ "texture": preload("res://assets/sprites/coffin.png"), "weight": 2 },
	{ "texture": preload("res://assets/sprites/armor.png"), "weight": 2 },
]

const CANDLE_TEX := preload("res://assets/sprites/candelabra.png")
const CANDLE_LIGHT_COLOR := Color(1.0, 0.68, 0.38)
const CANDLE_LIGHT_SCALE := 1.3
## 공격이 맞는 촛대 몸 크기
const CANDLE_HIT_RADIUS := 4.0

@export var target: Node2D
var enemies: Node  # EnemyManager: 촛대를 공격 대상으로 등록한다

var _cells := {}  # Vector2i -> Sprite2D, 빈 칸은 null
var _last_center := Vector2i(2147483647, 0)
var _candle_lights: Array[PointLight2D] = []
var _broken := {}  # 촛대가 깨진 칸 Vector2i -> true
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	_flicker_candles()
	if target == null:
		return
	var center := Vector2i((target.global_position / CELL).floor())
	if center == _last_center:
		return
	_last_center = center

	var view := get_viewport_rect().size
	var rx := int(ceil(view.x / 2.0 / CELL)) + 1
	var ry := int(ceil(view.y / 2.0 / CELL)) + 1
	var wanted := {}
	for cy in range(center.y - ry, center.y + ry + 1):
		for cx in range(center.x - rx, center.x + rx + 1):
			var key := Vector2i(cx, cy)
			wanted[key] = true
			if not _cells.has(key):
				_cells[key] = _spawn_cell(key)
	for key in _cells.keys():
		if not wanted.has(key):
			var node: Sprite2D = _cells[key]
			if node != null:
				if node is Enemy:
					enemies.remove_prop(node)
				node.queue_free()
			_cells.erase(key)


func _spawn_cell(cell: Vector2i) -> Sprite2D:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cell)
	if rng.randf() > SPAWN_CHANCE or _broken.has(cell):
		return null
	var pos := Vector2(cell * CELL) + Vector2(rng.randf_range(16, CELL - 16), rng.randf_range(24, CELL - 8))
	if _on_carpet(pos):
		return null
	var tex := _pick_texture(rng)
	# 촛대는 공격 대상이므로 적과 같은 Enemy 노드로 만든다
	var sprite: Sprite2D = Enemy.new() if tex == CANDLE_TEX else Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	# 그림의 바닥 가운데가 기준점이 되어야 Y 정렬이 맞는다.
	sprite.offset = Vector2(-tex.get_width() / 2, -tex.get_height())
	sprite.position = pos.floor()
	sprite.flip_h = rng.randf() < 0.5
	add_child(sprite)
	if tex == CANDLE_TEX:
		_add_candle_light(sprite, tex)
		sprite.radius = CANDLE_HIT_RADIUS
		enemies.add_prop(sprite)
	return sprite


## 공격에 맞은 촛대를 깨뜨린다. 그 칸은 다시 촛대가 나오지 않는다.
func on_prop_destroyed(prop: Enemy) -> void:
	for cell in _cells.keys():
		if _cells[cell] == prop:
			_broken[cell] = true
			_cells[cell] = null
			lamp_broken.emit(prop.position)
			prop.queue_free()
			return


## 촛대 주변만 따뜻하게 밝힌다 (5-8)
func _add_candle_light(sprite: Sprite2D, tex: Texture2D) -> void:
	var light := PointLight2D.new()
	light.texture = LightTex.get_texture()
	light.color = CANDLE_LIGHT_COLOR
	light.texture_scale = CANDLE_LIGHT_SCALE
	light.position = Vector2(0, -tex.get_height() + 2)
	sprite.add_child(light)
	_candle_lights.append(light)


func _flicker_candles() -> void:
	for i in range(_candle_lights.size() - 1, -1, -1):
		var light := _candle_lights[i]
		if not is_instance_valid(light):
			_candle_lights.remove_at(i)
			continue
		var seed := float(light.get_instance_id() % 97)
		light.energy = 1.1 + 0.12 * sin(_time * 9.0 + seed) + 0.08 * sin(_time * 23.0 + seed * 2.0)


func _pick_texture(rng: RandomNumberGenerator) -> Texture2D:
	var total := 0
	for d in DECOR:
		total += d.weight
	var r := rng.randi_range(0, total - 1)
	for d in DECOR:
		r -= d.weight
		if r < 0:
			return d.texture
	return DECOR[0].texture


func _on_carpet(p: Vector2) -> bool:
	return _near_carpet(posmod(int(p.x), FLOOR_PERIOD)) or _near_carpet(posmod(int(p.y), FLOOR_PERIOD))


func _near_carpet(v: int) -> bool:
	return v > CARPET_FROM - CARPET_CLEARANCE and v < CARPET_TO + CARPET_CLEARANCE
