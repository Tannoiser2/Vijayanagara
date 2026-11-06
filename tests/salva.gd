## Salvataggio e ripresa: godot --headless -s res://tests/salva.gd
extends SceneTree
func _init() -> void:
	var scena = load("res://scenes/main.tscn").instantiate()
	root.add_child(scena)
	await process_frame
	scena.ia_forza = 8
	scena.scelta_menu = {"D": "ia", "B": "ia", "V": "ia"}
	scena._nuova_locale(false)
	var t0 := Time.get_ticks_msec()
	while scena.atti.size() < 12 and Time.get_ticks_msec() - t0 < 60000:
		await process_frame
	var h1 := str(scena.base["sp"]).hash()
	var n: int = scena.atti.size()
	scena._torna_menu()
	scena._riprendi_locale()
	await process_frame
	var h2 := str(scena.base["sp"]).hash()
	print("atti ", n, " ripresi ", scena.atti.size(), " uguale=", h1 == h2)
	quit(0 if h1 == h2 and n == scena.atti.size() else 1)
