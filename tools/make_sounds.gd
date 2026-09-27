extends SceneTree
## Synthesizes every sound effect and the music loop into res://audio/*.wav.
## Run after changing a sound: godot --headless -s res://tools/make_sounds.gd && godot --headless --import

const RATE := 22050
const OUT_DIR := "res://audio/"
const BEAT := 60.0 / 120.0

## Effect layers: wave, start freq, end freq, start time, duration, volume.
const EFFECTS := {
	"jump": [["square", 320.0, 720.0, 0.0, 0.14, 0.25]],
	"slide": [["noise", 0.0, 0.0, 0.0, 0.25, 0.45]],
	"drop": [["sine", 220.0, 90.0, 0.0, 0.14, 0.7], ["noise", 0.0, 0.0, 0.0, 0.05, 0.25]],
	"hit": [["sine", 180.0, 50.0, 0.0, 0.25, 0.8], ["noise", 0.0, 0.0, 0.0, 0.12, 0.5], ["square", 420.0, 200.0, 0.0, 0.1, 0.15]],
	"knockout": [["sine", 160.0, 40.0, 0.0, 0.4, 0.9], ["square", 600.0, 90.0, 0.0, 0.6, 0.2], ["noise", 0.0, 0.0, 0.0, 0.2, 0.4]],
	"combo": [["square", 523.25, 523.25, 0.0, 0.08, 0.3], ["square", 659.25, 659.25, 0.07, 0.08, 0.3], ["square", 783.99, 783.99, 0.14, 0.08, 0.3], ["square", 1046.5, 1046.5, 0.21, 0.18, 0.3]],
	"win": [["triangle", 523.25, 523.25, 0.0, 0.14, 0.4], ["triangle", 659.25, 659.25, 0.13, 0.14, 0.4], ["triangle", 783.99, 783.99, 0.26, 0.14, 0.4], ["triangle", 1046.5, 1046.5, 0.39, 0.5, 0.4], ["square", 523.25, 523.25, 0.39, 0.5, 0.1]],
	"lose": [["triangle", 392.0, 392.0, 0.0, 0.2, 0.4], ["triangle", 329.63, 329.63, 0.2, 0.2, 0.4], ["triangle", 261.63, 240.0, 0.4, 0.6, 0.4]],
	"click": [["sine", 1400.0, 1000.0, 0.0, 0.035, 0.35]],
}

## Music: one chord per bar as MIDI notes, root first.
const CHORDS := [[48, 60, 64, 67], [45, 57, 60, 64], [41, 53, 57, 60], [43, 55, 59, 62]]
const BARS := 8


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for sound: String in EFFECTS:
		_save(sound, _render_effect(EFFECTS[sound]))
	_save("music", _render_music())
	print("DONE")
	quit()


func _render_effect(layers: Array) -> PackedFloat32Array:
	var length := 0.0
	for layer: Array in layers:
		length = maxf(length, layer[3] + layer[4])
	var samples := PackedFloat32Array()
	samples.resize(int(length * RATE) + 1)
	for layer: Array in layers:
		_add_note(samples, layer[0], layer[1], layer[2], layer[3], layer[4], layer[5], 0.005)
	return samples


func _render_music() -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(BARS * 4 * BEAT * RATE))
	for bar in BARS:
		var chord: Array = CHORDS[bar % CHORDS.size()]
		var bar_start := bar * 4 * BEAT
		for eighth in 8:
			var t := bar_start + eighth * BEAT / 2.0
			# Bass bounces between root and its octave.
			var bass := _midi(chord[0] + (12 if eighth % 2 == 1 else 0))
			_add_note(samples, "triangle", bass, bass, t, BEAT / 2.0 * 0.9, 0.3, 0.005)
			# Hi-hat on the off-beats.
			if eighth % 2 == 1:
				_add_note(samples, "noise", 0.0, 0.0, t, 0.03, 0.06, 0.001)
		for beat in 4:
			var t := bar_start + beat * BEAT
			_add_note(samples, "sine", 130.0, 45.0, t, 0.12, 0.45, 0.002)
		for sixteenth in 16:
			var t := bar_start + sixteenth * BEAT / 4.0
			var note: int = chord[1 + sixteenth % 3] + 12
			_add_note(samples, "pulse", _midi(note), _midi(note), t, BEAT / 4.0 * 0.7, 0.06, 0.003)
	return samples


## Mixes one note into samples, with a quick attack and exponential decay.
func _add_note(samples: PackedFloat32Array, wave: String, freq_start: float, freq_end: float,
		start: float, duration: float, volume: float, attack: float) -> void:
	var first := int(start * RATE)
	var count := int(duration * RATE)
	var phase := 0.0
	var noise_value := 0.0
	for i in count:
		var index := first + i
		if index >= samples.size():
			return
		var progress := float(i) / count
		var freq := lerpf(freq_start, freq_end, progress)
		phase = fmod(phase + freq / RATE, 1.0)
		var value := 0.0
		match wave:
			"sine":
				value = sin(TAU * phase)
			"square":
				value = 1.0 if phase < 0.5 else -1.0
			"pulse":
				value = 1.0 if phase < 0.25 else -1.0
			"triangle":
				value = 4.0 * absf(phase - 0.5) - 1.0
			"noise":
				# Slightly low-passed white noise.
				noise_value = lerpf(noise_value, randf_range(-1.0, 1.0), 0.6)
				value = noise_value
		var time := float(i) / RATE
		var envelope := minf(time / attack, 1.0) * pow(1.0 - progress, 2.0)
		samples[index] += value * envelope * volume


func _save(sound: String, samples: PackedFloat32Array) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		# Soft clip so stacked layers never wrap around.
		data.encode_s16(i * 2, int(tanh(samples[i]) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	stream.save_to_wav(OUT_DIR + sound + ".wav")


func _midi(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)
