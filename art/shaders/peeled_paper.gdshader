shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

uniform sampler2D print_texture : source_color, filter_linear_mipmap;
uniform bool use_print = true;
uniform vec4 paper_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float base_roughness : hint_range(0.75, 1.0) = 0.92;
uniform float fiber_strength : hint_range(0.0, 0.12) = 0.035;
uniform float fiber_scale : hint_range(40.0, 420.0) = 210.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float paper_fiber(vec2 uv) {
	vec2 p = uv * vec2(fiber_scale * 0.62, fiber_scale);
	vec2 cell = floor(p);
	vec2 local = fract(p);
	float coarse = hash21(cell);
	float next = hash21(cell + vec2(0.0, 1.0));
	float strand = mix(coarse, next, smoothstep(0.0, 1.0, local.y));
	float long_fiber = sin((uv.y * fiber_scale * 0.44) + sin(uv.x * 31.0) * 1.8) * 0.5 + 0.5;
	float cross_fiber = sin((uv.x * fiber_scale * 0.16) + uv.y * 19.0) * 0.5 + 0.5;
	return clamp(strand * 0.48 + long_fiber * 0.36 + cross_fiber * 0.16, 0.0, 1.0);
}

void fragment() {
	vec4 printed = texture(print_texture, UV);
	vec3 base = use_print ? printed.rgb * paper_tint.rgb : paper_tint.rgb;
	float fiber = paper_fiber(UV);
	float centered = fiber - 0.5;
	ALBEDO = base * (1.0 + centered * fiber_strength * 0.72);
	ROUGHNESS = clamp(base_roughness + centered * fiber_strength * 0.80, 0.78, 1.0);
	METALLIC = 0.0;
	SPECULAR = use_print ? 0.16 : 0.08;

	float eps = 1.0 / max(fiber_scale, 1.0);
	float dx = paper_fiber(UV + vec2(eps, 0.0)) - paper_fiber(UV - vec2(eps, 0.0));
	float dy = paper_fiber(UV + vec2(0.0, eps)) - paper_fiber(UV - vec2(0.0, eps));
	NORMAL_MAP = vec3(0.5 - dx * fiber_strength * 1.8, 0.5 - dy * fiber_strength * 1.8, 1.0);
	NORMAL_MAP_DEPTH = clamp(fiber_strength * 1.7, 0.0, 0.20);
}
