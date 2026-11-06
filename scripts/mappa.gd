## Vista della mappa: tabellone originale (tradotto), pezzi di legno disegnati, segnalini originali.
## Rotella o +/− per lo zoom, trascinamento per spostare, click sugli spazi evidenziati per sceglierli.
class_name MappaView
extends Control

signal spazio_cliccato(id: String)
signal spazio_sopra(id: String)

var m: Motore
var tex: Texture2D
var zoom := 1.0
var off := Vector2.ZERO
var candidati: Array = []
var selezionati: Array = []
var sopra := ""
var _trascina := false
var _press_pos := Vector2.ZERO
var _t := 0.0
var _seg: Dictionary = {}
var ultimo_cambiato: Dictionary = {}

const COL := {"t": Color("a9aba2"), "m": Color("a8291f"), "g": Color("222222"), "q": Color("1d1d1d"),
	"ao": Color("1aa3a0"), "ar": Color("1aa3a0"), "f": Color("1aa3a0"),
	"ro": Color("e7b21e"), "rr": Color("e7b21e"), "tp": Color("e7b21e")}


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	for n in ["tributo", "controllo_D", "controllo_B", "controllo_V", "vittoria_D", "vittoria_B", "vittoria_V",
			"influenza_B", "influenza_V", "cavalleria", "cavalleria_mongola"]:
		_seg[n] = load("res://assets/segnalini/%s.png" % n)
	tex = load("res://assets/mappa/tabellone.webp")
	resized.connect(adatta)


func imposta(motore: Motore) -> void:
	m = motore
	ultimo_cambiato.clear()
	candidati = []
	selezionati = []
	sopra = ""
	adatta()


func adatta() -> void:
	if tex == null or size.x < 10:
		return
	var ts := tex.get_size()
	zoom = min(size.x / ts.x, size.y / ts.y)
	off = (size - ts * zoom) * 0.5
	queue_redraw()


func zoom_a(z: float, centro: Vector2) -> void:
	if tex == null:
		return
	var ts := tex.get_size()
	var minz: float = min(size.x / ts.x, size.y / ts.y) * 0.9
	var nz: float = clamp(z, minz, minz * 5.0)
	var p := (centro - off) / zoom
	zoom = nz
	off = centro - p * zoom
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if not candidati.is_empty() or not ultimo_cambiato.is_empty():
		queue_redraw()


func pt(x: float, y: float) -> Vector2:
	return off + Vector2(x, y) * tex.get_size() * zoom


func pos_spazio(id: String) -> Vector2:
	var sp: Dictionary = m.SP[id]
	return pt(float(sp["x"]), float(sp["y"]))


func _gui_input(e: InputEvent) -> void:
	if m == null:
		return
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			zoom_a(zoom * 1.12, e.position)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			zoom_a(zoom / 1.12, e.position)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_trascina = true
				_press_pos = e.position
			else:
				_trascina = false
				if e.position.distance_to(_press_pos) < 8:
					var id := spazio_a(e.position)
					if id != "":
						spazio_cliccato.emit(id)
	elif e is InputEventMouseMotion:
		if _trascina and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) and e.position.distance_to(_press_pos) >= 8:
			off += e.relative
			queue_redraw()
		var id := spazio_a(e.position)
		if id != sopra:
			sopra = id
			spazio_sopra.emit(id)
			queue_redraw()
	elif e is InputEventMagnifyGesture:
		zoom_a(zoom * e.factor, e.position)
	elif e is InputEventPanGesture:
		off -= e.delta * 8.0
		queue_redraw()


## Spazio sotto il punto: Delhi è il cerchio centrale, poi il più vicino (preferendo i candidati).
func spazio_a(p: Vector2) -> String:
	if m == null or tex == null:
		return ""
	var ts := tex.get_size()
	var cd := pt(645.0 / 1275.0, 375.0 / 1650.0)
	if cd.distance_to(p) < 0.115 * ts.x * zoom:
		return "delhi"
	var best := ""
	var bd := 1e9
	var lim := 0.16 * ts.x * zoom
	for id in m.ordine:
		if id == "delhi":
			continue
		var sp: Dictionary = m.SP[id]
		var c := pos_spazio(id)
		if sp.has("mx"):
			c = (c + pt(float(sp["mx"]), float(sp["my"]))) * 0.5
		var d := c.distance_to(p)
		if not candidati.is_empty() and id in candidati:
			d *= 0.75
		if d < bd and d < lim:
			bd = d
			best = id
	return best


