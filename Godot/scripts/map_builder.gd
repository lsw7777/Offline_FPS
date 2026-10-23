class_name WBMapBuilder
extends RefCounted
## Three themed maps built from primitives:
##   sand_city      - Counter-Strike flavoured desert town (long lane / mid / platform)
##   transport_ship - CrossFire flavoured cargo ship (container corridors / catwalk)
##   maze           - industrial multi-room maze
## build(id) -> { "root": Node3D, "name": String, "player_spawn": Vector3, "enemy_spawns": Array }

const MAPS := [
	{"id": "sand_city", "name": "炽热沙城"},
	{"id": "transport_ship", "name": "运输船"},
	{"id": "maze", "name": "迷宫"},
	{"id": "range", "name": "靶场"},
]


static func build(id: String) -> Dictionary:
	match id:
		"transport_ship":
			return _transport_ship()
		"maze":
			return _maze()
		"range":
			return _range()
		_:
			return _sand_city()


# ---------------------------------------------------------------- helpers --
static func _env(root: Node3D, sky_top: Color, sky_horizon: Color, fog: Color,
		fog_density: float, ambient: Color, ambient_energy: float,
		sun_color: Color, sun_energy: float) -> void:
	var env := WorldEnvironment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = sky_top
	sm.sky_horizon_color = sky_horizon
	sm.ground_bottom_color = sky_horizon
	sm.ground_horizon_color = sky_horizon
	sky.sky_material = sm
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_color = ambient
	e.ambient_light_energy = ambient_energy
	e.fog_enabled = true
	e.fog_light_color = fog
	e.fog_density = fog_density
	env.environment = e
	root.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_color = sun_color
	sun.light_energy = sun_energy
	root.add_child(sun)


static func _box(bname: String, size: Vector3, pos: Vector3, color: Color,
		rot: Vector3 = Vector3.ZERO) -> StaticBody3D:
	return WBPrim.solid_box(bname, size, pos, color, rot)


static func _crate(bname: String, pos: Vector3, color: Color, size: Vector3 = Vector3(1.2, 1.2, 1.2)) -> StaticBody3D:
	return _box(bname, size, pos, color)


static func _stack(name: String, root: Node3D, base: Vector3, cols: int, rows: int,
		layers: int, color: Color) -> void:
	var idx := 0
	for l in range(layers):
		for cx in range(cols):
			for rz in range(rows):
				var p := base + Vector3(cx * 1.25, l * 1.25, rz * 1.25)
				root.add_child(_crate("%s_%d" % [name, idx], p, color))
				idx += 1


## Segmented wall along "x" (fixed z) or "z" (fixed x), with door gaps.
## gaps: Array of [start, end] intervals to leave open.
static func _wall_line(root: Node3D, axis: String, fixed: float, start: float, end: float,
		gaps: Array, h: float, t: float, color: Color, prefix: String) -> void:
	var cuts := [[minf(start, end), maxf(start, end)]]
	for g in gaps:
		var gc: Array = g
		var gs: float = minf(gc[0], gc[1])
		var ge: float = maxf(gc[0], gc[1])
		var nxt := []
		for c in cuts:
			var ca: float = c[0]
			var cb: float = c[1]
			if ge <= ca or gs >= cb:
				nxt.append([ca, cb])
			else:
				if gs > ca:
					nxt.append([ca, gs])
				if ge < cb:
					nxt.append([ge, cb])
		cuts = nxt

	var i := 0
	for c in cuts:
		var ca: float = c[0]
		var cb: float = c[1]
		var length: float = cb - ca
		if length <= 0.05:
			continue
		var mid: float = (ca + cb) * 0.5
		if axis == "z":
			root.add_child(_box("%s%d" % [prefix, i], Vector3(t, h, length), Vector3(fixed, h * 0.5, mid), color))
		else:
			root.add_child(_box("%s%d" % [prefix, i], Vector3(length, h, t), Vector3(mid, h * 0.5, fixed), color))
		i += 1


