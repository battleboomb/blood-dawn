class_name LightTex
extends RefCounted
## 2D 조명에 쓰는 둥근 빛 텍스처 (PRD #6: 촛불 주변만 밝게). 한 번 만들어 같이 쓴다.

static var _texture: GradientTexture2D


static func get_texture() -> GradientTexture2D:
	if _texture == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
		_texture = GradientTexture2D.new()
		_texture.gradient = g
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
		_texture.width = 128
		_texture.height = 128
	return _texture
