shader_type spatial;
render_mode cull_disabled;
varying vec3 world_point;
void vertex() { world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float ripple = sin(world_point.x * 2.7 + world_point.z * 3.0 + TIME * 1.1);
	float line = smoothstep(0.96, 1.0, ripple);
	ALBEDO = mix(vec3(0.12, 0.40, 0.46), vec3(0.48, 0.73, 0.68), line * 0.42);
	ROUGHNESS = 0.34;
	METALLIC = 0.15;
}
