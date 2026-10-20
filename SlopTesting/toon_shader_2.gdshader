shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, cull_disabled, shadows_disabled;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;

// Light direction (the direction the light travels, like your original)
uniform vec3 light_direction = vec3(0.5, 0.0, 0.0);
// false = view space (same behavior as your original shader, where NORMAL was view space)
// true  = world space (light stays fixed in the world as the camera turns)
uniform bool light_in_world_space = true;

// Colors per lighting band
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 mid1_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec4 mid2_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.3, 0.3, 0.3, 1.0);

// Thresholds
uniform float highlight_threshold : hint_range(0.0, 1.0) = 0.85;
uniform float mid1_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float mid2_threshold : hint_range(0.0, 1.0) = 0.35;

// Softness between bands
uniform float smoothness : hint_range(0.0, 1.0) = 0.1;

uniform float brightness = 1.5;
uniform float effect_strength : hint_range(0.0, 1.0, 0.05) = 1.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec3 screen = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float raw_depth = texture(depth_texture, SCREEN_UV).r;

	// Sky / nothing rendered here (reversed-Z: far plane = 0.0): leave untouched
	if (raw_depth < 0.00001) {
		ALBEDO = screen;
		ALPHA = 1.0;
	} else {
		vec3 normal = normalize(texture(normal_roughness_texture, SCREEN_UV).xyz * 2.0 - 1.0);

		vec3 light_dir = normalize(light_direction);
		if (light_in_world_space) {
			light_dir = normalize((VIEW_MATRIX * vec4(light_dir, 0.0)).xyz);
		}

		float NdotL = max(dot(normal, -light_dir), 0.0);

		// Stack the bands from darkest to brightest.
		// A tiny minimum keeps smoothstep valid when smoothness = 0 (hard edges).
		float s = max(smoothness * 0.5, 0.0001);

		vec3 toon_color = shadow_color.rgb;
		toon_color = mix(toon_color, mid2_color.rgb,      smoothstep(mid2_threshold - s,      mid2_threshold + s,      NdotL));
		toon_color = mix(toon_color, mid1_color.rgb,      smoothstep(mid1_threshold - s,      mid1_threshold + s,      NdotL));
		toon_color = mix(toon_color, highlight_color.rgb, smoothstep(highlight_threshold - s, highlight_threshold + s, NdotL));

		vec3 result = screen * toon_color * brightness;

		ALBEDO = mix(screen, result, effect_strength);
		ALPHA = 1.0;
	}
}