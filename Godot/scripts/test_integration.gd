extends Node
## Headless integration test: instantiate the real scene, exercise weapon system,
## enemies, and map. Run:
##   godot --headless res://Godot/scenes/test_integration.tscn


func _ready() -> void:
	var ok := true

	var main = load("res://Godot/scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame

	var ws = main.get_node_or_null("Player/WeaponSystem")
	if ws == null:
		printerr("FAIL: WeaponSystem not found")
		get_tree().quit(1)
		return

	print("current=%s ammo=%d" % [ws.current, ws.ammo_in_mag])
	if ws.current != "Desert_Eagle" or ws.ammo_in_mag != 7:
		ok = false
		print("FAIL: initial equip wrong")

	var wm = main.get_node_or_null("Player/Camera3D/WeaponModel")
	if wm == null:
		ok = false
		print("FAIL: WeaponModel (gun body) missing")

	ws.fire()
	if ws.ammo_in_mag != 6:
		ok = false
		print("FAIL: ammo after 1 shot = %d (expected 6)" % ws.ammo_in_mag)

	ws.equip("M249_SAW")
	if ws.ammo_in_mag != 100:
		ok = false
		print("FAIL: M249 magazine = %d (expected 100)" % ws.ammo_in_mag)

	# enemies spawned
	var enemies := get_tree().get_nodes_in_group("enemy")
	print("enemies=%d" % enemies.size())
	if enemies.size() == 0:
		ok = false
		print("FAIL: no enemies spawned")

	# map root present
	var has_map := false
	for c in main.get_children():
		if c is Node3D and c.name.begins_with("Map_"):
			has_map = true
	if not has_map:
		ok = false
		print("FAIL: map root missing")

	# enemy dies
	if enemies.size() > 0:
		enemies[0].take_damage(200.0)
		await get_tree().process_frame
		if is_instance_valid(enemies[0]) and not enemies[0].is_queued_for_deletion():
			ok = false
			print("FAIL: enemy did not die at 0 hp")

	print("INTEGRATION %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)
