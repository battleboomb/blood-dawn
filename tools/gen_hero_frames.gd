extends SceneTree
## 4방향 정지 그림(assets/imgs/hero/alucard/{south,north,west,east}.png, 48x48)을 가로세로 절반(24x24)으로
## 줄인 뒤 idle/walk 프레임을 만들어 한 장의 시트로 저장한다. 그림은 다시 그리지 않고 픽셀을 1px씩만 옮긴다.
## 실행: godot --headless --path . --script res://tools/gen_hero_frames.gd
##
## 시트 배치 (칸 24x24): 줄 = idle_south, idle_north, idle_west, idle_east, walk_south, walk_north, walk_west, walk_east
## - idle (4프레임): 상체가 1px 내려갔다 올라오는 숨쉬기, 옆모습은 등 뒤 망토 자락이 1px 흔들림
## - walk (6프레임): 두 발이 번갈아 1px 들리고(옆모습은 앞뒤로 1px 오감), 발을 디딜 때 상체가 1px 내려앉음

const SRC_DIR := "res://assets/imgs/hero/alucard/"
const OUT := "res://assets/imgs/hero/alucard/alucard_sheet.png"
const SRC_CELL := 48
const CELL := 24
const DIRS := ["south", "north", "west", "east"]
const IDLE_FRAMES := 4
const WALK_FRAMES := 6
const FEET_ROWS := 5        # 맨 아래 이만큼은 발(다리 끝)로 본다
const OUTLINE_LUMA := 0.2   # 이보다 어두운 색은 외곽선으로 보고 축소할 때 지킨다
const WAIST_RATIO := 0.55   # 위에서 이 비율까지는 상체(숨쉬기로 움직이는 부분)


func _init() -> void:
	var sheet := Image.create_empty(CELL * WALK_FRAMES, CELL * DIRS.size() * 2, false, Image.FORMAT_RGBA8)
	for d in DIRS.size():
		var src := _load_centered(DIRS[d])
		var side: bool = DIRS[d] == "west" or DIRS[d] == "east"
		var facing := -1 if DIRS[d] == "west" else 1
		for i in IDLE_FRAMES:
			var breath := 1 if i == 1 or i == 2 else 0
			var sway := -facing if side and (i == 1 or i == 2) else 0
			_put(sheet, _frame(src, breath, sway, [Vector2i.ZERO, Vector2i.ZERO]), i, d)
		for i in WALK_FRAMES:
			var phase := TAU * i / WALK_FRAMES
			var feet := []
			for foot in 2:
				var ph := phase + PI * foot
				var dx := int(round(sin(ph))) if side else 0
				var lift := int(round(maxf(cos(ph), 0.0) * 1.4))
				feet.append(Vector2i(dx, -lift))
			var contact := absf(sin(phase)) > 0.7
			var sway := -facing if side and contact else 0
			_put(sheet, _frame(src, 1 if contact else 0, sway, feet), i, d + DIRS.size())
	var err := sheet.save_png(OUT)
	print("saved ", OUT, " err=", err)
	quit()


## 발(맨 아래 줄들)의 가로 무게중심이 칸 가운데에 오도록 옮긴 뒤 절반 크기로 줄여 불러온다.
func _load_centered(dir_name: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC_DIR + dir_name + ".png"))
	img.convert(Image.FORMAT_RGBA8)
	var box := img.get_used_rect()
	var sum := 0.0
	var count := 0
	for y in range(box.end.y - 6, box.end.y):
		for x in SRC_CELL:
			if img.get_pixel(x, y).a > 0.0:
				sum += x
				count += 1
	# 2칸 단위로 옮겨 원본 픽셀이 축소 블록(2x2) 경계에 맞게 한다
	var shift := (SRC_CELL / 2 - int(round(sum / maxi(count, 1)))) / 2 * 2
	var out := Image.create_empty(SRC_CELL, SRC_CELL, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(0, 0, SRC_CELL, SRC_CELL), Vector2i(shift, 0))
	return _downscale_half(out)


