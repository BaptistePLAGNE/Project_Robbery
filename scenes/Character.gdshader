shader_type canvas_item;

uniform bool active = false;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	if (active) {
		// Calculate standard luminance for grayscale
		float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
		COLOR = vec4(vec3(gray), tex_color.a);
		} else {
			// Keep original colors
		COLOR = tex_color;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
