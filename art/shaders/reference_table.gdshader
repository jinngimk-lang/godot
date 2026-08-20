shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, blend_mix, depth_draw_opaque;

uniform vec3 base_color : source_color = vec3(0.30, 0.14, 0.055);
uniform float roughness_value : hint_range(0.05, 1.0) = 0.34;
uniform float grain_strength : hint_range(0.0, 0.35) = 0.18;
uniform float grain_scale : hint_range(5.0, 180.0) = 72.0;
uniform float stone_mode : hint_range(0.0, 1.0) = 0.0;
uniform float grain_bump_strength : hint_range(0.0, 0.12) = 0.04;
uniform float surface_alpha : hint_range(0.15, 1.0) = 0.48;
uniform float plank_count : hint_range(1.0, 14.0) = 6.0;
uniform float plank_contrast : hint_range(0.0, 0.25) = 0.10;
uniform float specular_variation : hint_range(0.0, 0.20) = 0.08;

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
	float long_warp = sin(uv.x * 13.0 + sin(uv.y * 5.0) * 1.7);
	float wood_wave = sin(uv.y * grain_scale + long_warp * 3.2);
	float fine = sin(uv.y * grain_scale * 3.1 + uv.x * 17.0) * 0.5 + 0.5;
	float pores = value_noise(uv * vec2(18.0, 190.0));
	float wood = 0.5 + 0.5 * wood_wave;
	return mix(mix(wood, fine, 0.24), pores, 0.12);
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

	float safe_planks = max(plank_count, 1.0);
	float plank_u = UV.x * safe_planks;
	float plank_id = floor(plank_u);
	float plank_local = fract(plank_u);
	float plank_random = hash21(vec2(plank_id, 17.37));
	float plank_edge_distance = min(plank_local, 1.0 - plank_local);
	float plank_seam = 1.0 - smoothstep(0.0, 0.018, plank_edge_distance);
	float plank_tone = (plank_random - 0.5) * 2.0 * plank_contrast - plank_seam * plank_contrast * 0.72;

	float wood_value = 0.82 + wood * grain_strength * 1.7 + plank_tone;
	float variation = mix(wood_value, stone, stone_mode);
	ALBEDO = base_color * variation;

	float micro = surface_signal(UV);
	float eps = 0.0025;
	float dx = surface_signal(UV + vec2(eps, 0.0)) - surface_signal(UV - vec2(eps, 0.0));
	float dy = surface_signal(UV + vec2(0.0, eps)) - surface_signal(UV - vec2(0.0, eps));
	vec2 packed_xy = clamp(vec2(0.5) - vec2(dx, dy) * 0.34, vec2(0.06), vec2(0.94));
	NORMAL_MAP = vec3(packed_xy, 1.0);
	NORMAL_MAP_DEPTH = grain_bump_strength;

	float wood_roughness = (wood - 0.5) * specular_variation + (plank_random - 0.5) * specular_variation * 0.70 + plank_seam * 0.035;
	float stone_roughness = (micro - 0.5) * 0.040;
	ROUGHNESS = clamp(roughness_value + mix(wood_roughness, stone_roughness, stone_mode), 0.04, 1.0);
	METALLIC = 0.0;
	float wood_specular = clamp(0.56 - wood_roughness * 1.4, 0.30, 0.72);
	SPECULAR = mix(wood_specular, 0.40, stone_mode);
	ALPHA = surface_alpha;
}
