## Bot ufficiali (regole Non-Player): carte azione, tabelle di selezione degli spazi, priorità dei pezzi e dei
## movimenti, Eventi «efficaci», Cavalleria, Successioni e carte delle Invasioni mongole.
##
## Il bot non ha uno stato nascosto: ogni risposta si ricava dallo stato all'inizio dell'atto, dalle risposte già
## date e da un generatore pseudocasuale che dipende solo dal seme della partita, dall'atto e dalla fazione.
## Così la partita resta ricostruibile da seme + risposte (salvataggi e gioco online).
class_name Bot
extends RefCounted

const CARTE := {"D": ["A", "AA", "B", "BB", "C", "CC", "D", "DD"], "B": ["E", "EE", "F", "FF", "G", "GG", "H", "HH"],
	"V": ["I", "JJ", "K", "KK", "L", "LL", "M", "MM"]}
const UNITA := {"D": ["t", "g"], "B": ["ao", "ar"], "V": ["ro", "rr"]}

## colonne delle tabelle di selezione degli spazi (righe in ordine di priorità)
const TAB := {
	"D": {
		"piazza_t": ["delhi", "qasbah", "punjab", "magg_giocatore", "provincia", "meno_avv1", "p2", "caso"],
		"marcia": ["delhi", "indip_gov", "punjab", "indip", "meno_avv1", "p2", "meno_avv", "piu_truppe", "caso"],
		"piazza_g": ["indip_gov", "provincia", "meno_avv1", "p2", "piu_truppe", "caso"],
		"attacca": ["delhi", "punjab", "indip", "passi", "magg_giocatore", "meno_avv1", "p2", "caso"],
		"campagna": ["delhi", "punjab", "indip", "passi", "magg_giocatore", "meno_avv1", "p2", "caso"],
		"rim_avv": ["indip", "magg_giocatore", "meno_avv1", "p2", "caso"],
		"rim_mio": ["p1", "non_cambia", "meno_avv", "piu_truppe", "caso"]},
	"B": {
		"piazza_u": ["p2", "trib_solo", "indip", "magg_giocatore", "nessuna_mia", "meno_avv", "caso"],
		"migra": ["trib_solo", "magg_giocatore", "meno_avv", "caso"],
		"ribellione": ["p2", "piu_mie", "con_gov", "caso"],
		"attacca": ["trib_solo", "piu_mie", "magg_giocatore", "meno_avv", "con_gov", "caso"],
		"piazza_s": ["p2", "piu_mie", "meno_avv", "caso"],
		"cospira": ["p2", "trib_solo", "indip", "nessuna_mia", "meno_avv", "caso"],
		"rim_avv": ["p2", "trib_solo", "indip", "piu_mie", "meno_avv", "caso"],
		"rim_mio": ["piu_mie", "meno_avv", "p1", "caso"]},
	"V": {
		"piazza_u": ["p2", "trib_solo", "tempio", "indip", "magg_giocatore", "nessuna_mia", "meno_avv", "caso"],
		"migra": ["trib_solo", "magg_giocatore", "meno_avv", "caso"],
		"ribellione": ["p2", "piu_mie", "gov_con_raja", "caso"],
		"attacca": ["trib_solo", "piu_mie", "gov_con_raja", "magg_giocatore", "meno_avv", "caso"],
		"piazza_s": ["p2", "piu_mie", "meno_avv", "caso"],
		"costringi": ["trib_solo", "gov_con_raja", "magg_giocatore", "nessuna_mia", "meno_avv", "caso"],
		"rim_avv": ["p2", "piu_mie", "meno_avv", "caso"],
		"rim_mio": ["piu_mie", "meno_avv", "p1", "caso"]},
}

## priorità dei pezzi (schede): da togliere, sostituire o spostare fra gli avversari, e fra i propri
const PRIO_AVV := ["q", "f", "tp", "g", "t", "ao", "ro", "m", "ar", "rr"]
const PRIO_MIEI := {"D": ["t", "g", "q"], "B": ["ao", "ar", "f"], "V": ["ro", "rr", "tp"]}
const CAV_MAX := {"D": 3, "B": 3, "V": 2}

static var _cache_piani: Dictionary = {}


# ================================================================ ingresso

## umani: fazioni guidate da persone (servono per le righe «Giocatore»). q: domanda in sospeso.
static func rispondi(base: Dictionary, ans: Array, q: Dictionary, m: Motore, umani: Array):
	var f: String = q["f"]
	var x: Dictionary = q.get("x", {})
	var tag: String = str(x.get("tag", ""))
	var ctx := Contesto.new(base, ans, q, m, umani)
	var v = _rispondi(ctx, f, tag)
	if v == null or not ctx.valida(v):
		v = ctx.ripiego()
	return v


static func piano_di(base: Dictionary, f: String, umani: Array) -> Dictionary:
	var chiave := "%d:%s:%s:%s:%s" % [int(base["seme"]), int(base["atto_n"]), f, str(base["carta"]), str(umani)]
	if _cache_piani.has(chiave):
		return _cache_piani[chiave]
	if _cache_piani.size() > 400:
		_cache_piani.clear()
	var p := _pianifica(base, f, umani)
	_cache_piani[chiave] = p
	return p


# ================================================================ contesto di una risposta

class Contesto:
	var base: Dictionary
	var ans: Array
	var q: Dictionary
	var m: Motore
	var umani: Array
	var opz: Array

	func _init(b: Dictionary, a: Array, qq: Dictionary, mm: Motore, u: Array) -> void:
		base = b
		ans = a
		q = qq
		m = mm
		umani = u
		opz = q["opz"]

	func valori() -> Array:
		return opz.map(func(o): return o["v"])

	func valida(v) -> bool:
		for o in opz:
			if str(o["v"]) == str(v):
				return true
		return false

	func ha(v) -> bool:
		return valida(v)

	## dado deterministico: dipende dal seme, dall'atto, dalla fazione e dal numero della domanda
	func rng(etichetta: String = "") -> RandomNumberGenerator:
		var r := RandomNumberGenerator.new()
		r.seed = hash([int(base["seme"]), int(base["atto_n"]), q["f"], ans.size(), etichetta])
		return r

	func d6(etichetta: String = "") -> int:
		return 1 + rng(etichetta).randi() % 6

	func ripiego():
		# prima opzione non passiva; altrimenti la prima
		for o in opz:
			var v = o["v"]
			if not (v is String and v in ["fine", "no", "nessuno", "nessuna", "passa"]):
				return v
		return opz[0]["v"]


# ================================================================ pianificazione del turno (scheda «è idoneo?»)

static func _motore(base: Dictionary) -> Motore:
	var mm := Motore.new()
	mm.usa_dati()
	mm.s = base.duplicate(true)
	mm.s["tmp"] = {}
	return mm


