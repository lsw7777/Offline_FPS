extends SceneTree
## Headless smoke test: prove the GDScript balance port matches the CI gate
## (same data file -> same golden winners). Run:
##   godot --headless --script res://Godot/scripts/test_smoke.gd


func _initialize() -> void:
	var ok := true

	var weapons := WBData.weapons()
	var melee := WBData.melee()
	var scenes := WBData.scenes()
	var dflt := WBData.weapons_defaults()

	print("== WB smoke test ==")
	print("weapons=%d melee=%d scenes=%d" % [weapons.size(), melee.size(), scenes.size()])
	if weapons.size() != 6 or melee.size() != 3 or scenes.size() != 7:
		printerr("FAIL: data counts wrong")
		quit(1)
		return

	var matrix := WBBalance.build_matrix(weapons, scenes, dflt)
	for s in scenes:
		var row: Dictionary = matrix[s["id"]]
		var best := ""
		var best_v := -INF
		for wid in row.keys():
			if row[wid] > best_v:
				best_v = row[wid]
				best = wid
		var expected: String = s.get("expected_best", "")
		var mark := "OK " if best == expected else "MISMATCH"
		if best != expected:
			ok = false
		print("%s scene=%-24s best=%-16s expected=%s" % [mark, s["id"], best, expected])

	# every weapon must own at least one scene
	var winners := {}
	for s in scenes:
		var row: Dictionary = matrix[s["id"]]
		var best := ""
		var best_v := -INF
		for wid in row.keys():
			if row[wid] > best_v:
				best_v = row[wid]
				best = wid
		winners[best] = true
	for wid in weapons.keys():
		if not winners.has(wid):
			ok = false
			printerr("FAIL: weapon %s owns no scene" % wid)

	print("SMOKE %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
