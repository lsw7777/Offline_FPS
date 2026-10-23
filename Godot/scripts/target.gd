extends StaticBody3D
## Greybox target: 100 HP, dies at 0. Damage is applied via take_damage().

signal died(target_name: String)

var hp := 100.0


func take_damage(amount: float) -> void:
	hp -= amount
	print("[target] %s hit: -%.1f (hp %.0f)" % [name, amount, hp])
	if hp <= 0.0:
		died.emit(name)
		queue_free()
