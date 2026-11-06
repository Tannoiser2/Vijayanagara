## Nucleo del motore: stato della partita, domande/risposte deterministiche, pezzi, sequenza di gioco.
##
## Ogni decisione è una "domanda" (chiedi). Un "atto" (il turno di una fazione su una carta, un'Invasione
## mongola, un passo di una Successione) è una procedura che pone domande: si riesegue da capo sullo stato di
## partenza con le risposte date finora, finché non ne serve una nuova (need) o l'atto finisce.
## La partita è sempre ricostruibile da seme + risposte: salvataggi, gioco online e IA usano la stessa via.
class_name Nucleo
extends RefCounted

const FAZ := ["D", "B", "V"]
const NOMI_FAZ := {"D": "Sultanato di Delhi", "B": "Regno Bahmani", "V": "Impero di Vijayanagara", "M": "Invasori mongoli"}
const BREVI := {"D": "Sultanato", "B": "Bahmani", "V": "Vijayanagara", "M": "Mongoli"}
## pezzi: chiave -> [fazione, unità?]
const PEZZI := {"t": ["D", true], "g": ["D", true], "q": ["D", false], "ao": ["B", true], "ar": ["B", true], "f": ["B", false],
	"ro": ["V", true], "rr": ["V", true], "tp": ["V", false], "m": ["M", true]}
const UNITA_DI := {"D": ["t", "g"], "B": ["ao", "ar"], "V": ["ro", "rr"], "M": ["m"]}
const PEZZI_DI := {"D": ["t", "g", "q"], "B": ["ao", "ar", "f"], "V": ["ro", "rr", "tp"], "M": ["m"]}
const STRUTTURA_DI := {"D": "q", "B": "f", "V": "tp"}
const RIS_MAX := 24
const CAV_TOT := 10

static var _dati_cache: Dictionary = {}

var s: Dictionary = {}
var D: Dictionary = {}
var SP: Dictionary = {}
var ordine: Array = []
var CITTA: Dictionary = {}

var _ans: Array = []
var _i := 0
var need = null
var registro: Array = []
var autorisposta: Callable


# ---------------------------------------------------------------- dati

static func carica_dati() -> Dictionary:
	if not _dati_cache.is_empty():
		return _dati_cache
	var d: Dictionary = {}
	for parte in ["mappa", "carte"]:
		var f = FileAccess.open("res://dati/%s.json" % parte, FileAccess.READ)
		if f:
			var x = JSON.parse_string(f.get_as_text())
			if x is Dictionary:
				d.merge(x)
	_dati_cache = d
	return d


func usa_dati() -> void:
	D = carica_dati()
	SP.clear()
	ordine.clear()
	for sp in D.get("spazi", []):
		SP[sp["id"]] = sp
		ordine.append(sp["id"])
	CITTA = D.get("citta", {})


# ---------------------------------------------------------------- nomi

func nome_faz(f: String) -> String:
	return NOMI_FAZ.get(f, f)


func breve(f: String) -> String:
	return BREVI.get(f, f)


func nome_pezzo(k: String, n: int = 1) -> String:
	var u := n == 1
	match k:
		"t": return "Truppa" if u else "Truppe"
		"g": return "Governatore" if u else "Governatori"
		"q": return "Qasbah"
		"a", "ao", "ar": return "Emiro" if u else "Emiri"
		"f": return "Forte" if u else "Forti"
		"r", "ro", "rr": return "Raja"
		"tp": return "Tempio" if u else "Templi"
		"m": return "Invasore mongolo" if u else "Invasori mongoli"
	return k


func nome_pezzo_stato(k: String, n: int = 1) -> String:
	var b := nome_pezzo(k, n)
	if k in ["ao", "ro"]:
		return b + (" obbediente" if n == 1 else " obbedienti")
	if k in ["ar", "rr"]:
		return b + (" ribelle" if n == 1 else " ribelli")
	return b


func pz(n: int, k: String) -> String:
	return "%d %s" % [n, nome_pezzo(k, n)]


func nome_sp(id: String) -> String:
	return SP[id]["nome"] if SP.has(id) else id


func nota(t: String) -> void:
	registro.append(t)


# ---------------------------------------------------------------- nuova partita

