shader_type spatial;
render_mode cull_back;

uniform vec4 paper_color : source_color = vec4(0.95, 0.935, 0.895, 1.0);
uniform float squeeze_amount : hint_range(0.0, 0.16) = 0.0;
uniform float squeeze_center_y = 0.02;
uniform float fiber_strength : hint_range(0.0, 0.08) = 0.022;

float paper_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	// A real pinch is localized around the fingers. Preserve cup mouth/base
	// dimensions and compress only a broad waist band, with a small depth bulge.
	float dy = (VERTEX.y - squeeze_center_y) / 0.46;
	float band = exp(-dy * dy * 1.45);
	float pinch = squeeze_amount * band;
	VERTEX.x *= 1.0 - pinch;
	VERTEX.z *= 1.0 + pinch * 0.34;
	// Give the compressed wall a tiny asymmetric buckle rather than a perfect
	// scale ellipse. Deterministic sine keeps it calm and repeatable.
	VERTEX.x += sin(VERTEX.y * 8.0 + VERTEX.z * 4.0) * pinch * 0.008;
}

void fragment() {
	vec2 fiber_cell = floor(UV * vec2(420.0, 860.0));
	float fleck = (paper_hash(fiber_cell) - 0.5) * 2.0;
	float strand = sin((UV.y + sin(UV.x * 31.0) * 0.004) * 920.0) * 0.5;
	float fiber = (fleck * 0.64 + strand * 0.36) * fiber_strength;
	ALBEDO = clamp(paper_color.rgb + vec3(fiber), vec3(0.0), vec3(1.0));
	ROUGHNESS = clamp(0.95 + abs(fiber) * 0.55, 0.90, 1.0);
	SPECULAR = 0.18;
}
