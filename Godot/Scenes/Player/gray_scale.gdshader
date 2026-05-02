shader_type canvas_item;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    // Calculate luminosity (weighted for natural eye perception)
    float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    COLOR = vec4(vec3(gray), col.a); // Keep original alpha
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
