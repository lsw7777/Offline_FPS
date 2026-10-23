extends Control
## HUD: crosshair, weapon, ammo, HP, map name, kill counter, damage vignette.

var weapon_label: Label
var ammo_label: Label
var hp_label: Label
var map_label: Label
var kill_label: Label
var crosshair: Label
var hint: Label
var vignette: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	weapon_label = _mk_label(Vector2(20, 20), "—", 22)
	ammo_label = _mk_label(Vector2(20, 50), "— / —", 22)
	hp_label = _mk_label(Vector2(20, 80), "HP 100", 20)
	hp_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

	map_label = _mk_label(Vector2(20, 110), "地图：炽热沙城", 16)
	map_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))

	kill_label = _mk_label(Vector2(0, 20), "击杀 0", 18)
	kill_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	kill_label.position = Vector2(-220, 20)
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	crosshair = _mk_label(Vector2.ZERO, "+", 30)
	var c := get_viewport_rect().size * 0.5
	crosshair.position = c - Vector2(9, 14)
	crosshair.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))

	hint = _mk_label(Vector2(0, get_viewport_rect().size.y - 46), "", 15)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "WASD 移动 · 左键 射击 · R 换弹 · 1-6 切枪 · V 近战 · F1/F2/F3 切地图 · Esc 释放鼠标"

	# damage vignette
	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(1, 0, 0, 0.0)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)


func _mk_label(pos: Vector2, text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	add_child(l)
	return l


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
	vignette.color = Color(1, 0, 0, 0.35)
	var tween := create_tween()
	tween.tween_property(vignette, "color", Color(1, 0, 0, 0.0), 0.3)
