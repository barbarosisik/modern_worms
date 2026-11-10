shader_type spatial;
varying vec3 local_point;
void vertex() { local_point = VERTEX; }
void fragment() {
	float grain = fract(sin(dot(floor(local_point.xy * 19.0), vec2(12.9898, 78.233))) * 43758.5453);
	float strata = sin(local_point.y * 4.8 + sin(local_point.x * 0.65) * 0.7) * 0.5 + 0.5;
	vec3 soil = mix(vec3(0.29, 0.19, 0.13), vec3(0.46, 0.32, 0.20), strata * 0.55 + grain * 0.15);
	vec3 grass = mix(vec3(0.26, 0.42, 0.13), vec3(0.48, 0.62, 0.22), grain * 0.35 + 0.35);
	ALBEDO = mix(soil, grass, COLOR.g);
	ROUGHNESS = 0.95;
}
