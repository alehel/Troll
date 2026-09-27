// Inverted hull outline, used as next_pass on character parts.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 color : source_color = vec4(0.14, 0.1, 0.09, 1.0);
uniform float width = 0.035;

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = color.rgb;
}
