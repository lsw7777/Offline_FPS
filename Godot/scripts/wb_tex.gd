class_name WBTex
extends RefCounted
## Runtime-generated PBR texture sets (albedo + roughness + normal).
## No external assets / no licensing issues; deterministic and cheap.

const S := 64
static var _cache := {}


static func _n(x: float, y: float) -> float:
	var v := sin(x * 12.9898 + y * 78.233) * 43758.5453
	return v - floor(v)


## Returns { "albedo": ImageTexture, "rough": ImageTexture, "normal": ImageTexture }
static func get_set(kind: String) -> Dictionary:
	if _cache.has(kind):
		return _cache[kind]

	var alb := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var rgh := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var nrm := Image.create(S, S, false, Image.FORMAT_RGBA8)

	var hh := PackedFloat32Array()
	hh.resize(S * S)

	for y in range(S):
		for x in range(S):
			var fx := float(x)
			var fy := float(y)
			var col := Color(0.5, 0.5, 0.5)
			var r := 0.5
			var h := 0.5

			match kind:
				"wood":
					var grain := sin(fx * 0.55 + sin(fy * 0.30) * 2.2 + _n(fx * 0.15, fy * 0.15) * 2.0)
					var t := 0.5 + 0.5 * grain
					col = Color(0.32 + 0.18 * t, 0.21 + 0.11 * t, 0.11 + 0.05 * t)
					r = 0.52 + 0.14 * _n(fx, fy)
					h = 0.5 + 0.14 * grain
				"polymer":
					var st := _n(fx * 1.7, fy * 1.7)
					col = Color(0.10 + 0.04 * st, 0.10 + 0.04 * st, 0.11 + 0.04 * st)
					r = 0.60 + 0.12 * st
					h = 0.5 + 0.06 * st
				"steel":
					var br := 0.58 + 0.12 * sin(fy * 2.0) + 0.06 * _n(fx * 3.0, fy * 0.3)
					col = Color(br, br, br * 1.03)
					r = 0.20 + 0.10 * _n(fx, fy)
					h = 0.5 + 0.10 * sin(fy * 2.0) + 0.05 * _n(fx * 3.0, fy)
				_:
					# brushed gunmetal (default)
					var b := 0.52 + 0.10 * sin(fy * 1.4) + 0.07 * (_n(fx * 0.7, fy * 3.0) - 0.5)
					if _n(fx * 0.13, fy * 0.9) > 0.94:
						b *= 0.62
					col = Color(b, b, b * 1.02)
					r = 0.30 + 0.14 * _n(fx, fy)
					h = 0.5 + 0.09 * sin(fy * 1.4) + 0.05 * (_n(fx * 0.7, fy * 3.0) - 0.5)

			alb.set_pixel(x, y, Color(col.r, col.g, col.b, 1.0))
			rgh.set_pixel(x, y, Color(r, r, r, 1.0))
			hh[y * S + x] = h

	# normals from height field (sobel-ish, wrapping)
	var strength := 2.2
	for y in range(S):
		for x in range(S):
			var hl: float = hh[y * S + ((x - 1 + S) % S)]
			var hr: float = hh[y * S + ((x + 1) % S)]
			var hu: float = hh[((y - 1 + S) % S) * S + x]
			var hd: float = hh[((y + 1) % S) * S + x]
			var nx: float = (hl - hr) * strength
			var ny: float = (hu - hd) * strength
			var l: float = sqrt(nx * nx + ny * ny + 1.0)
			nrm.set_pixel(x, y, Color(nx / l * 0.5 + 0.5, ny / l * 0.5 + 0.5, 1.0 / l * 0.5 + 0.5, 1.0))

	var out := {
		"albedo": ImageTexture.create_from_image(alb),
		"rough": ImageTexture.create_from_image(rgh),
		"normal": ImageTexture.create_from_image(nrm),
	}
	_cache[kind] = out
	return out


## Build a textured PBR material.
static func make(kind: String, tint: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var s := get_set(kind)
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = s["albedo"]
	m.roughness_texture = s["rough"]
	m.roughness = roughness
	m.metallic = metallic
	m.metallic_specular = 0.65
	m.normal_enabled = true
	m.normal_texture = s["normal"]
	m.normal_scale = 0.55
	m.uv1_scale = Vector3(1.8, 1.8, 1.8)
	return m


## Classify an existing flat colour into a texture family.
static func classify(col: Color) -> String:
	var mx: float = maxf(col.r, maxf(col.g, col.b))
	# skin / light warm materials: leave untouched
	if col.r > 0.70 and col.g > 0.55 and col.b > 0.40:
		return ""
	# green-ish dark = polymer furniture
	if col.g >= col.r and mx < 0.40:
		return "polymer"
	# brown = wood
	if col.r > col.g * 1.2 and col.g > col.b * 1.05 and col.r > 0.25:
		return "wood"
	if mx < 0.14:
		return "polymer"
	if mx > 0.50:
		return "steel"
	return "metal"


static func pbr_for(col: Color) -> StandardMaterial3D:
	var kind := classify(col)
	if kind == "":
		return null
	var metallic := 0.0
	var rough := 0.6
	var tint := Color(0.80, 0.80, 0.82)
	match kind:
		"steel":
			metallic = 0.9
			rough = 0.34
			tint = Color(1.0, 1.0, 1.0)
		"wood":
			metallic = 0.0
			rough = 0.62
			tint = Color(1.0, 1.0, 1.0)
		"polymer":
			metallic = 0.15
			rough = 0.66
			tint = Color(0.85, 0.85, 0.88)
		_:
			metallic = 0.78
			rough = 0.46
			tint = Color(0.72, 0.72, 0.75)
	return make(kind, tint, metallic, rough)
