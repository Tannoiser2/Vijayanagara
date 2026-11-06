## Regole: turno sulla carta Evento, Comandi, Decreti, battaglie, Invasioni mongole, Successioni e Timur.
class_name Regole
extends Nucleo

const NOMI_CMD := {"coscrivi": "Coscrizione", "marcia": "Marcia", "governa": "Governa", "attacca": "Attacco",
	"raduna": "Raduno", "migra": "Migrazione", "ribellione": "Ribellione",
	"tributo": "Riscuoti tributi", "campagna": "Campagna", "obbedienza": "Esigi obbedienza",
	"commercio": "Commercio", "costruisci": "Costruisci", "cospira": "Cospira", "tassa": "Tassa", "costringi": "Costringi",
	"ammassa": "Ammassa", "avanza": "Avanza", "saccheggio": "Attacca e saccheggia"}
const COMANDI := {"D": ["coscrivi", "marcia", "governa", "attacca"], "B": ["raduna", "migra", "ribellione", "attacca"], "V": ["raduna", "migra", "ribellione", "attacca"]}
const DECRETI := {"D": ["tributo", "campagna", "obbedienza"], "B": ["commercio", "costruisci", "cospira"], "V": ["tassa", "costruisci", "costringi"]}
const CASELLE := {"cd": "Comando e Decreto", "ec": "Evento o Comando", "limitata": "Comando Limitato", "passa": "Passa"}


func nome_cmd(k: String) -> String:
	return NOMI_CMD.get(k, k)


func descrizione(k: String, f: String = "") -> String:
	match k:
		"coscrivi": return "In Tributarie, spazi con Qasbah e Delhi (1 Risorsa ciascuno): 5 Truppe a Delhi, 2 dove c'è una Qasbah, 1 altrove."
		"marcia": return "Per ogni destinazione (1 Risorsa) sposta Truppe e Governatori dagli spazi adiacenti."
		"governa": return "In Tributarie, Province del Sultanato, Regioni mongole e Delhi (1 Risorsa): piazza un Governatore oppure, dove c'è già, rimuovi fino a 2 Unità obbedienti e/o piazza una Qasbah."
		"attacca":
			if f == "D":
				return "Dove ci sono Unità ribelli o una struttura avversaria senza le sue Unità (1 Risorsa): 4 dadi contro 2 (3 contro i Bahmani con un Forte). Fino a 2 Unità di rinforzo da uno spazio adiacente con una Qasbah."
			if f == "B":
				return "In Province con pezzi avversari (1 Risorsa): tutti gli Emiri attaccano, più fino a 2 da una Provincia adiacente con un Forte. 4 dadi contro 2."
			return "In Province con pezzi avversari (1 Risorsa): tutti i Raja attaccano, più 1 da una Provincia adiacente con un Tempio. 4 dadi contro 2 (3 contro i Bahmani con un Forte)."
		"raduna":
			if f == "B":
				return "In Province con un pezzo bahmani o nel Maharashtra (1 Risorsa): 1 Emiro, +1 nel Maharashtra, +1 se la Provincia è Bahmani."
			return "In Province con un pezzo di Vijayanagara o nel Karnataka (1 Risorsa): 1 Raja, +1 nel Karnataka, +1 con un Tempio, +1 se la Provincia è di Vijayanagara."
		"migra": return "Per ogni Provincia di destinazione (1 Risorsa) sposta fino a 3 tue Unità dalle Province adiacenti. In una destinazione con pezzi del rivale del Deccan puoi pagare 1 Risorsa per spostare l'Influenza a tuo favore."
		"ribellione": return "Solo con la Dinastia Tughlaq: nelle Tributarie dove hai la maggioranza (1 Risorsa) togli il Tributo e prendi il Controllo."
		"tributo": return "Risorse pari a metà della Prosperità Tributaria (per difetto) e 2 Cavallerie."
		"campagna": return "Sposta Truppe e Governatori da un unico spazio di partenza fino a 3 spazi di distanza, lasciandone o raccogliendone lungo la strada."
		"obbedienza": return "Nelle Province Indipendenti sotto Controllo del Sultanato con un Governatore: rimetti il Tributo e guadagna Risorse pari alla loro Prosperità."
		"commercio": return "Risorse pari alle Province con un pezzo bahmani, più 1 Cavalleria (2 con Influenza 1–2, 3 con Influenza 3–4)."
		"costruisci": return "Piazza un Forte in una Provincia con un Emiro." if f == "B" else "Piazza un Tempio in una Provincia con un Raja."
		"cospira": return "In fino a 2 Province con un pezzo bahmani sostituisci un Governatore con un Emiro. Con Influenza 2+ anche Raja, e anche nelle Province adiacenti."
		"tassa": return "Risorse pari alla Prosperità delle Province di Vijayanagara più i Templi sulla mappa."
		"costringi": return "In una Provincia con o adiacente a un tuo pezzo: piazza fino a 2 Raja o portane fino a 2 da una Provincia adiacente. Con Influenza 2+ anche 1 Cavalleria e rimozione di una Truppa, un Governatore o un Emiro."
	return ""


# ================================================================ TURNO SULLA CARTA EVENTO

func atto_turno(a: Dictionary) -> void:
	var f: String = a["f"]
	s["tmp"] = {}
	var cd := carta_dati(s["carta"])
	var ops: Array = []
	if not s["scelte"].has("cd"):
		ops.append(o("cd", CASELLE["cd"]))
	if not s["scelte"].has("ec"):
		ops.append(o("ec", CASELLE["ec"]))
	ops.append(o("limitata", CASELLE["limitata"] + " (resta idoneo)"))
	ops.append(o("passa", "Passa (+%d Risorse, resta idoneo)" % (3 if f == "D" else 1)))
	var b = chiedi(f, "%s: che cosa fai su «%s»?" % [nome_faz(f), cd["titolo"]], ops, {"tag": "casella", "mostra": true})
	if ferma():
		return
	if b in ["cd", "ec"]:
		s["scelte"][b] = f
	nota("%s: %s." % [breve(f), CASELLE[b]])
	match b:
		"passa":
			cambia_ris(f, 3 if f == "D" else 1)
		"limitata":
			comando(f, {"limitata": true})
		"cd":
			comando_e_decreto(f)
		"ec":
			var e := [o("evento", "Evento"), o("comando", "Comando (senza Decreto)")]
			var r: String = s["riserva"].get(f, "")
			if r != "":
				e.insert(1, o("riserva", "Evento riservato: " + carta_dati(r)["titolo"]))
			var v = chiedi(f, "Evento o Comando?", e, {"tag": "evcmd", "mostra": true})
			if ferma():
				return
			if v == "comando":
				comando(f, {})
			else:
				var cid: String = s["carta"] if v == "evento" else r
				evento(f, carta_dati(cid))
				if ferma():
					return
				if v == "riserva":
					s["riserva"].erase(f)
				if carta_dati(cid).get("resta", false):
					s["resta"].append(f)


