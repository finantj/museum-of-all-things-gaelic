shader_type spatial;

// Terrain shader for medieval Ireland landscape
// Uses vertex colors for terrain splatting

varying vec3 world_pos;
varying float height;

uniform float grass_roughness : hint_range(0.0, 1.0) = 0.85;
uniform float rock_roughness : hint_range(0.0, 1.0) = 0.75;
uniform float detail_scale : hint_range(0.1, 50.0) = 15.0;

// Simple noise for detail
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = world_pos.y;
}

void fragment() {
	// Base color from vertex color (set by terrain generator)
	vec3 base_color = COLOR.rgb;

	// Add noise detail for natural variation
	float detail = fbm(world_pos.xz * detail_scale);
	base_color = mix(base_color, base_color * 1.2, detail * 0.15);

	// Slope-based rock blending
	float slope = 1.0 - NORMAL.y;
	vec3 rock_color = vec3(0.4, 0.38, 0.35);
	base_color = mix(base_color, rock_color, smoothstep(0.3, 0.7, slope));

	// Wetness near water level
	float wetness = smoothstep(1.5, -0.5, height);
	base_color = mix(base_color, base_color * 0.7, wetness * 0.4);

	ALBEDO = base_color;

	// Roughness varies by terrain type
	float roughness = mix(grass_roughness, rock_roughness, smoothstep(0.3, 0.7, slope));
	roughness = mix(roughness, 0.5, wetness * 0.5); // Wet surfaces less rough
	ROUGHNESS = roughness;

	// Subtle normal variation for grass texture
	float nx = fbm(world_pos.xz * detail_scale + vec2(100.0, 0.0)) - 0.5;
	float nz = fbm(world_pos.xz * detail_scale + vec2(0.0, 100.0)) - 0.5;
	NORMAL_MAP = vec3(nx * 0.15 + 0.5, nz * 0.15 + 0.5, 1.0);

	METALLIC = 0.0;
	SPECULAR = 0.3;
}