# ------------------------------------------------------------- sand city --
static func _sand_city() -> Dictionary:
	var root := Node3D.new()
	root.name = "Map_SandCity"
	_env(root, Color(0.72, 0.40, 0.18), Color(0.95, 0.72, 0.45), Color(0.90, 0.70, 0.50), 0.0022,
		Color(1.0, 0.86, 0.70), 1.0, Color(1.0, 0.85, 0.60), 1.35)

	var sand := Color(0.82, 0.70, 0.52)
	var wall_c := Color(0.88, 0.76, 0.55)
	var crate_c := Color(0.52, 0.38, 0.24)
	var crate_c2 := Color(0.44, 0.33, 0.21)

	root.add_child(_box("Floor", Vector3(92, 1, 84), Vector3(0, -0.5, -20), sand))

	# perimeter
	root.add_child(_box("BoundN", Vector3(92, 7, 1), Vector3(0, 3.5, -62), wall_c))
	root.add_child(_box("BoundS", Vector3(92, 7, 1), Vector3(0, 3.5, 22), wall_c))
	root.add_child(_box("BoundW", Vector3(1, 7, 84), Vector3(-46, 3.5, -20), wall_c))
	root.add_child(_box("BoundE", Vector3(1, 7, 84), Vector3(46, 3.5, -20), wall_c))

	# "long A" lane (two parallel walls with a mid doorway)
	_wall_line(root, "z", 18.0, -4.0, -46.0, [[-28.0, -24.0]], 5.0, 0.8, wall_c, "LongW")
	_wall_line(root, "z", 23.0, -4.0, -46.0, [], 5.0, 0.8, wall_c, "LongE")

	# mid wall with a doorway
	_wall_line(root, "z", 0.0, -6.0, -34.0, [[-20.0, -17.0]], 5.0, 0.8, wall_c, "Mid")

	# choke wall across the west side
	_wall_line(root, "x", -14.0, -6.0, 20.0, [[0.0, 4.0]], 4.0, 0.8, wall_c, "Choke")

	# raised platform + ramp (standable)
	root.add_child(_box("Platform", Vector3(10, 1.4, 10), Vector3(-18, 0.7, -32), Color(0.76, 0.64, 0.46)))
	root.add_child(_box("Ramp", Vector3(4.4, 0.4, 9.0), Vector3(-18, 0.9, -24), Color(0.70, 0.58, 0.42), Vector3(-17, 0, 0)))

	# stacked crates
	_stack("CrateA", root, Vector3(7.4, 0.6, -13.4), 2, 2, 2, crate_c)
	_stack("CrateB", root, Vector3(-30.0, 0.6, -16.0), 2, 2, 1, crate_c2)
	_stack("CrateC", root, Vector3(30.0, 0.6, -30.0), 2, 1, 2, crate_c)

	# buildings (sight blockers / alleys)
	root.add_child(_box("BuildA", Vector3(9, 10, 9), Vector3(-34, 5, -44), wall_c))
	root.add_child(_box("BuildB", Vector3(11, 13, 9), Vector3(34, 6.5, -46), wall_c))
	root.add_child(_box("BuildC", Vector3(7, 9, 7), Vector3(0, 4.5, -48), wall_c))

	# low cover walls
	for i in range(5):
		root.add_child(_box("Cover%d" % i, Vector3(3.0, 1.2, 0.8), Vector3(-8 + i * 4.0, 0.6, 2), Color(0.72, 0.60, 0.44)))

	# scattered single crates
	for i in range(6):
		root.add_child(_crate("Loose%d" % i, Vector3(-24 + i * 9.0, 0.6, -8 - (i % 3) * 6.0), crate_c2))

	var spawns := [
		Vector3(4, 0, -10), Vector3(-18, 0, -16), Vector3(12, 0, -26),
		Vector3(20.5, 0, -38), Vector3(-34, 0, -20), Vector3(30, 0, -24),
	]
	return {"root": root, "name": "炽热沙城", "player_spawn": Vector3(0, 1, 10), "enemy_spawns": spawns}


