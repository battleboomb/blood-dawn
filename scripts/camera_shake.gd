extends Camera2D
## 화면 흔들림 (PRD #4-P1-4). 충격(trauma, 0~1)을 더하면 그 제곱만큼 흔들리고 서서히 가라앉는다.

const MAX_OFFSET := 6.0
const DECAY := 2.2  # 초당 줄어드는 충격

var trauma := 0.0


func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


func _process(delta: float) -> void:
	trauma = maxf(trauma - DECAY * delta, 0.0)
	var strength := trauma * trauma * MAX_OFFSET
	offset = (Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength).round()