func comando_e_decreto(f: String) -> void:
	var quando = chiedi(f, "Il Decreto prima o dopo il Comando?", [o("dopo", "Prima il Comando, poi il Decreto"), o("prima", "Prima il Decreto")], {"tag": "quando"})
	if ferma():
		return
	if quando == "prima":
		decreto(f, {})
		if ferma():
			return
		comando(f, {})
	else:
		comando(f, {})
		if ferma():
			return
		decreto(f, {})


# ================================================================ COMANDI

func comando_permesso(f: String, c: String, opz: Dictionary) -> bool:
	if c == "ribellione" and s["dinastia"] == "khalji" and not opz.get("sempre", false):
		return false
	return true


## opz: limitata, gratis, solo (Comando obbligato), filtro (Callable sugli spazi), sempre (Ribellione con ogni Dinastia),
## max (numero massimo di spazi), dif_no_dadi, att_4_dadi, bersaglio (fazione obbligata da attaccare).
func comando(f: String, opz: Dictionary) -> void:
	var ops: Array = []
	for c in COMANDI[f]:
		if opz.has("solo") and c != opz["solo"]:
			continue
		if not comando_permesso(f, c, opz):
			continue
		if not _spazi_validi(f, c, opz).is_empty():
			ops.append(o(c, nome_cmd(c)))
	ops.append(o("nessuno", "Nessun Comando"))
	var c = chiedi(f, "Quale Comando?" + (" (Limitato: un solo spazio)" if opz.get("limitata", false) else ""), ops, {"tag": "cmd", "mostra": opz.get("mostra", false)})
	if ferma() or c == null or c == "nessuno":
		return
	nota("%s: %s%s." % [breve(f), nome_cmd(c), " limitato" if opz.get("limitata", false) else ""])
	s["tmp"]["usati"] = {}
	s["tmp"]["scelti"] = []
	s["tmp"]["cmd"] = c
	s["tmp"]["cmd_gratis"] = opz.get("gratis", false)
	var maxn: int = 1 if opz.get("limitata", false) else int(opz.get("max", 99))
	if s["opz"].get("ombra_timur", false) and int(s["timur"]) >= 1:
		maxn = 1
	var fatti := 0
	while fatti < maxn:
		var validi := _spazi_validi(f, c, opz)
		if validi.is_empty():
			break
		var testo := "%s: scegli %sspazio%s" % [nome_cmd(c), "lo " if maxn == 1 else "un ", "" if opz.get("gratis", false) else " (1 Risorsa)"]
		var id = scegli_spazio(f, testo, func(x): return x in validi, fatti > 0 or not opz.get("obbligo", false), "spazio_cmd", "Basta così")
		if ferma() or id == null:
			break
		s["tmp"]["scelti"].append(id)
		if not opz.get("gratis", false):
			cambia_ris(f, -1)
		call("cmd_" + c, f, id, opz)
		if ferma():
			return
		fatti += 1
	if c == "migra" and fatti > 0:
		_migra_influenza(f)


func _costa(f: String, opz: Dictionary) -> bool:
	return opz.get("gratis", false) or int(s["ris"][f]) >= 1


func _spazi_validi(f: String, c: String, opz: Dictionary) -> Array:
	var r: Array = []
	if not _costa(f, opz):
		return r
	var scelti: Array = s["tmp"].get("scelti", [])
	for id in ordine:
		if id in scelti:
			continue
		if opz.has("filtro") and not (opz["filtro"] as Callable).call(id):
			continue
		if call("ok_" + c, f, id, opz):
			r.append(id)
	return r


# ---- Sultanato

func ok_coscrivi(_f: String, id: String, opz: Dictionary) -> bool:
	if disp("t") <= 0:
		return false
	if opz.get("ovunque", false):
		return true
	return id == "delhi" or int(X(id)["q"]) > 0 or (provincia(id) and X(id)["trib"])


func cmd_coscrivi(f: String, id: String, _opz: Dictionary) -> void:
	var mx := 5 if id == "delhi" else (2 if int(X(id)["q"]) > 0 else 1)
	mx = min(mx, disp("t"))
	var n := numero(f, "Quante Truppe piazzi in %s?" % nome_sp(id), 1, mx, "n_truppe") if mx > 1 else mx
	if ferma():
		return
	piazza(id, "t", n)
	nota("%s in %s." % [pz(n, "t"), nome_sp(id)])


func _mobili(id: String, k: String) -> int:
	var u: Dictionary = s["tmp"].get("usati", {})
	return int(X(id)[k]) - int(u.get(id + ":" + k, 0))


func _usa(id: String, k: String, n: int) -> void:
	var u: Dictionary = s["tmp"]["usati"]
	u[id + ":" + k] = int(u.get(id + ":" + k, 0)) + n


func ok_marcia(_f: String, id: String, _opz: Dictionary) -> bool:
	for a in adiacenti(id):
		if _mobili(a, "t") + _mobili(a, "g") > 0:
			return true
	return false


func cmd_marcia(f: String, id: String, _opz: Dictionary) -> void:
	var tot := 0
	for a in adiacenti(id):
		for k in ["t", "g"]:
			var mx := _mobili(a, k)
			if mx <= 0:
				continue
			var n := numero(f, "Marcia verso %s: quanti %s sposti da %s?" % [nome_sp(id), nome_pezzo(k, 2), nome_sp(a)], 0, mx, "n_marcia", {"da": a, "a": id, "k": k})
			if ferma():
				return
			if n > 0:
				muovi(a, id, k, n)
				_usa(id, k, n)
				tot += n
	nota("Marcia: %d Unità entrano in %s." % [tot, nome_sp(id)])


