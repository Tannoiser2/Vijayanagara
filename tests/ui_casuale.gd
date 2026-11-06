## Interfaccia: tre giocatori umani che rispondono a caso fino alla fine (usa i tasti veri del pannello).
extends SceneTree
func _init() -> void:
	var scena = load("res://scenes/main.tscn").instantiate()
	root.add_child(scena)
	root.size = Vector2i(1600, 900)
	await process_frame
	scena.scelta_menu = {"D": "umano", "B": "umano", "V": "umano"}
	scena._nuova_locale(false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var t0 := Time.get_ticks_msec()
	var clic := 0
	while Time.get_ticks_msec() - t0 < 150000:
		await process_frame
		if scena.m == null or scena.m.finita():
			break
		if scena.m.need == null:
			continue
		var tasti: Array = []
		for b in scena.box_opz.find_children("*", "Button", true, false):
			if not b.is_queued_for_deletion():
				tasti.append(b)
		if tasti.is_empty():
			var c: Array = scena.mappa.candidati
			if not c.is_empty():
				scena._click_spazio(c[rng.randi() % c.size()])
				clic += 1
			continue
		(tasti[rng.randi() % tasti.size()] as Button).pressed.emit()
		clic += 1
		if clic % 40 == 0:
			scena._mostra_regole()
			scena._mostra_carta(scena.m.s["carta"])
			scena._sopra_spazio("delhi")
	print("clic ", clic, " atti ", scena.atti.size(), " finita ", scena.m.finita() if scena.m else "?")
	quit()
