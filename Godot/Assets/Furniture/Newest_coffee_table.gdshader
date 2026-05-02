shader_type spatial;
uniform sampler2D albedo_tex;

void fragment() {
    vec4 texc = texture(albedo_tex, UV);
    // Calculate luminosity
    float lightness = 0.2126 * texc.r + 0.7152 * texc.g + 0.0722 * texc.b;
    ALBEDO = vec3(lightness);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