# ---------------------------------------------------------------- disegno

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tema.BG)
	if m == null or tex == null:
		return
	var ts := tex.get_size()
	draw_texture_rect(tex, Rect2(off, ts * zoom), false)
	var u: float = max(50.0 * zoom * (ts.x / 2550.0), 16.0)
	_disegna_tracciati(u)
	for id in m.ordine:
		_disegna_spazio(id, u)
	for id in candidati:
		var c := _centro_evid(id)
		var a := 0.55 + 0.35 * sin(_t * 5.0)
		var r := u * (5.2 if id == "delhi" else 2.6)
		draw_arc(c, r, 0, TAU, 56, Color(Tema.GOLD_HI, a), max(3.0, u * 0.16), true)
		draw_arc(c, r + u * 0.22, 0, TAU, 56, Color(0, 0, 0, a * 0.5), 2.0, true)
	var scaduti: Array = []
	for id in ultimo_cambiato:
		var eta: float = _t - float(ultimo_cambiato[id])
		if eta > 3.0:
			scaduti.append(id)
			continue
		var al := (1.0 - eta / 3.0) * (0.6 + 0.4 * sin(_t * 8.0))
		draw_arc(_centro_evid(id), u * 2.9, 0, TAU, 40, Color(1, 1, 1, al), max(2.0, u * 0.12), true)
	for id in scaduti:
		ultimo_cambiato.erase(id)
	for id in selezionati:
		draw_arc(_centro_evid(id), u * 2.3, 0, TAU, 40, Color.WHITE, 3.0, true)
	if sopra != "":
		var p := _centro_evid(sopra)
		var f = Tema.titolo()
		var fs := int(clamp(u * 0.62, 14, 26))
		var nome: String = m.nome_sp(sopra)
		var w := f.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var q := p + Vector2(-w * 0.5 - 8, -u * 3.4)
		draw_rect(Rect2(q, Vector2(w + 16, fs + 12)), Color(0.08, 0.06, 0.04, 0.85))
		draw_string(f, q + Vector2(8, fs + 3), nome, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tema.GOLD_HI)


func _centro_evid(id: String) -> Vector2:
	if id == "delhi":
		return pt(645.0 / 1275.0, 375.0 / 1650.0)
	var sp: Dictionary = m.SP[id]
	var c := pos_spazio(id)
	if sp.has("mx"):
		return (c + pt(float(sp["mx"]), float(sp["my"]))) * 0.5
	return c


func _segnalino(k: String, c: Vector2, lato: float) -> void:
	var t: Texture2D = _seg.get(k, null)
	if t == null:
		return
	var r := Rect2(c - Vector2(lato, lato) * 0.5, Vector2(lato, lato))
	draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.4))
	draw_texture_rect(t, r, false)
	draw_rect(r, Color(0, 0, 0, 0.6), false, 1.0)


