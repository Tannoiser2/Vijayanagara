## Prove mirate delle regole: godot --headless -s res://tests/test_regole.gd
extends SceneTree

var errori := 0

func ok(c: bool, t: String) -> void:
	if not c:
		errori += 1
		print("NO  ", t)
	else:
		print("ok  ", t)

func _init() -> void:
	var m := Motore.new()
	m.nuova(42)
	# preparazione
	ok(m.vp("D") == 18, "PV iniziali del Sultanato = 18")
	ok(m.vp("B") == 0 and m.vp("V") == 0, "PV iniziali Bahmani e Vijayanagara = 0")
	ok(m.disp("a") == 6 and m.disp("r") == 8, "Disponibili iniziali: 6 Emiri, 8 Raja")
	ok(int(m.X("andhra")["q"]) == 1 and int(m.X("andhra")["ro"]) == 2, "Andhra: Qasbah e 2 Raja")
	ok((m.s["mazzo"] as Array).size() + (m.s["giocate"] as Array).size() == 35, "mazzo di 35 carte")
	var mz: Array = m.s["giocate"] + m.s["mazzo"]
	ok(mz.find("S1") == 8 and mz.find("S2") == 17 and mz.find("S3") == 26, "Successioni dopo ogni pila di 8")
	ok(mz.slice(27).has("T1") and mz.slice(27).has("T2"), "Timuridi nell'ultima pila")
	# adiacenze
	ok(m.adiacente("gondwana", "andhra") and m.adiacente("madhyadesh", "orissa"), "adiacenze per vertice (1.3.5)")
	ok(not m.adiacente("jaunpur", "punjab") and not m.adiacente("malwa", "gondwana") and not m.adiacente("madhyadesh", "jaunpur"), "Vindhya e Punjab non adiacenti")
	# controllo e Ribellione
	m.X("karnataka")["trib"] = false
	m._aggiorna_controllo("karnataka")
	ok(m.X("karnataka")["ctrl"] == "V" and int(m.X("karnataka")["rr"]) == 3 and int(m.X("karnataka")["ro"]) == 0, "Controllo V rende ribelli i Raja")
	m.metti_tributo("karnataka")
	ok(m.X("karnataka")["ctrl"] == "" and int(m.X("karnataka")["ro"]) == 3, "il Tributo rende obbedienti")
	# Influenza e tracciato
	m.cambia_infl("V", 2)
	ok(m.disp("r") == 12 and int(m.s["slot"]["V"]["1"]) == 0 and int(m.s["slot"]["V"]["2"]) == 0, "Influenza V 2: 4 Raja liberati")
	m.cambia_infl("V", -1)
	ok(m.disp("r") == 10 and int(m.s["slot"]["V"]["2"]) == 2, "scendendo sotto 2 tornano 2 Raja")
	m.cambia_infl("B", 2)
	ok(m.disp("a") == 8, "Influenza B 2: 2 Emiri liberati")
	# PV
	m.X("tamilakam")["trib"] = false
	m._aggiorna_controllo("tamilakam")
	ok(m.vp("D") == 17, "PV Sultanato senza il Tamilakam")
	# Cavalleria dalla riserva e poi da altri
	m.s["cav"] = {"D": 6, "B": 4, "V": 0}
	m.guadagna_cav("V", 1)
	ok(m.need != null, "riserva vuota: si chiede a chi prendere")
	# Battaglia deterministica: dadi fissati dal seme
	var m2 := Motore.new()
	m2.nuova(7)
	m2.s["cav"] = {"D": 0, "B": 0, "V": 0}
	m2.s["tmp"] = {"usati": {}}
	var prima: int = m2.n_pezzi("maharashtra", "B")
	m2.X("maharashtra")["t"] = 5
	m2.battaglia("D", "B", "maharashtra", {"maharashtra:t": 5}, 4, 2)
	if m2.need == null:
		var lb: Dictionary = m2.s["tmp"].get("ultima_battaglia", {})
		ok(m2.n_pezzi("maharashtra", "B") == prima - int(lb.get("persi_d", -1)), "le perdite del difensore corrispondono ai colpi")
	else:
		ok(true, "la battaglia chiede le perdite (scelta del difensore)")
	print("errori: ", errori)
	quit(1 if errori > 0 else 0)
