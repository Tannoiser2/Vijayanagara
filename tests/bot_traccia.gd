## Traccia una partita di soli bot: tempo per domanda e domande lente.
extends SceneTree
func _init() -> void:
	var m := Motore.new()
	m.nuova(91)
	var atti := 0
	var t_tot := {}
	var n_tot := {}
	var t0 := Time.get_ticks_msec()
	while not m.finita() and atti < 400 and Time.get_ticks_msec() - t0 < 150000:
		var base: Dictionary = m.s.duplicate(true)
		var ans: Array = []
		var giri := 0
		while not m.prova(base, ans):
			giri += 1
			if giri > 400:
				print("BLOCCATO atto ", atti, " ", m.need["f"], " ", m.need["x"].get("tag",""), " ", m.need["testo"], " ans ", ans.slice(-12))
				quit(1)
				return
			var t1 := Time.get_ticks_msec()
			var tag: String = str(m.need["x"].get("tag", ""))
			printerr("Q ", atti, " ", m.need["f"], " ", tag, " | ", m.need["testo"].substr(0, 60))
			var v = Bot.rispondi(base, ans, m.need, m, [])
			printerr("  -> ", v)
			var dt := Time.get_ticks_msec() - t1
			t_tot[tag] = int(t_tot.get(tag, 0)) + dt
			n_tot[tag] = int(n_tot.get(tag, 0)) + 1
			ans.append(v)
		atti += 1
	print("atti ", atti, " finita ", m.finita(), " ms ", Time.get_ticks_msec() - t0)
	for k in t_tot:
		print(k, " n=", n_tot[k], " ms=", t_tot[k])
	print(m.s["fine"].get("m", ""))
	quit(0)