func nuova(seme: int, opzioni: Dictionary = {}) -> void:
	usa_dati()
	s = {"seme": seme, "rs": seme % 2147483647 + 1, "opz": opzioni, "atto_n": 0}
	var st: Dictionary = D["setup"]
	s["sp"] = {}
	for id in ordine:
		var x := {"t": 0, "g": 0, "q": 0, "ao": 0, "ar": 0, "f": 0, "ro": 0, "rr": 0, "tp": 0, "m": 0, "trib": false, "ctrl": ""}
		if tipo(id) == "prov":
			x["trib"] = true
		var su: Dictionary = st["spazi"].get(id, {})
		for k in su:
			var kk = {"a": "ao", "r": "ro"}.get(k, k)
			x[kk] = int(su[k])
		s["sp"][id] = x
	s["disp"] = {}
	for k in st["disp"]:
		s["disp"][k] = int(st["disp"][k])
	s["ris"] = {"D": int(st["ris"]["D"]), "B": int(st["ris"]["B"]), "V": int(st["ris"]["V"])}
	s["cav"] = {"D": int(st["cav"]["D"]), "B": 0, "V": 0}
	s["infl"] = {"B": 0, "V": 0}
	s["slot"] = {"B": {}, "V": {}}
	for f in ["B", "V"]:
		for lv in st["slot"][f]:
			s["slot"][f][lv] = int(st["slot"][f][lv])
	s["dinastia"] = "khalji"
	s["elig"] = {"D": true, "B": true, "V": true}
	s["scelte"] = {}
	s["resta"] = []
	s["riserva"] = {}
	s["fuori"] = []
	s["tmp"] = {}
	s["carta"] = ""
	s["giocate"] = []
	s["fine"] = {}
	s["coda"] = []
	s["timur"] = 0
	s["mazzo"] = _costruisci_mazzo()
	for id in ordine:
		_aggiorna_controllo(id)
	_pesca_carta()


func _rand(n: int) -> int:
	s["rs"] = (int(s["rs"]) * 48271) % 2147483647
	return int(s["rs"]) % n


func dado() -> int:
	return 1 + _rand(6)


func _mescola(a: Array) -> Array:
	var b := a.duplicate()
	for i in range(b.size() - 1, 0, -1):
		var j := _rand(i + 1)
		var t = b[i]
		b[i] = b[j]
		b[j] = t
	return b


## 2.1: 24 Eventi in quattro pile di 6; due Invasioni nelle prime tre, i Timuridi nella quarta;
## le Successioni fra una pila e l'altra.
func _costruisci_mazzo() -> Array:
	var ev: Array = []
	for c in D["carte"]:
		ev.append(c["id"])
	ev = _mescola(ev)
	var inv: Array = []
	for c in D["invasioni"]:
		inv.append(c["id"])
	inv = _mescola(inv)
	s["fuori"] = ev.slice(24)
	var pile: Array = []
	for i in 4:
		var p: Array = ev.slice(i * 6, i * 6 + 6)
		if i < 3:
			p += inv.slice(i * 2, i * 2 + 2)
		else:
			p += ["T1", "T2"]
		pile.append(_mescola(p))
	return pile[0] + ["S1"] + pile[1] + ["S2"] + pile[2] + ["S3"] + pile[3]


func carta_dati(id: String) -> Dictionary:
	for k in ["carte", "invasioni", "speciali"]:
		for c in D.get(k, []):
			if c["id"] == id:
				return c
	return {}


func tipo_carta(id: String) -> String:
	if id.begins_with("E"):
		return "evento"
	if id.begins_with("M"):
		return "mongola"
	if id.begins_with("S"):
		return "successione"
	if id.begins_with("T"):
		return "timuride"
	return ""


# ---------------------------------------------------------------- domande

func chiedi(f: String, testo: String, opzioni: Array, extra: Dictionary = {}):
	if need != null:
		return null
	if opzioni.is_empty():
		return null
	if opzioni.size() == 1 and extra.get("auto", true) and not extra.get("mostra", false):
		return opzioni[0]["v"]
	if _i < _ans.size():
		var v = _ans[_i]
		if v is float and v == floor(v):
			v = int(v)
		_i += 1
		for o in opzioni:
			if str(o["v"]) == str(v):
				return o["v"]
		if not autorisposta.is_valid():
			push_warning("risposta non valida: %s per %s" % [str(v), testo])
		_ans.resize(_i - 1)
		_i -= 1
	var q := {"f": f, "testo": testo, "opz": opzioni, "x": extra}
	if autorisposta.is_valid():
		var w = autorisposta.call(self, q)
		_ans.append(w)
		_i += 1
		return w
	need = q
	return null