func ok_governa(_f: String, id: String, opz: Dictionary) -> bool:
	if not opz.get("ovunque", false):
		if provincia(id) and not (X(id)["trib"] or X(id)["ctrl"] == "D"):
			return false
	if int(X(id)["g"]) > 0:
		return true
	return disp("g") > 0


func cmd_governa(f: String, id: String, _opz: Dictionary) -> void:
	var scelta = "piazza"
	if int(X(id)["g"]) > 0:
		var ops: Array = []
		if amiri_obb(id) + int(X(id)["ro"]) > 0 or (disp("q") > 0 and int(X(id)["q"]) == 0):
			ops.append(o("usa", "Rimuovi Unità obbedienti e/o piazza una Qasbah"))
		if disp("g") > 0:
			ops.append(o("piazza", "Piazza un altro Governatore"))
		if ops.is_empty():
			return
		scelta = chiedi(f, "Governa in %s:" % nome_sp(id), ops, {"tag": "governa"})
		if ferma():
			return
	if scelta == "piazza":
		piazza(id, "g", 1)
		nota("Un Governatore in %s." % nome_sp(id))
		return
	for i in 2:
		var ops2: Array = []
		if int(X(id)["ao"]) > 0:
			ops2.append(o("ao", "Rimuovi un Emiro obbediente"))
		if int(X(id)["ro"]) > 0:
			ops2.append(o("ro", "Rimuovi un Raja obbediente"))
		if ops2.is_empty():
			break
		ops2.append(o("no", "Nessun'altra rimozione"))
		var k = chiedi(f, "Governa in %s: rimozione %d di 2" % [nome_sp(id), i + 1], ops2, {"tag": "gov_rim"})
		if ferma():
			return
		if k == "no":
			break
		rimuovi(id, k, 1)
		nota("Rimosso un %s in %s." % [nome_pezzo_stato(k), nome_sp(id)])
	if disp("q") > 0 and int(X(id)["q"]) == 0:
		if si_no(f, "Piazzi una Qasbah in %s?" % nome_sp(id), "qasbah"):
			piazza(id, "q", 1)
			nota("Una Qasbah in %s." % nome_sp(id))


func amiri_obb(id: String) -> int:
	return int(X(id)["ao"])


func ok_attacca(f: String, id: String, opz: Dictionary) -> bool:
	return not _difensori(f, id, opz).is_empty() and (_attaccanti_qui(f, id) > 0 or not _sostegni(f, id).is_empty())


## Fazioni che f può attaccare in id.
func _difensori(f: String, id: String, opz: Dictionary) -> Array:
	var r: Array = []
	var cand: Array = ["B", "V", "M"] if f == "D" else ["D", altra_bv(f)]
	if opz.has("bersaglio"):
		cand = [opz["bersaglio"]]
	for g in cand:
		if g == f:
			continue
		if f == "D":
			if ribelli(id, g) > 0:
				r.append(g)
			elif g != "M" and int(X(id)[STRUTTURA_DI[g]]) > 0 and n_unita(id, g) == 0:
				r.append(g)
		else:
			if not provincia(id):
				continue
			if n_pezzi(id, g) > 0:
				r.append(g)
	return r


func _attaccanti_qui(f: String, id: String) -> int:
	var t := 0
	for k in UNITA_DI[f]:
		t += _mobili(id, k)
	return t


func _sostegni(f: String, id: String) -> Array:
	var r: Array = []
	var st: String = STRUTTURA_DI[f]
	for a in adiacenti(id):
		if f != "D" and not provincia(a):
			continue
		if int(X(a)[st]) > 0 and _attaccanti_qui(f, a) > 0:
			r.append(a)
	return r


func cmd_attacca(f: String, id: String, opz: Dictionary) -> void:
	var dif := _difensori(f, id, opz)
	var ops: Array = []
	for g in dif:
		ops.append(o(g, breve(g)))
	var g = chiedi(f, "Attacco in %s: chi attacchi?" % nome_sp(id), ops, {"tag": "bersaglio"})
	if ferma():
		return
	rendi_ribelli(id, g)
	# Unità che attaccano nello spazio
	var att := {}
	for k in UNITA_DI[f]:
		var n := _mobili(id, k)
		if n > 0:
			att[id + ":" + k] = n
	# rinforzi da uno spazio adiacente
	var sost := _sostegni(f, id)
	if not sost.is_empty():
		var mx := 1 if f == "V" else 2
		var opz2: Array = []
		for a in sost:
			opz2.append(o(a, nome_sp(a)))
		opz2.append(o("no", "Nessun rinforzo"))
		var da = chiedi(f, "Rinforzi (fino a %d) da uno spazio adiacente con %s?" % [mx, nome_pezzo(STRUTTURA_DI[f])], opz2, {"tag": "rinforzi", "spazi": true})
		if ferma():
			return
		if da != "no":
			var resto := mx
			for k in UNITA_DI[f]:
				var n: int = min(resto, _mobili(da, k))
				if n <= 0:
					continue
				if UNITA_DI[f].size() > 1 and k == UNITA_DI[f][0] and _mobili(da, UNITA_DI[f][1]) > 0:
					n = numero(f, "Rinforzi da %s: quanti %s?" % [nome_sp(da), nome_pezzo_stato(k, 2)], 0, n, "n_rinforzi")
					if ferma():
						return
				if n > 0:
					att[da + ":" + k] = n
					resto -= n
	var tot := 0
	for k in att:
		tot += int(att[k])
	if tot == 0:
		return
	for k in att:
		var p: Array = k.split(":")
		_usa(p[0], p[1], int(att[k]))
	var dadi := 4
	if g == "B" and int(X(id)["f"]) > 0 and f != "B" and not opz.get("att_4_dadi", false):
		dadi = 3
	battaglia(f, g, id, att, dadi, 0 if opz.get("dif_no_dadi", false) else 2)


# ---- Bahmani e Vijayanagara

