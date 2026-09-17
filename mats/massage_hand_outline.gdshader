shader_type spatial;
render_mode unshaded, depth_draw_never, cull_front;

uniform vec4 outline_color : source_color = vec4(1.0);
uniform float outline_width : hint_range(0.0, 0.02, 0.0001) = 0.0173;
// Kontura zmizne skor ako koza, aby na otvorenom zapasti nevznikol biely oval.
uniform float wrist_fade_start = 0.42;
uniform float wrist_fade_end = 0.78;

varying float wrist_coordinate;

void vertex() {
	wrist_coordinate = VERTEX.y;
	VERTEX += NORMAL * outline_width;
	vec4 clip_position = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float original_depth = clip_position.z / clip_position.w;
	// Godot 4 pouziva reversed-Z: 1.0 je pri kamere, 0.0 je daleko.
	clip_position.z = clip_position.w * (0.979 + original_depth * 0.01);
	POSITION = clip_position;
}

void fragment() {
	float fade = 1.0 - smoothstep(wrist_fade_start, wrist_fade_end, wrist_coordinate);
	float dither = fract(dot(floor(FRAGCOORD.xy), vec2(0.754877666, 0.569840296)));
	if (fade < dither) {
		discard;
	}
	ALBEDO = outline_color.rgb;
}
