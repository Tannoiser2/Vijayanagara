## Prova online con un finto Firebase (tools: finto_firebase.py).
## Uso: FR_DB_URL=http://127.0.0.1:8765/db FR_AUTH_URL=.../signup FR_REFRESH_URL=.../refresh godot --headless -s res://tests/online.gd -- host|ospite secondi
extends SceneTree

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var ruolo: String = a[0]
	var scena = load("res://scenes/main.tscn").instantiate()
	root.add_child(scena)
	await process_frame
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 if ruolo == "host" else 8
	scena.ia_forza = 12
	if ruolo == "host":
		scena.nome_edit.text = "Host"
		scena._crea_stanza("D")
		for i in 60:
			await create_timer(0.3).timeout
			if scena.stanza != "":
				var f := FileAccess.open("/tmp/codice_vij.txt", FileAccess.WRITE)
				f.store_string(scena.stanza)
				f.close()
				break
		# aspetta l'ospite poi avvia (Vijayanagara all'IA)
		for i in 100:
			await create_timer(0.5).timeout
			var r = await scena.rete.room(scena.stanza)
			if Rete._as_dict(r.get("seats", {})).size() >= 2:
				scena._avvia_stanza()
				break
	else:
		var code := ""
		for i in 100:
			await create_timer(0.3).timeout
			if FileAccess.file_exists("/tmp/codice_vij.txt"):
				code = FileAccess.get_file_as_string("/tmp/codice_vij.txt").strip_edges()
				if code != "":
					break
		scena.codice_edit.text = code
		scena.nome_edit.text = "Ospite"
		scena._entra_stanza("B")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(a[1]) * 1000:
		await create_timer(0.05).timeout
		var m = scena.m
		if m == null or not scena.online:
			continue
		if m.finita():
			break
		if m.need != null and scena.controllo.get(m.need["f"], "") == "umano":
			var opz: Array = m.need["opz"]
			scena.rispondi(opz[rng.randi() % opz.size()]["v"])
	await create_timer(4.0).timeout
	var m2 = scena.m
	if m2:
		print(ruolo, " ATTI ", scena.atti.size(), " CARTA ", m2.s["carta"], " CTRL ", scena.controllo, " HASH ", str(m2.s["sp"]).hash())
	else:
		print(ruolo, " nessuna partita: ", scena.menu_msg.text)
	quit()
