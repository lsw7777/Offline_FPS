class_name WBPrim
extends RefCounted
## Procedural mesh + material helpers (no external art assets).
## Everything is built from primitives so the prototype is fully self-contained.


static func mat(color: Color, emissive: Color = Color(0, 0, 0), energy: float = 1.0,
		metallic: float = 0.0, roughness: float = 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if emissive.a > 0.0 or emissive.r > 0.0 or emissive.g > 0.0 or emissive.b > 0.0:
		m.emission_enabled = true
		m.emission = emissive
		m.emission_energy_multiplier = energy
	return m


static func mesh_box(size: Vector3, color: Color, emissive: Color = Color(0, 0, 0),
		energy: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(color, emissive, energy)
	return mi


static func mesh_cyl(height: float, radius: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.height = height
	cm.top_radius = radius
	cm.bottom_radius = radius
	mi.mesh = cm
	mi.material_override = mat(color)
	return mi


static func mesh_sphere(radius: float, color: Color, emissive: Color = Color(0, 0, 0),
		energy: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = mat(color, emissive, energy)
	return mi


static func mesh_capsule(height: float, radius: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.height = height
	cm.radius = radius
	mi.mesh = cm
	mi.material_override = mat(color)
	return mi


## Static solid box (visual + collision), colored. Returns the StaticBody3D.
static func solid_box(bname: String, size: Vector3, pos: Vector3, color: Color,
		rot_deg: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = bname
	body.position = pos
	body.rotation_degrees = rot_deg
	body.add_child(mesh_box(size, color))
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body