func ferma() -> bool:
	return need != null


func o(v, t: String) -> Dictionary:
	return {"v": v, "t": t}


func si_no(f: String, testo: String, tag: String = "") -> bool:
	var v = chiedi(f, testo, [o("si", "Sì"), o("no", "No")], {"tag": tag})
	return v == "si"


func numero(f: String, testo: String, minn: int, maxn: int, tag: String = "") -> int:
	if maxn <= minn:
		return max(maxn, 0)
	var ops: Array = []
	for i in range(minn, maxn + 1):
		ops.append(o(i, str(i)))
	var v = chiedi(f, testo, ops, {"tag": tag, "num": true})
	return 0 if v == null else int(v)


func scegli_spazio(f: String, testo: String, filtro: Callable, facoltativo: bool = false, tag: String = "", testo_fine: String = "Fine"):
	var ops: Array = []
	for id in ordine:
		if filtro.call(id):
			ops.append(o(id, nome_sp(id)))
	if ops.is_empty():
		return null
	if facoltativo:
		ops.append(o("fine", testo_fine))
	var v = chiedi(f, testo, ops, {"tag": tag, "spazi": true})
	if v == null or v == "fine":
		return null
	return v


# ---------------------------------------------------------------- pezzi

func X(id: String) -> Dictionary:
	return s["sp"][id]


func tipo(id: String) -> String:
	return SP[id]["tipo"]


func provincia(id: String) -> bool:
	return tipo(id) == "prov"


func prosp(id: String) -> int:
	return int(SP[id].get("prosp", 0))


func adiacenti(id: String) -> Array:
	return SP[id]["adj"]


func adiacente(a: String, b: String) -> bool:
	return b in SP[a]["adj"]


func vicini_citta(c: String) -> Array:
	return CITTA.get(c, [])


func disp(k: String) -> int:
	return int(s["disp"].get(k, 0))


static func faz_pezzo(k: String) -> String:
	return PEZZI[k][0]


func n_pezzi(id: String, f: String) -> int:
	var t := 0
	for k in PEZZI_DI[f]:
		t += int(X(id)[k])
	return t


func n_unita(id: String, f: String) -> int:
	var t := 0
	for k in UNITA_DI[f]:
		t += int(X(id)[k])
	return t


func amiri(id: String) -> int:
	return int(X(id)["ao"]) + int(X(id)["ar"])


func raja(id: String) -> int:
	return int(X(id)["ro"]) + int(X(id)["rr"])


func ribelli(id: String, f: String) -> int:
	match f:
		"B": return int(X(id)["ar"])
		"V": return int(X(id)["rr"])
		"M": return int(X(id)["m"])
	return 0


func avversari(f: String) -> Array:
	var r: Array = []
	for g in FAZ:
		if g != f:
			r.append(g)
	return r


func altra_bv(f: String) -> String:
	return "V" if f == "B" else "B"


## Chi può stare in uno spazio: B e V solo nelle Province, i Mongoli solo fuori dalle Province.
func puo_stare(id: String, f: String) -> bool:
	if f in ["B", "V"]:
		return provincia(id)
	if f == "M":
		return not provincia(id)
	return true


## Chiave del Disponibile per un pezzo.
static func chiave_disp(k: String) -> String:
	match k:
		"ao", "ar": return "a"
		"ro", "rr": return "r"
	return k


## Piazza n pezzi dal Disponibile. k: t g q a r f tp m (Emiri/Raja obbedienti, ribelli se la Provincia è controllata
## dalla loro fazione; con ribelle=true sempre ribelli). Restituisce quanti ne ha piazzati.
func piazza(id: String, k: String, n: int, ribelle: bool = false) -> int:
	var f := ""
	match k:
		"a": f = "B"
		"r": f = "V"
		_: f = faz_pezzo(k)
	if not puo_stare(id, f):
		return 0
	var fatti := 0
	for i in n:
		var dk := chiave_disp(k)
		if disp(dk) <= 0:
			break
		if k in ["q", "f", "tp"] and int(X(id)[k]) >= 1:
			break
		s["disp"][dk] = disp(dk) - 1
		var kk := k
		if k == "a":
			kk = "ar" if ribelle or X(id)["ctrl"] == "B" else "ao"
		elif k == "r":
			kk = "rr" if ribelle or X(id)["ctrl"] == "V" else "ro"
		X(id)[kk] = int(X(id)[kk]) + 1
		fatti += 1
	if fatti > 0:
		_dopo(id)
	return fatti


