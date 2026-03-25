shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

// Lough Key water shader - dark Irish lake water with gentle waves

uniform vec4 deep_color : source_color = vec4(0.05, 0.15, 0.12, 0.85);
uniform vec4 shallow_color : source_color = vec4(0.1, 0.3, 0.2, 0.6);
uniform float wave_speed : hint_range(0.0, 0.1) = 0.02;
uniform float wave_strength : hint_range(0.0, 1.0) = 0.15;
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.8;
uniform float fresnel_power : hint_range(0.0, 10.0) = 4.0;
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.4;
uniform float ripple_scale : hint_range(0.1, 20.0) = 3.0;

varying vec3 world_pos;

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

float wave(vec2 p, float time) {
	float w = 0.0;
	// Multiple wave layers for realistic surface
	w += sin(p.x * 0.5 + time * 0.8) * 0.3;
	w += sin(p.y * 0.7 + time * 0.6) * 0.25;
	w += sin((p.x + p.y) * 0.3 + time * 1.2) * 0.2;
	w += noise(p * ripple_scale + time * 0.5) * 0.4;
	w += noise(p * ripple_scale * 2.0 - time * 0.3) * 0.2;
	return w;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Gentle vertex displacement for wave geometry
	float w = wave(world_pos.xz, TIME * wave_speed * 10.0);
	VERTEX.y += w * wave_strength;

	// Calculate normals from wave displacement
	float e = 0.1;
	float h1 = wave(world_pos.xz + vec2(e, 0.0), TIME * wave_speed * 10.0) * wave_strength;
	float h2 = wave(world_pos.xz + vec2(0.0, e), TIME * wave_speed * 10.0) * wave_strength;
	float h0 = w * wave_strength;

	vec3 wave_normal = normalize(vec3(h0 - h1, e, h0 - h2));
	NORMAL = wave_normal;
}

void fragment() {
	// Fresnel effect - more reflective at glancing angles
	float fresnel = pow(1.0 - abs(dot(NORMAL, VIEW)), fresnel_power);

	// Depth-based color (shallow vs deep)
	// Use screen depth if available, otherwise use distance from center
	float depth_factor = 0.5;

	vec4 water_color = mix(deep_color, shallow_color, depth_factor);

	// Add reflection tint
	vec3 sky_color = vec3(0.4, 0.5, 0.55); // Overcast Irish sky
	vec3 final_color = mix(water_color.rgb, sky_color, fresnel * reflection_strength);

	// Subtle foam on wave peaks
	float w = wave(world_pos.xz, TIME * wave_speed * 10.0);
	float foam = smoothstep(foam_threshold, 1.0, w);
	final_color = mix(final_color, vec3(0.7, 0.75, 0.7), foam * 0.3);

	// Caustic patterns underwater (subtle)
	float caustic = noise(world_pos.xz * 2.0 + TIME * 0.1);
	caustic = smoothstep(0.4, 0.6, caustic);
	final_color += vec3(0.02, 0.04, 0.03) * caustic;

	ALBEDO = final_color;
	ALPHA = mix(water_color.a, 1.0, fresnel * 0.5);
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	SPECULAR = 0.8;
}
