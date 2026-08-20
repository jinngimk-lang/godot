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

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

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

float wood_signal(vec2 p) {
	// p is object-space XZ.  The grain runs along X while its value changes
	// primarily across Z, matching the long café counter boards in the target.
	float long_warp = sin(p.x * 4.6 + sin(p.y * 2.2) * 1.5);
	float wood_wave = sin(p.y * grain_scale * 0.34 + long_warp * 3.1);
	float fine = sin(p.y * grain_scale * 1.07 + p.x * 8.5) * 0.5 + 0.5;
	float pores = value_noise(p * vec2(3.4, 52.0) + vec2(1.7, 4.3));
	float broad = value_noise(p * vec2(0.75, 5.5));
	float wood = 0.5 + 0.5 * wood_wave;
	return mix(mix(mix(wood, fine, 0.28), pores, 0.13), broad, 0.12);
}

float stone_signal(vec2 p) {
	float broad = value_noise(p * vec2(7.5, 6.0));
	float fine = value_noise(p * vec2(28.0, 22.0) + vec2(9.7, 4.3));
	return mix(broad, fine, 0.34);
}

float surface_signal(vec2 p) {
	return mix(wood_signal(p), stone_signal(p), stone_mode);
}

void fragment() {
	vec2 surface_p = local_pos.xz;
	float wood = wood_signal(surface_p);
	float stone_noise = stone_signal(surface_p);
	float stone = mix(0.90, 1.10, stone_noise);

	// BoxMesh UV orientation differs per face.  Use the known 3.5 m tabletop
	// depth in object space so broad plank seams stay stable across the visible
	// top surface regardless of UV packing.
	float safe_planks = max(plank_count, 1.0);
	float plank_u = (local_pos.z / 3.5 + 0.5) * safe_planks;
	float plank_id = floor(plank_u);
	float plank_local = fract(plank_u);
	float plank_random = hash21(vec2(plank_id, 17.37));
	float plank_edge_distance = min(plank_local, 1.0 - plank_local);
	float plank_seam = 1.0 - smoothstep(0.0, 0.035, plank_edge_distance);
	float plank_tone = (plank_random - 0.5) * 2.0 * plank_contrast - plank_seam * plank_contrast * 1.05;

	float wood_value = 0.78 + wood * grain_strength * 2.05 + plank_tone;
	float variation = mix(wood_value, stone, stone_mode);
	ALBEDO = base_color * variation;

	float micro = surface_signal(surface_p);
	float eps = 0.008;
	float dx = surface_signal(surface_p + vec2(eps, 0.0)) - surface_signal(surface_p - vec2(eps, 0.0));
	float dy = surface_signal(surface_p + vec2(0.0, eps)) - surface_signal(surface_p - vec2(0.0, eps));
	vec2 packed_xy = clamp(vec2(0.5) - vec2(dx, dy) * 0.58, vec2(0.06), vec2(0.94));
	NORMAL_MAP = vec3(packed_xy, 1.0);
	NORMAL_MAP_DEPTH = grain_bump_strength;

	float wood_roughness = (wood - 0.5) * specular_variation * 1.35 + (plank_random - 0.5) * specular_variation * 0.85 + plank_seam * 0.050;
	float stone_roughness = (micro - 0.5) * 0.050;
	ROUGHNESS = clamp(roughness_value + mix(wood_roughness, stone_roughness, stone_mode), 0.04, 1.0);
	METALLIC = 0.0;
	float wood_specular = clamp(0.60 - wood_roughness * 1.7, 0.28, 0.76);
	SPECULAR = mix(wood_specular, 0.42, stone_mode);
	ALPHA = surface_alpha;
}