func rimuovi(id: String, k: String, n: int) -> int:
	var fatti: int = min(n, int(X(id)[k]))
	if fatti <= 0:
		return 0
	X(id)[k] = int(X(id)[k]) - fatti
	var dk := chiave_disp(k)
	s["disp"][dk] = disp(dk) + fatti
	_dopo(id)
	return fatti


## Sposta n pezzi; Emiri e Raja: obbedienti se entrano in una Tributaria, ribelli in una Provincia della loro fazione.
func muovi(da: String, a: String, k: String, n: int) -> int:
	var m: int = min(n, int(X(da)[k]))
	if m <= 0:
		return 0
	X(da)[k] = int(X(da)[k]) - m
	var kk := k
	if k in ["ao", "ar"]:
		if X(a)["trib"]:
			kk = "ao"
		elif X(a)["ctrl"] == "B":
			kk = "ar"
	elif k in ["ro", "rr"]:
		if X(a)["trib"]:
			kk = "ro"
		elif X(a)["ctrl"] == "V":
			kk = "rr"
	X(a)[kk] = int(X(a)[kk]) + m
	_dopo(da)
	_dopo(a)
	return m


func rendi_ribelli(id: String, f: String) -> void:
	var x := X(id)
	if f == "B":
		x["ar"] = int(x["ar"]) + int(x["ao"])
		x["ao"] = 0
	elif f == "V":
		x["rr"] = int(x["rr"]) + int(x["ro"])
		x["ro"] = 0


func rendi_obbedienti(id: String) -> void:
	var x := X(id)
	x["ao"] = int(x["ao"]) + int(x["ar"])
	x["ar"] = 0
	x["ro"] = int(x["ro"]) + int(x["rr"])
	x["rr"] = 0


func metti_tributo(id: String) -> void:
	if not provincia(id) or X(id)["trib"]:
		return
	X(id)["trib"] = true
	rendi_obbedienti(id)
	nota("%s torna Tributaria." % nome_sp(id))
	_dopo(id)


func togli_tributo(id: String) -> void:
	if not provincia(id) or not X(id)["trib"]:
		return
	X(id)["trib"] = false
	nota("%s diventa Indipendente." % nome_sp(id))
	_dopo(id)


func _dopo(id: String) -> void:
	_aggiorna_controllo(id)


func _aggiorna_controllo(id: String) -> void:
	if not provincia(id):
		return
	var x := X(id)
	var nuovo := ""
	if not x["trib"]:
		var tot := 0
		var n := {}
		for f in FAZ:
			n[f] = n_pezzi(id, f)
			tot += int(n[f])
		for f in FAZ:
			if int(n[f]) * 2 > tot:
				nuovo = f
	if nuovo in ["B", "V"]:
		rendi_ribelli(id, nuovo)
	if nuovo != x["ctrl"]:
		x["ctrl"] = nuovo
		if nuovo != "":
			nota("%s: Controllo %s." % [nome_sp(id), breve(nuovo)])


# ---------------------------------------------------------------- risorse, cavalleria, influenza

func cambia_ris(f: String, d: int, minimo: int = 0) -> void:
	var v0 := int(s["ris"][f])
	var v: int = clamp(v0 + d, 0, RIS_MAX)
	if d < 0 and v0 >= minimo:
		v = max(v, minimo)
	elif d < 0 and v0 < minimo:
		v = v0
	if v != v0:
		s["ris"][f] = v
		nota("Risorse %s %s%d: ora %d" % [breve(f), "+" if v > v0 else "", v - v0, v])


func cav_pool() -> int:
	return CAV_TOT - int(s["cav"]["D"]) - int(s["cav"]["B"]) - int(s["cav"]["V"])


## Guadagna n Cavallerie: dalla riserva comune, poi (se finita) da un'altra fazione a scelta.
func guadagna_cav(f: String, n: int) -> void:
	var presi := 0
	for i in n:
		if cav_pool() > 0:
			s["cav"][f] = int(s["cav"][f]) + 1
			presi += 1
			continue
		var da: Array = []
		for g in FAZ:
			if g != f and int(s["cav"][g]) > 0:
				da.append(o(g, breve(g) + " (%d)" % int(s["cav"][g])))
		if da.is_empty():
			break
		var g = chiedi(f, "La riserva di Cavalleria è vuota: a chi prendi un segnalino?", da, {"tag": "cav_da"})
		if ferma():
			return
		s["cav"][g] = int(s["cav"][g]) - 1
		s["cav"][f] = int(s["cav"][f]) + 1
		presi += 1
	if presi > 0:
		nota("%s guadagna %d Cavalleri%s (ora %d)." % [breve(f), presi, "a" if presi == 1 else "e", int(s["cav"][f])])


