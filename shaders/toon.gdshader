// Cel-shaded material used for the world, props and characters.
shader_type spatial;
render_mode cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform bool use_vertex_color = true;
uniform sampler2D detail_tex : filter_nearest_mipmap, repeat_enable;
uniform float detail_strength = 0.0;
uniform float detail_scale = 0.125;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform float rim_strength = 0.0;
// Wind sway for foliage (0 = static).
uniform float sway = 0.0;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (sway > 0.0) {
		float h = max(VERTEX.y, 0.0);
		float s = sin(TIME * 1.3 + wp.x * 0.35 + wp.z * 0.27) * 0.5 + sin(TIME * 2.1 + wp.z * 0.5) * 0.25;
		VERTEX.x += s * sway * h * 0.08;
		VERTEX.z += s * sway * h * 0.05;
	}
	wpos = wp;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 c = albedo.rgb;
	if (use_vertex_color) {
		c *= COLOR.rgb;
	}
	if (detail_strength > 0.0) {
		vec3 an = abs(wnorm);
		vec2 uv = an.y > 0.6 ? wpos.xz : (an.x > an.z ? wpos.zy : wpos.xy);
		float d = texture(detail_tex, uv * detail_scale).r;
		c *= 1.0 + (d - 0.5) * detail_strength;
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = emission_color.rgb * emission_energy;
	if (rim_strength > 0.0) {
		float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		EMISSION += c * smoothstep(0.55, 0.8, rim) * rim_strength;
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// Two soft bands give a painterly cel look.
	float lit = smoothstep(0.0, 0.08, ndl) * 0.72 + smoothstep(0.45, 0.55, ndl) * 0.28;
	lit *= ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR * lit / PI;
}
