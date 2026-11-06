## Giocatore artificiale a simulazioni (come in The British Way, esteso a tre fazioni).
## 1) prova molte giocate casuali dell'atto in corso su copie dello stato (con dadi diversi: non "vede" il futuro);
## 2) riprova le migliori con altri dadi e, se subito dopo tocca a un'altra fazione sulla stessa carta,
##    simula anche la sua risposta (scelta per il suo interesse); 3) sceglie la giocata che regge meglio.
class_name IA
extends RefCounted

const PASSIVE := ["fine", "passa", "no", "nessuno", "nessuna"]


static func politica_casuale(_m, q: Dictionary, rng: RandomNumberGenerator):
	var opz: Array = q["opz"]
	var x: Dictionary = q.get("x", {})
	var tag: String = str(x.get("tag", ""))
	var pesi: Array = []
	var tot := 0.0
	for o in opz:
		var w := 1.0
		var v = o["v"]
		if v is String and v in PASSIVE:
			w = 0.35
		if x.get("num", false):
			w = 1.0 + float(v) * 0.6
		if v is String and v == "si":
			w = 1.5
		if tag == "casella":
			w = {"cd": 1.6, "ec": 1.4, "limitata": 0.6, "passa": 0.35}.get(v, 1.0)
		if tag == "cavalleria" and v is String and v != "fine":
			w = 0.8
		if tag == "spazio_cmd" and v is String and v == "fine":
			w = 0.45
		pesi.append(w)
		tot += w
	var r := rng.randf() * tot
	for i in opz.size():
		r -= pesi[i]
		if r <= 0.0:
			return opz[i]["v"]
	return opz[-1]["v"]


static func _simula(base: Dictionary, risposte: Array, rng: RandomNumberGenerator) -> Motore:
	var m := Motore.new()
	m.usa_dati()
	m.s = base.duplicate(true)
	m.s["rs"] = 1 + rng.randi() % 2147483640
	m.autorisposta = func(mm, q): return politica_casuale(mm, q, rng)
	m.esegui(risposte)
	return m


static func _valore_con_replica(m: Motore, f: String, rng: RandomNumberGenerator, n_rep: int) -> float:
	var a := m.atto_corrente()
	if a.is_empty() or n_rep <= 0 or a.get("t", "") != "turno" or a.get("f", "") == f:
		return m.valuta(f)
	var altro: String = a["f"]
	var miglior_altro := -INF
	var val_f := m.valuta(f)
	var stato: Dictionary = m.s
	for k in n_rep:
		var r := _simula(stato, [], rng)
		var va := r.valuta(altro)
		if va > miglior_altro:
			miglior_altro = va
			val_f = r.valuta(f)
	return val_f


static func pianifica(base: Dictionary, prefisso: Array, f: String, n_sim: int, rng: RandomNumberGenerator) -> Array:
	var candidati: Array = []
	var visti := {}
	for k in n_sim:
		var m := _simula(base, prefisso, rng)
		var ans := m.risposte_usate()
		var chiave := str(ans)
		var v := m.valuta(f) + rng.randf() * 0.3
		if visti.has(chiave):
			var c: Array = candidati[visti[chiave]]
			c[0] = max(float(c[0]), v)
			continue
		visti[chiave] = candidati.size()
		candidati.append([v, ans])
	if candidati.is_empty():
		return prefisso.duplicate()
	candidati.sort_custom(func(a, b): return a[0] > b[0])
	var top: Array = candidati.slice(0, min(5, candidati.size()))
	if n_sim < 20 or top.size() == 1:
		return top[0][1]
	var n_rep := 6 if n_sim >= 60 else 3
	var best := -INF
	var best_ans: Array = top[0][1]
	for c in top:
		var tot := 0.0
		var prove := 3
		for r in prove:
			var m := _simula(base, c[1], rng)
			tot += _valore_con_replica(m, f, rng, n_rep)
		var media := tot / prove
		if media > best:
			best = media
			best_ans = c[1]
	return best_ans


static func rispondi(base: Dictionary, risposte: Array, q: Dictionary, piano: Array, rng: RandomNumberGenerator, n_sim: int = 28):
	var i := risposte.size()
	var valido := func(v):
		for o in q["opz"]:
			if str(o["v"]) == str(v):
				return true
		return false
	if piano.size() > i and piano.slice(0, i) == risposte and valido.call(piano[i]):
		return piano[i]
	var nuovo := pianifica(base, risposte, q["f"], n_sim if i == 0 else max(10, n_sim / 3), rng)
	piano.clear()
	piano.append_array(nuovo)
	if nuovo.size() > i and valido.call(nuovo[i]):
		return nuovo[i]
	return politica_casuale(null, q, rng)
