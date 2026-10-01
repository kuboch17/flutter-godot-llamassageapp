shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_always;

uniform vec4 line_color : source_color = vec4(0.04, 0.55, 1.0, 1.0);
uniform float dash_length : hint_range(0.001, 0.2, 0.001) = 0.035;
uniform float gap_length : hint_range(0.001, 0.2, 0.001) = 0.025;
uniform float edge_softness : hint_range(0.0, 0.02, 0.001) = 0.004;

void fragment() {
	float cycle_length = dash_length + gap_length;
	float distance_on_line = mod(UV.x, cycle_length);
	float dash_mask = 1.0 - smoothstep(dash_length - edge_softness, dash_length + edge_softness, distance_on_line);

	ALBEDO = line_color.rgb;
	ALPHA = line_color.a * dash_mask;

	if (ALPHA <= 0.01) {
		discard;
	}
}
