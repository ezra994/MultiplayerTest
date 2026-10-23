shader_type spatial;
render_mode depth_prepass_alpha, specular_schlick_ggx, unshaded;

uniform float FresnelPower = 2.5;
uniform vec4 FresnelColor : source_color = vec4(0.6, 0.85, 1.0, 1.0);
uniform vec4 Color : source_color = vec4(0.7, 0.9, 1.0, 1.0);
uniform vec3 Tiling = vec3(1.0, 1.0, 0.0);
uniform vec3 Offset = vec3(0.0, 0.0, 0.0);
uniform sampler2D Ice_Texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float RefractionAmount = 1.0;
uniform float Metallic : hint_range(0.0, 1.0) = 0.134;
uniform float Smoothness : hint_range(0.0, 1.0) = 0.627;
uniform float Normals : hint_range(0.0, 1.0) = 0.77;

// Godot 4: SCREEN_TEXTURE was removed, it is now a uniform with this hint.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
	// Fresnel rim
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), FresnelPower);
	vec3 rim = fresnel * FresnelColor.rgb;

	// Tiling and offset UV
	vec2 ice_uv = mod(UV * Tiling.xy + Offset.xy, vec2(1.0));
	vec4 ice_tex = texture(Ice_Texture, ice_uv);

	// Fake refraction: distort the screen UV using the ice texture's red channel
	float avg = (SCREEN_UV.x + SCREEN_UV.y) / 3.0;
	float shift = avg + avg * ice_tex.r;
	vec2 refracted_uv = SCREEN_UV + (SCREEN_UV - vec2(shift)) * RefractionAmount;
	vec3 screen = texture(screen_texture, clamp(refracted_uv, vec2(0.0), vec2(1.0))).rgb;

	ALBEDO = rim + Color.rgb * (ice_tex.rgb + screen);
	ALPHA = Color.a;
	METALLIC = Metallic;
	ROUGHNESS = 1.0 - Smoothness;

	// Godot 4 replacement for the old read_normalmap() helper / NORMALMAP_DEPTH.
	NORMAL_MAP = ice_tex.rgb;
	NORMAL_MAP_DEPTH = Normals;
}
