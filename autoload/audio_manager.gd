extends Node
## 全局声音系统：音效池、按关卡切换的原创配乐/环境声，以及对话时自动压低配乐。

const EVENTS := {
	"ui_confirm": ["res://assets/audio/sfx/ui-confirm.ogg"],
	"ui_error": ["res://assets/audio/sfx/ui-error.ogg"],
	"ui_tick": ["res://assets/audio/sfx/ui-tick-1.ogg", "res://assets/audio/sfx/ui-tick-2.ogg"],
	"alert": ["res://assets/audio/sfx/alert.ogg"],
	"step": ["res://assets/audio/sfx/step-1.ogg", "res://assets/audio/sfx/step-2.ogg"],
	"jump": ["res://assets/audio/sfx/jump.ogg"],
	"cloth": ["res://assets/audio/sfx/cloth-1.ogg", "res://assets/audio/sfx/cloth-2.ogg"],
	"forge": ["res://assets/audio/sfx/forge-1.ogg", "res://assets/audio/sfx/forge-2.ogg"],
	"shield_hit": ["res://assets/audio/sfx/shield-1.ogg", "res://assets/audio/sfx/shield-2.ogg"],
	"explosion": ["res://assets/audio/sfx/explosion-1.ogg", "res://assets/audio/sfx/explosion-2.ogg"],
}
const BUS_BY_EVENT := {"ui_confirm": "UI", "ui_error": "UI", "ui_tick": "UI"}
const POOL_SIZE := 12
const SCENE_AUDIO := {
	"res://scenes/kaishi.tscn": ["res://assets/audio/generated/music-01-night.wav", "res://assets/audio/generated/ambient-01-rain.wav"],
	"res://scenes/guanqia/01_hongyadong.tscn": ["res://assets/audio/generated/music-01-night.wav", "res://assets/audio/generated/ambient-01-rain.wav"],
	"res://scenes/guanqia/02_ciqikou.tscn": ["res://assets/audio/generated/music-02-forge.wav", "res://assets/audio/field/kiln-fire-cc0.mp3"],
	"res://scenes/guanqia/03_zhongshan.tscn": ["res://assets/audio/generated/music-03-old-town.wav", "res://assets/audio/field/cloth-market-cc0.mp3"],
	"res://scenes/guanqia/04_fangdong.tscn": ["res://assets/audio/generated/music-04-shelter.wav", "res://assets/audio/field/air-raid-siren-cc0.mp3"],
	"res://scenes/guanqia/05_hongyadong_return.tscn": ["res://assets/audio/generated/music-05-dawn.wav", "res://assets/audio/generated/ambient-05-dawn.wav"],
	"res://scenes/jieju.tscn": ["res://assets/audio/generated/music-05-dawn.wav", "res://assets/audio/generated/ambient-05-dawn.wav"],
}
const STORY_AMBIENCE := {}
const MUSIC_DB := -15.0
const AMBIENT_DB := -17.0
const STORY_AMBIENT_DB := -11.5
const SCENE_AMBIENT_DB := {
	"res://scenes/guanqia/02_ciqikou.tscn": -13.0,
	"res://scenes/guanqia/03_zhongshan.tscn": -15.0,
	"res://scenes/guanqia/04_fangdong.tscn": -8.0,
}

var _pool: Array[AudioStreamPlayer] = []
var _cursor := 0
var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _story_ambient: AudioStreamPlayer
var _music_tween: Tween
var _ambient_tween: Tween
var _story_ambient_tween: Tween
var _dialogue_active := false
var _ambient_base_db := AMBIENT_DB
var current_music_path := ""
var current_ambient_path := ""
var current_story_ambient_path := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in ["SFX", "UI", "Ambient", "Music"]:
		_ensure_bus(bus_name)
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "Voice%d" % i
		add_child(player)
		_pool.append(player)
	_music = _make_loop_player("MusicPlayer", "Music")
	_ambient = _make_loop_player("AmbientPlayer", "Ambient")
	_story_ambient = _make_loop_player("StoryAmbiencePlayer", "Ambient")
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_on_scene_changed")

func play_event(event_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var paths: Array = EVENTS.get(event_name, [])
	if paths.is_empty() or _pool.is_empty():
		return
	var player := _pool[_cursor]
	_cursor = (_cursor + 1) % _pool.size()
	player.stop()
	player.stream = load(str(paths.pick_random())) as AudioStream
	player.bus = str(BUS_BY_EVENT.get(event_name, "SFX"))
	player.pitch_scale = clampf(pitch, 0.65, 1.45)
	player.volume_db = volume_db
	player.play()

func set_bus_volume(bus_name: String, linear_value: float) -> void:
	_ensure_bus(bus_name)
	var index := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear_value, 0.001)))
	AudioServer.set_bus_mute(index, linear_value <= 0.001)