func _disegna_tracciati(u: float) -> void:
	var tb: Dictionary = m.D["tabellone"]
	var tr: Array = tb["traccia"]
	# segnalini di Vittoria e cilindri delle Risorse sul tracciato numerato
	var occ := {}
	for f in m.FAZ:
		var v: int = clamp(m.vp(f), 0, 24)
		var n := int(occ.get(v, 0))
		occ[v] = n + 1
		var p := pt(float(tr[v][0]), float(tr[v][1])) + Vector2(n * u * 0.45, n * u * 0.45)
		_segnalino("vittoria_" + f, p, u * 1.15)
	var occ2 := {}
	for f in m.FAZ:
		var v: int = clamp(int(m.s["ris"][f]), 0, 24)
		var n := int(occ2.get(v, 0))
		occ2[v] = n + 1
		var p := pt(float(tr[v][0]), float(tr[v][1])) + Vector2(-u * 0.55 + n * u * 0.5, u * 0.62)
		_cilindro(p, Tema.FAZ[f].lightened(0.1), u * 0.36)
	# Influenza nel Deccan
	for f in ["B", "V"]:
		var caselle: Array = tb["infl"][f]
		var v := int(m.s["infl"][f])
		var c: Array = caselle[v]
		_segnalino("influenza_" + f, pt(float(c[0]), float(c[1])), u * 1.35)
		# Unità ancora sul tracciato
		for lv in m.s["slot"][f]:
			var n := int(m.s["slot"][f][lv])
			if n <= 0:
				continue
			var cc: Array = caselle[int(lv)]
			var q := pt(float(cc[0]), float(cc[1]))
			for i in n:
				_pezzo(q + Vector2((i - 0.5) * u * 0.8, u * 0.15), "ao" if f == "B" else "ro", u * 0.7)
	# cilindri di idoneità nella Sequenza di gioco
	var seq: Dictionary = tb["seq"]
	var posti := {}
	for f in m.FAZ:
		var dove := "elig" if m.s["elig"][f] else "inelig"
		for b in ["cd", "ec"]:
			if m.s["scelte"].get(b, "") == f:
				dove = b
		posti[f] = dove
	var conta := {}
	for f in m.FAZ:
		var d: String = posti[f]
		var n := int(conta.get(d, 0))
		conta[d] = n + 1
		var c: Array = seq[d]
		_cilindro(pt(float(c[0]), float(c[1])) + Vector2(0, (n - 1) * u * 0.95), Tema.FAZ[f].lightened(0.1), u * 0.42)
	# Disponibili nei riquadri delle fazioni e Cavalleria
	var box: Dictionary = tb["box"]
	var gruppi := {"M": [["m", m.disp("m")]], "D": [["t", m.disp("t")], ["g", m.disp("g")], ["q", m.disp("q")]],
		"B": [["ao", m.disp("a")], ["f", m.disp("f")]], "V": [["ro", m.disp("r")], ["tp", m.disp("tp")]]}
	for f in gruppi:
		var c: Array = box[f]
		var base := pt(float(c[0]), float(c[1]))
		var xx: float = base.x - u * 1.6 * (gruppi[f].size() - 1)
		for g in gruppi[f]:
			if int(g[1]) > 0:
				_pezzo(Vector2(xx, base.y), g[0], u)
				_numero(Vector2(xx + u * 0.6, base.y), int(g[1]), u)
			xx += u * 3.2
		if f in m.FAZ and int(m.s["cav"][f]) > 0:
			var q := base + Vector2(u * 2.6 * (gruppi[f].size() - 1) + u * 1.2, -u * 1.6)
			_segnalino("cavalleria", q, u * 1.1)
			_numero(q + Vector2(u * 0.6, 0), int(m.s["cav"][f]), u)


func _cilindro(c: Vector2, col: Color, r: float) -> void:
	draw_circle(c + Vector2(2, 3), r, Color(0, 0, 0, 0.35))
	draw_circle(c, r, col)
	draw_arc(c, r, 0, TAU, 24, col.darkened(0.55), 1.5, true)
	draw_circle(c, r * 0.4, col.lightened(0.3))


func _disegna_spazio(id: String, u: float) -> void:
	var x: Dictionary = m.X(id)
	var sp: Dictionary = m.SP[id]
	# segnalino di Tributo o Controllo sul cerchio della Provincia
	if sp.has("mx"):
		var c := pt(float(sp["mx"]), float(sp["my"]))
		if x["trib"]:
			_segnalino("tributo", c, u * 1.45)
		elif x["ctrl"] != "":
			_segnalino("controllo_" + x["ctrl"], c, u * 1.45)
	var righe: Array = []
	for f in ["D", "B", "V", "M"]:
		var r: Array = []
		for k in m.PEZZI_DI[f]:
			if int(x[k]) > 0:
				r.append([k, int(x[k])])
		if not r.is_empty():
			righe.append(r)
	var c := pos_spazio(id)
	var y := c.y - (righe.size() - 1) * u * 0.6
	for riga in righe:
		var w := 0.0
		for g in riga:
			w += _larghezza(g[1], u) + u * 0.3
		var xx := c.x - w * 0.5
		for g in riga:
			var gw = _larghezza(g[1], u)
			_gruppo(Vector2(xx + gw * 0.5, y), g[0], g[1], u)
			xx += gw + u * 0.3
		y += u * 1.2


