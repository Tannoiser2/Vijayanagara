## I 36 Eventi. La fazione che esegue sceglie il lato (chiaro o ombreggiato); quando il testo nomina un'altra
## fazione è quella a decidere i dettagli. Con «{B}/{V}» agisce chi esegue se è una delle due, altrimenti sceglie.
class_name Eventi
extends Regole


func evento(f: String, cd: Dictionary) -> void:
	var n := int(cd["n"])
	var lato := "u"
	if cd.get("testo_s", "") != "":
		var v = chiedi(f, "«%s»: quale testo esegui?" % cd["titolo"], [o("u", "Chiaro: " + cd["sott_u"].trim_suffix(":")), o("s", "Ombreggiato: " + cd["sott_s"].trim_suffix(":"))], {"tag": "lato", "mostra": true})
		if ferma():
			return
		lato = v
	nota("%s esegue l'Evento «%s» (%s)." % [breve(f), cd["titolo"], "testo chiaro" if lato == "u" else "testo ombreggiato"])
	s["tmp"] = {}
	call("ev%d%s" % [n, lato], f)


# ---------------------------------------------------------------- aiuti

## Chi agisce fra le fazioni elencate: chi esegue, se è fra loro; altrimenti chi esegue sceglie.
func attore(f: String, lista: Array) -> String:
	if f in lista:
		return f
	if lista.size() == 1:
		return lista[0]
	var ops: Array = []
	for g in lista:
		ops.append(o(g, nome_faz(g)))
	var v = chiedi(f, "Quale fazione agisce?", ops, {"tag": "attore"})
	return "" if v == null else v


func unita_k(f: String) -> String:
	return {"D": "t", "B": "a", "V": "r"}[f]


## Piazza fino a n Unità di f in id (Truppe, Emiri o Raja) chiedendo quante.
func piazza_fino(f: String, id: String, n: int, k: String = "", ribelle: bool = false) -> int:
	if k == "":
		k = unita_k(f)
	var mx: int = min(n, disp(chiave_disp(k)))
	if mx <= 0:
		return 0
	var q := numero(f, "Quanti %s piazzi in %s?" % [nome_pezzo(k, 2), nome_sp(id)], 0, mx, "ev_n")
	if ferma():
		return 0
	var p := piazza(id, k, q, ribelle)
	if p > 0:
		nota("%s in %s." % [pz(p, k), nome_sp(id)])
	return p


## Sceglie un pezzo di una fazione in id da togliere (o sostituire); restituisce la chiave o "".
func scegli_pezzo(chi: String, id: String, chiavi: Array, testo: String, facolt: bool = true) -> String:
	var ops: Array = []
	for k in chiavi:
		if int(X(id)[k]) > 0:
			ops.append(o(k, nome_pezzo_stato(k)))
	if ops.is_empty():
		return ""
	if facolt:
		ops.append(o("no", "Nessuno"))
	var v = chiedi(chi, testo, ops, {"tag": "pezzo"})
	if ferma() or v == null or v == "no":
		return ""
	return v


func unita_di(g: String) -> Array:
	return UNITA_DI[g]


func avversarie_unita(f: String) -> Array:
	var r: Array = []
	for g in FAZ:
		if g != f:
			r += UNITA_DI[g]
	return r


func pezzi_avversari(f: String) -> Array:
	var r: Array = []
	for g in FAZ:
		if g != f:
			r += PEZZI_DI[g]
	return r


## Sostituisce un pezzo k in id con un'Unità di g (ribelle se richiesto). Restituisce true se fatto.
func sostituisci(id: String, k: String, g: String, ribelle: bool = false) -> bool:
	if int(X(id)[k]) <= 0:
		return false
	rimuovi(id, k, 1)
	var p := piazza(id, unita_k(g), 1, ribelle)
	nota("In %s un %s è sostituito%s." % [nome_sp(id), nome_pezzo_stato(k), " da " + nome_pezzo(unita_k(g)) if p > 0 else ""])
	return true


func guadagna_misto(f: String, n: int) -> void:
	var c := numero(f, "Guadagni %d fra Risorse e Cavallerie: quante Cavallerie?" % n, 0, n, "misto")
	if ferma():
		return
	cambia_ris(f, n - c)
	guadagna_cav(f, c)


func attacco_libero(f: String, opz: Dictionary = {}) -> void:
	var o2 := {"limitata": true, "gratis": true, "solo": "attacca"}
	o2.merge(opz)
	comando(f, o2)


func prendi_ris(da: String, a: String, n: int) -> void:
	var m: int = min(n, int(s["ris"][da]))
	if m <= 0:
		return
	cambia_ris(da, -m)
	cambia_ris(a, m)


# ---------------------------------------------------------------- 1 Malik Kafur

func ev1u(f: String) -> void:
	var dest := ["rajput", "malwa", "jaunpur"]
	var giri := 0
	while giri < 10:
		giri += 1
		var da = scegli_spazio(f, "Sposta un Governatore in una Provincia adiacente a Delhi: quale?", func(x): return int(X(x)["g"]) > 0 and not x in dest, false, "ev_da")
		if ferma() or da == null:
			break
		var a = scegli_spazio(f, "Dove va il Governatore di %s?" % nome_sp(da), func(x): return x in dest, false, "ev_a")
		if ferma():
			return
		muovi(da, a, "g", 1)
	var g := attore(f, ["B", "V"])
	if ferma() or g == "":
		return
	comando(g, {"limitata": true, "gratis": true, "solo": "ribellione", "sempre": true})


