// Day/night sky with sun, moon, stars and northern lights.
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.35, 0.55, 0.85);
uniform vec3 horizon_color : source_color = vec3(0.75, 0.85, 0.92);
uniform vec3 ground_color : source_color = vec3(0.3, 0.35, 0.4);
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.8);
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 moon_dir = vec3(0.0, -1.0, 0.0);
uniform float stars = 0.0;
uniform float aurora = 0.0;
uniform float cloud_amount = 0.5;

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash2(i);
	float b = hash2(i + vec2(1.0, 0.0));
	float c = hash2(i + vec2(0.0, 1.0));
	float d = hash2(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col = mix(horizon_color, top_color, smoothstep(-0.02, 0.55, h));
	if (h < 0.0) {
		col = mix(horizon_color, ground_color, smoothstep(0.0, 0.25, -h));
	}
	// Soft clouds drifting on a plane.
	if (h > 0.02) {
		vec2 cp = d.xz / (h + 0.08) * 1.4 + vec2(TIME * 0.01, TIME * 0.004);
		float n = vnoise(cp) * 0.6 + vnoise(cp * 2.3) * 0.3 + vnoise(cp * 5.1) * 0.1;
		float cl = smoothstep(1.0 - cloud_amount * 0.6, 1.05 - cloud_amount * 0.45, n);
		cl = floor(cl * 3.0) / 3.0; // posterised, pixel-art clouds
		vec3 cloud_col = mix(horizon_color, vec3(1.0), 0.6) * (0.55 + 0.45 * (1.0 - stars));
		col = mix(col, cloud_col, cl * 0.8 * smoothstep(0.02, 0.18, h));
	}
	// Sun disc + halo.
	float sd = dot(d, normalize(sun_dir));
	col += sun_color * smoothstep(0.93, 1.0, sd) * 0.18;
	if (sd > 0.9975) {
		col = mix(col, vec3(1.0, 0.98, 0.9), 0.9);
	}
	// Moon.
	float md = dot(d, normalize(moon_dir));
	if (md > 0.9985) {
		col = mix(col, vec3(0.95, 0.95, 0.85), 0.9 * stars);
	}
	col += vec3(0.5, 0.55, 0.7) * smoothstep(0.97, 1.0, md) * 0.08 * stars;
	// Stars.
	if (stars > 0.01 && h > 0.0) {
		vec3 q = floor(d * 160.0);
		float s = hash3(q);
		if (s > 0.9965) {
			float tw = 0.6 + 0.4 * sin(TIME * 3.0 + s * 500.0);
			col += vec3(0.9, 0.92, 1.0) * stars * tw * smoothstep(0.0, 0.15, h);
		}
	}
	// Northern lights, mostly towards the north (-Z).
	if (aurora > 0.01 && h > 0.03) {
		vec2 ap = d.xz / (h + 0.25);
		float wave = sin(ap.x * 2.2 + TIME * 0.25 + sin(ap.y * 1.3 + TIME * 0.17) * 1.5);
		float band = smoothstep(0.55, 0.0, abs(ap.y + 1.1 + wave * 0.35));
		float curtain = vnoise(vec2(ap.x * 9.0 + TIME * 0.4, TIME * 0.1)) * 0.7 + 0.3;
		float fade = smoothstep(0.03, 0.2, h) * (1.0 - smoothstep(0.55, 0.95, h));
		vec3 ac = mix(vec3(0.2, 1.0, 0.55), vec3(0.6, 0.35, 0.95), smoothstep(0.1, 0.7, h));
		float a = band * curtain * fade * aurora;
		a = floor(a * 5.0) / 5.0;
		col += ac * a * 0.8;
	}
	COLOR = col;
}
