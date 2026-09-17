shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.94, 0.61, 0.43, 1.0);
uniform float texture_strength : hint_range(0.0, 0.15) = 0.035;
uniform float texture_scale : hint_range(1.0, 24.0) = 7.0;
uniform float edge_light : hint_range(0.0, 0.3) = 0.08;
uniform float material_roughness : hint_range(0.0, 1.0) = 0.82;

float random_value(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 fraction = fract(point);
	fraction = fraction * fraction * (3.0 - 2.0 * fraction);
	float a = random_value(cell);
	float b = random_value(cell + vec2(1.0, 0.0));
	float c = random_value(cell + vec2(0.0, 1.0));
	float d = random_value(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, fraction.x), mix(c, d, fraction.x), fraction.y);
}

void fragment() {
	// FBX je obojstranny, takze opravime svetelny smer aj pri otocenych normalach.
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	float broad_noise = value_noise(UV * texture_scale);
	float fine_noise = value_noise(UV * texture_scale * 2.7);
	float ambient_texture = (broad_noise * 0.72 + fine_noise * 0.28 - 0.5) * texture_strength;
	float soft_rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.5);

	ALBEDO = base_color.rgb * (1.0 + ambient_texture) + soft_rim * edge_light * base_color.rgb;
	ROUGHNESS = material_roughness;
	SPECULAR = 0.18;
}