func ok_raduna(f: String, id: String, _opz: Dictionary) -> bool:
	if not provincia(id) or disp("a" if f == "B" else "r") <= 0:
		return false
	return n_pezzi(id, f) > 0 or id == ("maharashtra" if f == "B" else "karnataka")


func cmd_raduna(f: String, id: String, _opz: Dictionary) -> void:
	var k := "a" if f == "B" else "r"
	var mx := 1
	if f == "B":
		if id == "maharashtra":
			mx += 1
	else:
		if id == "karnataka":
			mx += 1
		if int(X(id)["tp"]) > 0:
			mx += 1
	if X(id)["ctrl"] == f:
		mx += 1
	mx = min(mx, disp(k))
	var n := numero(f, "Raduno in %s: quanti %s piazzi?" % [nome_sp(id), nome_pezzo(k, 2)], 1, mx, "n_raduno") if mx > 1 else mx
	if ferma():
		return
	piazza(id, k, n)
	nota("Raduno: %s in %s." % [pz(n, k), nome_sp(id)])


func ok_migra(f: String, id: String, _opz: Dictionary) -> bool:
	if not provincia(id):
		return false
	for a in adiacenti(id):
		if provincia(a) and _attaccanti_qui(f, a) > 0:
			return true
	return false


func cmd_migra(f: String, id: String, _opz: Dictionary) -> void:
	var resto := 3
	var ks: Array = UNITA_DI[f]
	for a in adiacenti(id):
		if resto <= 0:
			break
		if not provincia(a):
			continue
		var mx: int = min(resto, _attaccanti_qui(f, a))
		if mx <= 0:
			continue
		var n := numero(f, "Migrazione verso %s: quanti %s porti da %s?" % [nome_sp(id), nome_pezzo(ks[0], 2), nome_sp(a)], 0, mx, "n_migra", {"da": a, "a": id})
		if ferma():
			return
		if n <= 0:
			continue
		# quanti ribelli fra quelli che si spostano (conta solo se la destinazione non decide da sé)
		var rib_disp := _mobili(a, ks[1])
		var obb_disp := _mobili(a, ks[0])
		var nr: int = max(0, n - obb_disp)
		if rib_disp > 0 and obb_disp > 0 and not X(id)["trib"] and X(id)["ctrl"] != f:
			nr = numero(f, "Di questi %d, quanti sono ribelli?" % n, max(0, n - obb_disp), min(n, rib_disp), "n_ribelli")
			if ferma():
				return
		if nr > 0:
			muovi(a, id, ks[1], nr)
		if n - nr > 0:
			muovi(a, id, ks[0], n - nr)
		_usa(id, ks[0], n)
		_usa(id, ks[1], n)
		resto -= n
	nota("Migrazione: %d %s entrano in %s." % [3 - resto, nome_pezzo(ks[0], 3 - resto), nome_sp(id)])


## Dopo una Migrazione: in una destinazione con pezzi del rivale si può pagare 1 Risorsa per spostare l'Influenza.
func _migra_influenza(f: String) -> void:
	var r := altra_bv(f)
	if int(s["ris"][f]) < 1:
		return
	var ok := false
	for id in s["tmp"].get("scelti", []):
		if n_pezzi(id, r) > 0:
			ok = true
	if not ok:
		return
	if int(s["infl"][f]) >= 4 and int(s["infl"][r]) <= 0:
		return
	if si_no(f, "Paghi 1 Risorsa per +1 alla tua Influenza e −1 a quella di %s?" % breve(r), "migra_infl"):
		cambia_ris(f, -1)
		cambia_infl(f, 1)
		if ferma():
			return
		cambia_infl(r, -1)


func ok_ribellione(f: String, id: String, _opz: Dictionary) -> bool:
	if not provincia(id) or not X(id)["trib"]:
		return false
	var mio := n_pezzi(id, f)
	var altri := 0
	for g in FAZ:
		if g != f:
			altri += n_pezzi(id, g)
	return mio > altri


func cmd_ribellione(f: String, id: String, _opz: Dictionary) -> void:
	X(id)["trib"] = false
	rendi_ribelli(id, f)
	nota("Ribellione: %s diventa Indipendente." % nome_sp(id))
	_dopo(id)


# ================================================================ BATTAGLIA

## att: {"spazio:chiave": n} Unità attaccanti; dadi_a/dadi_d: dadi dell'attaccante e del difensore.
func battaglia(fa: String, fd: String, id: String, att: Dictionary, dadi_a: int, dadi_d: int) -> void:
	var na := 0
	for k in att:
		na += int(att[k])
	var nd := n_unita(id, fd)
	var ra: Array = []
	var rd: Array = []
	for i in dadi_a:
		ra.append(dado())
	for i in dadi_d:
		rd.append(dado())
	nota("Battaglia in %s: %s (%d Unità) tira %s; %s (%d Unità) tira %s." % [nome_sp(id), breve(fa), na, _dadi_txt(ra), breve(fd), nd, _dadi_txt(rd) if not rd.is_empty() else "nessun dado"])
	# Cavalleria: prima l'attaccante, poi il difensore. I Mongoli caricano sempre una volta.
	if fa == "M":
		_carica_mongola(ra, na)
	else:
		_usa_cavalleria(fa, ra, rd, na, id, nd)
		if ferma():
			return
	if fd == "M":
		_carica_mongola(rd, nd)
	else:
		_usa_cavalleria(fd, rd, ra, nd, id, na)
		if ferma():
			return
	var ca: int = min(na, 5)
	var cdf: int = min(nd, 5)
	var colpi_a := 0
	var colpi_d := 0
	for v in ra:
		if int(v) < 6 and int(v) <= ca:
			colpi_a += 1
	for v in rd:
		if int(v) < 6 and int(v) <= cdf:
			colpi_d += 1
	nota("Colpi: %s %d, %s %d." % [breve(fa), colpi_a, breve(fd), colpi_d])
	var persi_d := _perdite_difensore(fd, id, colpi_a)
	if ferma():
		return
	var persi_a := _perdite_attaccante(fa, att, colpi_d)
	if ferma():
		return
	if fa in ["B", "V"] and fd in ["B", "V"]:
		if persi_a < persi_d:
			cambia_infl(fa, 1)
			if ferma():
				return
			cambia_infl(fd, -1)
		elif persi_d < persi_a:
			cambia_infl(fd, 1)
			if ferma():
				return
			cambia_infl(fa, -1)
	s["tmp"]["ultima_battaglia"] = {"persi_a": persi_a, "persi_d": persi_d}


