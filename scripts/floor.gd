extends Sprite2D
## 카메라를 따라다니며 반복 텍스처로 끝없는 고성 바닥을 그린다. (PRD #4-P0-1, #6)
## region_rect를 월드 좌표와 똑같이 두므로 어디로 가도 무늬가 이어진다.

const MARGIN := 32.0


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var view := get_viewport_rect().size
	var top_left := (cam.get_screen_center_position() - view / 2.0 - Vector2(MARGIN, MARGIN)).floor()
	position = top_left
	region_rect = Rect2(top_left, view + Vector2(MARGIN, MARGIN) * 2.0)
