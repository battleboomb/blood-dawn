extends SceneTree
## 임시 도트 그림 생성기 (PRD #8: 임시 도트는 직접 만들고 나중에 교체)
## 실행: godot --headless --path . --script res://tools/gen_placeholder_art.gd
## 결과는 res://assets/sprites/ 에 PNG로 저장된다. 같은 이름의 PNG로 바꾸면 게임에 그대로 반영된다.

const OUT := "res://assets/sprites/"
const FORMAT := Image.FORMAT_RGBA8

# floor.png 안의 카펫 띠 위치 (scripts/decor_spawner.gd 와 같아야 함)
const FLOOR_SIZE := 512
const CARPET_FROM := 224
const CARPET_TO := 272

var PAL := {
	"k": Color("0a0710"),  # 외곽선
	"d": Color("1e1a2e"),  # 머리카락, 정장
	"p": Color("c8bfc9"),  # 창백한 피부
	"R": Color("c41e2e"),  # 붉은 눈, 조끼
	"r": Color("6e0c18"),  # 망토 안감
	"W": Color("f2ece0"),  # 송곳니
	"G": Color("b08d3a"),  # 금장식
	"g": Color("6b5420"),  # 어두운 금
	"f": Color("ffe9a8"),  # 불꽃 심
	"F": Color("e89a3c"),  # 불꽃
	"w": Color("d8d0c0"),  # 초
	"L": Color("8a8a9a"),  # 밝은 강철
	"S": Color("5a5a6a"),  # 강철
	"s": Color("3a3a48"),  # 어두운 강철
	"b": Color("4a0a12"),  # 마른 피
	"B": Color("9a9080"),  # 뼈 그림자
	"h": Color("ff6a6a"),  # 핏방울 하이라이트
	"Y": Color("ebe7f0"),  # 백발
	"y": Color("9e97ad"),  # 백발 그림자
	"c": Color("161020"),  # 망토 겉감
	"D": Color("3a2f52"),  # 외투 앞섶 밝은 면
	"v": Color("3b2a4a"),  # 박쥐 몸
	"n": Color("6f7a64"),  # 구울 피부
	"N": Color("48503f"),  # 구울 피부 그림자
	"m": Color("4a2014"),  # 구운 고기 어두운 면
	"M": Color("8a3f22"),  # 구운 고기
	"o": Color("c8743c"),  # 구운 고기 윤기
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_save(_make_vampire(), "vampire.png")
	_save(_make_shadow(), "shadow.png")
	_save(_make_floor(), "floor.png")
	_save(_make_pillar(), "pillar.png")
	_save(_make_candelabra(), "candelabra.png")
	_save(_make_coffin(), "coffin.png")
	_save(_make_armor(), "armor.png")
	_save(_make_skeleton(), "skeleton.png")
	_save(_make_claw_slash(), "claw_slash.png")
	_save(_make_blood_drop(), "blood_drop.png")
	_save(_make_boss(), "boss_flesh.png")
	_save(_make_bat("v"), "bat.png")
	_save(_make_bat("b"), "blood_bat.png")
	_save(_make_knight(), "knight.png")
	_save(_make_ghoul(), "ghoul.png")
	_save(_make_spear(), "blood_spear.png")
	_save(_make_corpse_chunk(), "corpse_chunk.png")
	_save(_make_heroine(), "heroine.png")
	_save(_make_meat(), "meat.png")
	print("placeholder art generated in ", OUT)
	quit()


func _save(img: Image, file_name: String) -> void:
	var err := img.save_png(OUT + file_name)
	if err != OK:
		push_error("failed to save %s (%d)" % [file_name, err])


# ---------------------------------------------------------------- 도우미

func _blit_rows(img: Image, rows: Array, at: Vector2i, pal: Dictionary = PAL) -> void:
	var width: int = rows[0].length()
	for y in rows.size():
		var row: String = rows[y]
		if row.length() != width:
			push_error("row %d has width %d, expected %d: %s" % [y, row.length(), width, row])
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			var p := at + Vector2i(x, y)
			if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
				continue
			img.set_pixelv(p, pal[ch])


func _from_rows(rows: Array) -> Image:
	var img := Image.create_empty(rows[0].length(), rows.size(), false, FORMAT)
	_blit_rows(img, rows, Vector2i.ZERO)
	return img


## 불투명 픽셀 중 투명 픽셀과 맞닿은 것을 외곽선 색으로 칠한다.
func _outline_inner(img: Image, color: Color) -> void:
	var src := img.duplicate() as Image
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a == 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or src.get_pixelv(q).a == 0.0:
					img.set_pixel(x, y, color)
					break


# ---------------------------------------------------------------- 뱀파이어

## 20x28 프레임 6장: 0-1 숨쉬기, 2-5 걷기. 오른쪽을 보는 옆모습이고, 왼쪽은 게임에서 좌우 반전한다.
## 긴 백발이 등 뒤로 허리까지 흘러내리고, 붉은 안감 망토를 두른다.
func _make_vampire() -> Image:
	var upper := [
		"....................",
		".........kkkkk......",
		"........kYYYYYk.....",
		".......kYYYYYYYk....",
		".......kYYYYYyppk...",
		"......kYYYYYypRpk...",
		"......kYYYYyyppppk..",
		"......kYYYYykpppk...",
		".....kYYYYYykpWk....",
		".....kYYYYykrrkk....",
		"....kYYYYyykrdrk....",
		"....kYYYyykcdddGk...",
		"...kcYYYykccdddDk...",
		"...kcYYyykccddRDk...",
		"..kccYYyyccrdddDk...",
		"..kcccYyyccrddpDk...",
		".kccccyyccrrdddDk...",
		".kcccccccrrrdddDk...",
		"kcccccccrrrrdddDk...",
		"kccccccrrrrrdddDk...",
		"kkkkcccrrrrkdddDk...",
	]
	var legs_together := [
		"....kkkkkk..kddk....",
		"............kddk....",
		"............kddk....",
		"............kddk....",
		"............kddk....",
		"...........kkkkkk...",
		"....................",
	]
	var legs_stride := [
		"....kkkkkk..kddk....",
		"...........kdkkdk...",
		"..........kdk..kdk..",
		"..........kdk..kdk..",
		".........kdk....kdk.",
		"........kkkk....kkkk",
		"....................",
	]
	# [다리, 상체 세로 오프셋] — 다리를 벌린 프레임은 몸이 1px 내려간다
	var frames := [
		[legs_together, 0], [legs_together, 1],
		[legs_stride, 1], [legs_together, 0], [legs_stride, 1], [legs_together, 0],
	]
	var sheet := Image.create_empty(20 * frames.size(), 28, false, FORMAT)
	for i in frames.size():
		var ox := i * 20
		_blit_rows(sheet, frames[i][0], Vector2i(ox, 21))
		_blit_rows(sheet, upper, Vector2i(ox, frames[i][1]))
	return sheet


func _make_shadow() -> Image:
	var img := Image.create_empty(12, 5, false, FORMAT)
	for y in 5:
		for x in 12:
			var dx := (x - 5.5) / 6.0
			var dy := (y - 2.0) / 2.5
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.5))
	return img