func spendi_cav(f: String, n: int = 1) -> void:
	s["cav"][f] = max(0, int(s["cav"][f]) - n)


## Sposta l'Influenza nel Deccan di f di d. Salendo libera le Unità sul tracciato; scendendo sotto una casella
## svuotata la riempie di nuovo con 2 Unità (dal Disponibile o dalla mappa).
func cambia_infl(f: String, d: int) -> void:
	if not f in ["B", "V"] or d == 0:
		return
	var v0 := int(s["infl"][f])
	var v: int = clamp(v0 + d, 0, 4)
	if v == v0:
		return
	s["infl"][f] = v
	nota("Influenza nel Deccan %s: da %d a %d" % [breve(f), v0, v])
	var k := "a" if f == "B" else "r"
	var sl: Dictionary = s["slot"][f]
	if v > v0:
		for lv in range(v0 + 1, v + 1):
			var key := str(lv)
			if int(sl.get(key, 0)) > 0:
				var n := int(sl[key])
				s["disp"][k] = disp(k) + n
				sl[key] = 0
				s["tmp"]["liberati_" + f] = int(s["tmp"].get("liberati_" + f, 0)) + n
				nota("%d %s lasciano il tracciato e diventano Disponibili." % [n, nome_pezzo(k, n)])
	else:
		for lv in range(v0, v, -1):
			var key := str(lv)
			if not D["setup"]["slot"][f].has(key) or int(sl.get(key, 0)) > 0:
				continue
			var serve := int(D["setup"]["slot"][f][key])
			var messi := 0
			while messi < serve and disp(k) > 0:
				s["disp"][k] = disp(k) - 1
				messi += 1
			while messi < serve:
				var cand := func(id): return (amiri(id) if f == "B" else raja(id)) > 0
				var id = scegli_spazio(f, "Influenza scesa: da quale Provincia riporti 1 %s sul tracciato?" % nome_pezzo(k), cand, false, "slot")
				if ferma():
					return
				if id == null:
					break
				var ks: Array = ["ao", "ar"] if f == "B" else ["ro", "rr"]
				for kk in ks:
					if int(X(id)[kk]) > 0:
						X(id)[kk] = int(X(id)[kk]) - 1
						_dopo(id)
						break
				messi += 1
			sl[key] = messi
			if messi > 0:
				nota("%d %s tornano sulla casella %s del tracciato dell'Influenza." % [messi, nome_pezzo(k, messi), key])


# ---------------------------------------------------------------- punti vittoria

func vp(f: String) -> int:
	var v := 0
	match f:
		"D":
			for id in ordine:
				if provincia(id) and X(id)["trib"]:
					v += prosp(id)
		"B", "V":
			var k := "f" if f == "B" else "tp"
			for id in ordine:
				if provincia(id):
					if X(id)["ctrl"] == f:
						v += prosp(id)
					v += int(X(id)[k])
			v += int(s["infl"][f])
	return v


func strutture_mappa(k: String) -> int:
	var t := 0
	for id in ordine:
		t += int(X(id)[k])
	return t


func tributo_totale() -> int:
	var t := 0
	for id in ordine:
		if provincia(id) and X(id)["trib"]:
			t += prosp(id)
	return t


# ---------------------------------------------------------------- fine partita

func fine_partita() -> void:
	var bonus: int = max(-3, 3 - int(X("delhi")["m"]))
	var punti := {"D": vp("D") + bonus, "B": vp("B"), "V": vp("V")}
	var migl := -999
	for f in FAZ:
		migl = max(migl, int(punti[f]))
	var primi: Array = []
	for f in FAZ:
		if int(punti[f]) == migl:
			primi.append(f)
	if primi.size() > 1:
		var mr := -1
		for f in primi:
			mr = max(mr, int(s["ris"][f]))
		var p2: Array = []
		for f in primi:
			if int(s["ris"][f]) == mr:
				p2.append(f)
		primi = p2
	var testo := "Punti vittoria: Sultanato %d (%+d per i Mongoli a Delhi), Bahmani %d, Vijayanagara %d." % [punti["D"], bonus, punti["B"], punti["V"]]
	s["fine"] = {"v": primi, "punti": punti, "bonus": bonus, "m": testo}
	s["coda"] = []
	nota("FINE PARTITA. " + testo)
	if primi.size() == 1:
		nota("Vince: %s." % nome_faz(primi[0]))
	else:
		nota("Parità fra: %s." % ", ".join(primi.map(func(x): return breve(x))))


