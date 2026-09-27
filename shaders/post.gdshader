// Screen post process for the low resolution 3D image: colour grading,
// ordered dithering and a soft vignette.
shader_type canvas_item;

uniform bool dither = true;
uniform float levels = 28.0;
uniform float saturation = 1.08;
uniform float contrast = 1.04;
uniform float vignette = 0.25;
uniform vec3 tint : source_color = vec3(1.0);

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[i] / 16.0;
}

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	c *= tint;
	vec2 q = UV - 0.5;
	c *= 1.0 - dot(q, q) * vignette * 1.6;
	if (dither) {
		vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
		float b = bayer4(px) - 0.5;
		c = floor(c * levels + b + 0.5) / levels;
	}
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
