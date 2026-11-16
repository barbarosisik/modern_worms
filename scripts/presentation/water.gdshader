shader_type spatial;
render_mode cull_disabled, shadows_disabled, diffuse_toon, specular_disabled;
varying vec3 world_point;
void vertex() { world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float ripple = sin(world_point.x * 2.7 + world_point.z * 3.0 + TIME * 1.1);
	float line = smoothstep(0.5, 1.0, ripple);
	ALBEDO = mix(vec3(0.12, 0.52, 0.65), vec3(0.48, 0.83, 0.85), line * 0.08) * 0.9;
	ROUGHNESS = 0.82;
	METALLIC = 0.0;
}