# --------------------------------------------------------- transport ship --
static func _transport_ship() -> Dictionary:
	var root := Node3D.new()
	root.name = "Map_Ship"
	_env(root, Color(0.22, 0.36, 0.50), Color(0.55, 0.66, 0.76), Color(0.60, 0.68, 0.76), 0.0018,
		Color(0.75, 0.82, 0.90), 1.0, Color(0.95, 0.98, 1.0), 1.15)

	var deck_c := Color(0.23, 0.25, 0.29)
	var rail := Color(0.58, 0.40, 0.20)
	var steel := Color(0.34, 0.37, 0.43)
	var cont_colors := [Color(0.72, 0.24, 0.20), Color(0.20, 0.38, 0.70), Color(0.24, 0.55, 0.30)]

	root.add_child(_box("Deck", Vector3(28, 1, 96), Vector3(0, -0.5, -30), deck_c))
	# hull / railings
	root.add_child(_box("RailL", Vector3(0.5, 1.5, 96), Vector3(-13.7, 0.75, -30), rail))
	root.add_child(_box("RailR", Vector3(0.5, 1.5, 96), Vector3(13.7, 0.75, -30), rail))
	root.add_child(_box("Bow", Vector3(28, 4, 1), Vector3(0, 2, 18), steel))
	root.add_child(_box("Stern", Vector3(28, 4, 1), Vector3(0, 2, -78), steel))

	# container corridors (two rows with interleaved gaps)
	var row_left := [-8.0, -15.0, -22.0, -29.0, -36.0, -43.0, -50.0]
	var row_right := [-11.5, -18.5, -25.5, -32.5, -39.5, -46.5, -53.5]
	var idx := 0
	for z in row_left:
		root.add_child(_box("ContL%d" % idx, Vector3(5.0, 2.6, 2.6), Vector3(-6, 1.3, z), cont_colors[idx % 3]))
		idx += 1
	idx = 0
	for z in row_right:
		root.add_child(_box("ContR%d" % idx, Vector3(5.0, 2.6, 2.6), Vector3(6, 1.3, z), cont_colors[(idx + 1) % 3]))
		idx += 1
	# stacked containers
	root.add_child(_box("ContLStack", Vector3(5.0, 2.6, 2.6), Vector3(-6, 3.9, -15.0), cont_colors[1]))
	root.add_child(_box("ContRStack", Vector3(5.0, 2.6, 2.6), Vector3(6, 3.9, -25.5), cont_colors[2]))

	# side catwalk with ramps (raised so enemies can pass underneath)
	root.add_child(_box("Catwalk", Vector3(4.0, 0.4, 26.0), Vector3(-10.6, 2.6, -24), steel))
	root.add_child(_box("CatRampA", Vector3(4.0, 0.3, 7.0), Vector3(-10.6, 1.35, -9.0), steel, Vector3(-18, 0, 0)))
	root.add_child(_box("CatRampB", Vector3(4.0, 0.3, 7.0), Vector3(-10.6, 1.35, -39.0), steel, Vector3(18, 0, 0)))

	# superstructure (bridge) with a doorway
	root.add_child(_box("SuperL", Vector3(4.0, 8, 10), Vector3(-3.0, 4, -66), steel))
	root.add_child(_box("SuperR", Vector3(4.0, 8, 10), Vector3(3.0, 4, -66), steel))
	root.add_child(_box("SuperTop", Vector3(10.0, 2, 10), Vector3(0, 7, -66), steel))

	# masts
	root.add_child(_box("MastA", Vector3(0.5, 14, 0.5), Vector3(-9.5, 7, -56), steel))
	root.add_child(_box("MastB", Vector3(0.5, 14, 0.5), Vector3(9.5, 7, -60), steel))

	# crates near the bow
	_stack("ShipCrate", root, Vector3(8.0, 0.6, 4.0), 2, 2, 1, Color(0.45, 0.35, 0.22))

	var spawns := [
		Vector3(0, 0, -12), Vector3(6, 0, -22), Vector3(-9, 0, -16),
		Vector3(9, 0, -42), Vector3(0, 0, -56),
	]
	return {"root": root, "name": "运输船", "player_spawn": Vector3(0, 1, 10), "enemy_spawns": spawns}