func finita() -> bool:
	return not s["fine"].is_empty()


# ---------------------------------------------------------------- sequenza di gioco

func _pesca_carta() -> void:
	if finita():
		return
	if (s["mazzo"] as Array).is_empty():
		fine_partita()
		return
	var c: String = s["mazzo"].pop_front()
	s["carta"] = c
	s["giocate"].append(c)
	s["scelte"] = {}
	s["resta"] = []
	var cd := carta_dati(c)
	match tipo_carta(c):
		"evento":
			nota("— Carta %d: %s —" % [int(cd["n"]), cd["titolo"]])
			var q: Array = []
			for f in cd["ordine"]:
				if s["elig"][f]:
					q.append({"t": "turno", "f": f})
			s["coda"] = q
		"mongola":
			nota("— Invasione mongola: l'alleanza turca è offerta a %s —" % breve(cd["alleato"]))
			s["coda"] = [{"t": "mongola", "f": cd["alleato"]}]
		"successione":
			nota("— Successione: %s —" % cd["titolo"])
			s["coda"] = succ_atti(c)
		"timuride":
			s["timur"] = int(s["timur"]) + 1
			if int(s["timur"]) == 1:
				nota("— Impero timuride: crisi di successione a Delhi (1388) —")
				var n := disp("m") / 2
				if n > 0:
					s["disp"]["m"] = disp("m") - n
					X("passi")["m"] = int(X("passi")["m"]) + n
					nota("%s entrano nei Passi montani." % pz(n, "m"))
				s["coda"] = []
			else:
				nota("— Impero timuride: Timur invade Delhi (1398) —")
				s["coda"] = [{"t": "timur", "f": "D"}]


func atto_corrente() -> Dictionary:
	if finita() or (s["coda"] as Array).is_empty():
		return {}
	return s["coda"][0]


func esegui(risposte: Array) -> bool:
	_ans = risposte.duplicate()
	_i = 0
	need = null
	registro = []
	var a := atto_corrente()
	if a.is_empty():
		_avanza()
		return true
	_esegui_atto(a)
	if ferma():
		return false
	s["coda"].pop_front()
	s["atto_n"] = int(s["atto_n"]) + 1
	_avanza()
	return true


func _avanza() -> void:
	while not finita():
		if not (s["coda"] as Array).is_empty():
			var a: Dictionary = s["coda"][0]
			if a.get("auto", false):
				_esegui_atto(a)
				s["coda"].pop_front()
				continue
			return
		_fine_carta()


func _fine_carta() -> void:
	if tipo_carta(s["carta"]) == "evento":
		# 2.3.7: chi ha usato le caselle a forcella diventa non idoneo (salvo Evento «Resta idoneo»)
		for f in FAZ:
			s["elig"][f] = true
		for b in ["cd", "ec"]:
			if s["scelte"].has(b):
				var f: String = s["scelte"][b]
				if not f in s["resta"]:
					s["elig"][f] = false
	if tipo_carta(s["carta"]) == "timuride" and int(s["timur"]) >= 2:
		fine_partita()
		return
	_pesca_carta()


func _esegui_atto(a: Dictionary) -> void:
	if has_method("atto_" + a["t"]):
		call("atto_" + a["t"], a)


func accoda(lista: Array) -> void:
	var c: Array = s["coda"]
	for i in lista.size():
		c.insert(1 + i, lista[i])


func succ_atti(_c: String) -> Array:
	return []


# ---------------------------------------------------------------- utilità

func prova(base: Dictionary, risposte: Array) -> bool:
	s = base.duplicate(true)
	return esegui(risposte)


func risposte_usate() -> Array:
	return _ans.slice(0, _i)


func clona() -> Nucleo:
	var m = get_script().new()
	m.D = D
	m.SP = SP
	m.ordine = ordine
	m.CITTA = CITTA
	m.s = s.duplicate(true)
	return m
