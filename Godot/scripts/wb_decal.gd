class_name WBDecal
extends RefCounted
## Bullet holes and knife marks. Procedural textures (no external assets),
## parented to the hit static body so they are freed with the map. Capped.

const MAX_DECALS := 140

static var _tex_hole: ImageTexture = null
static var _tex_slash: ImageTexture = null
static var _spawned: Array = []


static func spawn(collider: Node, pos: Vector3, normal: Vector3, slash: bool) -> void:
	if collider == null or not (collider is StaticBody3D):
		return
	_ensure_textures()

	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.10, 0.34) if slash else Vector2(0.085, 0.085)
	mi.mesh = qm

	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _tex_slash if slash else _tex_hole
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m

	collider.add_child(mi)

	var n := normal.normalized()
	if n.length_squared() < 0.001:
		n = Vector3.UP
	var up := Vector3.UP if absf(n.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var x := up.cross(n).normalized()
	var y := n.cross(x).normalized()
	mi.global_transform = Transform3D(Basis(x, y, n), pos + n * 0.012)

	_spawned.append(mi)
	_trim()


static func _trim() -> void:
	var live := []
	for d in _spawned:
		if is_instance_valid(d):
			live.append(d)
	_spawned = live
	while _spawned.size() > MAX_DECALS:
		var old = _spawned.pop_front()
		if is_instance_valid(old):
			old.queue_free()


static func _ensure_textures() -> void:
	if _tex_hole == null:
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for yy in range(32):
			for xx in range(32):
				var d := Vector2(xx - 15.5, yy - 15.5).length()
				var a := clampf(1.0 - (d - 2.0) / 9.0, 0.0, 1.0)
				var c := Color(0.04, 0.04, 0.04, a)
				if d < 3.2:
					c = Color(0.02, 0.02, 0.02, 1.0)
				img.set_pixel(xx, yy, c)
		_tex_hole = ImageTexture.create_from_image(img)

	if _tex_slash == null:
		var img2 := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for yy in range(32):
			for xx in range(32):
				var t := absf(float(xx) - float(yy)) / 1.4142
				var a := clampf(1.0 - t / 3.0, 0.0, 1.0)
				img2.set_pixel(xx, yy, Color(0.06, 0.05, 0.05, a))
		_tex_slash = ImageTexture.create_from_image(img2)