# ------------------------------------------------------------------- maze --
static func _maze() -> Dictionary:
	var root := Node3D.new()
	root.name = "Map_Maze"
	_env(root, Color(0.05, 0.06, 0.09), Color(0.11, 0.12, 0.17), Color(0.05, 0.05, 0.07), 0.014,
		Color(0.42, 0.47, 0.58), 0.7, Color(0.70, 0.75, 0.92), 0.95)

	var wall_c := Color(0.33, 0.33, 0.39)
	var wall_c2 := Color(0.27, 0.27, 0.33)
	var floor_c := Color(0.15, 0.15, 0.17)

	root.add_child(_box("Floor", Vector3(58, 1, 58), Vector3(0, -0.5, -18), floor_c))

	# perimeter
	root.add_child(_box("BoundN", Vector3(58, 6, 1), Vector3(0, 3, -47), wall_c))
	root.add_child(_box("BoundS", Vector3(58, 6, 1), Vector3(0, 3, 11), wall_c))
	root.add_child(_box("BoundW", Vector3(1, 6, 58), Vector3(-29, 3, -18), wall_c))
	root.add_child(_box("BoundE", Vector3(1, 6, 58), Vector3(29, 3, -18), wall_c))

	# vertical internal walls (doors staggered)
	_wall_line(root, "z", -14.0, -47.0, 11.0, [[-36.0, -32.0], [-20.0, -16.0], [-4.0, 0.0]], 5.0, 0.8, wall_c2, "VW1")
	_wall_line(root, "z", 0.0, -47.0, 11.0, [[-38.0, -34.0], [-22.0, -18.0], [-6.0, -2.0]], 5.0, 0.8, wall_c2, "VW2")
	_wall_line(root, "z", 14.0, -47.0, 11.0, [[-34.0, -30.0], [-18.0, -14.0], [2.0, 6.0]], 5.0, 0.8, wall_c2, "VW3")

	# horizontal internal walls (doors staggered differently)
	_wall_line(root, "x", -34.0, -29.0, 29.0, [[-18.0, -14.0], [2.0, 6.0]], 5.0, 0.8, wall_c, "HW1")
	_wall_line(root, "x", -18.0, -29.0, 29.0, [[-10.0, -6.0], [10.0, 14.0]], 5.0, 0.8, wall_c, "HW2")
	_wall_line(root, "x", -2.0, -29.0, 29.0, [[-24.0, -20.0], [-2.0, 2.0], [20.0, 24.0]], 5.0, 0.8, wall_c, "HW3")

	# central room pillars
	root.add_child(_box("PillarA", Vector3(1.2, 5, 1.2), Vector3(-6, 2.5, -18), wall_c2))
	root.add_child(_box("PillarB", Vector3(1.2, 5, 1.2), Vector3(6, 2.5, -18), wall_c2))

	# raised platform + ramp in the north-east room
	root.add_child(_box("Plat", Vector3(7, 1.2, 7), Vector3(21, 0.6, -41), Color(0.22, 0.22, 0.26)))
	root.add_child(_box("PlatRamp", Vector3(3.4, 0.3, 7.0), Vector3(21, 0.8, -33.5), Color(0.20, 0.20, 0.24), Vector3(-16, 0, 0)))

	# crates
	_stack("MazeCrateA", root, Vector3(-26.0, 0.6, -42.0), 2, 2, 1, Color(0.40, 0.35, 0.28))
	root.add_child(_crate("MazeCrateB", Vector3(10.0, 0.6, -8.0), Color(0.38, 0.33, 0.26)))
	root.add_child(_crate("MazeCrateC", Vector3(-8.0, 0.6, -44.0), Color(0.38, 0.33, 0.26)))

	var spawns := [
		Vector3(-20, 0, -8), Vector3(-6, 0, -24), Vector3(8, 0, -12),
		Vector3(20, 0, -28), Vector3(-4, 0, -42),
	]
	return {"root": root, "name": "迷宫", "player_spawn": Vector3(6, 1, 7), "enemy_spawns": spawns}


# -------------------------------------------------------------- shooting range --
static func _range() -> Dictionary:
	var root := Node3D.new()
	root.name = "Map_Range"
	_env(root, Color(0.30, 0.42, 0.55), Color(0.60, 0.70, 0.80), Color(0.62, 0.70, 0.78), 0.0010,
		Color(0.80, 0.86, 0.92), 1.05, Color(1.0, 1.0, 1.0), 1.2)

	var floor_c := Color(0.30, 0.31, 0.34)
	var wall_c := Color(0.42, 0.44, 0.48)

	root.add_child(_box("Floor", Vector3(26, 1, 96), Vector3(0, -0.5, -26), floor_c))
	root.add_child(_box("SideW", Vector3(0.6, 3.2, 96), Vector3(-12.7, 1.6, -26), wall_c))
	root.add_child(_box("SideE", Vector3(0.6, 3.2, 96), Vector3(12.7, 1.6, -26), wall_c))
	root.add_child(_box("BackStop", Vector3(26, 7, 1.2), Vector3(0, 3.5, -74), wall_c))
	root.add_child(_box("FrontWall", Vector3(26, 3.2, 0.6), Vector3(0, 1.6, 21), wall_c))

	# shooting benches
	for i in range(3):
		root.add_child(_box("Bench%d" % i, Vector3(1.4, 1.0, 0.8), Vector3(-6 + i * 6, 0.5, 8), Color(0.36, 0.24, 0.16)))

	# distance markers + target spots
	var lanes := [10.0, 20.0, 35.0, 50.0]
	for d in lanes:
		var z: float = 12.0 - d
		_label3d(root, Vector3(0, 3.0, z), "%dm" % int(d))
	# a couple of cover crates on the sides
	_stack("RangeCrate", root, Vector3(-9.0, 0.6, -20.0), 1, 2, 1, Color(0.40, 0.33, 0.24))

	var targets := [
		Vector3(0, 0, 12.0 - 10.0),
		Vector3(-4, 0, 12.0 - 20.0),
		Vector3(4, 0, 12.0 - 35.0),
		Vector3(0, 0, 12.0 - 50.0),
	]
	return {
		"root": root, "name": "靶场",
		"player_spawn": Vector3(0, 1, 12), "enemy_spawns": [], "targets": targets,
	}


static func _label3d(root: Node3D, pos: Vector3, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 64
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.modulate = Color(1, 0.92, 0.55)
	root.add_child(l)