## 2x2 블록을 한 픽셀로 줄인다. 일반 축소처럼 색을 섞지 않고 블록 안의 실제 색 하나를 고른다.
## - 불투명 픽셀이 2개 미만이면 투명 (가는 잔털은 버림)
## - 실루엣 가장자리이거나 어두운 픽셀이 2개 이상이면 가장 어두운 색 (1px 외곽선과 눈을 지킴)
## - 그 밖에는 가장 많이 나온 색, 모두 다르면 평균에 가장 가까운 색
func _downscale_half(src: Image) -> Image:
	var out := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
	for y in CELL:
		for x in CELL:
			var colors: Array[Color] = []
			for dy in 2:
				for dx in 2:
					var c := src.get_pixel(x * 2 + dx, y * 2 + dy)
					if c.a > 0.5:
						colors.append(Color(c, 1.0))
			if colors.size() < 2:
				continue
			var darkest := colors[0]
			var dark_count := 0
			for c in colors:
				if c.get_luminance() < OUTLINE_LUMA:
					dark_count += 1
				if c.get_luminance() < darkest.get_luminance():
					darkest = c
			if darkest.get_luminance() < OUTLINE_LUMA and (colors.size() < 4 or dark_count >= 2):
				out.set_pixel(x, y, darkest)
				continue
			out.set_pixel(x, y, _dominant(colors))
	return out


func _dominant(colors: Array[Color]) -> Color:
	var best := colors[0]
	var best_n := 0
	for c in colors:
		var n := 0
		for o in colors:
			if o.is_equal_approx(c):
				n += 1
		if n > best_n:
			best_n = n
			best = c
	if best_n > 1:
		return best
	var avg := Color(0, 0, 0)
	for c in colors:
		avg += c
	avg /= colors.size()
	for c in colors:
		if _dist(c, avg) < _dist(best, avg):
			best = c
	return best


func _dist(a: Color, b: Color) -> float:
	return (a.r - b.r) ** 2 + (a.g - b.g) ** 2 + (a.b - b.b) ** 2


## 한 프레임: 발 → 몸통 아래 → 상체 순으로 겹쳐 그린다.
## breath: 상체를 아래로 내리는 양, sway: 등 뒤 자락(하체 중 바깥쪽)을 옆으로 옮기는 양,
## feet: [왼발, 오른발] 이동량 (x, y)
func _frame(src: Image, breath: int, sway: int, feet: Array) -> Image:
	var box := src.get_used_rect()
	var waist := box.position.y + int(box.size.y * WAIST_RATIO)
	var feet_top := box.end.y - FEET_ROWS
	var center := CELL / 2
	var out := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
	# 1) 발: 가운데를 기준으로 왼발/오른발을 나눠 따로 움직인다
	for y in range(feet_top, box.end.y):
		for x in CELL:
			var c := src.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var move: Vector2i = feet[0] if x < center else feet[1]
			_put_pixel(out, Vector2i(x, y) + move, c)
	# 2) 하체(허리~발 위): 등 뒤 자락만 sway 만큼 흔든다
	for y in range(waist, feet_top):
		for x in CELL:
			var c := src.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var behind := (sway < 0 and x < center - 1) or (sway > 0 and x > center + 1)
			var dx := sway if behind and y > waist + 1 else 0
			_put_pixel(out, Vector2i(x + dx, y), c)
	# 3) 상체: 숨쉬기/걸음 들썩임으로 아래로 내려간다
	for y in range(0, waist):
		for x in CELL:
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				_put_pixel(out, Vector2i(x, y + breath), c)
	return out


func _put_pixel(img: Image, p: Vector2i, c: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < CELL and p.y < CELL:
		img.set_pixelv(p, c)


func _put(sheet: Image, frame: Image, col: int, row: int) -> void:
	sheet.blit_rect(frame, Rect2i(0, 0, CELL, CELL), Vector2i(col * CELL, row * CELL))