func _dadi_txt(a: Array) -> String:
	return "[" + ", ".join(a.map(func(x): return str(x))) + "]"


func _carica_mongola(dadi: Array, n: int) -> void:
	var c: int = min(n, 5)
	for i in dadi.size():
		if int(dadi[i]) == c + 1 and int(dadi[i]) - 1 >= 1:
			dadi[i] = int(dadi[i]) - 1
			nota("Carica mongola: un dado passa a %d." % int(dadi[i]))
			return
	for i in dadi.size():
		if int(dadi[i]) == 2:
			dadi[i] = 1
			nota("Carica mongola: un 2 diventa 1.")
			return


func _usa_cavalleria(f: String, miei: Array, suoi: Array, n: int, id: String, n_suoi: int = 0) -> void:
	var giro := 0
	while int(s["cav"][f]) > 0 and giro < 12:
		giro += 1
		var ops: Array = []
		var visti := {}
		for i in miei.size():
			var v := int(miei[i])
			if v > 1 and not visti.has("c%d" % v):
				visti["c%d" % v] = true
				ops.append(o("c%d" % i, "Carica: un tuo %d diventa %d" % [v, v - 1]))
		for i in suoi.size():
			var v := int(suoi[i])
			if v != 1 and not visti.has("s%d" % v):
				visti["s%d" % v] = true
				ops.append(o("s%d" % i, "Schermo: togli il dado avversario %d" % v))
		if ops.is_empty():
			return
		ops.append(o("fine", "Non usare (altra) Cavalleria"))
		var v = chiedi(f, "Battaglia in %s — i tuoi dadi %s, quelli avversari %s, colpisci con %d o meno. Cavalleria: %d." % [nome_sp(id), _dadi_txt(miei), _dadi_txt(suoi), min(n, 5), int(s["cav"][f])], ops, {"tag": "cavalleria", "miei": miei.duplicate(), "suoi": suoi.duplicate(), "cap_mio": min(n, 5), "cap_suo": min(n_suoi, 5), "usate": giro - 1})
		if ferma() or v == "fine":
			return
		var i := int(str(v).substr(1))
		spendi_cav(f)
		if str(v).begins_with("c"):
			miei[i] = int(miei[i]) - 1
			nota("%s usa la Cavalleria per caricare (dado a %d)." % [breve(f), int(miei[i])])
		else:
			nota("%s usa la Cavalleria come schermo (tolto un %d)." % [breve(f), int(suoi[i])])
			suoi.remove_at(i)


func _perdite_difensore(fd: String, id: String, n: int) -> int:
	var tolti := 0
	while tolti < n:
		var ops: Array = []
		for k in PEZZI_DI[fd]:
			if int(X(id)[k]) > 0:
				ops.append(o(k, "Togli 1 %s" % nome_pezzo_stato(k)))
		if ops.is_empty():
			break
		var k = chiedi(fd, "Perdite in %s: togli ancora %d pezzi" % [nome_sp(id), n - tolti], ops, {"tag": "perdite"})
		if ferma():
			return tolti
		rimuovi(id, k, 1)
		tolti += 1
	if tolti > 0:
		nota("%s perde %d pezz%s in %s." % [breve(fd), tolti, "o" if tolti == 1 else "i", nome_sp(id)])
	return tolti


func _perdite_attaccante(fa: String, att: Dictionary, n: int) -> int:
	var tolti := 0
	while tolti < n:
		var ops: Array = []
		for k in att:
			if int(att[k]) > 0:
				var p: Array = k.split(":")
				if int(X(p[0])[p[1]]) > 0:
					ops.append(o(k, "Togli 1 %s da %s" % [nome_pezzo_stato(p[1]), nome_sp(p[0])]))
		if ops.is_empty():
			break
		var k = chiedi(fa, "Perdite dell'attacco: togli ancora %d Unità" % (n - tolti), ops, {"tag": "perdite"})
		if ferma():
			return tolti
		var p2: Array = k.split(":")
		rimuovi(p2[0], p2[1], 1)
		att[k] = int(att[k]) - 1
		tolti += 1
	if tolti > 0:
		nota("%s perde %d Unità nell'attacco." % [breve(fa), tolti])
	return tolti


# ================================================================ DECRETI

func decreto(f: String, opz: Dictionary) -> void:
	var ops: Array = []
	for d in DECRETI[f]:
		if opz.has("solo") and not d in opz["solo"]:
			continue
		if call("okd_" + d, f):
			ops.append(o(d, nome_cmd(d)))
	ops.append(o("nessuno", "Nessun Decreto"))
	var d = chiedi(f, "Quale Decreto?", ops, {"tag": "decreto"})
	if ferma() or d == null or d == "nessuno":
		return
	nota("%s: Decreto %s." % [breve(f), nome_cmd(d)])
	call("dec_" + d, f, opz)


func okd_tributo(_f: String) -> bool:
	return true


func dec_tributo(f: String, _opz: Dictionary) -> void:
	cambia_ris(f, tributo_totale() / 2)
	guadagna_cav(f, 2)


func okd_campagna(_f: String) -> bool:
	for id in ordine:
		if int(X(id)["t"]) + int(X(id)["g"]) > 0:
			return true
	return false


