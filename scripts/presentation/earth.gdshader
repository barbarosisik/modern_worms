shader_type spatial;
render_mode diffuse_toon, specular_disabled;
varying vec3 point;
void vertex() { point = VERTEX; }
void fragment() {
 float wave = sin(point.x * 0.75) * 0.16 + sin(point.x * 1.6) * 0.06;
 float band = smoothstep(0.45, 0.52, fract((point.y + wave) * 0.43));
 vec3 earth = mix(vec3(0.40,0.21,0.14), vec3(0.54,0.30,0.19), band * 0.38);
 vec3 turf = vec3(0.36,0.64,0.18);
 ALBEDO = mix(earth, turf, COLOR.g);
 ROUGHNESS = 1.0;
}
