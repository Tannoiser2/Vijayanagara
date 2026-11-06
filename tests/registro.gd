## Stampa il registro di una partita IA contro IA. Uso: godot --headless -s res://tests/registro.gd -- <seme> <forza>
extends SceneTree

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var seme := int(a[0]) if a.size() > 0 else 5
	var forza := int(a[1]) if a.size() > 1 else 30
	var rng := RandomNumberGenerator.new()
	rng.seed = seme
	var m := Motore.new()
	m.nuova(seme)
	var piano: Array = []
	var atti := 0
	while not m.finita() and atti < 400:
		var base: Dictionary = m.s.duplicate(true)
		var ans: Array = []
		while not m.prova(base, ans):
			ans.append(IA.rispondi(base, ans, m.need, piano, rng, forza))
		for l in m.registro:
			print(l)
		atti += 1
		if m.tipo_carta(m.s["carta"]) == "evento" and m.atto_corrente().is_empty():
			pass
	print("VP finali D %d B %d V %d" % [m.vp("D"), m.vp("B"), m.vp("V")])
	quit(0)
