class_name WBMapBuilder
extends RefCounted
## Builds three themed maps entirely from primitives: sand city, transport ship, maze.
## build(id) -> { "root": Node3D, "name": String, "player_spawn": Vector3, "enemy_spawns": Array }

const MAPS := [
	{"id": "sand_city", "name": "炽热沙城"},
	{"id": "transport_ship", "name": "运输船"},
	{"id": "maze", "name": "迷宫"},
]


static func build(id: String) -> Dictionary:
	match id:
		"transport_ship":
			return _transport_ship()
		"maze":
			return _maze()
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


static func _box(bname: String, size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	return WBPrim.solid_box(bname, size, pos, color)


static func _crate(bname: String, pos: Vector3, color: Color) -> StaticBody3D:
	return _box(bname, Vector3(1.2, 1.2, 1.2), pos, color)


# ------------------------------------------------------------- sand city --
static func _sand_city() -> Dictionary:
	var root := Node3D.new()
	root.name = "Map_SandCity"
	_env(root, Color(0.75, 0.42, 0.20), Color(0.95, 0.72, 0.45), Color(0.90, 0.70, 0.50), 0.002,
		Color(1.0, 0.85, 0.70), 1.0, Color(1.0, 0.85, 0.60), 1.3)

	root.add_child(_box("Floor", Vector3(70, 1, 70), Vector3(0, -0.5, -12), Color(0.82, 0.70, 0.52)))

	var cover_col := Color(0.75, 0.62, 0.45)
	for i in range(6):
		root.add_child(_box("Cover%d" % i, Vector3(2.4, 1.1, 0.6), Vector3(-14 + i * 5.5, 0.05, -4), cover_col))

	var bcol := Color(0.90, 0.78, 0.55)
	root.add_child(_box("B1", Vector3(6, 8, 6), Vector3(-16, 3.5, -18), bcol))
	root.add_child(_box("B2", Vector3(6, 7, 6), Vector3(16, 3.0, -20), bcol))
	root.add_child(_box("B3", Vector3(8, 5, 8), Vector3(0, 2.0, -34), bcol))

	var crates := [
		Vector3(6, 0.6, -10), Vector3(-8, 0.6, -14), Vector3(4, 0.6, -24),
		Vector3(-12, 0.6, -24), Vector3(10, 0.6, -16), Vector3(-4, 0.6, -30),
	]
	var ccol := [Color(0.55, 0.40, 0.25), Color(0.48, 0.36, 0.22)]
	for i in range(crates.size()):
		root.add_child(_crate("Crate%d" % i, crates[i], ccol[i % 2]))

	var spawns := [
		Vector3(8, 0, -10), Vector3(-9, 0, -16), Vector3(0, 0, -26),
		Vector3(12, 0, -20), Vector3(-12, 0, -6),
	]
	return {"root": root, "name": "炽热沙城", "player_spawn": Vector3(0, 1, 14), "enemy_spawns": spawns}


# --------------------------------------------------------- transport ship --
static func _transport_ship() -> Dictionary:
	var root := Node3D.new()
	root.name = "Map_Ship"
	_env(root, Color(0.25, 0.40, 0.55), Color(0.55, 0.65, 0.75), Color(0.60, 0.68, 0.76), 0.0015,
		Color(0.75, 0.82, 0.90), 1.0, Color(0.95, 0.98, 1.0), 1.1)

	root.add_child(_box("Deck", Vector3(22, 1, 64), Vector3(0, -0.5, -16), Color(0.24, 0.26, 0.30)))

	var rail := Color(0.60, 0.42, 0.22)
	root.add_child(_box("RailL", Vector3(0.4, 1.2, 64), Vector3(-10.8, 0.6, -16), rail))
	root.add_child(_box("RailR", Vector3(0.4, 1.2, 64), Vector3(10.8, 0.6, -16), rail))

	var cont_colors := [Color(0.75, 0.25, 0.20), Color(0.20, 0.40, 0.75), Color(0.25, 0.60, 0.30)]
	var containers := [
		Vector3(-6, 1.25, -8), Vector3(5, 1.25, -14), Vector3(-4, 1.25, -22),
		Vector3(7, 1.25, -28), Vector3(-7, 1.25, -34), Vector3(3, 1.25, -42),
	]
	for i in range(containers.size()):
		root.add_child(_box("Container%d" % i, Vector3(5.0, 2.5, 2.5), containers[i], cont_colors[i % 3]))

	root.add_child(_box("Bridge", Vector3(6, 4, 4), Vector3(0, 2.0, -50), Color(0.35, 0.38, 0.45)))

	var spawns := [
		Vector3(0, 0, -10), Vector3(6, 0, -25), Vector3(-6, 0, -30), Vector3(0, 0, -42),
	]
	return {"root": root, "name": "运输船", "player_spawn": Vector3(0, 1, 14), "enemy_spawns": spawns}


# ------------------------------------------------------------------- maze --
static func _maze() -> Dictionary:
	var root := Node3D.new()
	root.name = "Map_Maze"
	_env(root, Color(0.06, 0.07, 0.10), Color(0.12, 0.13, 0.18), Color(0.05, 0.05, 0.07), 0.012,
		Color(0.4, 0.45, 0.55), 0.7, Color(0.7, 0.75, 0.9), 0.9)

	root.add_child(_box("Floor", Vector3(44, 1, 44), Vector3(0, -0.5, -12), Color(0.16, 0.16, 0.18)))
	var wall_col := Color(0.34, 0.34, 0.40)

	root.add_child(_box("BoundaryN", Vector3(44, 4, 1), Vector3(0, 1.5, -34), wall_col))
	root.add_child(_box("BoundaryS", Vector3(44, 4, 1), Vector3(0, 1.5, 10), wall_col))
	root.add_child(_box("BoundaryE", Vector3(1, 4, 44), Vector3(22, 1.5, -12), wall_col))
	root.add_child(_box("BoundaryW", Vector3(1, 4, 44), Vector3(-22, 1.5, -12), wall_col))

	var walls := [
		[Vector3(-8, 0, -6), Vector3(1, 4, 16)],
		[Vector3(8, 0, -18), Vector3(1, 4, 16)],
		[Vector3(-4, 0, -26), Vector3(14, 4, 1)],
		[Vector3(14, 0, -12), Vector3(1, 4, 12)],
		[Vector3(-14, 0, -18), Vector3(1, 4, 12)],
		[Vector3(4, 0, -8), Vector3(10, 4, 1)],
		[Vector3(0, 0, -20), Vector3(1, 4, 8)],
	]
	for i in range(walls.size()):
		var w = walls[i]
		root.add_child(_box("Wall%d" % i, w[1], w[0], wall_col))

	root.add_child(_crate("CrateA", Vector3(-16, 0.6, -20), Color(0.4, 0.36, 0.30)))
	root.add_child(_crate("CrateB", Vector3(16, 0.6, -26), Color(0.4, 0.36, 0.30)))

	var spawns := [
		Vector3(-10, 0, -8), Vector3(10, 0, -14), Vector3(-6, 0, -22),
		Vector3(12, 0, -28), Vector3(0, 0, -30),
	]
	return {"root": root, "name": "迷宫", "player_spawn": Vector3(0, 1, 8), "enemy_spawns": spawns}
