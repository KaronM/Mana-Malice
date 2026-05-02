shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 10.0) = 3.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 color = vec4(0.0);
    float total = 0.0;

    for (float x = -4.0; x <= 4.0; x++) {
        for (float y = -4.0; y <= 4.0; y++) {
            vec2 offset = vec2(x, y) * blur_amount * 0.001;
            color += texture(screen_texture, uv + offset);
            total += 1.0;
        }
    }

    COLOR = color / total;
    COLOR.a = 0.7; // slight dim on top of blur
}