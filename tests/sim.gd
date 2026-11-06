## Partite automatiche. Uso: godot --headless -s res://tests/sim.gd -- <partite> <modo: casuale|ia> [forza]
extends SceneTree

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var n := int(a[0]) if a.size() > 0 else 3
	var modo := a[1] if a.size() > 1 else "casuale"
	var forza := int(a[2]) if a.size() > 2 else 12
	var vitt := {}
	var t0 := Time.get_ticks_msec()
	for p in n:
		var rng := RandomNumberGenerator.new()
		rng.seed = 1000 + p
		var m := Motore.new()
		m.nuova(77 + p * 13)
		var atti := 0
		var piano: Array = []
		while not m.finita() and atti < 4000:
			var base: Dictionary = m.s.duplicate(true)
			var ans: Array = []
			var giri := 0
			while true:
				giri += 1
				var fatto := m.prova(base, ans)
				if fatto:
					break
				if giri > 3000:
					push_error("atto bloccato: " + str(m.need))
					quit(1)
					return
				var v
				if modo == "ia":
					v = IA.rispondi(base, ans, m.need, piano, rng, forza)
				else:
					v = IA.politica_casuale(m, m.need, rng)
				ans.append(v)
			atti += 1
		var fine: Dictionary = m.s["fine"]
		print("partita %d: atti %d, %s vince=%s" % [p, atti, fine.get("m", "NON FINITA"), str(fine.get("v", []))])
		for f in fine.get("v", []):
			vitt[f] = int(vitt.get(f, 0)) + 1
	print("vittorie: ", vitt, " in ", (Time.get_ticks_msec() - t0) / 1000.0, " s")
	quit(0)