static func _rng_piano(base: Dictionary, f: String, etichetta: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash([int(base["seme"]), int(base["atto_n"]), f, "piano", etichetta])
	return r


static func _pianifica(base: Dictionary, f: String, umani: Array) -> Dictionary:
	var mm := _motore(base)
	var atto: Dictionary = mm.atto_corrente()
	var r := _rng_piano(base, f, "idoneo")
	var cd_libera: bool = not mm.s["scelte"].has("cd")
	var ec_libera: bool = not mm.s["scelte"].has("ec")
	var ris := int(mm.s["ris"][f])
	var cid: String = mm.s["carta"]
	var p := {"f": f, "carta_bot": "", "casella": "passa"}
	if atto.get("t", "") == "succ":
		var c := _pesca(mm, f, base, umani, "limitata")
		c["casella"] = "limitata"
		return c
	if atto.get("t", "") != "turno" or atto.get("f", "") != f:
		return p
	var ev := {}
	if ec_libera and mm.tipo_carta(cid) == "evento":
		ev = _evento_efficace(mm, f, cid, umani)
	var ev_resta: bool = not ev.is_empty() and mm.carta_dati(cid).get("resta", false)
	if f == "D":
		if ris < 3 and mm.tributo_totale() >= 6 and cd_libera:
			var c := _pesca(mm, f, base, umani, "comando")
			c["casella"] = "cd"
			c["decreti"] = [{"d": "tributo"}]
			c["dec_prima"] = true
			return c
		if cd_libera:
			var c := _pesca(mm, f, base, umani, "cd")
			if not c.is_empty():
				c["casella"] = "cd"
				return c
		if ev_resta:
			return {"f": f, "casella": "ec", "azione": "evento", "lato": ev["lato"], "carta_bot": ""}
		if ris < 2:
			return p
		var c := _pesca(mm, f, base, umani, "limitata")
		c["casella"] = "limitata"
		return c
	# Bahmani e Vijayanagara
	var puo_ribellarsi := false
	if mm.s["dinastia"] == "tughlaq" and ris >= 1:
		for id in mm.ordine:
			if mm.ok_ribellione(f, id, {}):
				puo_ribellarsi = true
	if not puo_ribellarsi and not ev.is_empty() and r.randi_range(1, 6) <= 3:
		return {"f": f, "casella": "ec", "azione": "evento", "lato": ev["lato"], "carta_bot": ""}
	var dec_eco := "commercio" if f == "B" else "tassa"
	if ris < 4 and cd_libera and _rendita(mm, f) >= (1 if f == "B" else 3):
		var c := _pesca(mm, f, base, umani, "comando")
		c["casella"] = "cd"
		c["decreti"] = [{"d": dec_eco}]
		c["dec_prima"] = true
		return c
	if ris >= 1 and cd_libera:
		var c := _pesca(mm, f, base, umani, "cd")
		if not c.is_empty():
			c["casella"] = "cd"
			return c
	if ev_resta:
		return {"f": f, "casella": "ec", "azione": "evento", "lato": ev["lato"], "carta_bot": ""}
	if ris >= 1:
		var c := _pesca(mm, f, base, umani, "limitata")
		c["casella"] = "limitata"
		return c
	return p


## Risorse che darebbe il Decreto economico (Commercio: Province con pezzi; Tassa: Prosperità controllata + Templi).
static func _rendita(mm: Motore, f: String) -> int:
	var n := 0
	if f == "B":
		for id in mm.ordine:
			if mm.provincia(id) and mm.n_pezzi(id, "B") > 0:
				n += 1
		return n
	n = mm.strutture_mappa("tp")
	for id in mm.ordine:
		if mm.provincia(id) and mm.X(id)["ctrl"] == "V":
			n += mm.prosp(id)
	return n


# ================================================================ Eventi efficaci

## Punteggio dal punto di vista del bot (righe «AGGIUNGE o AUMENTA» / «TOGLIE o RIDUCE» delle schede).
static func punteggio(mm: Motore, f: String, umani: Array) -> float:
	var v := 0.0
	var mio_r := 1.2 if f in ["D", "B"] else 1.0
	var mio_c := 1.0 if f in ["D", "B"] else 1.2
	v += float(mm.s["ris"][f]) * mio_r + float(mm.s["cav"][f]) * mio_c
	var mongoli := 0
	var trib := 0
	var pezzi := {"D": 0, "B": 0, "V": 0}
	for id in mm.ordine:
		mongoli += int(mm.X(id)["m"])
		if mm.provincia(id) and mm.X(id)["trib"]:
			trib += 1
		for g in pezzi:
			pezzi[g] = int(pezzi[g]) + mm.n_pezzi(id, g)
	v += float(pezzi[f]) * 1.5
	for g in ["D", "B", "V"]:
		if g != f:
			v -= float(pezzi[g]) * 1.2
			v -= float(mm.s["ris"][g]) * 0.4
	match f:
		"D":
			v += float(trib) * 2.0 - float(mongoli) * 1.0
			v -= float(mm.s["infl"]["B"]) * 1.5 + float(mm.s["infl"]["V"]) * 1.5
		"B", "V":
			var r := mm.altra_bv(f)
			v += float(mm.s["infl"][f]) * 2.5 + float(mongoli) * 0.5 - float(trib) * 1.5
			if r in umani:
				v -= float(mm.s["infl"][r]) * 1.5
	return v


## Restituisce {"lato": "u"/"s"} con il primo lato efficace della carta, o {} se nessuno lo è.
static func _evento_efficace(mm: Motore, f: String, cid: String, umani: Array) -> Dictionary:
	var cd := mm.carta_dati(cid)
	if cd.is_empty():
		return {}
	var prima := punteggio(mm, f, umani)
	var lati: Array = ["u", "s"] if cd.get("testo_s", "") != "" else ["u"]
	for lato in lati:
		if cd.get("np_" + lato, false):
			continue
		var migliore := -INF
		for k in 4:
			var m2 := Motore.new()
			m2.usa_dati()
			m2.s = mm.s.duplicate(true)
			m2.s["tmp"] = {}
			var r := RandomNumberGenerator.new()
			r.seed = hash([int(mm.s["seme"]), int(mm.s["atto_n"]), f, cid, lato, k])
			m2.autorisposta = func(_x, qq):
				if str(qq.get("x", {}).get("tag", "")) == "lato":
					return lato
				return IA.politica_casuale(_x, qq, r)
			m2.evento(f, cd)
			migliore = max(migliore, punteggio(m2, f, umani))
		if migliore - prima > 0.9:
			return {"lato": lato}
	return {}


# ================================================================ carte azione

## Pesca carte azione fino a una applicabile. modo: "cd" (Comando + Decreto), "comando" (solo Comando),
## "limitata" (un Comando in un solo spazio). Restituisce il piano o {} se nessuna carta è applicabile.
static func _pesca(mm: Motore, f: String, base: Dictionary, umani: Array, modo: String) -> Dictionary:
	var r := _rng_piano(base, f, "mazzo" + modo)
	var mazzo: Array = CARTE[f].duplicate()
	for i in range(mazzo.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t = mazzo[i]
		mazzo[i] = mazzo[j]
		mazzo[j] = t
	for cid in mazzo:
		var rr := _rng_piano(base, f, "carta" + cid)
		var p: Dictionary = _carta(mm, f, cid, rr, umani)
		if p.is_empty():
			continue
		p["carta_bot"] = cid
		p["f"] = f
		if modo == "comando" or modo == "limitata":
			p["decreti"] = []
			p["dec_prima"] = false
			p["dec_dopo"] = []
		if modo == "limitata":
			p["limitata"] = true
		# la carta serve solo se almeno un Comando (o un Decreto, in modo cd) è eseguibile
		var cmd_ok := false
		for c in p["comandi"]:
			if _comando_possibile(mm, f, c, umani):
				cmd_ok = true
				break
		var dec_ok := false
		for d in p.get("decreti", []) + p.get("dec_dopo", []):
			if _decreto_possibile(mm, f, d):
				dec_ok = true
		if cmd_ok or (modo == "cd" and dec_ok):
			return p
	return {}


## Comandi di una carta. Ogni opzione: {"c": comando, "filtro": "", "max": n, "infl": bool, "primo_rivale": bool}
static func _cmd(c: String, extra: Dictionary = {}) -> Dictionary:
	var d := {"c": c}
	d.merge(extra)
	return d


static func _carta(mm: Motore, f: String, cid: String, r: RandomNumberGenerator, umani: Array) -> Dictionary:
	var disp_r := mm.disp("r")
	var disp_a := mm.disp("a")
	var d_gioc := "D" in umani
	var comp_gov := {"d": "costringi", "gov": d_gioc}
	var mig := _cmd("migra", {"max": 3, "infl": true})
	var att_v := _cmd("attacca", {"filtro": "3raja"})
	var att_b := _cmd("attacca", {"filtro": "2amiri"})
	var rib := _cmd("ribellione")
	var rib2 := _cmd("ribellione", {"filtro": "p2"})
	var rad := _cmd("raduna")
	var p := {"comandi": [], "decreti": [], "dec_prima": true, "dec_dopo": []}
	match cid:
		# ---------------------------------------------------------------- Vijayanagara
		"I":
			if r.randi_range(1, 6) + r.randi_range(1, 6) > disp_r:
				return {}
			var prov := 0
			for id in mm.ordine:
				if mm.raja(id) > 0:
					prov += 1
			p["decreti"] = ([{"d": "costruisci"}] if prov >= 4 else []) + [comp_gov, {"d": "tassa"}]
			p["comandi"] = [rib, rad]
		"JJ":
			p["decreti"] = [{"d": "costruisci"}] + ([comp_gov] if disp_r >= 2 else []) + [{"d": "tassa"}]
			if mm.s["dinastia"] == "khalji":
				p["comandi"] = [mig, rad]
			else:
				p["comandi"] = [rib, att_v, mig]
		"K":
			if r.randi_range(1, 6) + r.randi_range(1, 6) > disp_r:
				return {}
			p["decreti"] = ([comp_gov] if int(mm.s["infl"]["V"]) >= 2 else []) + [{"d": "costruisci"}, {"d": "tassa"}]
			p["comandi"] = [rib, rad]
		"KK":
			var puo_gov := false
			if int(mm.s["infl"]["V"]) >= 2:
				for id in mm._costringi_spazi("V"):
					if int(mm.X(id)["g"]) > 0:
						puo_gov = true
			p["decreti"] = ([comp_gov] if puo_gov else []) + [{"d": "costruisci"}, {"d": "tassa"}]
			var n := 0
			for id in mm.ordine:
				if mm.provincia(id) and mm.raja(id) >= 3 and mm.n_pezzi(id, "D") + mm.n_pezzi(id, "B") > 0:
					n += 1
			if n >= 2:
				p["comandi"] = [rib2, att_v, mig]
			else:
				p["comandi"] = [rib, _cmd("migra", {"max": 3, "infl": true, "primo_rivale": int(mm.s["infl"]["V"]) < 3}), rad]
		"L":
			if int(mm.s["infl"]["V"]) >= 2:
				return {}
			p["decreti"] = ([{"d": "costringi", "pochi_b": true}] if disp_r >= 2 else []) + [{"d": "costruisci"}, {"d": "tassa"}]
			if r.randi_range(3, 18) <= disp_r:
				p["comandi"] = [rad]
			else:
				p["comandi"] = [rib2, att_v, mig]
		"LL":
			p["decreti"] = [{"d": "costruisci"}] + ([comp_gov] if disp_r >= 2 else []) + [{"d": "tassa"}]
			if r.randi_range(1, 6) + r.randi_range(1, 6) <= disp_r:
				p["comandi"] = [rib, rad]
			else:
				p["comandi"] = [rib, att_v, mig]
		"M":
			var sette := false
			for id in mm.ordine:
				if mm.raja(id) >= 7:
					sette = true
			if not sette:
				return {}
			p["comandi"] = [rib2, mig, rad]
			p["dec_prima"] = false
			p["decreti"] = [{"d": "costruisci"}] + ([comp_gov] if disp_r >= 2 else []) + [{"d": "tassa"}]
		"MM":
			p["decreti"] = ([comp_gov] if disp_r >= 2 else []) + [{"d": "costruisci"}, {"d": "tassa"}]
			if r.randi_range(1, 6) + r.randi_range(1, 6) <= disp_r:
				p["comandi"] = [rib, rad]
			else:
				p["comandi"] = [rib, att_v, mig]
		# ---------------------------------------------------------------- Bahmani
		"E":
			if r.randi_range(1, 6) > disp_a:
				return {}
			p["decreti"] = [{"d": "cospira", "min": 1}, {"d": "costruisci"}, {"d": "commercio"}]
			p["comandi"] = [rib, rad, att_b]
		"EE":
			p["comandi"] = [rib, mig]
			p["dec_prima"] = false
			p["decreti"] = [{"d": "cospira", "min": 2, "o_togli": true}, {"d": "costruisci"}, {"d": "commercio"}]
		"F":
			var quattro := false
			for id in mm.ordine:
				if mm.amiri(id) >= 4:
					quattro = true
			if not quattro:
				return {}
			p["decreti"] = [{"d": "cospira", "min": 2, "disp": true}, {"d": "costruisci"}, {"d": "commercio"}]
			if int(mm.s["infl"]["B"]) >= 2:
				p["comandi"] = [rib, att_b, rad]
			else:
				p["comandi"] = [rib2, mig, rad]
		"FF":
			if r.randi_range(1, 6) <= disp_a:
				p["comandi"] = [rib, rad]
			else:
				p["comandi"] = [rib, mig]
			p["dec_prima"] = false
			p["decreti"] = [{"d": "cospira", "min": 2, "raja": true}, {"d": "costruisci"}, {"d": "commercio"}]
		"G":
			if r.randi_range(1, 6) > disp_a:
				return {}
			p["decreti"] = [{"d": "cospira", "min": 2}, {"d": "costruisci"}, {"d": "commercio"}]
			p["comandi"] = [rib, rad]
		"GG":
			p["decreti"] = [{"d": "costruisci"}, {"d": "cospira", "min": 1, "disp": true}, {"d": "commercio"}]
			p["comandi"] = [rib, mig]
		"H":
			if int(mm.s["infl"]["B"]) >= 2:
				return {}
			p["decreti"] = [{"d": "costruisci"}, {"d": "cospira", "min": 1}, {"d": "commercio"}]
			if r.randi_range(1, 6) <= disp_a:
				p["comandi"] = [rib2, rad]
			else:
				p["comandi"] = [rib, att_b, mig]
		"HH":
			p["decreti"] = [{"d": "cospira", "min": 2, "raja": true, "disp": true}, {"d": "costruisci"}, {"d": "commercio"}]
			if r.randi_range(1, 6) <= disp_a:
				p["comandi"] = [rib, rad]
			else:
				p["comandi"] = [rib, mig, att_b]
		# ---------------------------------------------------------------- Sultanato
		"A", "C", "DD":
			var soglia := (6 + r.randi_range(1, 6) + r.randi_range(1, 6)) if cid == "A" else (r.randi_range(1, 6) + r.randi_range(1, 6) + r.randi_range(1, 6))
			var dec := [{"d": "obbedienza"}, {"d": "tributo"}]
			if soglia <= mm.disp("t"):
				p["decreti"] = dec if int(mm.s["ris"]["D"]) < 16 else []
				p["comandi"] = [_cmd("coscrivi", {"max": 6})]
			elif cid == "A":
				if not _gov_vicini_indip(mm):
					return {}
				p["decreti"] = []
				p["comandi"] = [_cmd("marcia", {"max": 4, "filtro": "indip"})]
			else:
				if not (mm.disp("g") >= 3 or _prov_obb_gov(mm) >= 2):
					return {}
				p["decreti"] = []
				p["comandi"] = [_cmd("governa")]
			p["dec_dopo"] = dec
		"AA":
			if not _due_spazi_attacco(mm):
				return {}
			p["comandi"] = [_cmd("attacca", {"filtro": "2d"})]
			p["dec_prima"] = false
			p["decreti"] = [{"d": "obbedienza"}, {"d": "tributo"}]
		"B":
			var mong := 0
			var nove := false
			for id in mm.ordine:
				mong += int(mm.X(id)["m"])
				if int(mm.X(id)["t"]) >= 9:
					nove = true
			if mong < 3 or not nove:
				return {}
			p["decreti"] = [{"d": "campagna"}]
			p["comandi"] = [_cmd("attacca", {"filtro": "2d"}), _cmd("governa")]
		"BB":
			var lords: bool = "S3" in mm.s["giocate"]
			if not (mm.disp("g") >= 3 and not lords) and _prov_obb_gov(mm) < 2:
				return {}
			p["decreti"] = [{"d": "obbedienza"}, {"d": "tributo"}] if int(mm.s["ris"]["D"]) < 16 else []
			p["comandi"] = [_cmd("governa")]
			p["dec_dopo"] = [{"d": "obbedienza"}, {"d": "tributo"}]
		"CC":
			if _gov_vicini_indip(mm):
				p["comandi"] = [_cmd("marcia", {"max": 4, "filtro": "indip"})]
				p["dec_prima"] = false
				p["decreti"] = [{"d": "obbedienza"}, {"d": "tributo"}]
			elif _due_spazi_attacco(mm):
				p["decreti"] = [{"d": "tributo"}]
				p["comandi"] = [_cmd("attacca", {"filtro": "2d"})]
			else:
				return {}
		"D":
			var nove := false
			for id in mm.ordine:
				if int(mm.X(id)["t"]) >= 9:
					nove = true
			if int(mm.s["ris"]["D"]) <= 12 or not nove:
				return {}
			p["decreti"] = [{"d": "campagna"}]
			p["comandi"] = [_cmd("attacca", {"filtro": "2d"}), _cmd("governa")]
	return p


static func _gov_vicini_indip(mm: Motore) -> bool:
	var n := 0
	for id in mm.ordine:
		if int(mm.X(id)["g"]) <= 0:
			continue
		var ind := 0
		for a in [id] + mm.adiacenti(id):
			if mm.provincia(a) and not mm.X(a)["trib"]:
				ind += 1
		if ind >= 2:
			n += int(mm.X(id)["g"])
	return n >= 2


static func _prov_obb_gov(mm: Motore) -> int:
	var n := 0
	for id in mm.ordine:
		if mm.provincia(id) and int(mm.X(id)["g"]) > 0 and int(mm.X(id)["ao"]) + int(mm.X(id)["ro"]) > 0:
			n += 1
	return n


static func _due_spazi_attacco(mm: Motore) -> bool:
	var n := 0
	for id in mm.ordine:
		if mm.n_unita(id, "D") >= 2 and (int(mm.X(id)["m"]) + int(mm.X(id)["ar"]) + int(mm.X(id)["rr"])) > 0:
			n += 1
	return n >= 2


# ================================================================ validità di Comandi e Decreti

static func _filtro_ok(mm: Motore, f: String, id: String, filtro: String) -> bool:
	match filtro:
		"p2": return mm.prosp(id) == 2
		"3raja": return mm.raja(id) >= 3
		"2amiri": return mm.amiri(id) >= 2
		"2d": return mm.n_unita(id, "D") >= 2
		"indip": return mm.provincia(id) and not mm.X(id)["trib"]
	return true


static func _comando_possibile(mm: Motore, f: String, c: Dictionary, _umani: Array) -> bool:
	var cmd: String = c["c"]
	if not mm.comando_permesso(f, cmd, {}):
		return false
	mm.s["tmp"] = {}
	for id in mm._spazi_validi(f, cmd, {}):
		if _filtro_ok(mm, f, id, str(c.get("filtro", ""))):
			if cmd in ["marcia", "migra"] and _quanti_portabili(mm, f, id, cmd) <= 0:
				continue
			return true
	return false


static func _decreto_possibile(mm: Motore, f: String, d: Dictionary) -> bool:
	var k: String = d["d"]
	if not mm.call("okd_" + k, f):
		return false
	match k:
		"cospira":
			var n := 0
			for id in mm._cospira_spazi(f):
				n += int(mm.X(id)["g"]) + (mm.raja(id) if d.get("raja", false) and int(mm.s["infl"]["B"]) >= 2 else 0)
			return n >= int(d.get("min", 1)) and (not d.get("disp", false) or mm.disp("a") >= int(d.get("min", 1)))
		"tassa":
			return _rendita(mm, "V") > 0
		"commercio":
			return true
		"costringi":
			if d.get("gov", false) and int(mm.s["infl"]["V"]) >= 2:
				return true
			return mm.disp("r") > 0 or int(mm.s["infl"]["V"]) >= 2
	return true


# ================================================================ tabelle di selezione degli spazi

static func scegli(m: Motore, f: String, colonna: String, cand: Array, umani: Array, r: RandomNumberGenerator) -> String:
	if cand.is_empty():
		return ""
	var righe: Array = TAB[f].get(colonna, ["caso"])
	var rest := cand.duplicate()
	for riga in righe:
		if rest.size() <= 1:
			break
		if riga == "caso":
			break
		var fn := _riga(m, f, riga, umani)
		if fn.is_empty():
			continue
		if fn["t"] == "si":
			var ok := rest.filter(func(id): return (fn["p"] as Callable).call(id))
			if not ok.is_empty():
				rest = ok
		else:
			var best := -INF
			for id in rest:
				var v: float = (fn["p"] as Callable).call(id) * (1.0 if fn["t"] == "max" else -1.0)
				best = max(best, v)
			rest = rest.filter(func(id): return (fn["p"] as Callable).call(id) * (1.0 if fn["t"] == "max" else -1.0) == best)
	return rest[r.randi() % rest.size()]


static func _giocatore_migliore(m: Motore, umani: Array) -> String:
	var best := ""
	var bv := -1
	for g in umani:
		if m.vp(g) > bv:
			bv = m.vp(g)
			best = g
	return best


static func _avversari_n(m: Motore, f: String, id: String) -> int:
	var t := 0
	for g in ["D", "B", "V", "M"]:
		if g != f:
			t += m.n_pezzi(id, g) if g != "M" else int(m.X(id)["m"])
	return t


static func _riga(m: Motore, f: String, riga: String, umani: Array) -> Dictionary:
	var mie := func(id): return float(m.n_unita(id, f))
	match riga:
		"delhi": return {"t": "si", "p": func(id): return id == "delhi"}
		"punjab": return {"t": "si", "p": func(id): return id == "punjab"}
		"passi": return {"t": "si", "p": func(id): return id == "passi"}
		"qasbah": return {"t": "si", "p": func(id): return int(m.X(id)["q"]) > 0}
		"provincia": return {"t": "si", "p": func(id): return m.provincia(id)}
		"tempio": return {"t": "si", "p": func(id): return int(m.X(id)["tp"]) > 0}
		"p2": return {"t": "si", "p": func(id): return m.prosp(id) == 2}
		"p1": return {"t": "si", "p": func(id): return m.prosp(id) == 1}
		"indip": return {"t": "si", "p": func(id): return m.provincia(id) and not m.X(id)["trib"]}
		"indip_gov": return {"t": "si", "p": func(id): return m.provincia(id) and not m.X(id)["trib"] and m.X(id)["ctrl"] == "D" and int(m.X(id)["g"]) == 0}
		"trib_solo":
			if umani != ["D"]:
				return {}
			return {"t": "si", "p": func(id): return m.provincia(id) and m.X(id)["trib"]}
		"gov_con_raja":
			if not "D" in umani:
				return {}
			return {"t": "si", "p": func(id): return int(m.X(id)["g"]) > 0 and m.raja(id) > 0}
		"con_gov": return {"t": "si", "p": func(id): return m.provincia(id) and int(m.X(id)["g"]) > 0}
		"nessuna_mia": return {"t": "si", "p": func(id): return m.n_unita(id, f) == 0}
		"magg_giocatore":
			var g := _giocatore_migliore(m, umani)
			if g == "" or g == f:
				return {}
			return {"t": "si", "p": func(id): return m.n_pezzi(id, g) * 2 > (m.n_pezzi(id, "D") + m.n_pezzi(id, "B") + m.n_pezzi(id, "V")) or m.X(id)["ctrl"] == g}
		"meno_avv1": return {"t": "min", "p": func(id): return float(_avversari_n(m, f, id)) if _avversari_n(m, f, id) > 0 else 999.0}
		"meno_avv": return {"t": "min", "p": func(id): return float(_avversari_n(m, f, id))}
		"piu_mie": return {"t": "max", "p": mie}
		"piu_truppe": return {"t": "max", "p": func(id): return float(m.X(id)["t"])}
		"non_cambia": return {"t": "si", "p": func(id): return _togliere_non_cambia(m, f, id)}
	return {}


static func _togliere_non_cambia(m: Motore, f: String, id: String) -> bool:
	if not m.provincia(id):
		return true
	var mio := m.n_pezzi(id, f) - 1
	var altri := 0
	for g in ["D", "B", "V"]:
		if g != f:
			altri += m.n_pezzi(id, g)
	var aveva: bool = m.n_pezzi(id, f) > altri
	return aveva == (mio > altri)


# ================================================================ priorità di movimento

## Quante Unità f può portare in dest (con Marcia/Migrazione) rispettando le regole «TIENI».
static func _quanti_portabili(m: Motore, f: String, dest: String, cmd: String) -> int:
	var t := 0
	for a in m.adiacenti(dest):
		if f != "D" and not m.provincia(a):
			continue
		t += _mobili(m, f, a)
	return t


## Unità di f che possono lasciare id senza perdere maggioranza/Controllo e senza scendere sotto i minimi.
static func _mobili(m: Motore, f: String, id: String) -> int:
	var n := 0
	for k in UNITA[f]:
		n += int(m.X(id)[k]) - int(m.s["tmp"].get("usati", {}).get(id + ":" + k, 0))
	if n <= 0:
		return 0
	var tieni := 0
	if f == "D":
		if id in ["delhi", "punjab", "passi"]:
			tieni = max(tieni, 4 + (int(m.X(id)["g"])))
		if m.provincia(id) and not m.X(id)["trib"] and m.X(id)["ctrl"] == "D":
			tieni = max(tieni, 1)
	if f == "B" and int(m.X(id)["f"]) > 0:
		tieni = max(tieni, 2)
	if f == "V" and int(m.X(id)["tp"]) > 0:
		tieni = max(tieni, 1)
	if m.provincia(id):
		var altri := 0
		for g in ["D", "B", "V"]:
			if g != f:
				altri += m.n_pezzi(id, g)
		var miei := m.n_pezzi(id, f)
		if miei > altri:
			tieni = max(tieni, n - (miei - altri - 1))
	return max(0, n - tieni)


## Quante Unità servono in dest secondo «PRENDI».
static func _bisogno(m: Motore, f: String, dest: String) -> int:
	var altri := 0
	for g in ["D", "B", "V"]:
		if g != f:
			altri += m.n_pezzi(dest, g)
	var miei := m.n_pezzi(dest, f)
	var magg: int = max(0, altri + 1 - miei)
	match f:
		"D":
			if not m.provincia(dest):
				return max(1, 4 - int(m.X(dest)["t"]))
			return max(magg, 1)
		"B":
			return clamp(max(magg, 2 - m.amiri(dest)), 1, 3)
		"V":
			if dest in ["karnataka", "tamilakam"]:
				return magg
			return 3
	return 1


# ================================================================ risposte

static func _rispondi(ctx: Contesto, f: String, tag: String):
	var m := ctx.m
	var x: Dictionary = ctx.q.get("x", {})
	var umani := ctx.umani
	var r := ctx.rng(tag)
	var piano := piano_di(ctx.base, f, umani)
	match tag:
		"casella":
			return piano.get("casella", "passa")
		"evcmd":
			return "evento" if piano.get("azione", "") == "evento" else "comando"
		"lato":
			if piano.has("lato"):
				return piano["lato"]
			var cd := m.carta_dati(m.s["carta"])
			return "s" if cd.get("np_u", false) else "u"
		"quando":
			return "prima" if piano.get("dec_prima", false) and not (piano.get("decreti", []) as Array).is_empty() else "dopo"
		"cmd":
			return _risp_cmd(ctx, f, piano)
		"decreto":
			return _risp_decreto(ctx, f, piano)
		"spazio_cmd":
			return _risp_spazio(ctx, f, piano)
		"n_truppe", "n_raduno", "n_rinforzi", "costr_n", "ev_n", "misto":
			var vals := ctx.valori()
			if tag == "misto":
				return vals[-1] if f == "V" else vals[0]
			return vals[-1]
		"n_marcia", "n_migra":
			var da: String = x.get("da", "")
			var a: String = x.get("a", "")
			var gia := 0
			for k in UNITA[f]:
				gia += int(m.s["tmp"].get("usati", {}).get(a + ":" + k, 0))
			if f == "D":
				var k: String = x.get("k", "t")
				var vuoi := 0
				if k == "g":
					var serve_g: bool = int(m.X(a)["g"]) == 0 and m.provincia(a) and (not m.X(a)["trib"] or int(m.X(a)["ao"]) + int(m.X(a)["ro"]) > 0)
					vuoi = 1 if serve_g and _mobili(m, f, da) > 0 and int(m.X(da)["g"]) > (1 if m.X(da)["ctrl"] == "D" else 0) else 0
				else:
					vuoi = min(_mobili(m, f, da), max(0, _bisogno(m, f, a)))
				return clamp(vuoi, 0, int(ctx.valori()[-1]))
			var vuoi2: int = min(_mobili(m, f, da), max(0, _bisogno(m, f, a)))
			return clamp(vuoi2, 0, int(ctx.valori()[-1]))
		"n_ribelli":
			return ctx.valori()[0]
		"migra_infl":
			return "si"
		"governa":
			return "usa" if ctx.ha("usa") else "piazza"
		"gov_rim":
			for k in ["ao", "ro"]:
				var g := "B" if k == "ao" else "V"
				if g in umani and ctx.ha(k):
					return k
			for k in ["ao", "ro"]:
				if ctx.ha(k):
					return k
			return "no"
		"qasbah":
			return "si"
		"bersaglio":
			return _risp_bersaglio(ctx, f)
		"rinforzi":
			var best = "no"
			var bn := 0
			for v in ctx.valori():
				if v is String and m.SP.has(v):
					var n := m.n_unita(v, f)
					if n > bn:
						bn = n
						best = v
			return best
		"cavalleria":
			return _risp_cavalleria(ctx, f)
		"perdite":
			return _risp_perdite(ctx, f)
		"cav_da":
			var vals := ctx.valori()
			var gioc := vals.filter(func(v): return v in umani)
			var pool: Array = gioc if not gioc.is_empty() else vals
			return pool[r.randi() % pool.size()]
		"orient":
			return "obb"
		"obb":
			return ctx.valori()[0] if ctx.valori()[0] != "fine" else "fine"
		"cospira":
			var cand := ctx.valori().filter(func(v): return v is String and m.SP.has(v))
			var id := scegli(m, f, "cospira", cand, umani, r)
			return id if id != "" else "fine"
		"cospira_k":
			if ctx.ha("g"):
				return "g"
			return ctx.valori()[0]
		"costringi":
			var cand := ctx.valori().filter(func(v): return v is String and m.SP.has(v))
			var dec: Dictionary = piano.get("dec_scelto", {})
			if int(m.s["infl"]["V"]) >= 2 and "D" in umani:
				var cg := cand.filter(func(id): return int(m.X(id)["g"]) > 0)
				if not cg.is_empty():
					cand = cg
			if dec.get("pochi_b", false):
				var cb := cand.filter(func(id): return m.n_pezzi(id, "B") > 0)
				if not cb.is_empty():
					var mn := 99
					for id in cb:
						mn = min(mn, m.n_pezzi(id, "B"))
					cand = cb.filter(func(id): return m.n_pezzi(id, "B") == mn)
			var id := scegli(m, f, "costringi", cand, umani, r)
			return id if id != "" else "fine"
		"costr_da":
			var cand := ctx.valori().filter(func(v): return v is String and m.SP.has(v) and _mobili(m, f, v) > 0)
			if cand.is_empty():
				return "fine"
			var best: String = cand[0]
			for id in cand:
				if m.raja(id) > m.raja(best):
					best = id
			return best
		"costr_rim":
			return _risp_rimuovi_avv(ctx, f)
		"costruisci":
			var cand := ctx.valori().filter(func(v): return v is String and m.SP.has(v))
			var id := scegli(m, f, "piazza_s", cand, umani, r)
			return id if id != "" else "fine"
		"camp_da", "camp_n", "camp_passo", "camp_lascia", "camp_prendi":
			return _risp_campagna(ctx, f, tag)
		"mongolo", "avanza", "n_avanza":
			return _risp_mongoli(ctx, f, tag)
		"doni":
			return "no"
		"sacc_truppa", "slot":
			var cand := ctx.valori().filter(func(v): return v is String and m.SP.has(v))
			var id := scegli(m, f, "rim_mio", cand, umani, r)
			return id if id != "" else ctx.valori()[0]
		"succ_camp":
			return "si"
		"succ_cav":
			return ctx.valori()[-1] if f == "V" else ctx.valori()[0]
		"succ_infl":
			return _risp_signori(ctx, f)
		"pezzo":
			# Eventi: togliere o sostituire pezzi avversari; i propri secondo le priorità
			var vals := ctx.valori().filter(func(v): return v != "no")
			for k in PRIO_AVV:
				if k in vals and Nucleo.faz_pezzo(k) != f:
					return k
			for k in PRIO_MIEI.get(f, []):
				if k in vals:
					return k
			return vals[0] if not vals.is_empty() else "no"
	return _ripiego_simulato(ctx, f)


static func _risp_cmd(ctx: Contesto, f: String, piano: Dictionary):
	var comandi: Array = piano.get("comandi", [])
	for c in comandi:
		if ctx.ha(c["c"]):
			if _comando_possibile(_motore_corrente(ctx), f, c, ctx.umani):
				return c["c"]
	# Comando dentro un Evento o una Successione senza piano: il primo possibile
	for v in ctx.valori():
		if v != "nessuno":
			return v
	return "nessuno"


static func _motore_corrente(ctx: Contesto) -> Motore:
	var mm := Motore.new()
	mm.usa_dati()
	mm.s = ctx.m.s.duplicate(true)
	return mm


static func _risp_decreto(ctx: Contesto, f: String, piano: Dictionary):
	var mm := _motore_corrente(ctx)
	var tutti: Array = piano.get("decreti", []) + piano.get("dec_dopo", [])
	for d in tutti:
		if ctx.ha(d["d"]) and _decreto_possibile(mm, f, d):
			piano["dec_scelto"] = d
			return d["d"]
	return "nessuno"


static func _opz_cmd(piano: Dictionary, cmd: String) -> Dictionary:
	for c in piano.get("comandi", []):
		if c["c"] == cmd:
			return c
	return {}


## Spazio per un Comando: tabella della fazione, filtri della carta, Risorse («fino a 1d6» o «tutte»).
static func _risp_spazio(ctx: Contesto, f: String, piano: Dictionary):
	var m := ctx.m
	var cmd: String = str(m.s["tmp"].get("cmd", ""))
	var c := _opz_cmd(piano, cmd)
	var scelti: Array = m.s["tmp"].get("scelti", [])
	var cand := ctx.valori().filter(func(v): return v is String and m.SP.has(v))
	var filtro: String = str(c.get("filtro", ""))
	if filtro != "":
		cand = cand.filter(func(id): return _filtro_ok(m, f, id, filtro))
	var mx: int = int(c.get("max", 99))
	if scelti.size() >= mx:
		return "fine"
	# Risorse: Bahmani e Vijayanagara si fermano quando le Risorse scendono sotto 1d6 (salvo Ribellione e dopo i Signori)
	if not scelti.is_empty() and f in ["B", "V"] and cmd != "ribellione" and not "S3" in m.s["giocate"] and not m.s["tmp"].get("cmd_gratis", false):
		if int(m.s["ris"][f]) < ctx.d6("ris"):
			return "fine"
	var col := ""
	match cmd:
		"coscrivi": col = "piazza_t"
		"marcia":
			col = "marcia"
			cand = cand.filter(func(id): return _quanti_portabili(m, f, id, cmd) > 0)
		"governa":
			# 1) dove si possono togliere Unità obbedienti; 2) dove piazzare una Qasbah; 3) Governatori nelle Province
			var c1 := cand.filter(func(id): return int(m.X(id)["g"]) > 0 and int(m.X(id)["ao"]) + int(m.X(id)["ro"]) > 0)
			var c2 := cand.filter(func(id): return int(m.X(id)["g"]) > 0 and int(m.X(id)["q"]) == 0 and m.disp("q") > 0)
			var c3 := cand.filter(func(id): return m.provincia(id) and m.disp("g") > 0)
			cand = c1 if not c1.is_empty() else (c2 if not c2.is_empty() else c3)
			col = "piazza_g"
		"attacca":
			col = "attacca"
			cand = cand.filter(func(id): return _attacco_sensato(m, f, id))
		"raduna": col = "piazza_u"
		"migra":
			col = "migra"
			cand = cand.filter(func(id): return _quanti_portabili(m, f, id, cmd) > 0 and _bisogno(m, f, id) > 0)
			if scelti.is_empty() and c.get("primo_rivale", false):
				var cr := cand.filter(func(id): return m.n_pezzi(id, m.altra_bv(f)) > 0)
				if not cr.is_empty():
					cand = cr
		"ribellione": col = "ribellione"
	if cand.is_empty():
		return "fine"
	var id := scegli(m, f, col, cand, ctx.umani, ctx.rng("spazio"))
	return id if id != "" else "fine"


static func _attacco_sensato(m: Motore, f: String, id: String) -> bool:
	# il bot attacca dove ha almeno tante Unità quante il difensore più debole (o un rinforzo)
	var mie := m.n_unita(id, f)
	var minimo := 99
	for g in ["D", "B", "V", "M"]:
		if g == f:
			continue
		var n := m.n_unita(id, g) if g != "M" else int(m.X(id)["m"])
		if n > 0 or (g != "M" and m.n_pezzi(id, g) > 0):
			minimo = min(minimo, n)
	return mie >= 1 and mie >= minimo


static func _risp_bersaglio(ctx: Contesto, f: String):
	var m := ctx.m
	var vals := ctx.valori()
	var ordine: Array = []
	if f == "D":
		for g in ctx.umani:
			if g != "D":
				ordine.append(g)
		var bv := ["B", "V"]
		bv.sort_custom(func(a, b): return m.vp(a) > m.vp(b))
		ordine += bv
		ordine.append("M")
	else:
		var r := m.altra_bv(f)
		var id: String = m.s["tmp"].get("scelti", [""])[-1] if not (m.s["tmp"].get("scelti", []) as Array).is_empty() else ""
		if id != "" and int(m.X(id)["g"]) > 0:
			ordine.append("D")
		for g in ctx.umani:
			if g != f:
				ordine.append(g)
		ordine += [r, "D"]
	for g in ordine:
		if g in vals:
			return g
	return vals[0]


static func _risp_cavalleria(ctx: Contesto, f: String):
	var x: Dictionary = ctx.q.get("x", {})
	if int(x.get("usate", 0)) >= int(CAV_MAX.get(f, 3)):
		return "fine"
	var miei: Array = x.get("miei", [])
	var suoi: Array = x.get("suoi", [])
	var cap_mio := int(x.get("cap_mio", 0))
	var cap_suo := int(x.get("cap_suo", 0))
	if f == "D":
		# solo Carica, quando trasforma un mancato in un colpo
		for i in miei.size():
			var v := int(miei[i])
			if v == cap_mio + 1 and v - 1 >= 1 and ctx.ha("c%d" % i):
				return "c%d" % i
		return "fine"
	# Bahmani e Vijayanagara: solo Schermo, quando toglie un colpo avversario
	for i in suoi.size():
		var v := int(suoi[i])
		if v != 1 and v < 6 and v <= cap_suo and ctx.ha("s%d" % i):
			return "s%d" % i
	return "fine"


static func _risp_perdite(ctx: Contesto, f: String):
	var vals := ctx.valori()
	# perdite del difensore: chiavi dei pezzi; dell'attaccante: "spazio:chiave"
	for k in PRIO_MIEI.get(f, ["m"]) + ["m"]:
		for v in vals:
			var kk: String = str(v).get_slice(":", 1) if ":" in str(v) else str(v)
			if kk == k:
				return v
	return vals[0]


static func _risp_rimuovi_avv(ctx: Contesto, f: String):
	var vals := ctx.valori()
	if "D" in ctx.umani and "g" in vals:
		return "g"
	for k in PRIO_AVV:
		if k in vals:
			return k
	return "no" if "no" in vals else vals[0]


## Campagna: destinazione dalla tabella, origine con più Unità, percorso più breve.
static func _risp_campagna(ctx: Contesto, f: String, tag: String):
	var m := ctx.m
	var x: Dictionary = ctx.q.get("x", {})
	var solo_prov: bool = ctx.base.get("coda", [{}])[0].get("t", "") == "succ" if not (ctx.base.get("coda", []) as Array).is_empty() else false
	var ammesso := func(id): return not solo_prov or m.provincia(id) or id == "delhi"
	match tag:
		"camp_da":
			var dest := _dest_campagna(m, f, ctx, ammesso)
			var cand := ctx.valori().filter(func(v): return v is String and m.SP.has(v) and v != dest and _dist(m, v, dest, ammesso) <= 3)
			if dest == "" or cand.is_empty():
				return "fine"
			cand.sort_custom(func(a, b): return _mobili(m, "D", a) > _mobili(m, "D", b))
			if _mobili(m, "D", cand[0]) <= 0:
				return "fine"
			m.s["tmp"]["camp_dest_bot"] = dest
			return cand[0]
		"camp_n":
			var da: String = x.get("da", "")
			var k: String = x.get("k", "t")
			if k == "g":
				return 0
			return clamp(_mobili(m, "D", da), 0, int(ctx.valori()[-1]))
		"camp_passo":
			var dest: String = str(m.s["tmp"].get("camp_dest_bot", ""))
			var qui: String = str(m.s["tmp"].get("camp_qui", ""))
			if dest == "" or qui == dest:
				return "fine"
			var best = "fine"
			var bd := 99
			for v in ctx.valori():
				if v is String and m.SP.has(v):
					var d := _dist(m, v, dest, ammesso)
					if d < bd:
						bd = d
						best = v
			return best
	return "no"


static func _dest_campagna(m: Motore, f: String, ctx: Contesto, ammesso: Callable) -> String:
	var cand: Array = []
	for id in m.ordine:
		if ammesso.call(id):
			cand.append(id)
	return scegli(m, f, "campagna", cand, ctx.umani, ctx.rng("campagna"))


static func _dist(m: Motore, a: String, b: String, ammesso: Callable) -> int:
	if a == b:
		return 0
	var visti := {a: 0}
	var coda := [a]
	while not coda.is_empty():
		var c: String = coda.pop_front()
		for n in m.adiacenti(c):
			if visti.has(n) or not ammesso.call(n):
				continue
			visti[n] = int(visti[c]) + 1
			if n == b:
				return visti[n]
			coda.append(n)
	return 99


## Carte delle Invasioni mongole (O e OO).
static func _risp_mongoli(ctx: Contesto, f: String, tag: String):
	var b := _motore(ctx.base)
	var m := ctx.m
	var piano := _piano_mongoli(b, ctx)
	match tag:
		"mongolo":
			var i := 0 if ctx.q["testo"].contains("1 di 2") else 1
			var scelta: String = piano[i] if i < piano.size() else ""
			if scelta == "":
				scelta = _oo(m, ctx, i)
			if ctx.ha(scelta):
				return scelta
			return _oo(m, ctx, i)
		"avanza":
			var dove: String = str(piano[2]) if piano.size() > 2 else ""
			if dove == "delhi" and ctx.ha("punjab"):
				return "punjab"
			if ctx.ha("passi"):
				return "passi"
			return ctx.valori()[0]
		"n_avanza":
			return ctx.valori()[-1]
	return ctx.ripiego()


static func _piano_mongoli(b: Motore, _ctx: Contesto) -> Array:
	var dm := int(b.X("delhi")["m"]) + int(b.X("punjab")["m"])
	if int(b.X("punjab")["m"]) > 0 and dm - int(b.X("delhi")["t"]) - int(b.X("delhi")["g"]) >= 3:
		return ["avanza", "sac_delhi", "delhi"]
	var pm := int(b.X("punjab")["m"]) + int(b.X("passi")["m"])
	if int(b.X("passi")["m"]) > 0 and pm - int(b.X("punjab")["t"]) - int(b.X("punjab")["g"]) >= 3:
		return ["avanza", "sac_punjab", "punjab"]
	return []


static func _oo(m: Motore, ctx: Contesto, i: int) -> String:
	var ris_d := int(m.s["ris"]["D"])
	for id in ["delhi", "punjab", "passi"]:
		if int(m.X(id)["m"]) >= 4 and int(m.X(id)["t"]) <= 2 and (id != "passi" or ris_d >= 7):
			return "sac_" + id
	var r := ctx.rng("oo%d" % i)
	if r.randi_range(1, 6) < int(m.X("delhi")["m"]):
		return "sac_delhi"
	if r.randi_range(1, 6) < int(m.X("punjab")["m"]):
		return "sac_punjab"
	if r.randi_range(1, 6) < int(m.X("passi")["m"]) and ris_d >= 7:
		return "sac_passi"
	if ctx.ha("ammassa"):
		return "ammassa"
	for v in ["sac_delhi", "sac_punjab", "sac_passi", "avanza"]:
		if ctx.ha(v):
			return v
	return ctx.valori()[0]


## Signori del Deccan: spendere 3 Risorse per spostare l'Influenza (schede, carta Successione).
static func _risp_signori(ctx: Contesto, f: String):
	var m := ctx.m
	var ris := int(m.s["ris"][f])
	var limite := 5 if f == "D" else 3
	if ris - 3 < limite:
		return "no"
	var r := ctx.rng("signori")
	if f == "D":
		var g: String = "B" if m.vp("B") > m.vp("V") else ("V" if m.vp("V") > m.vp("B") else ["B", "V"][r.randi() % 2])
		if ctx.ha(g + "-"):
			return g + "-"
		var h := m.altra_bv(g)
		return (h + "-") if ctx.ha(h + "-") else "no"
	var rv := m.altra_bv(f)
	if ctx.umani == ["D"]:
		return (f + "+") if ctx.ha(f + "+") else "no"
	if ctx.umani == [rv]:
		if ctx.ha(rv + "-"):
			return rv + "-"
		return (f + "+") if ctx.ha(f + "+") else "no"
	var ops: Array = []
	if ctx.ha(f + "+"):
		ops.append(f + "+")
	if ctx.ha(rv + "-"):
		ops.append(rv + "-")
	return ops[r.randi() % ops.size()] if not ops.is_empty() else "no"


## Domande senza una regola delle schede (dettagli degli Eventi): breve simulazione con il punteggio del bot.
static func _ripiego_simulato(ctx: Contesto, f: String):
	var best = null
	var bv := -INF
	var vals := ctx.valori()
	if vals.size() == 1:
		return vals[0]
	for v in vals:
		var tot := 0.0
		for k in 2:
			var mm := Motore.new()
			mm.usa_dati()
			mm.s = ctx.base.duplicate(true)
			var r := RandomNumberGenerator.new()
			r.seed = hash([int(ctx.base["seme"]), int(ctx.base["atto_n"]), ctx.ans.size(), str(v), k])
			mm.autorisposta = func(_x, qq): return IA.politica_casuale(_x, qq, r)
			mm.esegui(ctx.ans + [v])
			tot += punteggio(mm, f, ctx.umani)
		if tot > bv:
			bv = tot
			best = v
	return best
