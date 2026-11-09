class_name ArtilleryAudio
extends RefCounted


static func tone(duration: float, start_pitch: float, end_pitch: float) -> AudioStreamWAV:
	if DisplayServer.get_name() == "headless":
		return null
	const RATE := 22050
	var sample_count := roundi(duration * RATE)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var phase := 0.0
	for i in range(sample_count):
		var progress := float(i) / sample_count
		var amplitude := minf(1.0, progress * 65.0) * pow(1.0 - progress, 2.0) * 0.26
		phase += TAU * lerpf(start_pitch, end_pitch, progress) / RATE
		pcm.encode_s16(i * 2, roundi(sin(phase) * amplitude * 32767.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = RATE
	sound.data = pcm
	return sound