## Campagna: da un'unica origine fino a 3 spazi di distanza, lasciando o raccogliendo Unità lungo la strada.
## opz.solo_province: solo Delhi e Province; opz.fine_in: Callable che la destinazione finale deve soddisfare.
func dec_campagna(f: String, opz: Dictionary) -> void:
	var ammesso := func(id): return not opz.get("solo_province", false) or provincia(id) or id == "delhi"
	var origine = scegli_spazio(f, "Campagna: spazio di partenza", func(id): return ammesso.call(id) and int(X(id)["t"]) + int(X(id)["g"]) > 0, true, "camp_da", "Rinuncia")
	if ferma() or origine == null:
		return
	var porto := {"t": 0, "g": 0}
	for k in ["t", "g"]:
		var n := numero(f, "Campagna: quanti %s partono da %s?" % [nome_pezzo(k, 2), nome_sp(origine)], 0, int(X(origine)[k]), "camp_n", {"da": origine, "k": k})
		if ferma():
			return
		X(origine)[k] = int(X(origine)[k]) - n
		porto[k] = n
	_dopo(origine)
	var qui: String = origine
	for passo in 3:
		var fine_ok: bool = not opz.has("fine_in") or (opz["fine_in"] as Callable).call(qui)
		var ops := func(id): return adiacente(qui, id) and ammesso.call(id) and id != origine
		s["tmp"]["camp_qui"] = qui
		var nx = scegli_spazio(f, "Campagna: passo %d di 3 (ora in %s con %d Truppe e %d Governatori)" % [passo + 1, nome_sp(qui), porto["t"], porto["g"]], ops, fine_ok and passo > 0, "camp_passo", "Fermati qui")
		if ferma():
			return
		if nx == null:
			break
		qui = nx
		if passo < 2:
			for k in ["t", "g"]:
				if porto[k] > 0 and si_no(f, "Lasci %s in %s?" % [nome_pezzo(k, 2), nome_sp(qui)], "camp_lascia"):
					var n := numero(f, "Quanti %s lasci in %s?" % [nome_pezzo(k, 2), nome_sp(qui)], 1, porto[k], "camp_n")
					if ferma():
						return
					X(qui)[k] = int(X(qui)[k]) + n
					porto[k] -= n
				if ferma():
					return
				if int(X(qui)[k]) > 0 and si_no(f, "Raccogli %s in %s?" % [nome_pezzo(k, 2), nome_sp(qui)], "camp_prendi"):
					var n := numero(f, "Quanti %s raccogli in %s?" % [nome_pezzo(k, 2), nome_sp(qui)], 1, int(X(qui)[k]), "camp_n")
					if ferma():
						return
					X(qui)[k] = int(X(qui)[k]) - n
					porto[k] += n
				if ferma():
					return
			_dopo(qui)
	for k in ["t", "g"]:
		X(qui)[k] = int(X(qui)[k]) + porto[k]
	_dopo(qui)
	s["tmp"]["campagna_fine"] = qui
	nota("Campagna: da %s a %s." % [nome_sp(origine), nome_sp(qui)])


func okd_obbedienza(_f: String) -> bool:
	return not _obbedienza_spazi().is_empty()


func _obbedienza_spazi() -> Array:
	var r: Array = []
	for id in ordine:
		if provincia(id) and not X(id)["trib"] and X(id)["ctrl"] == "D" and int(X(id)["g"]) > 0:
			r.append(id)
	return r


func dec_obbedienza(f: String, opz: Dictionary) -> void:
	var fatte: Array = []
	while true:
		var c := _obbedienza_spazi()
		if opz.has("solo_in"):
			c = c.filter(func(x): return x in opz["solo_in"])
		c = c.filter(func(x): return not x in fatte)
		if c.is_empty():
			break
		var id = scegli_spazio(f, "Esigi obbedienza: scegli una Provincia", func(x): return x in c, true, "obb", "Basta così")
		if ferma() or id == null:
			break
		metti_tributo(id)
		cambia_ris("D", prosp(id))
		fatte.append(id)


func okd_commercio(_f: String) -> bool:
	return true


func dec_commercio(f: String, _opz: Dictionary) -> void:
	var n := 0
	for id in ordine:
		if provincia(id) and n_pezzi(id, "B") > 0:
			n += 1
	cambia_ris(f, n)
	var i := int(s["infl"]["B"])
	guadagna_cav(f, 1 if i == 0 else (2 if i <= 2 else 3))


func okd_tassa(_f: String) -> bool:
	return true


func dec_tassa(f: String, _opz: Dictionary) -> void:
	var n := strutture_mappa("tp")
	for id in ordine:
		if provincia(id) and X(id)["ctrl"] == "V":
			n += prosp(id)
	cambia_ris(f, n)


func okd_costruisci(f: String) -> bool:
	var k := "f" if f == "B" else "tp"
	if disp(k) <= 0:
		return false
	for id in ordine:
		if _ok_costruisci(f, id):
			return true
	return false


func _ok_costruisci(f: String, id: String) -> bool:
	var k := "f" if f == "B" else "tp"
	return provincia(id) and int(X(id)[k]) == 0 and (amiri(id) if f == "B" else raja(id)) > 0


func dec_costruisci(f: String, opz: Dictionary) -> void:
	var k := "f" if f == "B" else "tp"
	var filtro: Callable = opz.get("filtro", func(_x): return true)
	var id = scegli_spazio(f, "Costruisci un %s: dove?" % nome_pezzo(k), func(x): return _ok_costruisci(f, x) and filtro.call(x), true, "costruisci", "Rinuncia")
	if ferma() or id == null:
		return
	piazza(id, k, 1)
	nota("Un %s in %s." % [nome_pezzo(k), nome_sp(id)])


func okd_cospira(f: String) -> bool:
	return not _cospira_spazi(f).is_empty() and disp("a") > 0


func _cospira_spazi(_f: String) -> Array:
	var forte := int(s["infl"]["B"]) >= 2
	var r: Array = []
	for id in ordine:
		if not provincia(id):
			continue
		var bersagli := int(X(id)["g"]) + (raja(id) if forte else 0)
		if bersagli <= 0:
			continue
		var ok := n_pezzi(id, "B") > 0
		if forte and not ok:
			for a in adiacenti(id):
				if provincia(a) and n_pezzi(a, "B") > 0:
					ok = true
		if ok:
			r.append(id)
	return r