# ---------------------------------------------------------------- 바닥

## 512x512 반복 바닥: 돌 판석 + 십자 모양 붉은 카펫 + 마른 핏자국
func _make_floor() -> Image:
	var img := Image.create_empty(FLOOR_SIZE, FLOOR_SIZE, false, FORMAT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1347
	var stones := [Color("2f2c3b"), Color("332f40"), Color("2b2836"), Color("363245")]
	var mortar := Color("17141f")
	var tiles := FLOOR_SIZE / 16
	for ty in tiles:
		for tx in tiles:
			var base: Color = stones[rng.randi() % stones.size()]
			for y in 16:
				for x in 16:
					var c := base
					if x == 15 or y == 15:
						c = mortar
					elif x == 0 or y == 0:
						c = base.lightened(0.1)
					elif rng.randf() < 0.06:
						c = base.darkened(0.25)
					elif rng.randf() < 0.04:
						c = base.lightened(0.08)
					img.set_pixel(tx * 16 + x, ty * 16 + y, c)
			if rng.randf() < 0.12:
				_draw_crack(img, rng, tx * 16 + rng.randi_range(3, 10), ty * 16 + rng.randi_range(3, 10), mortar)

	for i in 9:
		var center := Vector2i(rng.randi_range(0, FLOOR_SIZE - 1), rng.randi_range(0, FLOOR_SIZE - 1))
		if _in_carpet(center.x) or _in_carpet(center.y):
			continue
		_draw_stain(img, rng, center, rng.randi_range(3, 7))

	for y in FLOOR_SIZE:
		for x in FLOOR_SIZE:
			var in_h := _in_carpet(y)
			var in_v := _in_carpet(x)
			if in_h or in_v:
				img.set_pixel(x, y, _carpet_px(x, y, in_h, in_v, rng))
	return img


func _in_carpet(v: int) -> bool:
	return v >= CARPET_FROM and v < CARPET_TO


func _carpet_px(x: int, y: int, in_h: bool, in_v: bool, rng: RandomNumberGenerator) -> Color:
	# 가장자리 금색 테두리: 카펫끼리 겹치는 곳은 생략
	var edge := 99
	if in_h and not in_v:
		edge = mini(y - CARPET_FROM, CARPET_TO - 1 - y)
	elif in_v and not in_h:
		edge = mini(x - CARPET_FROM, CARPET_TO - 1 - x)
	match edge:
		0:
			return Color("3a2e12")
		1:
			return Color("8a6c2a")
		2, 3:
			return Color("2e050b")
	var c := Color("5c0d18")
	if (x + y) % 12 == 0 or (x - y + FLOOR_SIZE * 2) % 12 == 0:
		c = Color("420911")
	if rng.randf() < 0.05:
		c = c.darkened(0.2)
	return c


func _draw_crack(img: Image, rng: RandomNumberGenerator, x: int, y: int, color: Color) -> void:
	var p := Vector2i(x, y)
	for i in rng.randi_range(4, 7):
		img.set_pixel(posmod(p.x, FLOOR_SIZE), posmod(p.y, FLOOR_SIZE), color)
		p += Vector2i(rng.randi_range(0, 1), 1) if rng.randf() < 0.5 else Vector2i(1, rng.randi_range(-1, 1))


func _draw_stain(img: Image, rng: RandomNumberGenerator, center: Vector2i, radius: int) -> void:
	var blood := Color(0.22, 0.02, 0.05)
	for y in range(-radius - 3, radius + 4):
		for x in range(-radius - 3, radius + 4):
			var d := Vector2(x, y).length()
			var inside := d <= radius - 1 or (d <= radius + 1 and rng.randf() < 0.5)
			var splatter := d > radius + 1 and rng.randf() < 0.04
			if not (inside or splatter):
				continue
			var p := Vector2i(posmod(center.x + x, FLOOR_SIZE), posmod(center.y + y, FLOOR_SIZE))
			img.set_pixelv(p, img.get_pixelv(p).lerp(blood, 0.8))


# ---------------------------------------------------------------- 장식

## 16x40 돌기둥. 왼쪽 위에서 빛이 드는 원통 음영.
func _make_pillar() -> Image:
	var img := Image.create_empty(16, 40, false, FORMAT)
	_fill_cylinder(img, 1, 15, 0, 2)
	_fill_cylinder(img, 2, 14, 2, 5)
	_fill_cylinder(img, 3, 13, 5, 34)
	_fill_cylinder(img, 2, 14, 34, 37)
	_fill_cylinder(img, 1, 15, 37, 40)
	var groove := Color("24222d")
	for y in range(7, 32):
		img.set_pixel(6, y, groove)
		img.set_pixel(9, y, groove)
	for x in range(3, 13):
		img.set_pixel(x, 5, groove)
		img.set_pixel(x, 33, groove)
	# 금 간 자국과 오래된 핏자국
	for p in [Vector2i(10, 14), Vector2i(11, 15), Vector2i(11, 16), Vector2i(10, 17)]:
		img.set_pixelv(p, Color("17141f"))
	for p in [Vector2i(4, 22), Vector2i(4, 23), Vector2i(5, 23), Vector2i(4, 24), Vector2i(4, 26)]:
		img.set_pixelv(p, PAL["b"])
	_outline_inner(img, PAL["k"])
	return img


func _fill_cylinder(img: Image, x0: int, x1: int, y0: int, y1: int) -> void:
	var shades := [Color("625e76"), Color("57536a"), Color("4a4659"), Color("3d3a4d"), Color("34313f"), Color("2c2a36")]
	for x in range(x0, x1):
		var t := float(x - x0) / float(x1 - x0 - 1)
		var idx := clampi(int(absf(t - 0.25) * 8.0), 0, shades.size() - 1)
		for y in range(y0, y1):
			img.set_pixel(x, y, shades[idx])


func _make_candelabra() -> Image:
	return _from_rows([
		".f...f...f.",
		".F...f...F.",
		".F...F...F.",
		".w...w...w.",
		".w...w...w.",
		".w...w...w.",
		"gGg.gGg.gGg",
		".G...G...G.",
		".GgggGgggG.",
		".....G.....",
		".....G.....",
		"....gGg....",
		".....G.....",
		".....G.....",
		".....G.....",
		".....G.....",
		".....G.....",
		".....G.....",
		".....G.....",
		"....gGg....",
		".....G.....",
		"...gGGGg...",
		"..gGGGGGg..",
		".ggggggggg.",
	])


## 14x24 바닥에 놓인 관 (위에서 본 모습)
func _make_coffin() -> Image:
	var img := Image.create_empty(14, 24, false, FORMAT)
	var dark := Color("2e1b12")
	var mid := Color("4a2c1a")
	var light := Color("63402a")
	for y in 24:
		var half := lerpf(4.0, 7.0, y / 6.0) if y < 6 else lerpf(7.0, 5.0, (y - 6) / 17.0)
		for x in 14:
			var dx := absf(x - 6.5)
			if dx > half:
				continue
			var c := mid
			if dx > half - 1.0:
				c = light if x < 7 else dark
			img.set_pixel(x, y, c)
	for y in range(5, 15):
		img.set_pixel(6, y, PAL["g"])
		img.set_pixel(7, y, PAL["g"])
	for x in range(4, 10):
		img.set_pixel(x, 8, PAL["g"])
	_outline_inner(img, PAL["k"])
	return img


# ---------------------------------------------------------------- 적, 무기, 경험치

## 16x20 해골 병사, 걷기 2프레임
func _make_skeleton() -> Image:
	var upper := [
		".....kkkkkk.....",
		"....kwwwwwwk....",
		"....kwwwwwwk....",
		"....kRkwwkRk....",
		"....kwwBBwwk....",
		".....kwkwkwk....",
		"......kkkk......",
		".......kk.......",
		"....kkkwwkkk....",
		"...kw.kwwk.wk...",
		"...kw.kBBk.wk...",
		"...kw.kwwk.wk...",
		"...kk.kBBk.kk...",
		".......kk.......",
		".....kkwwkk.....",
	]
	var legs_a := [
		".....kw..wk.....",
		".....kw..wk.....",
		".....kw..wk.....",
		"....kkw..wkk....",
		"................",
	]
	var legs_b := [
		".....kw..wk.....",
		"....kw....wk....",
		"....kw....wk....",
		"...kkw.....kk...",
		"................",
	]
	var sheet := Image.create_empty(32, 20, false, FORMAT)
	for i in 2:
		_blit_rows(sheet, upper, Vector2i(i * 16, 0))
		_blit_rows(sheet, legs_a if i == 0 else legs_b, Vector2i(i * 16, 15))
	return sheet


## 32x32 발톱 자국 3프레임 (오른쪽을 향함): 그어지는 중 → 다 그어짐 → 사라지는 중
func _make_claw_slash() -> Image:
	var sheet := Image.create_empty(96, 32, false, FORMAT)
	var core := Color("ffd6d6")
	var edge := Color("c41e2e")
	var fade := Color("6e0c18")
	var spans := [[4, 18], [4, 28], [12, 28]]
	for f in 3:
		for mark in [-7, 0, 7]:
			for x in range(spans[f][0], spans[f][1]):
				var t := (x - 4) / 24.0
				var y: int = 16 + mark - int(round(sin(t * PI) * 4.0))
				var thick := 2 if t > 0.2 and t < 0.8 else 1
				for k in thick:
					sheet.set_pixel(f * 32 + x, y + k, fade if f == 2 else core)
				sheet.set_pixel(f * 32 + x, y + thick, fade if f == 2 else edge)
	return sheet


## 64x56 보스 "시체 육괴" 2프레임 (꿈틀거림). 꿰맨 살덩어리에 얼굴과 팔이 박혀 있다.
func _make_boss() -> Image:
	var sheet := Image.create_empty(128, 56, false, FORMAT)
	for f in 2:
		var img := Image.create_empty(64, 56, false, FORMAT)
		var squash := 1.0 if f == 0 else 0.93
		var widen := 1.0 if f == 0 else 1.05
		var lift := 0 if f == 0 else 2
		var flesh_light := Color("8e5a58")
		var flesh := Color("6a3540")
		var flesh_dark := Color("3e1a24")
		# 몸통 덩어리와 위쪽 혹
		var blobs := [
			[Vector2(32, 35), 27.0 * widen, 19.0 * squash],
			[Vector2(18, 20 + lift), 10.0, 9.0],
			[Vector2(35, 15 + lift), 11.0, 10.0],
			[Vector2(49, 22 + lift), 8.0, 8.0],
		]
		for y in 56:
			for x in 64:
				var best := 99.0
				var dy_top := 0.0
				for b in blobs:
					var dx: float = (x - b[0].x) / b[1]
					var dy: float = (y - b[0].y) / b[2]
					var d := dx * dx + dy * dy + sin(x * 0.8 + y * 0.3) * 0.06
					if d < best:
						best = d
						dy_top = dy
				if best > 1.0:
					continue
				var c := flesh
				if dy_top < -0.45:
					c = flesh_light
				elif dy_top > 0.5:
					c = flesh_dark
				if (x * 7 + y * 13) % 17 == 0:
					c = flesh_dark
				elif (x * 5 + y * 3) % 9 == 0 or (y > 40 and (x + y) % 5 == 0):
					c = PAL["b"]
				img.set_pixel(x, y, c)
		# 꿰맨 자국
		_draw_stitch(img, Vector2i(10, 36), Vector2i(54, 30))
		_draw_stitch(img, Vector2i(33, 8 + lift), Vector2i(28, 50))
		# 박혀 있는 얼굴들: 잿빛 얼굴, 텅 빈 눈, 피를 흘리며 비명 지르는 입
		for face in [Vector2i(19, 28), Vector2i(42, 24), Vector2i(36, 43), Vector2i(14, 44)]:
			_draw_face(img, face + Vector2i(0, lift if face.y < 35 else 0), f)
		# 사방으로 튀어나온 팔
		_draw_arm(img, Vector2i(7, 34), -1, f)
		_draw_arm(img, Vector2i(56, 38), 1, f)
		_draw_arm(img, Vector2i(12, 20 + lift), -1, 1 - f)
		_draw_arm(img, Vector2i(52, 22 + lift), 1, 1 - f)
		_outline_inner(img, PAL["k"])
		# 바닥으로 떨어지는 피
		for x in [14, 22, 33, 41, 50]:
			var length: int = 2 + (x * 3 + f) % 4
			for k in length:
				var y: int = 53 - k
				if img.get_pixel(x, y).a > 0.0:
					img.set_pixel(x, y, PAL["R"] if k < length - 1 else PAL["b"])
		sheet.blit_rect(img, Rect2i(0, 0, 64, 56), Vector2i(f * 64, 0))
	return sheet


func _draw_stitch(img: Image, from: Vector2i, to: Vector2i) -> void:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	var dir := Vector2(to - from).normalized()
	var normal := Vector2(-dir.y, dir.x)
	for i in steps + 1:
		var p := Vector2(from).lerp(Vector2(to), float(i) / steps)
		_set_if_inside(img, Vector2i(p.round()), Color("2a1418"))
		if i % 4 == 0:
			for s in [-1, 1]:
				_set_if_inside(img, Vector2i((p + normal * s).round()), Color("8a7a68"))


func _draw_face(img: Image, c: Vector2i, frame: int) -> void:
	var skin := Color("9a9098")
	for y in range(-5, 6):
		for x in range(-4, 5):
			if (x * x) / 16.0 + (y * y) / 25.0 <= 1.0:
				_set_if_inside(img, c + Vector2i(x, y), skin if y > -4 else skin.darkened(0.2))
	# 텅 빈 눈구멍
	for e in [Vector2i(-2, -2), Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(1, -2), Vector2i(2, -2), Vector2i(2, -1)]:
		_set_if_inside(img, c + e, PAL["k"])
	# 벌어진 입과 흘러내리는 피
	var mouth := 3 if frame == 0 else 4
	for y in range(1, 1 + mouth):
		for x in range(-1, 2):
			_set_if_inside(img, c + Vector2i(x, y), PAL["k"] if absi(x) == 1 else PAL["b"])
	for y in range(1 + mouth, 4 + mouth):
		_set_if_inside(img, c + Vector2i(0, y), PAL["R"])


func _draw_arm(img: Image, base: Vector2i, side: int, frame: int) -> void:
	var skin := Color("8a7f88")
	var reach := 10 if frame == 0 else 8
	for i in reach:
		var p := base + Vector2i(side * i, -i / 2 - (frame if i > 5 else 0))
		_set_if_inside(img, p, skin)
		_set_if_inside(img, p + Vector2i(0, 1), skin.darkened(0.35))
		_set_if_inside(img, p + Vector2i(0, -1), PAL["k"])
		_set_if_inside(img, p + Vector2i(0, 2), PAL["k"])
	var hand := base + Vector2i(side * reach, -reach / 2 - frame)
	for f in [Vector2i(side, -2), Vector2i(side * 2, -1), Vector2i(side, 0), Vector2i(side * 2, 1), Vector2i(side, 2)]:
		_set_if_inside(img, hand + f, skin)
	_set_if_inside(img, hand, PAL["R"])


func _set_if_inside(img: Image, p: Vector2i, color: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixelv(p, color)


## 12x10 박쥐 2프레임 (날개 위/아래). body: 몸 색 글자 (적은 보라 v, 무기는 마른 피 b)
func _make_bat(body: String) -> Image:
	var up := [
		"k..........k",
		"kk........kk",
		"kdk.kkkk.kdk",
		"kddkdRdRkddk",
		".kddddddddk.",
		"..kkddddkk..",
		"....kWWk....",
		".....kk.....",
		"............",
		"............",
	]
	var down := [
		"............",
		"............",
		"....kkkk....",
		"...kdRdRk...",
		".kkddddddkk.",
		"kddddddddddk",
		"kdk.kWWk.kdk",
		"kk...kk...kk",
		"k..........k",
		"............",
	]
	var sheet := Image.create_empty(24, 10, false, FORMAT)
	var frames := [up, down]
	for i in 2:
		var rows := []
		for r in frames[i]:
			rows.append(r.replace("d", body))
		_blit_rows(sheet, rows, Vector2i(i * 12, 0))
	return sheet


## 18x24 갑옷 기사 2프레임: 붉은 깃털, 붉은 눈이 비치는 투구, 붉은 휘장, 검
func _make_knight() -> Image:
	var upper := [
		".......kkk........",
		"......kRRRk.......",
		"......kkkkkk......",
		".....kLLLSSsk.....",
		".....kLkkkksk.....",
		".....kSRkRksk.....",
		".....kSSSsssk.....",
		"....kkkkkkkkkk....",
		"...kLLSSSSSSssk...",
		"..kLkLSSSSSSsksk..",
		"..kLkLSSRRSSsksk..",
		"..kLkSSSRRSSsksk..",
		"..kLkSSSRRSSskLk..",
		"..kkkSSSRRSSskLk..",
		"....kSSSRRSSskLk..",
		"....kkkkkkkkkkLk..",
		".....kSSk.kSSkL...",
	]
	var legs_a := [
		".....kSSk.kSSk....",
		".....kSSk.kSSk....",
		".....kssk.kssk....",
		"....kkkkk.kkkkk...",
	]
	var legs_b := [
		".....kSSk.kSSk....",
		"....kSSk...kSSk...",
		"....kssk...kssk...",
		"...kkkkk...kkkkk..",
	]
	var sheet := Image.create_empty(36, 24, false, FORMAT)
	for i in 2:
		_blit_rows(sheet, legs_a if i == 0 else legs_b, Vector2i(i * 18, 17))
		_blit_rows(sheet, upper, Vector2i(i * 18, 0))
	return sheet


## 16x18 구부정한 구울 2프레임: 썩은 녹색 피부, 피 묻은 손톱
func _make_ghoul() -> Image:
	var upper := [
		"................",
		".....kkkk.......",
		"....knnnnk......",
		"...knRnnRnk.....",
		"...knnnnnnk.....",
		"....kWkWkk......",
		"...kknnnnkk.....",
		"..knnNNNNnnk....",
		".knNkNNNNkNnk...",
		".kNk.kNNk.kNk...",
		".kbk.kNNk.kbk...",
		".....kNNk.......",
		".....kbNk.......",
	]
	var legs_a := [
		"....kNk.kNk.....",
		"....kNk.kNk.....",
		"...kkk..kkk.....",
	]
	var legs_b := [
		"....kNk.kNk.....",
		"...kNk...kNk....",
		"..kkk.....kkk...",
	]
	var sheet := Image.create_empty(32, 18, false, FORMAT)
	for i in 2:
		_blit_rows(sheet, upper, Vector2i(i * 16, 0))
		_blit_rows(sheet, legs_a if i == 0 else legs_b, Vector2i(i * 16, 13))
	return sheet


# ---------------------------------------------------------------- 주인공 (흑발 뱀파이어 여성)

const HERO_W := 24
const HERO_H := 38
const HERO_HIP_Y := 21     # 허벅지가 시작하는 줄
const HERO_GROUND_Y := 35  # 밑창 줄
const HERO_IDLE := 5
const HERO_WALK := 7

var HERO_PAL := {
	"k": Color("0b0810"),  # 외곽선
	"H": Color("1d1824"),  # 머리카락
	"J": Color("3b3346"),  # 머리카락 윤기
	"p": Color("ecd4cf"),  # 피부
	"P": Color("b9969c"),  # 피부 그림자 (뾰족한 귀)
	"E": Color("e0102a"),  # 붉은 눈
	"R": Color("9c1626"),  # 코트 안감, 입술
	"r": Color("5c0b16"),  # 어두운 안감
	"W": Color("f4eeea"),  # 송곳니
	"C": Color("221c2a"),  # 코트
	"c": Color("15111b"),  # 코트 그림자
	"D": Color("40354f"),  # 코트 앞섶 밝은 면
	"B": Color("17131c"),  # 부츠
	"O": Color("3d3546"),  # 부츠 윤기
}


## 24x38 칸, 오른쪽을 보는 옆모습. 1줄: idle 5프레임, 2줄: walk 7프레임.
## 몸통·머리·코트 자락은 손으로 찍은 한 장을 쓰고, 다리는 프레임마다 코드로 그린다.
## 숨쉬기는 상체를 1px 내리고, 머리카락과 코트 자락은 뒤쪽 끝일수록 더 크게 흔든다.
func _make_heroine() -> Image:
	var body := [
		"........................",
		"..........kkkkk.........",
		"........kkHHHHHkk.......",
		".......kHHHJJHHHHk......",
		"......kHHHJHHHHHHHk.....",
		"......kHHHHHHHHHHpk.....",
		".....kHHHHHHHHHHppk.....",
		".....kHHHHHHHHHpEppk....",
		".....kHHHHHHHPHpppk.....",
		"....kHHHHHHHHHHpRk......",
		"....kHHHHHHHHHkpWk......",
		"...kHHHHHHHHHkpk........",
		"..kHHHHHHHkCCRCk........",
		"..kHHHHHHkCCCRCCk.......",
		"..kHHHHHHkCCCCRCk.......",
		"..kHHHHHkCCCCCCDk.......",
		"..kHHHHHkCCCCpCDk.......",
		"..kHHHHkcCCCCCCDk.......",
		"..kHHHkRcCCCCCCCk.......",
		"..kHHkrRcCCCCCCCk.......",
		"..kHkrRRccCCCCCk........",
		"..kkrRRRck..............",
		"..krRRRRck..............",
		"..krRRRRck..............",
		"...krRRRrk..............",
		"...krRRRrk..............",
		"...krRRrkk..............",
		"....krRrkk..............",
		".....krk................",
		"......k.................",
	]
	# 머리카락 결: 정수리부터 등 뒤로 흘러내리는 윤기 줄을 몇 가닥 넣는다
	for y in range(4, 21):
		var row: String = body[y]
		for x in ([8, 12] if y < 12 else [4, 7]):
			if row[x] == "H" and y % 4 != 0:
				row = row.substr(0, x) + "J" + row.substr(x + 1)
		body[y] = row
	var sheet := Image.create_empty(HERO_W * HERO_WALK, HERO_H * 2, false, FORMAT)
	for i in HERO_IDLE:
		var t := float(i) / HERO_IDLE
		var breath := 1 if i == 2 or i == 3 else 0
		var sway := sin(t * TAU) * 1.5 + 0.5
		var frame := _hero_frame(body, breath, sway, [[11.0, 0.0], [13.0, 0.0]])
		sheet.blit_rect(frame, Rect2i(0, 0, HERO_W, HERO_H), Vector2i(i * HERO_W, 0))
	for i in HERO_WALK:
		var phase := TAU * i / HERO_WALK
		# 두 다리는 반 주기 어긋나 앞뒤로 오간다. 앞으로 내딛는 쪽 다리는 발을 든다.
		var legs := []
		for leg in 2:
			var ph := phase + PI * leg
			var reach := sin(ph) * 5.0
			var lift := maxf(cos(ph), 0.0) * 2.5
			legs.append([12.0 + reach, lift])
		# 두 발이 땅을 디딘 순간에는 상체가 1px 내려앉고, 다리가 엇갈릴 때 다시 올라온다
		var contact := absf(sin(phase)) >= 0.5
		var frame := _hero_frame(body, 1 if contact else 0, 2.0 + sin(phase * 2.0) * 1.0, legs)
		sheet.blit_rect(frame, Rect2i(0, 0, HERO_W, HERO_H), Vector2i(i * HERO_W, HERO_H))
	return sheet


## 한 프레임: 뒷다리 → 앞다리 → 몸통 순으로 그린다.
## legs: [[발목 x, 발 든 높이], ...] 첫 번째가 뒷다리(어둡게)
func _hero_frame(body: Array, breath: int, sway: float, legs: Array) -> Image:
	var img := Image.create_empty(HERO_W, HERO_H, false, FORMAT)
	var hips := [11.0, 13.0]
	for leg in 2:
		_hero_leg(img, Vector2(hips[leg], HERO_HIP_Y), legs[leg][0], legs[leg][1], leg == 0)
	var layer := Image.create_empty(HERO_W, HERO_H, false, FORMAT)
	_blit_rows(layer, body, Vector2i.ZERO, HERO_PAL)
	for y in range(HERO_H - 1, -1, -1):
		for x in HERO_W:
			var c := layer.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var dx := 0
			var dy := 0
			# 뒤로 늘어진 머리카락·코트 자락(왼쪽 아래)은 끝으로 갈수록 크게 흔들린다
			if y >= 12 and x <= 9:
				dx = -int(round(sway * clampf((y - 11) / 18.0, 0.0, 1.0)))
			# 숨쉬기/걸음 들썩임은 상체(머리~가슴)만 움직인다
			if y <= 17:
				dy = breath
			var p := Vector2i(x + dx, y + dy)
			if p.x >= 0 and p.y >= 0 and p.x < HERO_W and p.y < HERO_H:
				img.set_pixelv(p, c)
	return img


## 엉덩이에서 발목까지 2px 굵기 다리 + 앞코가 오른쪽인 부츠 + 1px 외곽선
func _hero_leg(img: Image, hip: Vector2, ankle_x: float, lift: float, back: bool) -> void:
	var leg := Image.create_empty(HERO_W, HERO_H, false, FORMAT)
	var ankle := Vector2(ankle_x, HERO_GROUND_Y - 2 - lift)
	var knee := (hip + ankle) / 2.0 + Vector2(1.0 + lift * 0.6, 0)
	var boot: Color = HERO_PAL["B"]
	var shine: Color = HERO_PAL["O"]
	var skin: Color = HERO_PAL["p"]
	if back:
		boot = boot.darkened(0.3)
		shine = boot
		skin = HERO_PAL["P"]
	for seg in [[hip, knee], [knee, ankle]]:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)) * 2.0) + 1
		for s in steps + 1:
			var p := a.lerp(b, float(s) / steps)
			var px := Vector2i(int(round(p.x)), int(round(p.y)))
			var thigh := px.y - int(hip.y) < 2  # 부츠 위로 드러난 허벅지
			_set_if_inside(leg, px, skin if thigh else boot)
			_set_if_inside(leg, px + Vector2i(1, 0), skin if thigh else shine)
	# 부츠 발: 발목 아래로 앞코가 오른쪽을 향하고 굽이 있다
	var f := Vector2i(int(round(ankle.x)), int(round(ankle.y)))
	for x in range(f.x, f.x + 3):
		_set_if_inside(leg, Vector2i(x, f.y + 1), boot)
	for x in range(f.x - 1, f.x + 4):
		_set_if_inside(leg, Vector2i(x, f.y + 2), boot)
	_set_if_inside(leg, Vector2i(f.x - 1, f.y + 1), boot)  # 굽
	# 외곽선
	var outlined := leg.duplicate() as Image
	for y in HERO_H:
		for x in HERO_W:
			if leg.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < HERO_W and q.y < HERO_H and leg.get_pixelv(q).a > 0.0:
					outlined.set_pixel(x, y, HERO_PAL["k"])
					break
	img.blend_rect(outlined, Rect2i(0, 0, HERO_W, HERO_H), Vector2i.ZERO)


