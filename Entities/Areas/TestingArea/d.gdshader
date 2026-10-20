shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, cull_disabled, shadows_disabled;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;

group_uniforms Shader.Light;
uniform vec3 light_direction = vec3(0.3, 0.8, 0.5); // WORLD space, pointing TOWARD the light
uniform vec4 light_color : source_color = vec4(1.0);
uniform vec4 ambient : source_color = vec4(0.15, 0.15, 0.15, 1.0);
uniform bool use_stepped = true;
uniform float steps = 3.0;
uniform float step_smoothness : hint_range(0.0, 1.0, 0.05) = 0.3;
uniform vec4 shadow_tint : source_color;
uniform float shadow_tint_amount : hint_range(0.0, 1.0, 0.1) = 0.4;

group_uniforms Shader.Specular;
uniform float specular : hint_range(0.0, 1.0, 0.05) = 0.0;

group_uniforms Shader.Rim;
uniform bool use_rim = true;
uniform vec4 rim_color : source_color = vec4(1.0);
uniform float rim_amount = 2.0;
uniform float rim_smoothness = 0.2;
uniform float rim_mask_shadow : hint_range(0.0, 1.0, 0.05) = 1.0;
uniform float rim_blend : hint_range(0.0, 1.0, 0.05) = 1.0;

group_uniforms Shader.Pattern;
uniform bool use_pattern = true;
uniform sampler2D pattern_texture : repeat_enable;
uniform float pattern_tiling = 32.0;
uniform float pattern_amount : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float pattern_smoothness : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float pattern_blend : hint_range(0.0, 1.0, 0.05) = 0.2;

group_uniforms Shader.Output;
uniform float effect_strength : hint_range(0.0, 1.0, 0.05) = 1.0;

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), amount);
}

float shape_value(float value, vec2 uv, vec2 screen_size) {
	float aspect = screen_size.y / screen_size.x;
	vec2 p_uv = uv * pattern_tiling * vec2(1.0, aspect);
	float shadow_pattern = texture(pattern_texture, p_uv).r;
	shadow_pattern = clamp(
		smoothstep(shadow_pattern - pattern_smoothness, shadow_pattern + pattern_smoothness, value + pattern_amount),
		0.0, value + pattern_amount);
	return shadow_pattern;
}

void vertex() {
	// Fullscreen quad, always at the near plane (reversed-Z => z = 1.0)
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec3 screen = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float raw_depth = texture(depth_texture, SCREEN_UV).r;

	// Sky / nothing rendered here (far plane is 0.0 with reversed-Z): leave untouched
	if (raw_depth < 0.00001) {
		ALBEDO = screen;
		ALPHA = 1.0;
	} else {
		// Reconstruct view-space position -> view vector
		vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
		vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		view_pos.xyz /= view_pos.w;
		vec3 view_dir = normalize(-view_pos.xyz);

		// Scene normals (view space) and light direction (converted to view space)
		vec3 normal = normalize(texture(normal_roughness_texture, SCREEN_UV).xyz * 2.0 - 1.0);
		vec3 light_dir = normalize((VIEW_MATRIX * vec4(normalize(light_direction), 0.0)).xyz);

		float light = clamp(dot(normal, light_dir), 0.0, 1.0);

		if (use_stepped) {
			float light_mult = light * steps;
			float step_base = floor(light_mult);
			float light_factor = light_mult - step_base;
			light_factor = smoothstep(0.5 - step_smoothness, 0.5 + step_smoothness, light_factor);
			light = (step_base + light_factor) / steps;
		}

		if (use_pattern) {
			light = mix(light, shape_value(light, SCREEN_UV, VIEWPORT_SIZE), pattern_blend);
		}

		vec3 diffuse = vec3(light) * light_color.rgb;
		diffuse = (shadow_tint.rgb * (1.0 - light) * shadow_tint_amount) + diffuse * light;

		if (use_rim) {
			float rim_value = fresnel(rim_amount, normal, view_dir);
			rim_value = smoothstep(0.5 - (rim_smoothness / 2.0), 0.5 + (rim_smoothness / 2.0), rim_value);
			rim_value = mix(rim_value, rim_value * light, rim_mask_shadow);
			diffuse += rim_color.rgb * rim_value * rim_blend;
		}

		vec3 toon = screen * (ambient.rgb + diffuse);
		toon += vec3(pow(light, 50.0)) * specular;

		ALBEDO = mix(screen, toon, effect_strength);
		ALPHA = 1.0;
	}
}