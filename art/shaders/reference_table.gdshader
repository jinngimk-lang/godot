shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.20, 0.095, 0.04);
uniform float roughness_value : hint_range(0.05, 1.0) = 0.45;
uniform float grain_strength : hint_range(0.0, 0.35) = 0.12;
uniform float grain_scale : hint_range(5.0, 180.0) = 72.0;
uniform float stone_mode : hint_range(0.0, 1.0) = 0.0;
uniform float grain_bump_strength : hint_range(0.0, 0.12) = 0.04;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	vec2 smooth_local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, smooth_local.x), mix(c, d, smooth_local.x), smooth_local.y);
}

float wood_signal(vec2 uv) {
	float wood_wave = sin(uv.y * grain_scale + sin(uv.x * 18.0) * 2.8);
	float fine = sin(uv.y * grain_scale * 3.1 + uv.x * 17.0) * 0.5 + 0.5;
	float wood = 0.5 + 0.5 * wood_wave;
	return mix(wood, fine, 0.24);
}

float stone_signal(vec2 uv) {
	float broad = value_noise(uv * vec2(42.0, 31.0));
	float fine = value_noise(uv * vec2(113.0, 83.0) + vec2(9.7, 4.3));
	return mix(broad, fine, 0.30);
}

float surface_signal(vec2 uv) {
	return mix(wood_signal(uv), stone_signal(uv), stone_mode);
}

void fragment() {
	float wood = wood_signal(UV);
	float stone_noise = stone_signal(UV);
	float stone = mix(0.965, 1.035, stone_noise);
	float variation = mix(0.88 + wood * grain_strength, stone, stone_mode);
	ALBEDO = base_color * variation;

	float micro = surface_signal(UV);
	float eps = 0.0025;
	float dx = surface_signal(UV + vec2(eps, 0.0)) - surface_signal(UV - vec2(eps, 0.0));
	float dy = surface_signal(UV + vec2(0.0, eps)) - surface_signal(UV - vec2(0.0, eps));
	vec2 packed_xy = clamp(vec2(0.5) - vec2(dx, dy) * 0.34, vec2(0.06), vec2(0.94));
	NORMAL_MAP = vec3(packed_xy, 1.0);
	NORMAL_MAP_DEPTH = grain_bump_strength;

	float wood_roughness = (wood - 0.5) * 0.08;
	float stone_roughness = (micro - 0.5) * 0.040;
	ROUGHNESS = clamp(roughness_value + mix(wood_roughness, stone_roughness, stone_mode), 0.04, 1.0);
	METALLIC = 0.0;
	SPECULAR = mix(0.52, 0.38, stone_mode);
}
