shader_type spatial;
render_mode cull_disabled, shadows_disabled, diffuse_toon, specular_disabled;

varying vec3 world_point;

void vertex() {
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float near_bank = smoothstep(-38.0, 5.0, world_point.z);
	float swell = sin(world_point.z * 1.8 + sin(world_point.x * 0.45) * 0.65 + TIME * 0.78);
	float broken = smoothstep(0.15, 0.85, sin(world_point.x * 1.35 + world_point.z * 0.30 - TIME * 0.31));
	float ripple = smoothstep(0.90, 0.98, swell) * broken * near_bank;
	vec3 river = mix(vec3(0.125, 0.315, 0.34), vec3(0.039, 0.22, 0.27), near_bank);
	ALBEDO = mix(river, vec3(0.29, 0.55, 0.57), ripple * 0.25);
	ROUGHNESS = 0.88;
}
