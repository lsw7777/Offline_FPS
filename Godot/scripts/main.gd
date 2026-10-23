extends Node3D
## Scene root: builds the themed map, player (with weapon viewmodel), enemies and
## HUD. Map switching comes from the HUD settings panel; switching (or falling
## off the map / dying) respawns the player at full HP and full ammo.

var current_map_id := "sand_city"
var current_spawn := Vector3.ZERO
var map_root: Node3D = null
var player: CharacterBody3D = null
var hud: Control = null
var kills := 0


func _ready() -> void:
	player = _build_player()
	_build_hud(player)
	_load_map(current_map_id)


func _respawn_player() -> void:
	player.respawn(current_spawn)
	var ws := player.get_node("WeaponSystem")
	if ws and ws.has_method("reset_ammo"):
		ws.reset_ammo()


func _load_map(id: String) -> void:
	current_map_id = id

	if map_root:
		map_root.queue_free()
	for e in get_tree().get_nodes_in_group("enemy"):
		e.queue_free()

	var info: Dictionary = WBMapBuilder.build(id)
	map_root = info["root"]
	add_child(map_root)
	current_spawn = info["player_spawn"]

	_respawn_player()
	hud.on_map_changed(info["name"])
	_spawn_enemies(info["enemy_spawns"])
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _spawn_enemies(spawns: Array) -> void:
	for pos in spawns:
		var e := CharacterBody3D.new()
		e.name = "Enemy"
		e.position = pos
		e.set_script(load("res://Godot/scripts/enemy.gd"))
		add_child(e)
		e.setup(player)
		e.died.connect(_on_enemy_died)


func _on_enemy_died(_pos: Vector3) -> void:
	kills += 1
	if hud:
		hud.on_kill(kills)


func _build_player() -> Node:
	var p := CharacterBody3D.new()
	p.name = "Player"
	p.position = Vector3(0, 1.0, 14)
	p.set_script(load("res://Godot/scripts/player.gd"))

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.position = Vector3(0, 0.6, 0)
	p.add_child(cam)

	var wm := Node3D.new()
	wm.name = "WeaponModel"
	wm.set_script(load("res://Godot/scripts/weapon_model.gd"))
	cam.add_child(wm)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	p.add_child(col)

	var ws := Node.new()
	ws.name = "WeaponSystem"
	ws.set_script(load("res://Godot/scripts/weapon_system.gd"))
	p.add_child(ws)

	var ms := Node.new()
	ms.name = "MeleeSystem"
	ms.set_script(load("res://Godot/scripts/melee_system.gd"))
	p.add_child(ms)

	add_child(p)
	p.died.connect(_respawn_player)
	p.fell.connect(_respawn_player)
	return p


func _build_hud(p: Node) -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUDLayer"
	var h := Control.new()
	h.name = "HUD"
	h.set_script(load("res://Godot/scripts/hud.gd"))
	layer.add_child(h)
	add_child(layer)
	hud = h

	var ws: Node = p.get_node("WeaponSystem")
	ws.weapon_changed.connect(h.on_weapon_changed)
	ws.ammo_changed.connect(h.on_ammo_changed)
	ws.recoil.connect(p.apply_recoil)
	ws.shot_fired.connect(h.on_shot_fired)
	p.health_changed.connect(h.on_health_changed)
	p.damaged.connect(h.on_damage)
	p.aim_changed.connect(ws.on_aim_changed)
	p.aim_changed.connect(h.on_aim_changed)
	h.map_selected.connect(_load_map)
	h.ui_state_changed.connect(func(open: bool): ws.ui_blocked = open)

	var order := WBData.weapons_order()
	if order.size() > 0:
		ws.equip(order[0])
