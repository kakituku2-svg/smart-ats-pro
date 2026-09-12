extends Node

signal event_played(event_id: StringName)

var _cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _music_player: AudioStreamPlayer

func _ready() -> void:
    _music_player = AudioStreamPlayer.new()
    _music_player.name = "MusicPlayer"
    _music_player.volume_db = -17.0
    add_child(_music_player)

func play_event(event_id: StringName) -> void:
    event_played.emit(event_id)
    var stream := _get_or_create_tone(event_id)
    if stream == null:
        return
    var player := AudioStreamPlayer.new()
    player.name = "SFX_%s" % String(event_id)
    player.stream = stream
    player.volume_db = -11.0
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()

func play_music(track_id: StringName) -> void:
    if _music_player == null:
        return
    var stream := _get_or_create_music(track_id)
    if stream == null:
        return
    if _music_player.playing and _music_player.get_meta("track_id", &"") == track_id:
        return
    _music_player.stop()
    _music_player.stream = stream
    _music_player.set_meta("track_id", track_id)
    _music_player.play()

func stop_music() -> void:
    if _music_player != null:
        _music_player.stop()
        _music_player.set_meta("track_id", &"")

func _get_or_create_tone(event_id: StringName) -> AudioStreamWAV:
    if _cache.has(event_id):
        return _cache[event_id] as AudioStreamWAV
    var spec := _tone_spec(event_id)
    if spec.is_empty():
        return null
    var stream := _build_tone(float(spec[0]), float(spec[1]), float(spec[2]))
    _cache[event_id] = stream
    return stream

func _tone_spec(event_id: StringName) -> Array:
    match event_id:
        &"scan": return [720.0, 0.09, 0.34]
        &"capture": return [980.0, 0.18, 0.42]
        &"lure": return [440.0, 0.13, 0.28]
        &"pulse": return [190.0, 0.16, 0.44]
        &"drone": return [610.0, 0.12, 0.26]
        &"relic": return [860.0, 0.20, 0.34]
        &"unlock": return [1260.0, 0.28, 0.40]
        &"stage_clear": return [1080.0, 0.30, 0.40]
        &"warning": return [260.0, 0.10, 0.30]
        &"transfer": return [1180.0, 0.34, 0.42]
        &"transfer_return": return [820.0, 0.34, 0.38]
        &"enemy_hit": return [230.0, 0.08, 0.40]
        &"enemy_down": return [150.0, 0.22, 0.38]
    return []

func _get_or_create_music(track_id: StringName) -> AudioStreamWAV:
    if _music_cache.has(track_id):
        return _music_cache[track_id] as AudioStreamWAV
    var stream: AudioStreamWAV
    match track_id:
        &"transfer_loading":
            stream = _build_loop_music([220.0, 277.18, 329.63, 440.0], 4.0, 0.12)
        &"hub":
            stream = _build_loop_music([164.81, 220.0, 246.94, 329.63], 6.0, 0.075)
        _:
            return null
    _music_cache[track_id] = stream
    return stream

func _build_loop_music(notes: Array, duration: float, amplitude: float) -> AudioStreamWAV:
    var sample_rate := 22050
    var count := int(duration * sample_rate)
    var bytes := PackedByteArray()
    bytes.resize(count * 2)
    var note_duration := duration / float(maxi(notes.size(), 1))
    for i in range(count):
        var t := float(i) / float(sample_rate)
        var note_index := mini(int(t / note_duration), notes.size() - 1)
        var local_t := fmod(t, note_duration)
        var frequency := float(notes[note_index])
        var pulse := 0.72 + sin(TAU * 2.0 * t) * 0.12
        var envelope := 0.60 + 0.40 * sin(clampf(local_t / note_duration, 0.0, 1.0) * PI)
        var tone := sin(TAU * frequency * t) * 0.56
        tone += sin(TAU * frequency * 2.0 * t) * 0.18
        tone += sin(TAU * frequency * 0.5 * t) * 0.14
        var sample := int(clampf(tone * envelope * pulse * amplitude, -1.0, 1.0) * 32767.0)
        bytes.encode_s16(i * 2, sample)
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = sample_rate
    wav.stereo = false
    wav.data = bytes
    wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
    wav.loop_begin = 0
    wav.loop_end = count
    return wav

func _build_tone(frequency: float, duration: float, amplitude: float) -> AudioStreamWAV:
    var sample_rate := 22050
    var count := int(duration * sample_rate)
    var bytes := PackedByteArray()
    bytes.resize(count * 2)
    for i in range(count):
        var t := float(i) / float(sample_rate)
        var progress := float(i) / maxf(float(count - 1), 1.0)
        var envelope := sin(progress * PI)
        var harmonic := sin(TAU * frequency * t) * 0.78 + sin(TAU * frequency * 2.0 * t) * 0.22
        var sample := int(clampf(harmonic * envelope * amplitude, -1.0, 1.0) * 32767.0)
        bytes.encode_s16(i * 2, sample)
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = sample_rate
    wav.stereo = false
    wav.data = bytes
    return wav
