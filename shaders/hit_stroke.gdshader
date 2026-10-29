shader_type canvas_item;
// 맞은 적의 몸 둘레에 1px 흰 테두리를 깜빡이게 그린다 (타격 표현).
// 투명한 픽셀 중 상하좌우에 몸 픽셀이 붙어 있으면 테두리로 칠한다.

uniform vec4 stroke : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float blink_speed = 45.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float n = texture(TEXTURE, UV + vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a
			+ texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		if (n > 0.5) {
			float blink = 0.55 + 0.45 * step(0.0, sin(TIME * blink_speed));
			COLOR = vec4(stroke.rgb, stroke.a * blink);
		}
	}
}