## 20x5 피의 창 (오른쪽을 향함)
func _make_spear() -> Image:
	return _from_rows([
		".............kk.....",
		"kkkkkkkkkkkkkRhkk...",
		"kbbbbbbbbbbbbRRhhk..",
		"kkkkkkkkkkkkkRhkk...",
		".............kk.....",
	])


## 8x8 보스가 던지는 시체 덩어리
func _make_corpse_chunk() -> Image:
	return _from_rows([
		"..kkkk..",
		".kRbbRk.",
		"kbppbbRk",
		"kbRbpbbk",
		"kbbRbbbk",
		".kbbRbk.",
		"..kkkk..",
		"........",
	])


## 12x9 회복 고기: 접시에 담긴 구운 고기 덩어리와 삐져나온 뼈
func _make_meat() -> Image:
	return _from_rows([
		"....kkkk..kk",
		"..kkMoooMkWk",
		".kMMoMMMMMkW",
		".kmMMMMMMmk.",
		"kkkmmmmmmkkk",
		"kwwkkkkkkwwk",
		"kBwwwwwwwwBk",
		".kBBBBBBBBk.",
		"..kkkkkkkk..",
	])


func _make_blood_drop() -> Image:
	return _from_rows([
		"..k..",
		".kRk.",
		".kRk.",
		"kRhRk",
		"kRRRk",
		"kbRbk",
		".kkk.",
	])


func _make_armor() -> Image:
	return _from_rows([
		"......kkkk........",
		".....kLLSSk.......",
		"....kLLSSSsk......",
		"....kLskkssk......",
		"....kSSsssk.......",
		".....kkkkk..kkk...",
		"..kkk.....kLLSk...",
		".kLSsk...kLLSSsk..",
		".kSssk..kLSSSssk..",
		"..kkk...kSSsssk...",
		".bb.....kkkkkk....",
		"bbbb..............",
	])
