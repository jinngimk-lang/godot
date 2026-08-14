shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.20, 0.095, 0.04);
uniform float roughness_value : hint_range(0.05, 1.0) = 0.45;
uniform float grain_strength : hint_range(0.0, 0.35) = 0.12;
uniform float grain_scale : hint_range(5.0, 180.0) = 72.0;
uniform float stone_mode : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	float wood_wave = sin(UV.y * grain_scale + sin(UV.x * 18.0) * 2.8);
	float fine = sin(UV.y * grain_scale * 3.1 + UV.x * 17.0) * 0.5 + 0.5;
	float wood = 0.5 + 0.5 * wood_wave;
	wood = mix(wood, fine, 0.24);
	float speckle = hash21(floor(UV * vec2(170.0, 110.0)));
	float stone = mix(0.90, 1.08, speckle);
	float variation = mix(0.88 + wood * grain_strength, stone, stone_mode);
	ALBEDO = base_color * variation;
	ROUGHNESS = clamp(roughness_value + (wood - 0.5) * 0.08 * (1.0 - stone_mode), 0.04, 1.0);
	METALLIC = 0.0;
	SPECULAR = mix(0.52, 0.34, stone_mode);
}
