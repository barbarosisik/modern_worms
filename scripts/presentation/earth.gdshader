shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec4 grass_color : source_color = vec4(0.49, 0.69, 0.30, 1.0);
uniform vec4 soil_color : source_color = vec4(0.55, 0.32, 0.22, 1.0);
varying vec3 point;

float tile_seed(vec2 tile) {
	return fract(sin(dot(tile, vec2(19.43, 71.17))) * 17431.13);
}

void vertex() {
	point = VERTEX;
}

void fragment() {
	// World-sized clay layers follow the same coordinates across every chunk.
	float bend = sin(point.x * 0.60) * 0.30 + sin(point.x * 0.21) * 0.33;
	float strata = (point.y + bend) * 0.58;
	float layer = fract(strata);
	float seam = 1.0 - smoothstep(0.035, 0.11, abs(layer - 0.29));
	float clay = mix(0.84, 1.26, smoothstep(0.30, 0.60, layer));
	float depth_light = mix(0.77, 1.18, smoothstep(1.0, 7.8, point.y));
	vec3 earth = soil_color.rgb * clay * depth_light * (1.0 - seam * 0.18);

	// Sparse rounded flecks give the cutaway side some scale from the normal camera.
	vec2 pebble_grid = point.xy * vec2(1.10, 1.70);
	float seed = tile_seed(floor(pebble_grid));
	vec2 center = vec2(0.27 + seed * 0.42, 0.30 + fract(seed * 4.21) * 0.42);
	vec2 pebble = (fract(pebble_grid) - center) * vec2(1.0, 1.85);
	float grain = (1.0 - smoothstep(0.055, 0.104, length(pebble))) * step(0.54, seed);
	earth = mix(earth, soil_color.rgb * 1.62, grain * 0.48);

	float leaf = sin(point.x * 2.7 + point.z * 1.2) * 0.5 + 0.5;
	vec3 grass = grass_color.rgb * mix(0.87, 1.14, leaf);
	// Only the existing contour and grass mask can draw here. Blast holes stay empty.
	ALBEDO = mix(earth, grass, COLOR.g);
	ROUGHNESS = 1.0;
}