func dec_cospira(f: String, _opz: Dictionary) -> void:
	var fatte: Array = []
	for i in 2:
		var c := _cospira_spazi(f).filter(func(x): return not x in fatte)
		if c.is_empty() or disp("a") <= 0:
			break
		var id = scegli_spazio(f, "Cospira (%d di 2): in quale Provincia sostituisci un pezzo con un Emiro?" % (i + 1), func(x): return x in c, i > 0, "cospira", "Basta così")
		if ferma() or id == null:
			break
		var ops: Array = []
		if int(X(id)["g"]) > 0:
			ops.append(o("g", "Un Governatore"))
		if int(s["infl"]["B"]) >= 2:
			if int(X(id)["ro"]) > 0:
				ops.append(o("ro", "Un Raja obbediente"))
			if int(X(id)["rr"]) > 0:
				ops.append(o("rr", "Un Raja ribelle"))
		var k = chiedi(f, "Quale pezzo sostituisci in %s?" % nome_sp(id), ops, {"tag": "cospira_k"})
		if ferma():
			return
		var rib := k == "rr"
		if not rib:
			rib = chiedi(f, "Il nuovo Emiro è…", [o("rib", "Ribelle"), o("obb", "Obbediente")], {"tag": "orient"}) == "rib"
			if ferma():
				return
		rimuovi(id, k, 1)
		piazza(id, "a", 1, rib)
		fatte.append(id)
		nota("Cospira: in %s un %s diventa un Emiro." % [nome_sp(id), nome_pezzo(k)])


func okd_costringi(f: String) -> bool:
	return not _costringi_spazi(f).is_empty()


func _costringi_spazi(f: String) -> Array:
	var r: Array = []
	for id in ordine:
		if not provincia(id):
			continue
		var ok := n_pezzi(id, f) > 0
		var porta := false
		for a in adiacenti(id):
			if provincia(a) and n_pezzi(a, f) > 0:
				ok = true
			if provincia(a) and raja(a) > 0:
				porta = true
		if ok and (disp("r") > 0 or porta or int(s["infl"]["V"]) >= 2):
			r.append(id)
	return r


func dec_costringi(f: String, opz: Dictionary) -> void:
	var filtro: Callable = opz.get("filtro", func(_x): return true)
	var c := _costringi_spazi(f).filter(func(x): return filtro.call(x))
	var id = scegli_spazio(f, "Costringi: in quale Provincia?", func(x): return x in c, true, "costringi", "Rinuncia")
	if ferma() or id == null:
		return
	s["tmp"]["costringi_in"] = id
	var nuovi := 0
	var p := numero(f, "Costringi in %s: quanti Raja piazzi dal Disponibile?" % nome_sp(id), 0, min(2, disp("r")), "costr_n")
	if ferma():
		return
	if p > 0:
		piazza(id, "r", p)
		nuovi += p
	if p < 2:
		var da_ok := func(a): return provincia(a) and adiacente(id, a) and raja(a) > 0
		var da = scegli_spazio(f, "Costringi: da quale Provincia adiacente porti Raja in %s?" % nome_sp(id), da_ok, true, "costr_da", "Nessuna")
		if ferma():
			return
		if da != null:
			var n := numero(f, "Quanti Raja porti da %s?" % nome_sp(da), 1, min(2 - p, raja(da)), "costr_n")
			if ferma():
				return
			var nr: int = min(n, int(X(da)["rr"]))
			muovi(da, id, "rr", nr)
			muovi(da, id, "ro", n - nr)
			nuovi += n
	if int(s["infl"]["V"]) >= 2:
		guadagna_cav(f, 1)
		if ferma():
			return
		var ops: Array = []
		for k in ["t", "g", "ao", "ar"]:
			if int(X(id)[k]) > 0:
				ops.append(o(k, "Rimuovi 1 %s" % nome_pezzo_stato(k)))
		if not ops.is_empty():
			ops.append(o("no", "Nessuna rimozione"))
			var k = chiedi(f, "Costringi (influente): rimuovi un pezzo in %s?" % nome_sp(id), ops, {"tag": "costr_rim"})
			if ferma():
				return
			if k != "no":
				rimuovi(id, k, 1)
				nota("Costringi: rimosso 1 %s in %s." % [nome_pezzo_stato(k), nome_sp(id)])
				if k in ["t", "g"] and nuovi > 0:
					X(id)["rr"] = int(X(id)["rr"]) + min(nuovi, int(X(id)["ro"]))
					X(id)["ro"] = max(0, int(X(id)["ro"]) - nuovi)
	nota("Costringi in %s: %d Raja." % [nome_sp(id), nuovi])


# ================================================================ INVASIONI MONGOLE

func atto_mongola(a: Dictionary) -> void:
	var f: String = a["f"]
	s["tmp"] = {}
	for i in 2:
		var ops: Array = []
		if disp("m") > 0:
			ops.append(o("ammassa", "Ammassa: 3 Invasori nei Passi montani"))
		if int(X("passi")["m"]) + int(X("punjab")["m"]) > 0:
			ops.append(o("avanza", "Avanza verso Delhi"))
		for id in ["passi", "punjab", "delhi"]:
			if int(X(id)["m"]) > 0:
				ops.append(o("sac_" + id, "Attacca e saccheggia: " + nome_sp(id)))
		if ops.is_empty():
			break
		var c = chiedi(f, "Assistenza strategica: Comando mongolo %d di 2" % (i + 1), ops, {"tag": "mongolo", "mostra": true})
		if ferma():
			return
		if c == "ammassa":
			_ammassa()
		elif c == "avanza":
			_avanza_mongoli(f)
		else:
			_saccheggio(f, str(c).substr(4), true, true, true)
		if ferma():
			return
	var ik := int(s["infl"][f])
	if ik >= 1 and si_no(f, "Doni compromettenti: −1 Influenza per +2 Risorse e +2 Cavallerie?", "doni"):
		cambia_infl(f, -1)
		if ferma():
			return
		cambia_ris(f, 2)
		guadagna_cav(f, 2)


func _ammassa() -> void:
	var n: int = min(3, disp("m"))
	s["disp"]["m"] = disp("m") - n
	X("passi")["m"] = int(X("passi")["m"]) + n
	var p: int = max(0, int(X("passi")["m"]) - 4)
	X("passi")["m"] = int(X("passi")["m"]) - p
	X("punjab")["m"] = int(X("punjab")["m"]) + p
	var q: int = max(0, int(X("punjab")["m"]) - 4)
	X("punjab")["m"] = int(X("punjab")["m"]) - q
	X("delhi")["m"] = int(X("delhi")["m"]) + q
	nota("I Mongoli si ammassano: %d nei Passi montani%s%s." % [n, (", %d scendono nel Punjab" % p) if p > 0 else "", (", %d arrivano a Delhi" % q) if q > 0 else ""])


