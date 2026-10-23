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

	# enemies must actually move toward the player
	if enemies.size() > 1:
		var e = enemies[1]
		if is_instance_valid(e):
			var p0: Vector3 = e.global_position
			for i in range(40):
				await get_tree().physics_frame
			if is_instance_valid(e):
				var moved: float = e.global_position.distance_to(p0)
				print("enemy moved %.2f m" % moved)
				if moved < 0.5:
					ok = false
					print("FAIL: enemy did not move (%.2f m)" % moved)

	# enemy must have a health bar
	if enemies.size() > 0 and is_instance_valid(enemies[0]):
		var has_bar := false
		for c in enemies[0].get_children():
			if c is MeshInstance3D and c.mesh is QuadMesh:
				has_bar = true
		if not has_bar:
			ok = false
			print("FAIL: enemy has no health bar")

	# HUD settings button must exist and sit inside the viewport
	var hud = main.get_node_or_null("HUDLayer/HUD")
	if hud == null:
		ok = false
		print("FAIL: HUD missing")
	else:
		if hud.settings_button == null:
			ok = false
			print("FAIL: settings button missing")
		else:
			var vp: Vector2 = hud.get_viewport_rect().size
			var r: Rect2 = hud.settings_button.get_global_rect()
			print("settings_button rect=%s vp=%s" % [str(r), str(vp)])
			if r.position.x < 0 or r.position.x > vp.x or r.size.x <= 0:
				ok = false
				print("FAIL: settings button off-screen")
			# the HUD must not swallow mouse input (regression guard)
			if hud.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				ok = false
				print("FAIL: HUD swallows mouse input (mouse_filter=%d)" % hud.mouse_filter)
			if hud.settings_button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				ok = false
				print("FAIL: settings button is not clickable")

	# fall off the map -> respawn at spawn with full HP
	var pl = main.get_node_or_null("Player")
	if pl:
		pl.global_position = Vector3(0, -30, 0)
		await get_tree().physics_frame
		await get_tree().physics_frame
		if pl.global_position.y < 0.0:
			ok = false
			print("FAIL: player did not respawn after falling (y=%.1f)" % pl.global_position.y)
		if pl.hp < 99.0:
			ok = false
			print("FAIL: HP not reset after falling (%d)" % int(pl.hp))

	# ADS toggle: engages on player + weapon system, tightens crosshair
	if pl:
		pl._toggle_aim()
		await get_tree().process_frame
		if not pl.aiming:
			ok = false
			print("FAIL: ADS did not engage")
		if not ws.aiming:
			ok = false
			print("FAIL: weapon system did not receive ADS state")
		if hud and hud._base_gap >= 6.0:
			ok = false
			print("FAIL: crosshair did not tighten in ADS (gap=%.1f)" % hud._base_gap)
		pl._toggle_aim()
		if pl.aiming:
			ok = false
			print("FAIL: ADS did not toggle off")

	# firing ejects a shell casing from the gun's right side
	var has_shell := false
	ws.fire()
	await get_tree().process_frame
	await get_tree().process_frame
	for c in main.get_children():
		if c is MeshInstance3D:
			var s = c.get_script()
			if s and s.resource_path.ends_with("shell.gd"):
				has_shell = true
	if not has_shell:
		ok = false
		print("FAIL: no shell casing ejected on fire")

	# mouse look must rotate the view (only assertable if capture works headless)
	if pl:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var yaw0: float = pl.yaw
		var ev := InputEventMouseMotion.new()
		ev.relative = Vector2(120, 0)
		Input.parse_input_event(ev)
		await get_tree().process_frame
		print("mouse_mode=%d yaw0=%.3f yaw1=%.3f" % [Input.mouse_mode, yaw0, pl.yaw])
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and absf(pl.yaw - yaw0) < 0.001:
			ok = false
			print("FAIL: mouse look did not rotate the view")

	print("INTEGRATION %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)
