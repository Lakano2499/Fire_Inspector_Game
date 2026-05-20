shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Set these to match your screen's aspect ratio (e.g., 64 and 36 is 16:9)
// This keeps the pixels perfectly square!
uniform float pixel_size_x = 64.0; 
uniform float pixel_size_y = 36.0;

void fragment() {
	// Create a chunky grid for square pixels
	vec2 pixelated_uv = vec2(
		floor(UV.x * pixel_size_x) / pixel_size_x,
		floor(UV.y * pixel_size_y) / pixel_size_y
	);
	
	// Read the noise texture
	float noise_val = texture(noise_tex, pixelated_uv).r;
	
	// Combine the X coordinate with the noise. 
	// The 0.3 controls how "deep" or jagged the pixelated edge is.
	float wipe_edge = pixelated_uv.x + (noise_val * 0.3);
	
	// We multiply progress by 1.3 to ensure the wave sweeps completely off the right side
	if (wipe_edge < progress * 1.3) {
		COLOR.a = 0.0;
	}
}