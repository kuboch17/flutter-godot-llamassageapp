shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.7685, 0.5459, 0.4111, 1.0);
uniform float wrist_fade_start = 0.38;
uniform float wrist_fade_end = 1.24;
uniform float material_roughness : hint_range(0.0, 1.0) = 0.78;

varying float wrist_coordinate;

void vertex() {
	wrist_coordinate = VERTEX.y;
	// Zachovaj vzajomnu hlbku ploch ruky, ale cely jej rozsah presun tesne
	// pred ostatnu 3D scenu. Dlan tak zakryje zadne prsty a telo nezakryje ruku.
	vec4 clip_position = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float original_depth = clip_position.z / clip_position.w;
	// Godot 4 pouziva reversed-Z: 1.0 je pri kamere, 0.0 je daleko.
	clip_position.z = clip_position.w * (0.98 + original_depth * 0.01);
	POSITION = clip_position;
}

void fragment() {
	float fade = 1.0 - smoothstep(wrist_fade_start, wrist_fade_end, wrist_coordinate);
	// Stabilny screen-door fade ostava v opaque depth passe. Preto sa zadne
	// prsty nezobrazia cez dlan, no zapastie sa vizualne straca postupne.
	float dither = fract(dot(floor(FRAGCOORD.xy), vec2(0.754877666, 0.569840296)));
	if (fade < dither) {
		discard;
	}
	ALBEDO = base_color.rgb;
	ROUGHNESS = material_roughness;
	SPECULAR = 0.16;
}