func ev1s(_f: String) -> void:
	var id = scegli_spazio("D", "Il generale prediletto: in quale spazio porti fino a 8 Unità?", func(_x): return true, false, "ev_sp")
	if ferma():
		return
	var portate := 0
	while portate < 8:
		var da = scegli_spazio("D", "Da dove arrivano altre Unità? (%d di 8)" % portate, func(x): return x != id and n_unita(x, "D") > 0, true, "ev_da", "Basta così")
		if ferma() or da == null:
			break
		for k in ["t", "g"]:
			var mx: int = min(8 - portate, int(X(da)[k]))
			if mx <= 0:
				continue
			var n := numero("D", "Quanti %s porti da %s?" % [nome_pezzo(k, 2), nome_sp(da)], 0, mx, "ev_n")
			if ferma():
				return
			muovi(da, id, k, n)
			portate += n
	if si_no("D", "Rendi ribelli tutte le Unità avversarie in %s?" % nome_sp(id), "ev_rib"):
		rendi_ribelli(id, "B")
		rendi_ribelli(id, "V")
	if ferma():
		return
	attacco_libero("D", {"filtro": func(x): return x == id})


# ---------------------------------------------------------------- 2 Esercito mongolo respinto

func ev2u(f: String) -> void:
	for id in ["passi", "punjab"]:
		for i in 2:
			var k := scegli_pezzo(f, id, ["t", "g"], "Rimuovi un'Unità del Sultanato in %s (%d di 2)" % [nome_sp(id), i + 1])
			if ferma() or k == "":
				break
			rimuovi(id, k, 1)


func ev2s(_f: String) -> void:
	attacco_libero("D", {"filtro": func(x): return x in ["passi", "punjab"]})
	if ferma():
		return
	var altro = scegli_spazio("D", "Ridistribuzione: quale terzo spazio oltre a Passi montani e Punjab?", func(x): return not x in ["passi", "punjab"], true, "ev_sp", "Nessuna ridistribuzione")
	if ferma() or altro == null:
		return
	var gruppo := ["passi", "punjab", altro]
	var mosse := 0
	while mosse < 6:
		var da = scegli_spazio("D", "Ridistribuzione (%d di 6): da dove?" % mosse, func(x): return x in gruppo and n_unita(x, "D") > 0, true, "ev_da", "Basta così")
		if ferma() or da == null:
			break
		var a = scegli_spazio("D", "Verso dove?", func(x): return x in gruppo and x != da, false, "ev_a")
		if ferma():
			return
		var k = "t" if int(X(da)["t"]) > 0 else "g"
		if int(X(da)["t"]) > 0 and int(X(da)["g"]) > 0:
			k = chiedi("D", "Quale Unità?", [o("t", "Truppe"), o("g", "Governatori")], {"tag": "ev_k"})
			if ferma():
				return
		var n := numero("D", "Quanti %s sposti?" % nome_pezzo(k, 2), 1, min(6 - mosse, int(X(da)[k])), "ev_n")
		if ferma():
			return
		muovi(da, a, k, n)
		mosse += n


# ---------------------------------------------------------------- 3 Golconda

func ev3u(f: String) -> void:
	var g := attore(f, ["B", "V"])
	if ferma() or g == "":
		return
	for id in vicini_citta("warangal"):
		if n_pezzi(id, g) > 0 and disp(unita_k(g)) > 0:
			if si_no(g, "Raduno gratuito in %s?" % nome_sp(id), "ev_rad"):
				cmd_raduna(g, id, {})
			if ferma():
				return
	cambia_ris(g, 2)


func ev3s(_f: String) -> void:
	for id in vicini_citta("warangal"):
		if n_pezzi(id, "D") <= 0:
			continue
		for g in ["B", "V"]:
			if n_pezzi(id, g) > 0:
				prendi_ris(g, "D", 2)


# ---------------------------------------------------------------- 4 Orecchie del Sultano

func ev4u(f: String) -> void:
	var g := attore(f, ["V", "B"])
	if ferma() or g == "":
		return
	var id = scegli_spazio(g, "Quale Governatore sostituisci?", func(x): return provincia(x) and int(X(x)["g"]) > 0, true, "ev_sp", "Nessuno")
	if ferma() or id == null:
		return
	var rib = chiedi(g, "La nuova Unità è…", [o("rib", "Ribelle"), o("obb", "Obbediente")], {"tag": "orient"})
	if ferma():
		return
	sostituisci(id, "g", g, rib == "rib")


func ev4s(_f: String) -> void:
	comando("D", {"solo": "governa", "ovunque": true})


# ---------------------------------------------------------------- 5 Chittor

