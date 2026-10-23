extends Control
## HUD: dynamic crosshair, weapon, ammo, HP, map name, kills, damage vignette,
## and a top-right SETTINGS button that opens a panel (volume + map switch).

signal map_selected(id: String)
signal ui_state_changed(open: bool)
signal next_map_requested
signal retry_requested

var weapon_label: Label
var ammo_label: Label
var hp_label: Label
var map_label: Label
var kill_label: Label
var hint: Label
var vignette: ColorRect

var settings_button: Button
var settings_panel: Panel
var volume_slider: HSlider
var volume_value: Label

var results_panel: Panel
var results_stats: Label

var _vp := Vector2(1280, 720)
var _cross_parts: Array[ColorRect] = []
var _cross_center := Vector2.ZERO
var _gap := 6.0
var _base_gap := 6.0
var _gap_target := 6.0


func _ready() -> void:
	set_process(true)
	_vp = get_viewport_rect().size
	size = _vp
	_cross_center = _vp * 0.5
	# CRITICAL: the HUD covers the whole screen, so it must NOT swallow mouse
	# events. Only the settings button / panel should be clickable.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# vignette (bottom layer)
	vignette = ColorRect.new()
	vignette.position = Vector2.ZERO
	vignette.size = _vp
	vignette.color = Color(1, 0, 0, 0.0)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	weapon_label = _mk_label(Vector2(20, 20), "—", 22)
	ammo_label = _mk_label(Vector2(20, 50), "— / —", 22)
	hp_label = _mk_label(Vector2(20, 80), "HP 100", 20)
	hp_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	map_label = _mk_label(Vector2(20, 110), "地图：炽热沙城", 16)
	map_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))

	kill_label = _mk_label(Vector2(maxf(0.0, _vp.x - 220.0), 16), "击杀 0", 18)
	kill_label.size = Vector2(200, 26)
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_build_crosshair()

	hint = _mk_label(Vector2(0, maxf(0.0, _vp.y - 46.0)), "", 15)
	hint.size = Vector2(_vp.x, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "WASD 移动 · 左键 射击/挥刀 · 右键 瞄准 · R 换弹 · 1-6 切枪 / 1-3 切刀 · V 近战 · 中键 检视 · Esc→设置"

	settings_button = Button.new()
	settings_button.text = "设置"
	settings_button.position = Vector2(maxf(0.0, _vp.x - 150.0), 52)
	settings_button.size = Vector2(130, 40)
	settings_button.add_theme_font_size_override("font_size", 16)
	settings_button.pressed.connect(_on_settings_pressed)
	add_child(settings_button)

	_build_settings_panel()
	_build_results_panel()


func _build_crosshair() -> void:
	for i in range(4):
		var r := ColorRect.new()
		r.color = Color(1, 1, 1, 0.9)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		_cross_parts.append(r)
	_layout_crosshair()


func _layout_crosshair() -> void:
	if _cross_parts.size() < 4:
		return
	var length := 9.0
	var thick := 2.0
	var c := _cross_center
	var g := _gap
	_cross_parts[0].position = Vector2(c.x - thick * 0.5, c.y - g - length)
	_cross_parts[0].size = Vector2(thick, length)
	_cross_parts[1].position = Vector2(c.x - thick * 0.5, c.y + g)
	_cross_parts[1].size = Vector2(thick, length)
	_cross_parts[2].position = Vector2(c.x - g - length, c.y - thick * 0.5)
	_cross_parts[2].size = Vector2(length, thick)
	_cross_parts[3].position = Vector2(c.x + g, c.y - thick * 0.5)
	_cross_parts[3].size = Vector2(length, thick)


func _process(delta: float) -> void:
	_gap = lerpf(_gap, _gap_target, clampf(delta * 12.0, 0.0, 1.0))
	_layout_crosshair()


# ---- crosshair state ----
func on_shot_fired() -> void:
	_gap_target = _base_gap + 11.0
	get_tree().create_timer(0.07).timeout.connect(_reset_gap)


func _reset_gap() -> void:
	_gap_target = _base_gap


func on_aim_changed(aiming: bool) -> void:
	_base_gap = 3.0 if aiming else 6.0
	_gap_target = _base_gap


# ---- settings panel ----
func _build_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.size = Vector2(380, 300)
	settings_panel.position = Vector2(_vp.x * 0.5 - 190, _vp.y * 0.5 - 150)
	settings_panel.visible = false
	add_child(settings_panel)

	var title := Label.new()
	title.text = "设置"
	title.position = Vector2(20, 12)
	title.add_theme_font_size_override("font_size", 22)
	settings_panel.add_child(title)

	var vol_label := Label.new()
	vol_label.text = "音量"
	vol_label.position = Vector2(20, 62)
	vol_label.add_theme_font_size_override("font_size", 17)
	settings_panel.add_child(vol_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.position = Vector2(90, 62)
	volume_slider.size = Vector2(200, 26)
	var bus_idx := AudioServer.get_bus_index("Master")
	var cur := 0.8
	if bus_idx >= 0 and not AudioServer.is_bus_mute(bus_idx):
		cur = clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_idx)), 0.0, 1.0)
	volume_slider.value = cur
	volume_slider.value_changed.connect(_on_volume_changed)
	settings_panel.add_child(volume_slider)

	volume_value = Label.new()
	volume_value.text = "%d%%" % int(cur * 100)
	volume_value.position = Vector2(300, 60)
	volume_value.add_theme_font_size_override("font_size", 15)
	settings_panel.add_child(volume_value)

	var map_title := Label.new()
	map_title.text = "切换地图"
	map_title.position = Vector2(20, 108)
	map_title.add_theme_font_size_override("font_size", 17)
	settings_panel.add_child(map_title)

	var maps := [
		{"id": "sand_city", "name": "炽热沙城"},
		{"id": "transport_ship", "name": "运输船"},
		{"id": "maze", "name": "迷宫"},
		{"id": "range", "name": "靶场"},
	]
	for i in range(maps.size()):
		var b := Button.new()
		b.text = maps[i]["name"]
		b.position = Vector2(20 + i * 88, 140)
		b.size = Vector2(82, 38)
		b.add_theme_font_size_override("font_size", 14)
		var mid: String = maps[i]["id"]
		b.pressed.connect(func(): _on_map_selected(mid))
		settings_panel.add_child(b)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.position = Vector2(20, 240)
	close_btn.size = Vector2(340, 40)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_on_settings_pressed)
	settings_panel.add_child(close_btn)