func _avanza_mongoli(f: String) -> void:
	var ops: Array = []
	if int(X("passi")["m"]) > 0:
		ops.append(o("passi", "Dai Passi montani al Punjab"))
	if int(X("punjab")["m"]) > 0:
		ops.append(o("punjab", "Dal Punjab a Delhi"))
	var da = chiedi(f, "Avanza: da dove?", ops, {"tag": "avanza"})
	if ferma():
		return
	var a := "punjab" if da == "passi" else "delhi"
	var n := numero(f, "Quanti Invasori avanzano?", 1, int(X(da)["m"]), "n_avanza")
	if ferma():
		return
	X(da)["m"] = int(X(da)["m"]) - n
	X(a)["m"] = int(X(a)["m"]) + n
	nota("%s avanzano da %s a %s." % [pz(n, "m"), nome_sp(da), nome_sp(a)])


## Attacco mongolo in id; conseguenze di Risorse e Province opzionali (Timur ne ignora alcune).
func _saccheggio(_f: String, id: String, con_ris: bool, con_prov: bool, eccesso: bool) -> void:
	var nm := int(X(id)["m"])
	if nm > 0 and n_pezzi(id, "D") > 0:
		battaglia("M", "D", id, {id + ":m": nm}, 3 if id == "delhi" else 4, 2)
		if ferma():
			return
	var resto := int(X(id)["m"])
	if con_ris and resto > 0:
		cambia_ris("D", -resto, 3)
	if con_prov and resto > 0 and id != "passi":
		var n := resto * (2 if id == "delhi" else 1)
		for i in n:
			var c := func(x): return provincia(x) and int(X(x)["t"]) > 0
			var dove = scegli_spazio("D", "Saccheggio: togli una Truppa da una Provincia (%d di %d)" % [i + 1, n], c, false, "sacc_truppa")
			if ferma():
				return
			if dove == null:
				break
			rimuovi(dove, "t", 1)
		nota("Saccheggio in %s: il Sultanato perde fino a %s nelle Province." % [nome_sp(id), pz(n, "t")])
	if eccesso and resto > 3:
		X(id)["m"] = 3
		s["disp"]["m"] = disp("m") + resto - 3
		nota("%d Invasori tornano oltre le montagne." % (resto - 3))


# ================================================================ TIMUR

func atto_timur(_a: Dictionary) -> void:
	s["tmp"] = {}
	_saccheggio("V", "passi", false, true, false)
	if ferma():
		return
	_trasferisci("passi", "punjab")
	_saccheggio("V", "punjab", false, false, false)
	if ferma():
		return
	_trasferisci("punjab", "delhi")
	var giri := 0
	while int(X("delhi")["m"]) > 0 and n_pezzi("delhi", "D") > 0 and giri < 30:
		giri += 1
		_saccheggio("V", "delhi", true, false, false)
		if ferma():
			return
	nota("Timur lascia Delhi con %s in città." % pz(int(X("delhi")["m"]), "m"))


func _trasferisci(da: String, a: String) -> void:
	for k in ["t", "g", "m"]:
		X(a)[k] = int(X(a)[k]) + int(X(da)[k])
		X(da)[k] = 0


# ================================================================ SUCCESSIONI

func succ_atti(c: String) -> Array:
	match c:
		"S1":
			return [{"t": "succ", "c": "S1", "f": "D"}]
		"S2":
			return [{"t": "succ", "c": "S2a", "f": "D"}, {"t": "succ", "c": "S2b", "f": "B"}, {"t": "succ", "c": "S2b", "f": "V"}]
		"S3":
			return [{"t": "succ", "c": "S3", "f": "D"}, {"t": "succ", "c": "S3", "f": "B"}, {"t": "succ", "c": "S3", "f": "V"}]
	return []


func atto_succ(a: Dictionary) -> void:
	var f: String = a["f"]
	s["tmp"] = {}
	match a["c"]:
		"S1":
			if s["dinastia"] != "tughlaq":
				s["dinastia"] = "tughlaq"
				nota("Inizia la Dinastia Tughlaq: la Ribellione è ora possibile.")
			if si_no("D", "Il Sultanato reimpone il suo dominio: fai una Campagna (solo Delhi e Province)?", "succ_camp"):
				dec_campagna("D", {"solo_province": true})
				if ferma():
					return
			guadagna_cav("B", int(s["infl"]["B"]) + strutture_mappa("f"))
			if ferma():
				return
			cambia_ris("V", int(s["infl"]["V"]) + strutture_mappa("tp"))
		"S2a":
			if si_no("D", "Delhi sorveglia i suoi interessi: fai una Campagna (solo Delhi e Province)?", "succ_camp"):
				dec_campagna("D", {"solo_province": true})
		"S2b":
			comando(f, {"limitata": true, "gratis": true, "mostra": true})
			if ferma():
				return
			var n := 0
			for id in ordine:
				if provincia(id) and X(id)["ctrl"] == f:
					n += prosp(id)
			n = min(n, 3)
			if n > 0:
				var c := numero(f, "Guadagni %d fra Risorse e Cavalleria: quante Cavallerie?" % n, 0, n, "succ_cav")
				if ferma():
					return
				cambia_ris(f, n - c)
				guadagna_cav(f, c)
		"S3":
			for i in 3:
				if int(s["ris"][f]) < 3:
					break
				var ops: Array = []
				for g in ["B", "V"]:
					if int(s["infl"][g]) < 4:
						ops.append(o(g + "+", "Influenza %s +1" % breve(g)))
					if int(s["infl"][g]) > 0:
						ops.append(o(g + "-", "Influenza %s −1" % breve(g)))
				ops.append(o("no", "Basta così"))
				var v = chiedi(f, "Spendi 3 Risorse per spostare un'Influenza (%d di 3)?" % (i + 1), ops, {"tag": "succ_infl"})
				if ferma() or v == "no":
					break
				cambia_ris(f, -3)
				cambia_infl(str(v)[0], 1 if str(v)[1] == "+" else -1)
				if ferma():
					return


# Ridefinita in Eventi.
func evento(_f: String, _cd: Dictionary) -> void:
	pass