func _larghezza(n: int, u: float) -> float:
	var vis: int = n if n <= 3 else 1
	return u * vis + (u * 0.12) * (vis - 1) + (u * 0.95 if n > 3 else 0.0)


func _gruppo(centro: Vector2, k: String, n: int, u: float) -> void:
	var vis: int = n if n <= 3 else 1
	var tot := u * vis + u * 0.12 * (vis - 1)
	var x := centro.x - tot * 0.5 - (u * 0.47 if n > 3 else 0.0) + u * 0.5
	for i in vis:
		_pezzo(Vector2(x, centro.y), k, u)
		x += u * 1.12
	if n > 3:
		_numero(Vector2(x - u * 0.5, centro.y), n, u)


func _numero(p: Vector2, n: int, u: float) -> void:
	var f = Tema.ui_heavy()
	var fs := int(clamp(u * 0.85, 12, 32))
	var s := "×%d" % n
	draw_string_outline(f, p + Vector2(0, fs * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.85))
	draw_string(f, p + Vector2(0, fs * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


func _pezzo(c: Vector2, k: String, u: float) -> void:
	var h := u * 0.5
	var col: Color = COL.get(k, Color.WHITE)
	match k:
		"t", "m":
			var d := u * 0.22
			var front := Rect2(c - Vector2(h, h) + Vector2(0, d * 0.5), Vector2(u - d, u - d))
			draw_rect(Rect2(front.position + Vector2(2, 3), front.size), Color(0, 0, 0, 0.35))
			draw_rect(front, col)
			draw_colored_polygon(PackedVector2Array([front.position, front.position + Vector2(d, -d), front.position + Vector2(front.size.x + d, -d), front.position + Vector2(front.size.x, 0)]), col.lightened(0.3))
			draw_colored_polygon(PackedVector2Array([front.position + Vector2(front.size.x, 0), front.position + Vector2(front.size.x + d, -d), front.position + Vector2(front.size.x + d, front.size.y - d), front.position + front.size]), col.darkened(0.3))
			draw_rect(front, col.darkened(0.5), false, 1.0)
		"g", "ao", "ar", "ro", "rr":
			# cilindro esagonale: lato e faccia superiore; i ribelli mostrano il simbolo inciso
			var top := PackedVector2Array()
			var lato := PackedVector2Array()
			for i in 6:
				var ang := i * TAU / 6.0
				top.append(c + Vector2(cos(ang) * h * 1.02, sin(ang) * h * 0.62 - h * 0.25))
			for i in 6:
				var ang := i * TAU / 6.0
				lato.append(c + Vector2(cos(ang) * h * 1.02, sin(ang) * h * 0.62 + h * 0.3))
			var ombra := PackedVector2Array()
			for p in lato:
				ombra.append(p + Vector2(2, 3))
			draw_colored_polygon(ombra, Color(0, 0, 0, 0.35))
			draw_colored_polygon(lato, col.darkened(0.35))
			draw_rect(Rect2(c + Vector2(-h * 1.02, -h * 0.25), Vector2(h * 2.04, h * 0.55)), col.darkened(0.2))
			draw_colored_polygon(top, col)
			var t2 := top.duplicate()
			t2.append(top[0])
			draw_polyline(t2, col.darkened(0.55), 1.2, true)
			var cs := c + Vector2(0, -h * 0.25)
			if k == "ar":
				draw_circle(cs, h * 0.36, Color("f2fffd"))
				draw_circle(cs + Vector2(h * 0.15, -h * 0.05), h * 0.3, col)
			elif k == "rr":
				for i in 8:
					var a := i * TAU / 8.0
					draw_line(cs, cs + Vector2(cos(a), sin(a) * 0.62) * h * 0.5, Color("c43d12"), max(1.5, h * 0.12))
				draw_circle(cs, h * 0.22, Color("e2561b"))
		"q", "f", "tp":
			var r := Vector2(h * 1.1, h * 0.55)
			_ellisse(c + Vector2(2, 5), r, Color(0, 0, 0, 0.35))
			_ellisse(c + Vector2(0, h * 0.28), r, col.darkened(0.4))
			_ellisse(c, r, col)
			_ellisse(c, r * 0.6, col.lightened(0.18))


func _ellisse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := i * TAU / 28.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)