func ev5u(f: String) -> void:
	var g := attore(f, ["V", "B"])
	if ferma() or g == "":
		return
	for i in 2:
		var id = scegli_spazio(g, "Sostituisci un'Unità del Sultanato adiacente a Chittor (%d di 2)" % (i + 1), func(x): return x in vicini_citta("chittor") and n_unita(x, "D") > 0, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		var k := scegli_pezzo(g, id, ["t", "g"], "Quale Unità?", false)
		if ferma():
			return
		sostituisci(id, k, g, true)
	var st: String = STRUTTURA_DI[g]
	if disp(st) > 0 and int(X("rajput")[st]) == 0 and si_no(g, "Piazzi un %s nei Regni Rajput?" % nome_pezzo(st), "ev_str"):
		piazza("rajput", st, 1)


func ev5s(_f: String) -> void:
	for i in 3:
		var id = scegli_spazio("D", "Sostituisci un'Unità avversaria adiacente a Chittor con una Truppa (%d di 3)" % (i + 1), func(x): return x in vicini_citta("chittor") and amiri(x) + raja(x) > 0, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		var k := scegli_pezzo("D", id, ["ao", "ar", "ro", "rr"], "Quale Unità?", false)
		if ferma():
			return
		sostituisci(id, k, "D")
	if disp("q") > 0 and int(X("rajput")["q"]) == 0 and si_no("D", "Piazzi una Qasbah nei Regni Rajput?", "ev_str"):
		piazza("rajput", "q", 1)


# ---------------------------------------------------------------- 6 Warangal

func ev6u(f: String) -> void:
	var g := attore(f, ["V", "B"])
	if ferma() or g == "":
		return
	var id = scegli_spazio(g, "In quale Provincia adiacente a Warangal agisci?", func(x): return x in vicini_citta("warangal"), true, "ev_sp", "Rinuncia")
	if ferma() or id == null:
		return
	if X(id)["trib"] and si_no(g, "Togli il segnalino Tributo da %s?" % nome_sp(id), "ev_trib"):
		togli_tributo(id)
	if ferma():
		return
	piazza_fino(g, id, 2)


func ev6s(_f: String) -> void:
	dec_campagna("D", {"fine_in": func(x): return x in vicini_citta("warangal")})
	if ferma():
		return
	var fine: String = s["tmp"].get("campagna_fine", "")
	if not fine in vicini_citta("warangal"):
		return
	var ops: Array = []
	for g in ["B", "V"]:
		if n_pezzi(fine, g) > 0 and int(s["ris"][g]) > 0:
			ops.append(o(g, breve(g)))
	if ops.is_empty():
		return
	var g = chiedi("D", "Da chi prendi 3 Risorse?", ops, {"tag": "ev_da_chi"})
	if ferma():
		return
	prendi_ris(g, "D", 3)


# ---------------------------------------------------------------- 7 Madurai

func ev7u(f: String) -> void:
	var g := attore(f, ["V", "B"])
	if ferma() or g == "":
		return
	piazza_fino(g, "tamilakam", 2)
	if ferma():
		return
	guadagna_misto(g, 3)


func ev7s(_f: String) -> void:
	piazza_fino("D", "tamilakam", 4)
	if ferma():
		return
	if disp("g") > 0 and si_no("D", "Piazzi un Governatore nel Tamilakam?", "ev_gov"):
		piazza("tamilakam", "g", 1)
	if ferma():
		return
	guadagna_misto("D", 3)


# ---------------------------------------------------------------- 8 Yadava

func _devagiri_gulbarga() -> Array:
	var r: Array = []
	for c in ["devagiri", "gulbarga"]:
		for id in vicini_citta(c):
			if not id in r:
				r.append(id)
	return r


func ev8u(f: String) -> void:
	var g := attore(f, ["B", "V"])
	if ferma() or g == "":
		return
	for id in _devagiri_gulbarga():
		if n_unita(id, "D") <= 0:
			continue
		var k := scegli_pezzo(g, id, ["t", "g"], "In %s sostituisci un'Unità del Sultanato?" % nome_sp(id))
		if ferma():
			return
		if k != "":
			sostituisci(id, k, g)


func ev8s(_f: String) -> void:
	for id in _devagiri_gulbarga():
		if si_no("D", "Governa gratis in %s (e piazza 1 Truppa)?" % nome_sp(id), "ev_gov"):
			if ok_governa("D", id, {"ovunque": true}):
				cmd_governa("D", id, {"ovunque": true})
				if ferma():
					return
			piazza(id, "t", 1)
		if ferma():
			return


# ---------------------------------------------------------------- 9 Kakatiya

func ev9u(_f: String) -> void:
	cambia_infl("V", 1)
	if ferma():
		return
	var filtro := func(x): return x in vicini_citta("warangal") and X(x)["ctrl"] != "V"
	if not _costringi_spazi("V").filter(filtro).is_empty():
		dec_costringi("V", {"filtro": filtro})
		if ferma():
			return
	var dove: String = s["tmp"].get("costringi_in", "")
	if dove != "" and okd_costruisci("V") and _ok_costruisci("V", dove):
		if si_no("V", "Costruisci un Tempio in %s?" % nome_sp(dove), "ev_cos"):
			piazza(dove, "tp", 1)


func ev9s(_f: String) -> void:
	cambia_ris("D", 3)
	var id = scegli_spazio("D", "In quale Provincia adiacente a Warangal porti fino a 4 Truppe e un Governatore?", func(x): return x in vicini_citta("warangal"), true, "ev_sp", "Rinuncia")
	if ferma() or id == null:
		return
	piazza_fino("D", id, 4)
	if ferma():
		return
	if disp("g") > 0 and si_no("D", "Piazzi un Governatore in %s?" % nome_sp(id), "ev_gov"):
		piazza(id, "g", 1)
	if ferma():
		return
	dec_obbedienza("D", {"solo_in": [id]})


# ---------------------------------------------------------------- 10 Capitale trasferita

func ev10u(f: String) -> void:
	var mossi := 0
	while mossi < 4:
		var da = scegli_spazio(f, "Sposta Unità del Sultanato da una Provincia (%d di 4)" % mossi, func(x): return provincia(x) and n_unita(x, "D") > 0, true, "ev_da", "Basta così")
		if ferma() or da == null:
			break
		var a = scegli_spazio(f, "In quale Provincia adiacente?", func(x): return provincia(x) and adiacente(da, x), false, "ev_a")
		if ferma():
			return
		var k := scegli_pezzo(f, da, ["t", "g"], "Quale Unità?", false)
		if ferma():
			return
		muovi(da, a, k, 1)
		mossi += 1
	cambia_ris("D", -5)


func ev10s(_f: String) -> void:
	var giri := 0
	while giri < 6:
		giri += 1
		var da = scegli_spazio("D", "Sposta una Qasbah: quale?", func(x): return int(X(x)["q"]) > 0, true, "ev_da", "Basta così")
		if ferma() or da == null:
			break
		var a = scegli_spazio("D", "Dove va la Qasbah?", func(x): return int(X(x)["g"]) > 0 and int(X(x)["q"]) == 0, true, "ev_a", "Non spostarla")
		if ferma():
			return
		if a == null:
			break
		muovi(da, a, "q", 1)
	for id in ordine:
		if int(X(id)["q"]) > 0 and disp("t") > 0:
			piazza_fino("D", id, 2)
			if ferma():
				return


# ---------------------------------------------------------------- 11 Hindu Kush

func ev11u(f: String) -> void:
	for id in ["passi", "punjab"]:
		var n := numero(f, "Quanti Invasori mongoli piazzi in %s?" % nome_sp(id), 0, min(2, disp("m")), "ev_n")
		if ferma():
			return
		piazza(id, "m", n)


func ev11s(_f: String) -> void:
	var tolti := 0
	while tolti < 4:
		var id = scegli_spazio("D", "Rimuovi Invasori mongoli (%d di 4)" % tolti, func(x): return int(X(x)["m"]) > 0, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		var n := numero("D", "Quanti ne togli da %s?" % nome_sp(id), 1, min(4 - tolti, int(X(id)["m"])), "ev_n")
		if ferma():
			return
		rimuovi(id, "m", n)
		tolti += n


# ---------------------------------------------------------------- 12 Musunuri

func ev12u(f: String) -> void:
	var g := attore(f, ["B", "V"])
	if ferma() or g == "":
		return
	guadagna_cav(g, 2)
	for i in 4:
		var id = scegli_spazio(g, "Rimuovi un pezzo del Sultanato adiacente a Warangal (%d di 4)" % (i + 1), func(x): return x in vicini_citta("warangal") and n_pezzi(x, "D") > 0, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		var k := scegli_pezzo(g, id, ["t", "g", "q"], "Quale pezzo?", false)
		if ferma():
			return
		rimuovi(id, k, 1)


func ev12s(_f: String) -> void:
	guadagna_cav("D", 2)
	if ferma():
		return
	var id = scegli_spazio("D", "Dove piazzi Qasbah e Truppe (adiacente a Warangal)?", func(x): return x in vicini_citta("warangal"), true, "ev_sp", "Nessun piazzamento")
	if ferma():
		return
	if id != null:
		if disp("q") > 0 and int(X(id)["q"]) == 0 and si_no("D", "Piazzi una Qasbah in %s?" % nome_sp(id), "ev_str"):
			piazza(id, "q", 1)
		if ferma():
			return
		piazza_fino("D", id, 4)
		if ferma():
			return
	attacco_libero("D", {"filtro": func(x): return x in vicini_citta("warangal")})


# ---------------------------------------------------------------- 13 Vidyaranya

func ev13u(_f: String) -> void:
	s["tmp"]["liberati_V"] = 0
	cambia_infl("V", 2)
	if ferma():
		return
	var n: int = min(int(s["tmp"].get("liberati_V", 0)), disp("r"))
	for i in n:
		var id = scegli_spazio("V", "Piazza un Raja appena ottenuto adiacente a Vijayanagara (%d di %d)" % [i + 1, n], func(x): return x in vicini_citta("vijayanagara"), true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		piazza(id, "r", 1)


func ev13s(f: String) -> void:
	var da = scegli_spazio(f, "Da quale Provincia sposti i Raja?", func(x): return provincia(x) and raja(x) > 0 and adiacenti(x).any(func(a): return provincia(a) and n_pezzi(a, "B") > 0), true, "ev_da", "Rinuncia")
	if ferma() or da == null:
		return
	var a = scegli_spazio(f, "In quale Provincia adiacente con un pezzo bahmani?", func(x): return provincia(x) and adiacente(da, x) and n_pezzi(x, "B") > 0, false, "ev_a")
	if ferma():
		return
	var n := numero(f, "Quanti Raja sposti?", 1, raja(da), "ev_n")
	if ferma():
		return
	var nr: int = min(n, int(X(da)["rr"]))
	muovi(da, a, "rr", nr)
	muovi(da, a, "ro", n - nr)
	attacco_libero("B", {"filtro": func(x): return x == a, "bersaglio": "V"})


# ---------------------------------------------------------------- 14 Hoysala

func ev14u(_f: String) -> void:
	guadagna_cav("V", 2)
	if ferma():
		return
	var vic: Array = vicini_citta("vijayanagara")
	var t = scegli_spazio("V", "Togli un segnalino Tributo adiacente a Vijayanagara?", func(x): return x in vic and X(x)["trib"], true, "ev_trib", "Nessuno")
	if ferma():
		return
	if t != null:
		togli_tributo(t)
	for i in 2:
		var id = scegli_spazio("V", "Piazza un Raja adiacente a Vijayanagara (%d di 2)" % (i + 1), func(x): return x in vic, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		piazza(id, "r", 1)


func ev14s(_f: String) -> void:
	guadagna_cav("D", 3)
	if ferma():
		return
	var id = scegli_spazio("D", "In quale Provincia adiacente a Vijayanagara porti Truppe e un Governatore?", func(x): return x in vicini_citta("vijayanagara"), true, "ev_sp", "Rinuncia")
	if ferma() or id == null:
		return
	piazza_fino("D", id, 4)
	if ferma():
		return
	if disp("g") > 0 and si_no("D", "Piazzi un Governatore in %s?" % nome_sp(id), "ev_gov"):
		piazza(id, "g", 1)
	if ferma():
		return
	dec_obbedienza("D", {"solo_in": [id]})


# ---------------------------------------------------------------- 15 Daulatabad

func ev15u(f: String) -> void:
	var toccate: Array = []
	for id in vicini_citta("devagiri"):
		var n := int(X(id)["g"])
		if n <= 0:
			continue
		X(id)["g"] = 0
		s["disp"]["g"] = disp("g") + n
		piazza(id, "a", n, true)
		_dopo(id)
		toccate.append(id)
		nota("In %s %s diventano Emiri ribelli." % [nome_sp(id), pz(n, "g")])
	var c := toccate.filter(func(x): return X(x)["trib"])
	if c.is_empty():
		return
	var id = scegli_spazio(f, "In quale delle Province coinvolte togli il Tributo?", func(x): return x in c, false, "ev_trib")
	if ferma():
		return
	togli_tributo(id)


func ev15s(f: String) -> void:
	var id = scegli_spazio(f, "In quale Provincia adiacente a Devagiri sostituisci un Emiro con un Governatore?", func(x): return x in vicini_citta("devagiri") and amiri(x) > 0 and disp("g") > 0, true, "ev_sp", "Rinuncia")
	if ferma() or id == null:
		return
	var k := "ar" if int(X(id)["ar"]) > 0 else "ao"
	rimuovi(id, k, 1)
	piazza(id, "g", 1)
	metti_tributo(id)


# ---------------------------------------------------------------- 16 Gulbarga

func ev16u(_f: String) -> void:
	var vic: Array = vicini_citta("gulbarga")
	for i in 3:
		var id = scegli_spazio("B", "Aggiungi un Emiro adiacente a Gulbarga (%d di 3)" % (i + 1), func(x): return x in vic and disp("a") > 0, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		piazza(id, "a", 1)
	if ferma():
		return
	if disp("f") > 0:
		var id = scegli_spazio("B", "Dove aggiungi un Forte (adiacente a Gulbarga)?", func(x): return x in vic and int(X(x)["f"]) == 0, true, "ev_sp", "Nessun Forte")
		if ferma() or id == null:
			return
		piazza(id, "f", 1)


func ev16s(f: String) -> void:
	var g := attore(f, ["D", "V"])
	if ferma() or g == "":
		return
	var c := "marcia" if g == "D" else "migra"
	comando(g, {"limitata": true, "gratis": true, "solo": c, "filtro": func(x): return int(X(x)["f"]) > 0})
	if ferma():
		return
	for id in s["tmp"].get("scelti", []):
		if int(X(id)["f"]) > 0:
			rimuovi(id, "f", 1)
			nota("Il Forte in %s è rimosso." % nome_sp(id))


# ---------------------------------------------------------------- 17 Shaikh sufi

func ev17u(_f: String) -> void:
	cambia_infl("B", 1)
	if ferma():
		return
	for i in 5:
		var id = scegli_spazio("B", "Rimuovi un pezzo del Sultanato in una Provincia con un pezzo bahmani (%d di 5)" % (i + 1), func(x): return provincia(x) and n_pezzi(x, "B") > 0 and n_pezzi(x, "D") > 0, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		var k := scegli_pezzo("B", id, ["t", "g", "q"], "Quale pezzo?", false)
		if ferma():
			return
		rimuovi(id, k, 1)


func ev17s(f: String) -> void:
	var id = scegli_spazio(f, "Da quale Provincia togli un Forte e fino a 2 Emiri?", func(x): return provincia(x) and (int(X(x)["f"]) > 0 or amiri(x) > 0), true, "ev_sp", "Nessuna")
	if ferma():
		return
	if id != null:
		rimuovi(id, "f", 1)
		var n := numero(f, "Quanti Emiri togli da %s?" % nome_sp(id), 0, min(2, amiri(id)), "ev_n")
		if ferma():
			return
		var nr: int = min(n, int(X(id)["ar"]))
		rimuovi(id, "ar", nr)
		rimuovi(id, "ao", n - nr)
	cambia_ris("B", -2)


# ---------------------------------------------------------------- 18 Centro di alta cultura

func ev18u(_f: String) -> void:
	var n := 0
	for id in ordine:
		if provincia(id) and n_pezzi(id, "B") > 0 and n_pezzi(id, "V") > 0:
			n += 1
	cambia_infl("B", n)


func ev18s(f: String) -> void:
	var g := attore(f, ["D", "V"])
	if ferma() or g == "":
		return
	var id = scegli_spazio(g, "Sostituisci un Emiro: dove?", func(x): return amiri(x) > 0, true, "ev_sp", "Nessuno")
	if ferma():
		return
	if id != null:
		var k := "ar" if int(X(id)["ar"]) > 0 else "ao"
		rimuovi(id, k, 1)
		piazza(id, "g" if g == "D" else "r", 1)
	cambia_infl("B", -1)


# ---------------------------------------------------------------- 19 Bengala

func ev19u(f: String) -> void:
	for id in ["jaunpur", "bengal"]:
		var g := attore(f, ["B", "V"])
		if ferma() or g == "":
			return
		piazza_fino(g, id, 2)
		if ferma():
			return
	var c := ["jaunpur", "bengal"].filter(func(x): return X(x)["trib"])
	if c.is_empty():
		return
	var id = scegli_spazio(f, "Dove togli il segnalino Tributo?", func(x): return x in c, false, "ev_trib")
	if ferma():
		return
	togli_tributo(id)


func ev19s(_f: String) -> void:
	for id in ["jaunpur", "bengal"]:
		piazza_fino("D", id, 4)
		if ferma():
			return
	var c := ["jaunpur", "bengal"].filter(func(x): return not X(x)["trib"])
	if c.is_empty():
		return
	var id = scegli_spazio("D", "Dove rimetti il segnalino Tributo?", func(x): return x in c, true, "ev_trib", "In nessuna")
	if ferma() or id == null:
		return
	metti_tributo(id)


# ---------------------------------------------------------------- 20 Ganga orientali

func ev20u(f: String) -> void:
	var g := attore(f, ["V", "B"])
	if ferma() or g == "":
		return
	cambia_infl(g, 1)
	if ferma():
		return
	var zona := ["orissa"] + adiacenti("orissa")
	var id = scegli_spazio(g, "In quale Provincia (Orissa o adiacente) agisci?", func(x): return x in zona and provincia(x), true, "ev_sp", "Rinuncia")
	if ferma() or id == null:
		return
	if ok_migra(g, id, {}) and si_no(g, "Migrazione gratuita verso %s?" % nome_sp(id), "ev_mig"):
		s["tmp"]["usati"] = {}
		cmd_migra(g, id, {})
	if ferma():
		return
	if ok_raduna(g, id, {}) and si_no(g, "Raduno gratuito in %s?" % nome_sp(id), "ev_rad"):
		cmd_raduna(g, id, {})
	if ferma():
		return
	if okd_costruisci(g) and _ok_costruisci(g, id) and si_no(g, "Costruisci in %s?" % nome_sp(id), "ev_cos"):
		piazza(id, "f" if g == "B" else "tp", 1)


func ev20s(_f: String) -> void:
	var id := "orissa"
	var k := scegli_pezzo("D", id, ["tp", "f"], "Rimuovi un Tempio o un Forte in Orissa?")
	if ferma():
		return
	if k != "":
		rimuovi(id, k, 1)
	if disp("g") > 0 and si_no("D", "Piazzi un Governatore in Orissa?", "ev_gov"):
		piazza(id, "g", 1)
	if ferma():
		return
	if disp("q") > 0 and int(X(id)["q"]) == 0 and si_no("D", "Piazzi una Qasbah in Orissa?", "ev_str"):
		piazza(id, "q", 1)
	if ferma():
		return
	piazza_fino("D", id, 2)
	if ferma():
		return
	if not X(id)["trib"] and si_no("D", "Rimetti il Tributo in Orissa?", "ev_trib"):
		metti_tributo(id)


# ---------------------------------------------------------------- 21 Vindhya

func ev21u(f: String) -> void:
	var g := attore(f, ["B", "V"])
	if ferma() or g == "":
		return
	for id in ["gondwana", "madhyadesh"]:
		var n := int(X(id)["t"])
		if n > 0:
			var q := numero(g, "Quante Truppe di %s mandi a Delhi?" % nome_sp(id), 0, n, "ev_n")
			if ferma():
				return
			muovi(id, "delhi", "t", q)


func ev21s(_f: String) -> void:
	dec_campagna("D", {})
	if ferma():
		return
	var zona: Array = vicini_citta("vindhya")
	var ops := [o("governa", "Governa"), o("attacca", "Attacca"), o("obbedienza", "Esigi obbedienza"), o("no", "Niente")]
	var v = chiedi("D", "Poi, in una Provincia adiacente ai Vindhya:", ops, {"tag": "ev_azione"})
	if ferma() or v == "no":
		return
	if v == "obbedienza":
		dec_obbedienza("D", {"solo_in": zona})
	else:
		comando("D", {"limitata": true, "solo": v, "filtro": func(x): return x in zona})


# ---------------------------------------------------------------- 22 Nuovo calcolo

func ev22u(f: String) -> void:
	var g := attore(f, ["V", "B"])
	if ferma() or g == "":
		return
	if okd_costruisci(g):
		dec_costruisci(g, {})


func ev22s(_f: String) -> void:
	var fatti: Array = []
	for n in [1, 2, 4]:
		if disp("t") <= 0:
			break
		var id = scegli_spazio("D", "Piazza fino a %d Truppe: in quale spazio?" % n, func(x): return not x in fatti, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		fatti.append(id)
		piazza_fino("D", id, n)
		if ferma():
			return


# ---------------------------------------------------------------- 23 Virupaksha

func ev23u(_f: String) -> void:
	cambia_infl("V", 1)
	if ferma():
		return
	if okd_costruisci("V"):
		dec_costruisci("V", {})
		if ferma():
			return
	for id in ordine:
		if int(X(id)["tp"]) > 0 and n_unita(id, "D") + amiri(id) > 0:
			var k := scegli_pezzo("V", id, ["t", "g", "ao", "ar"], "In %s sostituisci un'Unità con un Raja?" % nome_sp(id))
			if ferma():
				return
			if k != "":
				sostituisci(id, k, "V")


func ev23s(f: String) -> void:
	var g := f if f != "V" else attore(f, ["D", "B"])
	if ferma() or g == "":
		return
	var id = scegli_spazio(g, "In quale Provincia con un Tempio?", func(x): return int(X(x)["tp"]) > 0, true, "ev_sp", "Rinuncia")
	if ferma() or id == null:
		return
	piazza_fino(g, id, 4)
	if ferma():
		return
	rimuovi(id, "tp", 1)
	nota("Il Tempio in %s è distrutto." % nome_sp(id))
	prendi_ris("V", g, 2)


# ---------------------------------------------------------------- 24 Carri di pietra

func ev24u(_f: String) -> void:
	comando("V", {"gratis": true, "solo": "migra", "max": 2})
	if ferma():
		return
	var c: Array = s["tmp"].get("scelti", [])
	var cand := c.filter(func(x): return n_unita(x, "D") + amiri(x) > 0)
	if cand.is_empty() or disp("r") <= 0:
		return
	var id = scegli_spazio("V", "In quale delle destinazioni sostituisci un'Unità con un Raja?", func(x): return x in cand, true, "ev_sp", "Nessuna")
	if ferma() or id == null:
		return
	var k := scegli_pezzo("V", id, ["t", "g", "ao", "ar"], "Quale Unità?", false)
	if ferma():
		return
	sostituisci(id, k, "V")


func ev24s(f: String) -> void:
	var g := attore(f, ["D", "B"])
	if ferma() or g == "":
		return
	for id in ordine:
		if int(X(id)["tp"]) > 0:
			piazza_fino(g, id, 2)
			if ferma():
				return


# ---------------------------------------------------------------- 25 Costruire un impero

func ev25u(f: String) -> void:
	var g := attore(f, ["B", "V"])
	if ferma() or g == "":
		return
	var d := "commercio" if g == "B" else "tassa"
	var v = chiedi(g, "Che cosa scegli?", [o(d, nome_cmd(d)), o("3", "Guadagna 3 Risorse")], {"tag": "ev_scelta"})
	if ferma():
		return
	if v == "3":
		cambia_ris(g, 3)
	else:
		call("dec_" + d, g, {})


func ev25s(_f: String) -> void:
	var zona: Array = vicini_citta("goa") + vicini_citta("warangal")
	var fatti: Array = []
	for i in 3:
		var id = scegli_spazio("D", "Piazza fino a 2 Truppe vicino a Goa o Warangal (%d di 3)" % (i + 1), func(x): return x in zona and not x in fatti, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		fatti.append(id)
		piazza_fino("D", id, 2)
		if ferma():
			return
	if fatti.is_empty():
		return
	var id = scegli_spazio("D", "Governa gratis in una di esse?", func(x): return x in fatti and ok_governa("D", x, {"ovunque": true}), true, "ev_sp", "No")
	if ferma() or id == null:
		return
	cmd_governa("D", id, {"ovunque": true})


# ---------------------------------------------------------------- 26 Di dèi e di re

func ev26u(f: String) -> void:
	var fuori: Array = s["fuori"]
	if fuori.is_empty():
		nota("Nessuna carta Evento fuori gioco.")
		return
	var c: String = fuori[_rand(fuori.size())]
	fuori.erase(c)
	s["riserva"][f] = c
	nota("%s tiene da parte l'Evento «%s»." % [breve(f), carta_dati(c)["titolo"]])


func ev26s(f: String) -> void:
	ev26u(f)


# ---------------------------------------------------------------- 27 Taghi

func ev27u(_f: String) -> void:
	cambia_infl("B", 1)
	if ferma():
		return
	for id in ["sindh", "gujarat"]:
		piazza_fino("B", id, 2)
		if ferma():
			return
	piazza("sindh", "f", 1)
	togli_tributo("sindh")


func ev27s(_f: String) -> void:
	for id in ["sindh", "gujarat"]:
		piazza_fino("D", id, 2)
		if ferma():
			return
		if disp("g") > 0 and si_no("D", "Piazzi un Governatore in %s?" % nome_sp(id), "ev_gov"):
			piazza(id, "g", 1)
		if ferma():
			return
	piazza("sindh", "q", 1)
	metti_tributo("sindh")


# ---------------------------------------------------------------- 28 Trono turchese

func ev28u(_f: String) -> void:
	cambia_infl("B", 1)
	if ferma():
		return
	cambia_infl("V", -1)
	if ferma():
		return
	if int(s["cav"]["B"]) > 0 and si_no("B", "Spendi 1 Cavalleria per piazzare 2 Emiri e togliere 1 Raja nell'Andhra?", "ev_spendi"):
		spendi_cav("B")
		piazza("andhra", "a", 2)
		var k := "rr" if int(X("andhra")["rr"]) > 0 else "ro"
		rimuovi("andhra", k, 1)


func ev28s(f: String) -> void:
	var g := attore(f, ["D", "V"])
	if ferma() or g == "":
		return
	var id = scegli_spazio(g, "In quale spazio con un pezzo bahmani?", func(x): return n_pezzi(x, "B") > 0, true, "ev_sp", "Rinuncia")
	if ferma() or id == null:
		return
	piazza_fino(g, id, 2)
	if ferma():
		return
	attacco_libero(g, {"filtro": func(x): return x == id, "bersaglio": "B", "dif_no_dadi": true})


# ---------------------------------------------------------------- 29 Ashvapati

func ev29u(_f: String) -> void:
	guadagna_cav("B", 3)
	if ferma():
		return
	attacco_libero("B")


func ev29s(f: String) -> void:
	var n := numero(f, "Quante Risorse spendi per altrettanta Cavalleria?", 0, min(3, int(s["ris"][f])), "ev_n")
	if ferma():
		return
	if n > 0:
		cambia_ris(f, -n)
		guadagna_cav(f, n)
		if ferma():
			return
	attacco_libero(f)


# ---------------------------------------------------------------- 30 Bara Gazi Toph

func ev30u(_f: String) -> void:
	comando("B", {"gratis": true, "solo": "attacca", "dif_no_dadi": true, "filtro": func(x): return int(X(x)["f"]) > 0})


func ev30s(f: String) -> void:
	attacco_libero(f, {"dif_no_dadi": true, "att_4_dadi": true})


# ---------------------------------------------------------------- 31 Raichur

func ev31u(f: String) -> void:
	var g := attore(f, ["B", "V"])
	if ferma() or g == "":
		return
	var vic: Array = vicini_citta("vijayanagara")
	comando(g, {"limitata": true, "gratis": true, "solo": "migra", "filtro": func(x): return x in vic})
	if ferma():
		return
	var c: Array = s["tmp"].get("scelti", [])
	if c.is_empty():
		return
	var id: String = c[0]
	var k := scegli_pezzo(g, id, avversarie_unita(g).filter(func(x): return x != "m"), "Rimuovi 1 Unità avversaria in %s?" % nome_sp(id))
	if ferma():
		return
	if k != "":
		rimuovi(id, k, 1)
	s["tmp"]["usati"] = {}
	s["tmp"]["scelti"] = []
	attacco_libero(g, {"filtro": func(x): return x == id})


func ev31s(_f: String) -> void:
	var vic: Array = vicini_citta("vijayanagara")
	for k in ["f", "tp"]:
		var id = scegli_spazio("D", "Rimuovi un %s adiacente a Vijayanagara?" % nome_pezzo(k), func(x): return x in vic and int(X(x)[k]) > 0, true, "ev_sp", "No")
		if ferma():
			return
		if id != null:
			rimuovi(id, k, 1)
	cambia_infl("B", -1)
	if ferma():
		return
	cambia_infl("V", -1)


# ---------------------------------------------------------------- 32 La lepre e i cani

func ev32u(f: String) -> void:
	var g := attore(f, ["B", "V"])
	if ferma() or g == "":
		return
	var r := altra_bv(g)
	cambia_infl(g, 1)
	if ferma():
		return
	cambia_infl(r, -1)
	if ferma():
		return
	var ks: Array = UNITA_DI[r]
	for i in 2:
		var id = scegli_spazio(g, "Sostituisci un %s con un tuo %s (%d di 2)" % [nome_pezzo(ks[0]), nome_pezzo(unita_k(g)), i + 1], func(x): return n_unita(x, r) > 0, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		var k := scegli_pezzo(g, id, ks, "Quale?", false)
		if ferma():
			return
		sostituisci(id, k, g)


func ev32s(_f: String) -> void:
	cambia_infl("B", -1)
	if ferma():
		return
	cambia_infl("V", -1)


# ---------------------------------------------------------------- 33 Goa

func ev33u(_f: String) -> void:
	var vic: Array = vicini_citta("goa")
	var cont := {}
	for g in FAZ:
		cont[g] = 0
		for id in vic:
			cont[g] = int(cont[g]) + n_pezzi(id, g)
	var mx := 0
	for g in FAZ:
		mx = max(mx, int(cont[g]))
	var best: Array = []
	for g in FAZ:
		if int(cont[g]) == mx:
			best.append(g)
	var g: String = "B" if best.size() > 1 and "B" in best else best[0]
	if best.size() > 1 and not "B" in best:
		g = best[0]
	nota("Domina intorno a Goa: %s." % breve(g))
	for i in 3:
		var id = scegli_spazio(g, "Rimuovi un'Unità avversaria adiacente a Goa (%d di 3)" % (i + 1), func(x): return x in vic and avversarie_unita(g).any(func(k): return int(X(x)[k]) > 0), true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		var k := scegli_pezzo(g, id, avversarie_unita(g), "Quale Unità?", false)
		if ferma():
			return
		rimuovi(id, k, 1)
	cambia_ris(g, 2)


func ev33s(_f: String) -> void:
	if si_no("D", "Dimezzi le Risorse di Vijayanagara e dei Bahmani?", "ev_dim"):
		for g in ["V", "B"]:
			cambia_ris(g, -(int(s["ris"][g]) - int(s["ris"][g]) / 2))


# ---------------------------------------------------------------- 34 Sultano bahmani assassinato

func ev34u(_f: String) -> void:
	prendi_ris("B", "V", 2)
	var n: int = min(2, int(s["cav"]["B"]))
	if n > 0:
		s["cav"]["B"] = int(s["cav"]["B"]) - n
		s["cav"]["V"] = int(s["cav"]["V"]) + n
		nota("Vijayanagara prende %d Cavalleri%s ai Bahmani." % [n, "a" if n == 1 else "e"])


func ev34s(_f: String) -> void:
	decreto("B", {"solo": ["cospira", "commercio"]})


# ---------------------------------------------------------------- 35 Matrimoni

func ev35u(f: String) -> void:
	var g := attore(f, ["B", "V"])
	if ferma() or g == "":
		return
	cambia_infl(g, 1)
	if ferma():
		return
	var r := altra_bv(g)
	var fatti: Array = []
	for i in 3:
		var id = scegli_spazio(g, "Piazza una tua Unità dove ci sono Unità di %s (%d di 3)" % [breve(r), i + 1], func(x): return n_unita(x, r) > 0 and not x in fatti and disp(unita_k(g)) > 0, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		fatti.append(id)
		piazza(id, unita_k(g), 1)


func ev35s(_f: String) -> void:
	ev32s(_f)


# ---------------------------------------------------------------- 36 Alleanze del nord

func ev36u(_f: String) -> void:
	var vic: Array = vicini_citta("chittor")
	for i in 4:
		var id = scegli_spazio("V", "Piazza un Raja adiacente a Chittor (%d di 4)" % (i + 1), func(x): return x in vic and disp("r") > 0, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		piazza(id, "r", 1)


func ev36s(f: String) -> void:
	cambia_infl("V", -1)
	if ferma():
		return
	for i in 3:
		var id = scegli_spazio(f, "Rimuovi un Raja dalla mappa (%d di 3)" % (i + 1), func(x): return raja(x) > 0, true, "ev_sp", "Basta così")
		if ferma() or id == null:
			break
		var k := scegli_pezzo(f, id, ["ro", "rr"], "Quale?", false)
		if ferma():
			return
		rimuovi(id, k, 1)
