// Stylised opaque water. Vertex colour R = depth / 8, G = flowing (river), B = spare.
shader_type spatial;
render_mode cull_disabled;

uniform vec4 deep_color : source_color = vec4(0.13, 0.3, 0.45, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.3, 0.62, 0.66, 1.0);
uniform vec4 foam_color : source_color = vec4(0.9, 0.96, 0.95, 1.0);
uniform float night = 0.0;

varying vec3 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float flowing = COLOR.g;
	VERTEX.y += (sin(TIME * 1.1 + wpos.x * 0.21 + wpos.z * 0.13) * 0.06) * (1.0 - flowing);
}

void fragment() {
	float depth = COLOR.r * 8.0;
	float flowing = COLOR.g;
	vec3 c = mix(shallow_color.rgb, deep_color.rgb, smoothstep(0.2, 5.0, depth));
	// Chunky moving ripples.
	vec2 cell = floor(wpos.xz * 1.5);
	float t = TIME * (0.6 + flowing * 2.5);
	float r = hash(cell + vec2(floor(t), 0.0));
	float band = sin(wpos.x * 0.7 + wpos.z * 0.4 + TIME * 0.8) * 0.5 + 0.5;
	if (r > 0.93 && band > 0.55) {
		c = mix(c, foam_color.rgb, 0.35);
	}
	if (flowing > 0.5) {
		// streaks along the river flow direction (UV.y is distance along the river)
		float s = hash(floor(vec2(UV.x * 5.0, UV.y * 0.9 - TIME * 3.0)));
		if (s > 0.86) {
			c = mix(c, foam_color.rgb, 0.35);
		}
		// white water on steep parts
		c = mix(c, foam_color.rgb, clamp(COLOR.b, 0.0, 1.0) * (0.55 + 0.35 * s));
	}
	// Foam where the water meets the shore.
	float edge = (0.28 - flowing * 0.16) + 0.1 * sin(TIME * 1.7 + wpos.x * 0.6 + wpos.z * 0.4);
	if (depth < edge) {
		c = foam_color.rgb;
	}
	ALBEDO = c;
	ROUGHNESS = 0.4;
	SPECULAR = 0.0;
	// A touch of self light so water keeps its colour at night.
	EMISSION = c * 0.08 * (1.0 - night);
}

void light() {
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * (0.35 + 0.65 * ndl) * ATTENUATION / PI;
	vec3 h = normalize(LIGHT + VIEW);
	float spec = pow(clamp(dot(NORMAL, h), 0.0, 1.0), 180.0);
	SPECULAR_LIGHT += LIGHT_COLOR * step(0.5, spec) * 0.25 * ATTENUATION;
}
