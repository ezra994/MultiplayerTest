shader_type canvas_item;

// Godot 4.7 requires explicit screen texture declaration
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform int color_depth : hint_range(1, 8) = 5;
uniform bool dithering = true;

const mat4 pattern = mat4(
    vec4(-4.0, +0.0, -3.0, +1.0),
    vec4(+2.0, -2.0, +3.0, -1.0),
    vec4(-3.0, +1.0, -4.0, +0.0),
    vec4(+3.0, -1.0, +2.0, -2.0)
);

int dithering_pattern(ivec2 fragcoord) {
    int x = fragcoord.x % 4;
    int y = fragcoord.y % 4;

    vec4 pattern_vec4;

    if (y == 0) pattern_vec4 = pattern[0];
    else if (y == 1) pattern_vec4 = pattern[1];
    else if (y == 2) pattern_vec4 = pattern[2];
    else if (y == 3) pattern_vec4 = pattern[3];

    float pattern_int = 0.0;

    if (x == 0) pattern_int = pattern_vec4.x;
    else if (x == 1) pattern_int = pattern_vec4.y;
    else if (x == 2) pattern_int = pattern_vec4.z;
    else if (x == 3) pattern_int = pattern_vec4.w;

    return int(pattern_int);
}

void fragment() {
    // SCREEN_PIXEL_SIZE is 1/resolution. 
    // Inverting it gives us the game's actual pixel width/height.
    vec2 pixel_size = 1.0 / SCREEN_PIXEL_SIZE;
    
    // Using textureLod instead of texture is standard practice in Godot 4 screen shaders
    vec2 uv_snapped = round(SCREEN_UV * pixel_size) / pixel_size;
    vec3 color = textureLod(screen_texture, uv_snapped, 0.0).rgb;
    
    // Convert from [0.0, 1.0] range to [0, 255] range
    ivec3 c = ivec3(round(color * 255.0));
    
    if (dithering) {
        c += ivec3(dithering_pattern(ivec2(FRAGCOORD.xy)));
    }
    
    // Truncate from 8 bits to color_depth bits
    int shift = int(pow(2.0, float(8 - color_depth)));
    c = c / shift;
    
    // Convert back
    c = c * shift;
    
    COLOR.rgb = clamp(vec3(c) / 255.0, 0.0, 1.0);
}