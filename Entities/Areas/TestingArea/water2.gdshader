/**
* Ported from the original unity shader by Erik Roystan Ross
* https://roystan.net/articles/toon-water.html
* https://github.com/IronWarrior/ToonWaterShader
* Camera Depth taken from Bastiaan Olij's video on: https://www.youtube.com/watch?v=Jq3he9Lbj7M
* Updated for Godot 4.x
*/

shader_type spatial;
render_mode depth_draw_never, cull_disabled;

const float SMOOTHSTEP_AA = 0.01;

uniform sampler2D surfaceNoise;
uniform sampler2D distortNoise;

// Screen-space textures (Godot 4 replacement for DEPTH_TEXTURE)
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;

uniform float beer_factor = 0.8;

uniform float foam_distance = 0.01;
uniform float foam_max_distance = 0.4;
uniform float foam_min_distance = 0.04;
uniform vec4 foam_color : source_color = vec4(1.0);

uniform vec2 surface_noise_tiling = vec2(1.0, 4.0);
uniform vec3 surface_noise_scroll = vec3(0.03, 0.03, 0.0);
uniform float surface_noise_cutoff : hint_range(0.0, 1.0) = 0.777;
uniform float surface_distortion_amount : hint_range(0.0, 1.0) = 0.27;

uniform vec4 _DepthGradientShallow : source_color = vec4(0.325, 0.807, 0.971, 0.725);
uniform vec4 _DepthGradientDeep : source_color = vec4(0.086, 0.407, 1.0, 0.749);
uniform float _DepthMaxDistance : hint_range(0.0, 1.0) = 1.0;
uniform float _DepthFactor = 1.0;

varying vec2 noiseUV;
varying vec2 distortUV;

vec4 alphaBlend(vec4 top, vec4 bottom)
{
	vec3 color = (top.rgb * top.a) + (bottom.rgb * (1.0 - top.a));
	float alpha = top.a + bottom.a * (1.0 - top.a);

	return vec4(color, alpha);
}

void vertex() {
	noiseUV = UV * surface_noise_tiling;
	distortUV = UV;
}

void fragment() {
	// Reconstruct view-space position of the scene geometry behind the water
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	float linear_depth = -view_pos.z;

	// Distance between the scene and the water surface along the view ray
	float scene_depth = -view_pos.z;
	float surface_depth = -VERTEX.	z;
	float depth = max(scene_depth - surface_depth, 0.0);
	depth = 1.0 - exp(-depth * beer_factor);
	depth = exp(-depth * beer_factor);
	depth = 1.0 - depth;

	// Real view-space normals of the scene behind the water
	// (replaces the dFdx/dFdy approximation; needs Forward+ or Mobile renderer)
	vec3 existingNormal = texture(normal_roughness_texture, SCREEN_UV).xyz * 2.0 - 1.0;

	float normalDot = clamp(dot(existingNormal, NORMAL), 0.0, 1.0);
	float foamDistance = mix(foam_max_distance, foam_min_distance, normalDot);

	float foamDepth = clamp(depth / foamDistance, 0.0, 1.0);
	float surfaceNoiseCutoff = foamDepth * surface_noise_cutoff;

	vec4 distortNoiseSample = texture(distortNoise, distortUV);
	vec2 distortAmount = (distortNoiseSample.xy * 2.0 - 1.0) * surface_distortion_amount;

	vec2 noise_uv = vec2(
		noiseUV.x + TIME * surface_noise_scroll.x + distortAmount.x,
		noiseUV.y + TIME * surface_noise_scroll.y + distortAmount.y
	);
	float surfaceNoiseSample = texture(surfaceNoise, noise_uv).r;
	float surfaceNoiseAmount = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);

	float waterDepth = clamp(depth / _DepthMaxDistance, 0.0, 1.0) * _DepthFactor;
	vec4 waterColor = mix(_DepthGradientShallow, _DepthGradientDeep, waterDepth);

	vec4 surfaceNoiseColor = foam_color;
	surfaceNoiseColor.a *= surfaceNoiseAmount;
	vec4 color = alphaBlend(surfaceNoiseColor, waterColor);

	ALBEDO = color.rgb;
	ALPHA = color.a;
}