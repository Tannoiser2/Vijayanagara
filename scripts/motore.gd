## Motore completo con la valutazione delle posizioni usata dall'IA (tre fazioni, ognuna contro le altre due).
class_name Motore
extends Eventi


## Carte che mancano a Timur (per pesare il futuro: più è vicino, più contano i punti attuali).
func carte_alla_fine() -> int:
	var n := 0
	for c in s["mazzo"]:
		n += 1
		if c == "T2":
			break
	return n


## Minaccia mongola sul Sultanato: Invasori vicini a Delhi contro le difese.
func minaccia_mongola() -> float:
	var m := float(X("passi")["m"]) * 0.4 + float(X("punjab")["m"]) * 0.8 + float(X("delhi")["m"]) * 1.4
	var dif := float(n_unita("delhi", "D")) * 0.5 + float(n_unita("punjab", "D")) * 0.3 + float(n_unita("passi", "D")) * 0.2
	return max(0.0, m - dif)


## Punteggio "di posizione" di una fazione: punti attuali più potenziale.
func potenziale(f: String) -> float:
	var resto := carte_alla_fine()
	var peso_fut: float = clamp(float(resto) / 35.0, 0.0, 1.0)
	var v := float(vp(f)) * 10.0
	v += float(s["ris"][f]) * (0.9 + peso_fut * 0.5)
	v += float(s["cav"][f]) * 1.6
	match f:
		"D":
			if not finita():
				v += float(max(-3, 3 - int(X("delhi")["m"]))) * 10.0 * (1.0 - peso_fut * 0.6)
				v -= minaccia_mongola() * (4.0 + (1.0 - peso_fut) * 6.0)
			for id in ordine:
				var x := X(id)
				v += float(x["t"]) * 0.9 + float(x["g"]) * 2.0 + float(x["q"]) * 2.5
				if provincia(id) and x["trib"]:
					# Tributarie minacciate: dove gli insorti sono forti rischiano la Ribellione
					var rival := n_pezzi(id, "B") + n_pezzi(id, "V")
					var mio := n_pezzi(id, "D")
					if rival > mio:
						v -= float(prosp(id)) * (4.0 if s["dinastia"] == "tughlaq" else 1.5) * (0.4 + peso_fut)
				elif provincia(id) and x["ctrl"] == "D":
					v += float(prosp(id)) * (4.0 if int(x["g"]) > 0 else 2.0)
		"B", "V":
			var st := "f" if f == "B" else "tp"
			for id in ordine:
				if not provincia(id):
					continue
				var x := X(id)
				var mie := n_unita(id, f)
				v += float(mie) * 1.3 + float(x[st]) * 2.0
				v += float(ribelli(id, f)) * -0.15
				if x["trib"]:
					var rival := 0
					for g in FAZ:
						if g != f:
							rival += n_pezzi(id, g)
					if n_pezzi(id, f) > rival:
						# pronta a ribellarsi
						v += float(prosp(id)) * (5.0 if s["dinastia"] == "tughlaq" else 2.0) * (0.3 + peso_fut)
				elif x["ctrl"] == "":
					v += float(n_pezzi(id, f)) * 0.6
			v += float(s["infl"][f]) * 2.0
			v += float(disp("a" if f == "B" else "r")) * 0.3
	return v


func valuta(f: String) -> float:
	if finita():
		var p: Dictionary = s["fine"]["punti"]
		var vinc: Array = s["fine"]["v"]
		var base := float(p[f]) * 10.0
		var mx := -999.0
		for g in FAZ:
			if g != f:
				mx = max(mx, float(p[g]))
		var bonus := 0.0
		if f in vinc:
			bonus = 2000.0 / float(vinc.size())
		return bonus + (base - mx * 10.0)
	var mio := potenziale(f)
	var altri: Array = []
	for g in FAZ:
		if g != f:
			altri.append(potenziale(g))
	altri.sort()
	# conta soprattutto il rivale più forte
	return mio - float(altri[1]) * 0.7 - float(altri[0]) * 0.3
