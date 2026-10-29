extends Node
## 효과음과 배경음 (PRD #4-P1-6, #8).
## 공격음(attack)과 배경음은 assets/sounds 의 파일을 쓰고, 나머지 임시 효과음은 코드로 합성한다.
## 나중에 진짜 소리로 바꿀 때는 _streams에 같은 이름으로 불러온 AudioStream을 넣으면 된다.
## 자동 로드(Sfx)라서 어디서나 Sfx.play("hit")처럼 부른다.

const RATE := 22050
const VOICES := 14
const ATTACK_SOUND := preload("res://assets/sounds/attack.wav")
## 반복 재생은 bgm.mp3.import 의 loop=true 로 켜 두었다.
const BGM := preload("res://assets/sounds/bgm.mp3")
const BGM_VOLUME_DB := -8.0
## 같은 소리를 너무 자주 겹쳐 내지 않도록 최소 간격(밀리초)
const MIN_GAP := { "hit": 45, "kill": 55, "pickup": 35, "card": 0 }

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _last_play := {}
var _next_voice := 0
var _bgm: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_streams = {
		"attack": ATTACK_SOUND,
		"hit": _wav(_synth_hit()),
		"kill": _wav(_synth_kill()),
		"hurt": _wav(_synth_hurt()),
		"pickup": _wav(_synth_pickup()),
		"levelup": _wav(_synth_levelup()),
		"card": _wav(_synth_card()),
		"select": _wav(_synth_select()),
		"bell": _wav(_synth_bell()),
		"roar": _wav(_synth_roar()),
		"throw": _wav(_synth_throw()),
		"explosion": _wav(_synth_explosion()),
	}
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_bgm = AudioStreamPlayer.new()
	_bgm.stream = BGM
	_bgm.volume_db = BGM_VOLUME_DB
	add_child(_bgm)
	_bgm.play()


func play(sound: String, volume_db := 0.0, pitch_jitter := 0.08) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_play.get(sound, -100000) < MIN_GAP.get(sound, 30):
		return
	_last_play[sound] = now
	var p := _players[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	p.stream = _streams[sound]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


# ---------------------------------------------------------------- 합성

func _wav(samples: PackedFloat32Array, rate := RATE, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = samples.size()
	return w


func _buffer(seconds: float, rate := RATE) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * rate))
	return b


## 퍽 하는 타격음: 짧은 잡음 + 낮은 쿵
func _synth_hit() -> PackedFloat32Array:
	var b := _buffer(0.09)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (randf_range(-1, 1) * 0.5 + sin(TAU * 140.0 * t) * 0.7) * exp(-t * 45.0) * 0.6
	return b


## 찢어지는 사망음: 걸러진 잡음 + 아래로 떨어지는 음
func _synth_kill() -> PackedFloat32Array:
	var b := _buffer(0.25)
	var low := 0.0
	var phase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		low += 0.25 * (randf_range(-1, 1) - low)
		phase += TAU * lerpf(220.0, 55.0, t / 0.25) / RATE
		b[i] = (low * 0.9 + sin(phase) * 0.5) * exp(-t * 13.0) * 0.55
	return b


func _synth_hurt() -> PackedFloat32Array:
	var b := _buffer(0.3)
	for i in b.size():
		var t := float(i) / RATE
		var square := 1.0 if sin(TAU * 98.0 * t) > 0.0 else -1.0
		b[i] = (square * 0.35 + randf_range(-1, 1) * 0.3) * exp(-t * 10.0) * 0.6
	return b


func _synth_pickup() -> PackedFloat32Array:
	var b := _buffer(0.07)
	var phase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		phase += TAU * lerpf(700.0, 1050.0, t / 0.07) / RATE
		b[i] = sin(phase) * exp(-t * 40.0) * 0.25
	return b


## 어두운 단조 아르페지오
func _synth_levelup() -> PackedFloat32Array:
	var notes := [220.0, 261.63, 329.63, 440.0, 392.0]
	var step := 0.13
	var b := _buffer(step * notes.size() + 0.6)
	for n in notes.size():
		var start := int(n * step * RATE)
		for i in range(start, b.size()):
			var t := float(i - start) / RATE
			var f: float = notes[n]
			b[i] += (sin(TAU * f * t) + 0.4 * sin(TAU * f * 2.0 * t)) * exp(-t * 5.0) * 0.18
	return b


func _synth_card() -> PackedFloat32Array:
	var b := _buffer(0.06)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (randf_range(-1, 1) * 0.4 + sin(TAU * 180.0 * t) * 0.6) * exp(-t * 60.0) * 0.5
	return b


func _synth_select() -> PackedFloat32Array:
	var b := _buffer(0.6)
	for i in b.size():
		var t := float(i) / RATE
		var thump := sin(TAU * 70.0 * t) * exp(-t * 18.0)
		var chime := (sin(TAU * 659.25 * t) + 0.5 * sin(TAU * 987.77 * t)) * exp(-t * 6.0) * 0.3
		b[i] = (thump + chime) * 0.5
	return b


## 낮고 긴 종소리: 비화성 배음이 서로 다르게 사라진다
func _synth_bell() -> PackedFloat32Array:
	var partials := [[1.0, 1.0, 0.9], [2.0, 0.6, 1.4], [2.76, 0.5, 1.9], [5.4, 0.3, 3.0], [8.9, 0.15, 4.5]]
	var base := 98.0
	var b := _buffer(3.5)
	for i in b.size():
		var t := float(i) / RATE
		var s := 0.0
		for p in partials:
			s += sin(TAU * base * p[0] * t) * p[1] * exp(-t * p[2])
		s += randf_range(-1, 1) * exp(-t * 40.0) * 0.3
		b[i] = s * 0.3
	return b


func _synth_roar() -> PackedFloat32Array:
	var b := _buffer(0.9)
	var low := 0.0
	for i in b.size():
		var t := float(i) / RATE
		low += 0.08 * (randf_range(-1, 1) - low)
		var growl := sin(TAU * 55.0 * t + sin(TAU * 7.0 * t) * 2.0)
		var env := minf(t / 0.08, 1.0) * exp(-t * 2.5)
		b[i] = (low * 2.5 + growl * 0.5) * env * 0.5
	return b


func _synth_throw() -> PackedFloat32Array:
	var b := _buffer(0.3)
	var low := 0.0
	for i in b.size():
		var t := float(i) / RATE
		low += lerpf(0.05, 0.4, t / 0.3) * (randf_range(-1, 1) - low)
		b[i] = low * sin(PI * t / 0.3) * 0.6
	return b


func _synth_explosion() -> PackedFloat32Array:
	var b := _buffer(1.8)
	var low := 0.0
	for i in b.size():
		var t := float(i) / RATE
		low += 0.05 * (randf_range(-1, 1) - low)
		b[i] = (low * 3.0 + sin(TAU * 42.0 * t) * 0.6) * exp(-t * 2.2) * 0.6
	return b

