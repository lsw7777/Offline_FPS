class_name WBData
extends RefCounted
## Reads the single source of truth: res://ProjectWB/Config/Data/*.json
## (never duplicate the numbers — they are gated by Tools/validate_data.py).

const WEAPONS_PATH := "res://ProjectWB/Config/Data/weapons.json"
const MELEE_PATH := "res://ProjectWB/Config/Data/melee.json"
const SCENES_PATH := "res://ProjectWB/Config/Data/scenes.json"
const LOADOUT_PATH := "res://ProjectWB/Config/Data/loadout.json"


static func _load_json(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("WBData: cannot open " + path)
		return null
	var text := f.get_as_text()
	var data = JSON.parse_string(text)
	if data == null:
		push_error("WBData: invalid JSON in " + path)
		return null
	return data


## { weapon_id -> item dict }
static func weapons() -> Dictionary:
	var doc = _load_json(WEAPONS_PATH)
	var out := {}
	if doc == null:
		return out
	for it in doc.get("items", []):
		out[it["id"]] = it
	return out


static func weapons_defaults() -> Dictionary:
	var doc = _load_json(WEAPONS_PATH)
	return doc.get("defaults", {}) if doc else {}


static func weapons_order() -> Array:
	var doc = _load_json(WEAPONS_PATH)
	var out := []
	if doc == null:
		return out
	for it in doc.get("items", []):
		out.append(it["id"])
	return out


## { melee_id -> item dict }
static func melee() -> Dictionary:
	var doc = _load_json(MELEE_PATH)
	var out := {}
	if doc == null:
		return out
	for it in doc.get("items", []):
		out[it["id"]] = it
	return out


static func scenes() -> Array:
	var doc = _load_json(SCENES_PATH)
	return doc.get("scenes", []) if doc else []


static func loadout() -> Dictionary:
	return _load_json(LOADOUT_PATH)
