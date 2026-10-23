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

	# weapon reload / switch animations
	if wm:
		ws.equip("AK-47")
		if wm._anim != "switch":
			ok = false
			print("FAIL: switch animation not triggered on equip")
		ws.fire()
		ws.begin_reload()
		if wm._anim != "reload":
			ok = false
			print("FAIL: reload animation not triggered")
		if absf(wm._anim_dur - 1.5) > 0.01:
			ok = false
			print("FAIL: AK reload duration not updated (%.2f)" % wm._anim_dur)
		ws.reloading = false
		# inspect (middle mouse) animation
		wm._anim = ""
		wm.play_inspect()
		if wm._anim != "inspect":
			ok = false
			print("FAIL: gun inspect animation not triggered")

	# PBR textures on gun parts + inspect light
	if wm:
		var pbr_gun = wm.get_node_or_null("Gun")
		var tex_count := 0
		if pbr_gun:
			for c in pbr_gun.get_children():
				if c is MeshInstance3D and c.material_override is StandardMaterial3D:
					if c.material_override.albedo_texture != null:
						tex_count += 1
		print("textured gun parts=%d" % tex_count)
		if tex_count < 3:
			ok = false
			print("FAIL: PBR textures not applied to gun")
		wm._anim = ""
		wm.play_inspect()
		for i in range(20):
			await get_tree().process_frame
		if wm._inspect_light == null or wm._inspect_light.light_energy < 0.2:
			ok = false
			print("FAIL: inspect light did not light up")

	# post-processing (SSAO) enabled on the map environment
	var world_env = null
	for c in main.map_root.get_children():
		if c is WorldEnvironment:
			world_env = c
	if world_env == null or not world_env.environment.ssao_enabled:
		ok = false
		print("FAIL: SSAO not enabled on map environment")

	# range map: no enemies, has targets
	var rinfo: Dictionary = WBMapBuilder.build("range")
	var rtargets: Array = rinfo.get("targets", [])
	if rtargets.size() < 3:
		ok = false
		print("FAIL: range map has too few targets (%d)" % rtargets.size())
	if rinfo["enemy_spawns"].size() != 0:
		ok = false
		print("FAIL: range map should have no enemies")
	rinfo["root"].free()

	# bullet holes / knife marks attach to the hit static body
	var floor_body = main.map_root.get_node_or_null("Floor") if main.map_root else null
	if floor_body:
		var before: int = floor_body.get_child_count()
		WBDecal.spawn(floor_body, Vector3(0, 0, 0), Vector3.UP, false)
		WBDecal.spawn(floor_body, Vector3(0, 0, 0), Vector3.UP, true)
		if floor_body.get_child_count() < before + 2:
			ok = false
			print("FAIL: bullet hole / knife mark not spawned")
	else:
		ok = false
		print("FAIL: map floor body not found for decal test")

	# all maps must build with substantial geometry
	for mid in ["sand_city", "transport_ship", "maze", "range"]:
		var info: Dictionary = WBMapBuilder.build(mid)
		var mroot: Node3D = info["root"]
		var n: int = mroot.get_child_count()
		print("map %s children=%d" % [mid, n])
		if n < 12:
			ok = false
			print("FAIL: map %s too simple (%d children)" % [mid, n])
		# spawn points must not be inside geometry
		var spawn_list := [info["player_spawn"]]
		for s in info["enemy_spawns"]:
			spawn_list.append(s)
		for sp in spawn_list:
			if not _spawn_clear(mroot, sp):
				ok = false
				print("FAIL: %s spawn blocked at %s" % [mid, str(sp)])
		mroot.free()

	# V toggles melee mode; knife viewmodel shows; 1/2/3 switch knives
	var ms = main.get_node_or_null("Player/MeleeSystem")
	var mm = main.get_node_or_null("Player/Camera3D/MeleeModel")
	if pl and ms:
		pl._toggle_mode()
		await get_tree().process_frame
		if not pl.melee_mode:
			ok = false
			print("FAIL: V did not enter melee mode")
		if not ms.melee_mode:
			ok = false
			print("FAIL: melee system did not receive melee mode")
		if mm == null or not mm.visible:
			ok = false
			print("FAIL: melee viewmodel not visible in melee mode")
		elif mm.get_child_count() == 0:
			ok = false
			print("FAIL: knife model not built")
		ms.equip("KA-BAR")
		if ms.current_melee_id != "KA-BAR":
			ok = false
			print("FAIL: knife switch to KA-BAR failed")
		mm.play_inspect()
		if mm._inspect_t <= 0.0:
			ok = false
			print("FAIL: knife inspect animation not triggered")
		# gun must be hidden and firing blocked while in melee mode
		var gun = wm.get_node_or_null("Gun") if wm else null
		if gun and gun.visible:
			ok = false
			print("FAIL: gun still visible in melee mode")
		var ammo_before: int = ws.ammo_in_mag
		ws.fire()
		if ws.ammo_in_mag != ammo_before:
			ok = false
			print("FAIL: gun fired while in melee mode")
		pl._toggle_mode()
		await get_tree().process_frame
		if pl.melee_mode:
			ok = false
			print("FAIL: V did not return to ranged mode")
		if mm and mm.visible:
			ok = false
			print("FAIL: melee viewmodel still visible in ranged mode")

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

	# clearing every enemy must open the results screen
	if hud:
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e):
				e.take_damage(999.0)
		await get_tree().process_frame
		await get_tree().process_frame
		if not hud.results_panel.visible:
			ok = false
			print("FAIL: results screen not shown after clearing all enemies")

	print("INTEGRATION %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)


## Axis-aligned approximation: is a 0.7 x 1.8 x 0.7 body clear at `p`?
func _spawn_clear(root: Node3D, p: Vector3) -> bool:
	var lo := p + Vector3(-0.35, 0.15, -0.35)
	var hi := p + Vector3(0.35, 1.75, 0.35)
	for c in root.get_children():
		if not (c is StaticBody3D):
			continue
		var box_size := Vector3.ZERO
		var found := false
		for m in c.get_children():
			if m is MeshInstance3D and m.mesh is BoxMesh:
				box_size = m.mesh.size
				found = true
				break
		if not found:
			continue
		var center: Vector3 = c.position
		var mn := center - box_size * 0.5
		var mx := center + box_size * 0.5
		if lo.x < mx.x and hi.x > mn.x and lo.y < mx.y and hi.y > mn.y and lo.z < mx.z and hi.z > mn.z:
			return false
	return true
