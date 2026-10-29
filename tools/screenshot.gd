extends SceneTree
## 개발용: 메인 씬을 띄워 잠시 움직인 뒤 화면을 PNG로 저장한다.
## 실행: godot --path . --script res://tools/screenshot.gd -- <저장 경로> [이동 x] [이동 y] [초]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "user://screenshot.png"
	var move := Vector2(float(args[1]), float(args[2])) if args.size() > 2 else Vector2.ZERO
	var seconds: float = float(args[3]) if args.size() > 3 else 1.0

	root.add_child(load("res://scenes/main.tscn").instantiate())
	_hold(move)
	await create_timer(seconds).timeout
	await process_frame
	# 화면 버퍼의 알파값이 PNG에 섞이지 않도록 RGB로만 저장한다.
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(out_path)
	print("saved ", out_path)
	quit()


func _hold(move: Vector2) -> void:
	if move.x < 0.0: Input.action_press("move_left")
	if move.x > 0.0: Input.action_press("move_right")
	if move.y < 0.0: Input.action_press("move_up")
	if move.y > 0.0: Input.action_press("move_down")