func _mk_label(pos: Vector2, text: String, size_px: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size_px)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _on_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible
	ui_state_changed.emit(settings_panel.visible)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if settings_panel.visible else Input.MOUSE_MODE_CAPTURED


func _on_volume_changed(v: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_mute(bus, v <= 0.001)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.001)))
	volume_value.text = "%d%%" % int(v * 100)


func _on_map_selected(id: String) -> void:
	map_selected.emit(id)
	settings_panel.visible = false
	ui_state_changed.emit(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_results_panel() -> void:
	results_panel = Panel.new()
	results_panel.size = Vector2(420, 280)
	results_panel.position = Vector2(_vp.x * 0.5 - 210.0, _vp.y * 0.5 - 140.0)
	results_panel.visible = false
	add_child(results_panel)

	var title := Label.new()
	title.text = "地区清除"
	title.position = Vector2(24, 20)
	title.add_theme_font_size_override("font_size", 30)
	results_panel.add_child(title)

	results_stats = Label.new()
	results_stats.text = ""
	results_stats.position = Vector2(24, 84)
	results_stats.add_theme_font_size_override("font_size", 18)
	results_panel.add_child(results_stats)

	var next_btn := Button.new()
	next_btn.text = "下一张地图"
	next_btn.position = Vector2(20, 190)
	next_btn.size = Vector2(185, 50)
	next_btn.add_theme_font_size_override("font_size", 17)
	next_btn.pressed.connect(func(): next_map_requested.emit())
	results_panel.add_child(next_btn)

	var retry_btn := Button.new()
	retry_btn.text = "重玩本图"
	retry_btn.position = Vector2(215, 190)
	retry_btn.size = Vector2(185, 50)
	retry_btn.add_theme_font_size_override("font_size", 17)
	retry_btn.pressed.connect(func(): retry_requested.emit())
	results_panel.add_child(retry_btn)


func show_results(kills_count: int, seconds: float) -> void:
	if settings_panel:
		settings_panel.visible = false
	results_panel.visible = true
	results_stats.text = "击杀 %d    ·    用时 %.1f 秒" % [kills_count, seconds]


func hide_results() -> void:
	if results_panel:
		results_panel.visible = false


func on_melee_changed(id: String, display: String) -> void:
	weapon_label.text = "%s  (%s)" % [display, id]
	ammo_label.text = "近战 / ∞"


func on_weapon_changed(id: String, display: String) -> void:
	weapon_label.text = "%s  (%s)" % [display, id]


func on_ammo_changed(id: String, ammo: int, mag: int) -> void:
	ammo_label.text = "%d / %d" % [ammo, mag]


func on_health_changed(hp: float) -> void:
	hp_label.text = "HP %d" % int(hp)


func on_map_changed(name: String) -> void:
	map_label.text = "地图：%s" % name


func on_kill(count: int) -> void:
	kill_label.text = "击杀 %d" % count


func on_damage() -> void:
	vignette.color = Color(1, 0, 0, 0.45)
	var tween := create_tween()
	tween.tween_property(vignette, "color", Color(1, 0, 0, 0.0), 0.35)