func set_dialogue_active(active: bool) -> void:
	_dialogue_active = active
	if _music != null and _music.playing:
		_tween_volume(_music, MUSIC_DB - (7.0 if active else 0.0), 0.22, true)
	if _ambient != null and _ambient.playing:
		_tween_volume(_ambient, _ambient_base_db - (3.0 if active else 0.0), 0.22, false)
	if _story_ambient != null and _story_ambient.playing:
		_tween_story_volume(STORY_AMBIENT_DB - (3.0 if active else 0.0), 0.22)

func start_story_ambience(level: int) -> void:
	var path := str(STORY_AMBIENCE.get(level, ""))
	if path.is_empty() or _story_ambient == null:
		stop_story_ambience()
		return
	if current_story_ambient_path == path and _story_ambient.playing:
		return
	_kill_story_tween()
	_story_ambient.stop()
	current_story_ambient_path = path
	var source := load(path) as AudioStream
	if source == null:
		push_warning("无法加载过场环境声：%s" % path)
		return
	var looped := source.duplicate() as AudioStream
	if looped is AudioStreamWAV:
		(looped as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_story_ambient.stream = looped
	_story_ambient.volume_db = -40.0
	_story_ambient.play()
	_tween_story_volume(STORY_AMBIENT_DB - (3.0 if _dialogue_active else 0.0), 0.8)

func stop_story_ambience() -> void:
	if _story_ambient == null:
		return
	_kill_story_tween()
	if not _story_ambient.playing:
		current_story_ambient_path = ""
		return
	_story_ambient_tween = create_tween()
	_story_ambient_tween.tween_property(_story_ambient, "volume_db", -40.0, 0.45)
	_story_ambient_tween.tween_callback(_clear_story_ambience)

func _clear_story_ambience() -> void:
	_story_ambient.stop()
	_story_ambient.stream = null
	current_story_ambient_path = ""

func _tween_story_volume(target_db: float, duration: float) -> void:
	_kill_story_tween()
	_story_ambient_tween = create_tween()
	_story_ambient_tween.tween_property(_story_ambient, "volume_db", target_db, duration)

func _kill_story_tween() -> void:
	if _story_ambient_tween != null and _story_ambient_tween.is_valid():
		_story_ambient_tween.kill()

func _make_loop_player(player_name: String, bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player

func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var scene_path := scene.scene_file_path
	var tracks: Array = SCENE_AUDIO.get(scene_path, [])
	if tracks.is_empty():
		_ambient_base_db = AMBIENT_DB
		_fade_to(_music, "", MUSIC_DB, true)
		_fade_to(_ambient, "", AMBIENT_DB, false)
		return
	_ambient_base_db = float(SCENE_AMBIENT_DB.get(scene_path, AMBIENT_DB))
	_fade_to(_music, str(tracks[0]), MUSIC_DB, true)
	_fade_to(_ambient, str(tracks[1]), _ambient_base_db, false)

func _fade_to(player: AudioStreamPlayer, path: String, target_db: float, is_music: bool) -> void:
	var current_path := current_music_path if is_music else current_ambient_path
	if current_path == path and player.playing:
		return
	_kill_tween(is_music)
	if player.playing:
		var tween := create_tween()
		_store_tween(tween, is_music)
		tween.tween_property(player, "volume_db", -40.0, 0.35)
		tween.tween_callback(_assign_track.bind(player, path, target_db, is_music))
	else:
		_assign_track(player, path, target_db, is_music)

func _assign_track(player: AudioStreamPlayer, path: String, target_db: float, is_music: bool) -> void:
	player.stop()
	if is_music:
		current_music_path = path
	else:
		current_ambient_path = path
	if path.is_empty():
		player.stream = null
		return
	var source := load(path) as AudioStream
	if source == null:
		push_warning("无法加载声音：%s" % path)
		return
	var looped := source.duplicate() as AudioStream
	if looped is AudioStreamWAV:
		(looped as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif looped is AudioStreamMP3:
		(looped as AudioStreamMP3).loop = true
	elif looped is AudioStreamOggVorbis:
		(looped as AudioStreamOggVorbis).loop = true
	player.stream = looped
	player.volume_db = -40.0
	player.play()
	var final_db := target_db
	if _dialogue_active:
		final_db -= 7.0 if is_music else 3.0
	var tween := create_tween()
	_store_tween(tween, is_music)
	tween.tween_property(player, "volume_db", final_db, 1.2)

func _tween_volume(player: AudioStreamPlayer, target_db: float, duration: float, is_music: bool) -> void:
	_kill_tween(is_music)
	var tween := create_tween()
	_store_tween(tween, is_music)
	tween.tween_property(player, "volume_db", target_db, duration)

func _kill_tween(is_music: bool) -> void:
	var tween := _music_tween if is_music else _ambient_tween
	if tween != null and tween.is_valid():
		tween.kill()

func _store_tween(tween: Tween, is_music: bool) -> void:
	if is_music:
		_music_tween = tween
	else:
		_ambient_tween = tween

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
