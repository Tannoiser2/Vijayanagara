## Schermata principale: menu iniziale e partita (mappa, pannello azione, registro).
## Gestisce chi risponde alle domande del motore: giocatore locale, IA o giocatore online.
extends Control

const FILE_SALVA := "user://vijayanagara_partita.json"
const ORDINE_F := ["D", "B", "V"]

var m: Motore
var seme := 0
var opz := {}
var atti: Array = []
var base: Dictionary = {}
var ans: Array = []
var controllo := {"D": "umano", "B": "ia", "V": "ia"}
var scelta_menu := {"D": "umano", "B": "ia", "V": "ia"}
var piano: Array = []
var rng := RandomNumberGenerator.new()
var registro_fisso: Array = []
var storia: Array = []
var ia_in_corso := false
var ia_forza := 100
var rete: Rete
var online := false
var host := false
var stanza := ""
var posto := -1
var net_k := 0
var net_inviati := {}
var _poll_t := 0.0
var _attesa_stanza := false

# nodi
var menu: Control
var partita: Control
var mappa: MappaView
var chips: Dictionary = {}
var lbl_mazzo: Label
var btn_annulla: Button
var pannello: VBoxContainer
var banner: PanelContainer
var lbl_chi: Label
var lbl_domanda: Label
var box_opz: GridContainer
var carta_tex: TextureRect
var lbl_carta: Label
var riserva_box: VBoxContainer
var stato_lbl: RichTextLabel
var log_lbl: RichTextLabel
var info_lbl: Label
var fine_dlg: AcceptDialog
var carta_pop: PopupPanel
var carta_pop_tex: TextureRect
var regole_pop: AcceptDialog
var regole_txt: RichTextLabel
var menu_msg: Label
var nome_edit: LineEdit
var codice_edit: LineEdit
var tasti_ctrl: Dictionary = {}
var btn_avvia_stanza: Button
var timur_chk: CheckBox
var forza_btns: Dictionary = {}
var bot_diff := "normale"
var diff_btns: Dictionary = {}
var carta_bot_tex: TextureRect
var lbl_carta_bot: Label
var ultima_bot := {}


func _ready() -> void:
	theme = Tema.tema()
	rng.randomize()
	rete = Rete.new()
	add_child(rete)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_costruisci_menu()
	_costruisci_partita()
	partita.visible = false
	menu.visible = true
	_aggiorna_menu()


# ================================================================ MENU

func _costruisci_menu() -> void:
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var bg := ColorRect.new()
	bg.color = Tema.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu.add_child(scroll)
	var centro := CenterContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(centro)
	var riga := HBoxContainer.new()
	riga.add_theme_constant_override("separation", 26)
	centro.add_child(riga)
	var cop := TextureRect.new()
	cop.texture = load("res://assets/mappa/retro.webp")
	cop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cop.custom_minimum_size = Vector2(470, 660)
	riga.add_child(cop)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size = Vector2(760, 0)
	riga.add_child(col)
	var t := Label.new()
	t.text = "VIJAYANAGARA"
	t.add_theme_font_override("font", Tema.titolo_forte())
	t.add_theme_font_size_override("font_size", 64)
	t.add_theme_color_override("font_color", Tema.GOLD_HI)
	col.add_child(t)
	var st := Label.new()
	st.text = "Gli imperi del Deccan nell'India medievale, 1290–1398"
	st.add_theme_font_override("font", Tema.ui_it())
	st.add_theme_font_size_override("font_size", 25)
	st.add_theme_color_override("font_color", Tema.PAPER)
	col.add_child(st)
	var pan := PanelContainer.new()
	col.add_child(pan)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 9)
	pan.add_child(pv)
	pv.add_child(_lbl_carta("Partita locale", 27, true))
	var sp := _lbl_carta("Scegli chi guida ogni fazione: tu (anche in più sullo stesso schermo), l'IA a simulazioni oppure il bot ufficiale (carte azione e schede Non-Player). I Mongoli li muovono a turno Bahmani e Vijayanagara.", 16)
	sp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sp.add_theme_color_override("font_color", Tema.INK_DIM)
	pv.add_child(sp)
	for f in ORDINE_F:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 10)
		pv.add_child(r)
		var ic := TextureRect.new()
		ic.texture = Tema.icona(f)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(52, 38)
		r.add_child(ic)
		var n := _lbl_carta(Nucleo.NOMI_FAZ[f], 21, true)
		n.custom_minimum_size = Vector2(300, 0)
		r.add_child(n)
		tasti_ctrl[f] = {}
		for k in [["umano", "Tu"], ["ia", "IA"], ["bot", "Bot"]]:
			var b := Button.new()
			b.text = k[1]
			b.toggle_mode = true
			b.custom_minimum_size = Vector2(96, 38)
			Tema.tasto_carta(b)
			b.pressed.connect(_scegli_ctrl.bind(f, k[0]))
			r.add_child(b)
			tasti_ctrl[f][k[0]] = b
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 10)
	pv.add_child(r1)
	var bi := Button.new()
	bi.text = "Inizia la partita"
	bi.custom_minimum_size = Vector2(0, 48)
	bi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Tema.tasto_carta(bi, true, Color("8a5a12"))
	bi.pressed.connect(_nuova_locale.bind(false))
	r1.add_child(bi)
	var bd := Button.new()
	bd.text = "IA contro IA (dimostrazione)"
	bd.custom_minimum_size = Vector2(0, 48)
	bd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Tema.tasto_carta(bd)
	bd.pressed.connect(_nuova_locale.bind(true))
	r1.add_child(bd)
	var r1b := HBoxContainer.new()
	r1b.add_theme_constant_override("separation", 10)
	pv.add_child(r1b)
	timur_chk = CheckBox.new()
	timur_chk.text = "Variante «L'ombra di Timur»"
	timur_chk.tooltip_text = "Dopo la prima carta Timuride ogni Comando sceglie un solo spazio."
	timur_chk.add_theme_color_override("font_color", Tema.INK)
	timur_chk.add_theme_color_override("font_hover_color", Tema.INK)
	timur_chk.add_theme_color_override("font_pressed_color", Tema.INK)
	for sty in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		timur_chk.add_theme_stylebox_override(sty, StyleBoxEmpty.new())
	r1b.add_child(timur_chk)
	r1b.add_child(_lbl_carta("   Forza dell'IA:", 18))
	for k in [[40, "Rapida"], [100, "Normale"], [220, "Forte"]]:
		var b := Button.new()
		b.text = k[1]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(96, 34)
		Tema.tasto_carta(b)
		b.pressed.connect(_scegli_forza.bind(k[0]))
		r1b.add_child(b)
		forza_btns[k[0]] = b
	var r1c := HBoxContainer.new()
	r1c.add_theme_constant_override("separation", 10)
	pv.add_child(r1c)
	r1c.add_child(_lbl_carta("Difficoltà dei bot (preparazione delle schede):", 18))
	for k in [["normale", "Normale"], ["difficile", "Difficile"], ["esperto", "Esperto"]]:
		var b := Button.new()
		b.text = k[1]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(96, 34)
		Tema.tasto_carta(b)
		b.pressed.connect(func(): bot_diff = k[0]; _aggiorna_menu())
		r1c.add_child(b)
		diff_btns[k[0]] = b
	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 10)
	pv.add_child(r2)
	var bl := Button.new()
	bl.text = "Riprendi la partita salvata su questo dispositivo"
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl.custom_minimum_size = Vector2(0, 40)
	Tema.tasto_carta(bl)
	bl.pressed.connect(_riprendi_locale)
	bl.set_meta("riprendi", true)
	r2.add_child(bl)
	var bc := Button.new()
	bc.text = "Riprendi dal salvataggio online"
	bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bc.custom_minimum_size = Vector2(0, 40)
	Tema.tasto_carta(bc)
	bc.pressed.connect(_riprendi_cloud)
	r2.add_child(bc)
	pv.add_child(_lbl_carta("Partita online", 27, true))
	var r3 := HBoxContainer.new()
	r3.add_theme_constant_override("separation", 8)
	pv.add_child(r3)
	nome_edit = LineEdit.new()
	nome_edit.placeholder_text = "Il tuo nome"
	nome_edit.text = "Stefano"
	nome_edit.custom_minimum_size = Vector2(170, 40)
	r3.add_child(nome_edit)
	r3.add_child(_lbl_carta("Crea stanza come:", 17))
	for f in ORDINE_F:
		var b := Button.new()
		b.text = Nucleo.BREVI[f]
		b.custom_minimum_size = Vector2(0, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Tema.tasto_carta(b, true, Tema.FAZ[f].darkened(0.1))
		b.pressed.connect(_crea_stanza.bind(f))
		r3.add_child(b)
	var r4 := HBoxContainer.new()
	r4.add_theme_constant_override("separation", 8)
	pv.add_child(r4)
	codice_edit = LineEdit.new()
	codice_edit.placeholder_text = "Codice"
	codice_edit.max_length = 4
	codice_edit.custom_minimum_size = Vector2(110, 40)
	r4.add_child(codice_edit)
	r4.add_child(_lbl_carta("Entra come:", 17))
	for f in ORDINE_F:
		var b := Button.new()
		b.text = Nucleo.BREVI[f]
		b.custom_minimum_size = Vector2(0, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Tema.tasto_carta(b)
		b.pressed.connect(_entra_stanza.bind(f))
		r4.add_child(b)
	var r5 := HBoxContainer.new()
	r5.add_theme_constant_override("separation", 8)
	pv.add_child(r5)
	btn_avvia_stanza = Button.new()
	btn_avvia_stanza.text = "Avvia ora (IA o bot ai posti liberi)"
	btn_avvia_stanza.custom_minimum_size = Vector2(0, 40)
	btn_avvia_stanza.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_avvia_stanza.disabled = true
	Tema.tasto_carta(btn_avvia_stanza, true, Color("8a5a12"))
	btn_avvia_stanza.pressed.connect(_avvia_stanza)
	r5.add_child(btn_avvia_stanza)
	var br2 := Button.new()
	br2.text = "Rientra nell'ultima stanza"
	br2.custom_minimum_size = Vector2(0, 40)
	br2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Tema.tasto_carta(br2)
	br2.pressed.connect(_rientra_stanza)
	r5.add_child(br2)
	menu_msg = _lbl_carta("", 17)
	menu_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(menu_msg)
	var cred := Label.new()
	cred.text = "Gioco originale di Saverio Spagnolie, Mathieu Johnson, Cory Graham e Aman Matthews, GMT Games (2023). Versione digitale per uso personale."
	cred.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cred.add_theme_color_override("font_color", Tema.TEXT_DIM)
	cred.add_theme_font_size_override("font_size", 15)
	col.add_child(cred)


func _lbl_carta(t: String, fs: int = 18, titolo: bool = false) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Tema.INK)
	l.add_theme_font_size_override("font_size", fs)
	if titolo:
		l.add_theme_font_override("font", Tema.titolo())
	return l


func _scegli_ctrl(f: String, k: String) -> void:
	scelta_menu[f] = k
	_aggiorna_menu()


func _scegli_forza(n: int) -> void:
	ia_forza = n
	_aggiorna_menu()


func _aggiorna_menu() -> void:
	for f in tasti_ctrl:
		for k in tasti_ctrl[f]:
			var b: Button = tasti_ctrl[f][k]
			b.set_pressed_no_signal(scelta_menu[f] == k)
			Tema.tasto_carta(b, scelta_menu[f] == k, Tema.FAZ[f].darkened(0.1))
	for k in diff_btns:
		diff_btns[k].set_pressed_no_signal(k == bot_diff)
		Tema.tasto_carta(diff_btns[k], k == bot_diff, Color("6b4f1d"))
	for n in forza_btns:
		forza_btns[n].set_pressed_no_signal(n == ia_forza)
		Tema.tasto_carta(forza_btns[n], n == ia_forza, Color("6b4f1d"))
	for b in menu.find_children("*", "Button", true, false):
		if b.has_meta("riprendi"):
			b.disabled = not FileAccess.file_exists(FILE_SALVA)


func _nuova_locale(demo: bool) -> void:
	controllo = scelta_menu.duplicate() if not demo else {"D": "ia", "B": "ia", "V": "ia"}
	online = false
	host = false
	var o2 := {}
	if timur_chk.button_pressed:
		o2["ombra_timur"] = true
	var bd := {}
	for f in controllo:
		if controllo[f] == "bot":
			bd[f] = bot_diff
	if not bd.is_empty():
		o2["bot_diff"] = bd
	avvia(rng.randi() % 1000000000 + 1, o2, [])


# ================================================================ PARTITA: costruzione

func _costruisci_partita() -> void:
	partita = Control.new()
	partita.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(partita)
	var bg := ColorRect.new()
	bg.color = Tema.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	partita.add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 0)
	partita.add_child(v)
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", Tema.box(Tema.BAR, Tema.BAR_LINE, 0, 0, 6))
	top.custom_minimum_size = Vector2(0, 66)
	v.add_child(top)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 8)
	top.add_child(th)
	var tit := VBoxContainer.new()
	tit.add_theme_constant_override("separation", -6)
	th.add_child(tit)
	var t1 := Label.new()
	t1.text = "VIJAYANAGARA"
	t1.add_theme_font_override("font", Tema.titolo_forte())
	t1.add_theme_font_size_override("font_size", 24)
	t1.add_theme_color_override("font_color", Tema.GOLD_HI)
	tit.add_child(t1)
	var t2 := Label.new()
	t2.name = "Sotto"
	t2.add_theme_font_override("font", Tema.ui_it())
	t2.add_theme_font_size_override("font_size", 13)
	t2.add_theme_color_override("font_color", Tema.PAPER)
	tit.add_child(t2)
	for f in ORDINE_F:
		var c := _chip(f)
		chips[f] = c
		th.add_child(c)
	lbl_mazzo = Label.new()
	lbl_mazzo.add_theme_font_override("font", Tema.ui_heavy())
	lbl_mazzo.add_theme_font_size_override("font_size", 17)
	lbl_mazzo.add_theme_color_override("font_color", Tema.TEXT_DIM)
	lbl_mazzo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_mazzo.clip_text = true
	lbl_mazzo.custom_minimum_size = Vector2(60, 0)
	lbl_mazzo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	th.add_child(lbl_mazzo)
	for k in [["−", "zoom_meno"], ["+", "zoom_piu"], ["Adatta", "zoom_adatta"]]:
		var b := Button.new()
		b.text = k[0]
		b.custom_minimum_size = Vector2(38 if k[0].length() == 1 else 66, 42)
		b.pressed.connect(_zoom.bind(k[1]))
		th.add_child(b)
	btn_annulla = Button.new()
	btn_annulla.text = "Annulla"
	btn_annulla.custom_minimum_size = Vector2(84, 42)
	btn_annulla.pressed.connect(_annulla)
	th.add_child(btn_annulla)
	for k in [["Regole", "_mostra_regole"], ["Salva", "_salva_cloud"], ["Menu", "_torna_menu"]]:
		var b := Button.new()
		b.text = k[0]
		b.custom_minimum_size = Vector2(0, 42)
		b.pressed.connect(Callable(self, k[1]))
		th.add_child(b)
	var corpo := HBoxContainer.new()
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_theme_constant_override("separation", 6)
	v.add_child(corpo)
	var cornice := PanelContainer.new()
	cornice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cornice.size_flags_stretch_ratio = 2.2
	cornice.add_theme_stylebox_override("panel", Tema.box(Color("0d1513"), Tema.GOLD.darkened(0.35), 2, 2, 0))
	corpo.add_child(cornice)
	mappa = MappaView.new()
	mappa.spazio_cliccato.connect(_click_spazio)
	mappa.spazio_sopra.connect(_sopra_spazio)
	cornice.add_child(mappa)
	var lato := VBoxContainer.new()
	lato.custom_minimum_size = Vector2(300, 0)
	lato.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lato.add_theme_constant_override("separation", 6)
	corpo.add_child(lato)
	var statop := PanelContainer.new()
	statop.add_theme_stylebox_override("panel", Tema.box(Tema.LOG_BG, Color("3b4a3f"), 1, 4, 8))
	statop.custom_minimum_size = Vector2(0, 300)
	lato.add_child(statop)
	stato_lbl = RichTextLabel.new()
	stato_lbl.bbcode_enabled = true
	statop.add_child(stato_lbl)
	var logp := PanelContainer.new()
	logp.add_theme_stylebox_override("panel", Tema.box(Tema.LOG_BG, Color("3b4a3f"), 1, 4, 8))
	logp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lato.add_child(logp)
	var lv := VBoxContainer.new()
	logp.add_child(lv)
	info_lbl = Label.new()
	info_lbl.add_theme_color_override("font_color", Tema.GOLD_HI)
	info_lbl.add_theme_font_size_override("font_size", 15)
	info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(info_lbl)
	log_lbl = RichTextLabel.new()
	log_lbl.bbcode_enabled = true
	log_lbl.scroll_following = true
	log_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(log_lbl)
	var dx := PanelContainer.new()
	dx.custom_minimum_size = Vector2(400, 0)
	corpo.add_child(dx)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dx.add_child(sc)
	pannello = VBoxContainer.new()
	pannello.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pannello.add_theme_constant_override("separation", 8)
	sc.add_child(pannello)
	banner = PanelContainer.new()
	pannello.add_child(banner)
	var bv := VBoxContainer.new()
	banner.add_child(bv)
	lbl_chi = Label.new()
	lbl_chi.add_theme_font_override("font", Tema.titolo())
	lbl_chi.add_theme_font_size_override("font_size", 23)
	lbl_chi.add_theme_color_override("font_color", Color.WHITE)
	lbl_chi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bv.add_child(lbl_chi)
	lbl_domanda = Label.new()
	lbl_domanda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_domanda.add_theme_font_override("font", Tema.ui_bold())
	lbl_domanda.add_theme_font_size_override("font_size", 19)
	lbl_domanda.add_theme_color_override("font_color", Color.WHITE)
	lbl_domanda.custom_minimum_size = Vector2(350, 0)
	bv.add_child(lbl_domanda)
	box_opz = GridContainer.new()
	box_opz.columns = 1
	box_opz.add_theme_constant_override("h_separation", 6)
	box_opz.add_theme_constant_override("v_separation", 6)
	pannello.add_child(box_opz)
	pannello.add_child(_titoletto("Carta in gioco"))
	carta_tex = TextureRect.new()
	carta_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	carta_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	carta_tex.custom_minimum_size = Vector2(360, 400)
	carta_tex.mouse_filter = Control.MOUSE_FILTER_STOP
	carta_tex.tooltip_text = "Clicca per ingrandire"
	carta_tex.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and m: _mostra_carta(m.s["carta"]))
	pannello.add_child(carta_tex)
	lbl_carta = _lbl_carta("", 16)
	lbl_carta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_carta.custom_minimum_size = Vector2(350, 0)
	pannello.add_child(lbl_carta)
	lbl_carta_bot = _titoletto("Carta azione del bot")
	pannello.add_child(lbl_carta_bot)
	carta_bot_tex = TextureRect.new()
	carta_bot_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	carta_bot_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	carta_bot_tex.custom_minimum_size = Vector2(360, 420)
	carta_bot_tex.mouse_filter = Control.MOUSE_FILTER_STOP
	carta_bot_tex.tooltip_text = "Clicca per ingrandire"
	carta_bot_tex.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and carta_bot_tex.texture: carta_pop_tex.texture = carta_bot_tex.texture; carta_pop.popup_centered(Vector2(580, 800)))
	pannello.add_child(carta_bot_tex)
	pannello.add_child(_titoletto("Eventi riservati e carte giocate"))
	riserva_box = VBoxContainer.new()
	pannello.add_child(riserva_box)
	fine_dlg = AcceptDialog.new()
	fine_dlg.title = "Fine della partita"
	fine_dlg.ok_button_text = "Torna al menu"
	fine_dlg.confirmed.connect(_torna_menu)
	add_child(fine_dlg)
	regole_pop = AcceptDialog.new()
	regole_pop.title = "Regole in breve"
	regole_pop.ok_button_text = "Chiudi"
	add_child(regole_pop)
	regole_txt = RichTextLabel.new()
	regole_txt.bbcode_enabled = true
	regole_txt.custom_minimum_size = Vector2(940, 640)
	regole_txt.add_theme_color_override("default_color", Tema.INK)
	regole_pop.add_child(regole_txt)
	carta_pop = PopupPanel.new()
	add_child(carta_pop)
	carta_pop_tex = TextureRect.new()
	carta_pop_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	carta_pop_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	carta_pop_tex.custom_minimum_size = Vector2(560, 770)
	carta_pop.add_child(carta_pop_tex)


func _titoletto(t: String) -> Label:
	var l := Label.new()
	l.text = t.to_upper()
	l.add_theme_font_override("font", Tema.titolo())
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Tema.INK_DIM)
	return l


func _chip(f: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(178, 54)
	p.add_theme_stylebox_override("panel", Tema.box(Tema.FAZ[f].darkened(0.4), Tema.FAZ[f], 2, 4, 6))
	var h := HBoxContainer.new()
	p.add_child(h)
	var ic := TextureRect.new()
	ic.texture = Tema.icona(f)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(30, 36)
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	h.add_child(v)
	var n := Label.new()
	n.add_theme_font_override("font", Tema.titolo())
	n.add_theme_font_size_override("font_size", 17)
	n.add_theme_color_override("font_color", Color.WHITE)
	v.add_child(n)
	var d := Label.new()
	d.add_theme_font_size_override("font_size", 14)
	d.add_theme_color_override("font_color", Color("f1e8d4"))
	v.add_child(d)
	p.set_meta("n", n)
	p.set_meta("d", d)
	return p


# ================================================================ PARTITA: controllo

func avvia(sm: int, o2: Dictionary, atti_prec: Array, ans_prec: Array = []) -> void:
	seme = sm
	opz = o2
	m = Motore.new()
	m.nuova(sm, o2)
	registro_fisso = ["[color=#f2d27a][b]Vijayanagara — gli imperi del Deccan, 1290–1398[/b][/color]"]
	for l in m.registro:
		registro_fisso.append(_colora(l))
	atti = []
	for r in atti_prec:
		var b: Dictionary = m.s.duplicate(true)
		m.prova(b, r)
		for l in m.registro:
			registro_fisso.append(_colora(l))
		atti.append(r)
	base = m.s.duplicate(true)
	ans = ans_prec.duplicate()
	piano = []
	storia = []
	ultima_bot = {}
	if carta_bot_tex:
		carta_bot_tex.texture = null
		lbl_carta_bot.text = "CARTA AZIONE DEL BOT"
	menu.visible = false
	partita.visible = true
	var chi: Array = []
	for f in ORDINE_F:
		chi.append("%s: %s" % [Nucleo.BREVI[f], {"umano": "tu", "ia": "IA", "bot": "bot", "remoto": "online"}.get(controllo[f], "")])
	(partita.find_child("Sotto", true, false) as Label).text = " · ".join(chi)
	mappa.imposta(m)
	call_deferred("_passo")


func _colora(l: String) -> String:
	if l.begins_with("—"):
		return "[color=#f2d27a][b]%s[/b][/color]" % l
	if l.begins_with("FINE") or l.begins_with("Vince") or l.begins_with("Parità"):
		return "[color=#ffe08a][b]%s[/b][/color]" % l
	if l.begins_with("Battaglia") or l.begins_with("Colpi"):
		return "[color=#f0a58f]%s[/color]" % l
	if l.begins_with("Influenza"):
		return "[color=#9fe3dc]%s[/color]" % l
	return l


func _passo() -> void:
	if m == null or not partita.visible:
		return
	var fatto := m.prova(base, ans)
	if fatto:
		for l in m.registro:
			registro_fisso.append(_colora(l))
		var prima: Dictionary = base.get("sp", {})
		for id in m.ordine:
			if prima.has(id) and str(prima[id]) != str(m.s["sp"][id]):
				mappa.ultimo_cambiato[id] = mappa._t
		var concluso := ans.duplicate()
		atti.append(concluso)
		_invia_rete(atti.size() - 1, concluso, true)
		base = m.s.duplicate(true)
		ans = []
		piano = []
		_salva_locale()
		_aggiorna_ui()
		if m.finita():
			_fine()
			return
		call_deferred("_passo")
		return
	_aggiorna_ui()
	var f: String = m.need["f"]
	var chi: String = controllo.get(f, "umano")
	if chi == "ia":
		_turno_ia()
	elif chi == "bot":
		_turno_bot()
	elif chi == "remoto":
		_invia_rete(atti.size(), ans, false)
	_mostra_domanda(chi)


func _turno_ia() -> void:
	if ia_in_corso:
		return
	ia_in_corso = true
	var demo: bool = not controllo.values().has("umano") and not online
	await get_tree().create_timer((0.5 if demo else 0.35) if ans.is_empty() else (0.15 if demo else 0.08)).timeout
	if m == null or m.need == null or not partita.visible:
		ia_in_corso = false
		return
	var v = IA.rispondi(base, ans, m.need, piano, rng, ia_forza)
	ans.append(v)
	ia_in_corso = false
	_passo()


func umani() -> Array:
	var u: Array = []
	for f in ORDINE_F:
		if controllo.get(f, "") in ["umano", "remoto"]:
			u.append(f)
	return u


func _turno_bot() -> void:
	if ia_in_corso:
		return
	ia_in_corso = true
	var demo: bool = not controllo.values().has("umano") and not online
	await get_tree().create_timer((0.5 if demo else 0.35) if ans.is_empty() else (0.12 if demo else 0.06)).timeout
	if m == null or m.need == null or not partita.visible:
		ia_in_corso = false
		return
	var f: String = m.need["f"]
	var tag: String = str(m.need.get("x", {}).get("tag", ""))
	if tag in ["casella", "cmd"] and ans.is_empty() or tag == "casella":
		var p := Bot.piano_di(base, f, umani())
		var cb: String = p.get("carta_bot", "")
		if cb != "" and ultima_bot.get(f, "") != "%d:%s" % [atti.size(), cb]:
			ultima_bot[f] = "%d:%s" % [atti.size(), cb]
			registro_fisso.append("[color=#c9cec4]%s (bot) pesca la carta azione %s.[/color]" % [Nucleo.BREVI[f], cb])
			carta_bot_tex.texture = load("res://assets/bot/%s.webp" % cb)
			lbl_carta_bot.text = "CARTA AZIONE DEL BOT: %s (%s)" % [Nucleo.BREVI[f].to_upper(), cb]
	elif tag == "mongolo" and carta_bot_tex != null:
		carta_bot_tex.texture = load("res://assets/bot/%s.webp" % ("O" if m.need["testo"].contains("1 di 2") else "OO"))
		lbl_carta_bot.text = "CARTA DEI MONGOLI (%s)" % Nucleo.BREVI[f].to_upper()
	var v = Bot.rispondi(base, ans, m.need, m, umani())
	ans.append(v)
	ia_in_corso = false
	_passo()


func rispondi(v) -> void:
	if m == null or m.need == null:
		return
	if controllo.get(m.need["f"], "") != "umano":
		return
	storia.append([atti.size(), ans.duplicate()])
	ans.append(v)
	piano = []
	_passo()


func _annulla() -> void:
	if online or storia.is_empty() or ia_in_corso:
		return
	var st: Array = storia.pop_back()
	var n: int = st[0]
	if n != atti.size():
		avvia(seme, opz, atti.slice(0, n), st[1])
		return
	ans = st[1]
	piano = []
	_passo()


# ================================================================ PARTITA: interfaccia

func _aggiorna_ui() -> void:
	if m == null:
		return
	var s: Dictionary = m.s
	var di_turno: String = m.need["f"] if m.need != null else ""
	for f in ORDINE_F:
		var p: PanelContainer = chips[f]
		(p.get_meta("n") as Label).text = Nucleo.BREVI[f] + {"ia": " · IA", "bot": " · Bot", "remoto": " · online", "umano": ""}.get(controllo.get(f, ""), "")
		var d := "PV %d · Ris. %d · Cav. %d" % [m.vp(f), int(s["ris"][f]), int(s["cav"][f])]
		if f != "D":
			d += " · Infl. %d" % int(s["infl"][f])
		if not s["elig"][f]:
			d += " · non idoneo"
		(p.get_meta("d") as Label).text = d
		p.add_theme_stylebox_override("panel", Tema.box(Tema.FAZ[f].darkened(0.4 if f != di_turno else 0.05), Tema.GOLD_HI if f == di_turno else Tema.FAZ[f], 3 if f == di_turno else 1, 4, 6))
	var mazzo: Array = s["mazzo"]
	var a_succ := 0
	for c in mazzo:
		if m.tipo_carta(c) in ["successione", "timuride"]:
			break
		a_succ += 1
	lbl_mazzo.text = "Mazzo %d · %s" % [mazzo.size(), "Tughlaq" if s["dinastia"] == "tughlaq" else "Khalji"] if not m.finita() else "Partita conclusa"
	lbl_mazzo.tooltip_text = "Carte nel mazzo: %d. Dinastia: %s. Carte prima della prossima Successione o carta Timuride: %d." % [mazzo.size(), s["dinastia"].capitalize(), a_succ]
	btn_annulla.disabled = online or storia.is_empty()
	var cid: String = s["carta"]
	carta_tex.texture = _tex_carta(cid)
	var cd := m.carta_dati(cid)
	match m.tipo_carta(cid):
		"evento":
			var ord: Array = []
			for f in cd["ordine"]:
				ord.append(Nucleo.BREVI[f] + ("" if s["elig"][f] else " (non idoneo)"))
			var prese: Array = []
			for b in ["cd", "ec"]:
				if s["scelte"].has(b):
					prese.append("%s: %s" % [Regole.CASELLE[b], Nucleo.BREVI[s["scelte"][b]]])
			lbl_carta.text = "Ordine: %s.%s%s" % [", ".join(ord), (" Resta idoneo chi sceglie l'Evento." if cd.get("resta", false) else ""), ("\n" + "; ".join(prese)) if not prese.is_empty() else ""]
		"mongola":
			lbl_carta.text = "Invasione mongola: due Comandi mongoli scelti da %s." % m.nome_faz(cd["alleato"])
		_:
			lbl_carta.text = cd.get("titolo", "")
	for c in riserva_box.get_children():
		c.queue_free()
	for f in s["riserva"]:
		var b := Button.new()
		b.text = "%s: %s" % [Nucleo.BREVI[f], m.carta_dati(s["riserva"][f])["titolo"]]
		Tema.tasto_carta(b)
		b.pressed.connect(_mostra_carta.bind(s["riserva"][f]))
		riserva_box.add_child(b)
	var giocate: Array = s["giocate"]
	var hf := HFlowContainer.new()
	hf.add_theme_constant_override("h_separation", 4)
	hf.add_theme_constant_override("v_separation", 4)
	for i in range(max(0, giocate.size() - 12), giocate.size()):
		var c: String = giocate[i]
		var b := Button.new()
		var dd := m.carta_dati(c)
		b.text = str(int(dd.get("n", 0))) if m.tipo_carta(c) == "evento" else {"mongola": "Inv.", "successione": "Succ.", "timuride": "Timur"}.get(m.tipo_carta(c), c)
		b.tooltip_text = dd.get("titolo", c)
		b.custom_minimum_size = Vector2(44, 30)
		b.add_theme_font_size_override("font_size", 14)
		Tema.tasto_carta(b)
		b.pressed.connect(_mostra_carta.bind(c))
		hf.add_child(b)
	riserva_box.add_child(hf)
	var ci_sono_bot: bool = controllo.values().has("bot")
	lbl_carta_bot.visible = ci_sono_bot
	carta_bot_tex.visible = ci_sono_bot
	stato_lbl.text = _testo_stato()
	var righe = registro_fisso.slice(max(0, registro_fisso.size() - 400))
	var corr: Array = []
	if m.need != null:
		for l in m.registro:
			corr.append("[color=#9fb2a6]" + l + "[/color]")
	log_lbl.text = "\n".join(righe + corr)
	mappa.queue_redraw()


func _tex_carta(cid: String) -> Texture2D:
	if cid == "":
		return null
	var p := "res://assets/carte/%s.webp" % cid
	return load(p) if ResourceLoader.exists(p) else null


func _testo_stato() -> String:
	var s: Dictionary = m.s
	var t: Array = []
	t.append("[b]Dinastia %s[/b]%s" % ["Tughlaq: Ribellione possibile" if s["dinastia"] == "tughlaq" else "Khalji: Ribellione vietata", " · seconda carta Timuride in arrivo" if int(s["timur"]) == 1 else ""])
	t.append("[color=#c9cec4][b]Sultanato[/b][/color]: PV %d (Prosperità Tributaria) · Risorse %d · Cavallerie %d" % [m.vp("D"), int(s["ris"]["D"]), int(s["cav"]["D"])])
	t.append("   Disponibili: %s, %s, %s" % [m.pz(m.disp("t"), "t"), m.pz(m.disp("g"), "g"), m.pz(m.disp("q"), "q")])
	t.append("[color=#6fd3cf][b]Bahmani[/b][/color]: PV %d · Risorse %d · Cavallerie %d · Influenza %d" % [m.vp("B"), int(s["ris"]["B"]), int(s["cav"]["B"]), int(s["infl"]["B"])])
	t.append("   Disponibili: %s, %s" % [m.pz(m.disp("a"), "a"), m.pz(m.disp("f"), "f")])
	t.append("[color=#f6cc5a][b]Vijayanagara[/b][/color]: PV %d · Risorse %d · Cavallerie %d · Influenza %d" % [m.vp("V"), int(s["ris"]["V"]), int(s["cav"]["V"]), int(s["infl"]["V"])])
	t.append("   Disponibili: %s, %s" % [m.pz(m.disp("r"), "r"), m.pz(m.disp("tp"), "tp")])
	t.append("[color=#e07a6a][b]Mongoli[/b][/color]: Passi %d · Punjab %d · Delhi %d · Disponibili %d" % [int(m.X("passi")["m"]), int(m.X("punjab")["m"]), int(m.X("delhi")["m"]), m.disp("m")])
	t.append("Cavallerie nella riserva comune: %d" % m.cav_pool())
	var bonus: int = max(-3, 3 - int(m.X("delhi")["m"]))
	t.append("[color=#f2d27a]Se Timur arrivasse ora: Sultanato %+d PV per i Mongoli a Delhi.[/color]" % bonus)
	return "\n".join(t)


func _mostra_domanda(chi: String) -> void:
	for c in box_opz.get_children():
		c.queue_free()
	mappa.candidati = []
	mappa.selezionati = []
	if m.finita():
		lbl_chi.text = "Partita conclusa"
		lbl_domanda.text = m.s["fine"].get("m", "")
		banner.add_theme_stylebox_override("panel", Tema.box(Tema.GOLD.darkened(0.5), Tema.GOLD, 2, 4, 10))
		return
	var q: Dictionary = m.need
	var f: String = q["f"]
	banner.add_theme_stylebox_override("panel", Tema.box(Tema.FAZ[f].darkened(0.25), Tema.GOLD if chi == "umano" else Tema.FAZ[f].darkened(0.5), 2, 4, 10))
	lbl_chi.text = m.nome_faz(f) + {"umano": " · tocca a te", "ia": " · l'IA sta pensando…", "bot": " · il bot segue la sua carta", "remoto": " · in attesa del giocatore online"}.get(chi, "")
	lbl_domanda.text = q["testo"]
	if chi != "umano":
		return
	var opzioni: Array = q["opz"]
	var qx: Dictionary = q.get("x", {})
	var spazi: bool = qx.get("spazi", false)
	var num: bool = qx.get("num", false)
	var lunghe := false
	for o in opzioni:
		if str(o["t"]).length() > 20:
			lunghe = true
	box_opz.columns = 1 if lunghe or spazi else (6 if num else 2)
	var tag: String = str(qx.get("tag", ""))
	for o in opzioni:
		var v = o["v"]
		if spazi and v is String and m.SP.has(v):
			mappa.candidati.append(v)
			continue
		var b := Button.new()
		b.text = str(o["t"])
		b.custom_minimum_size = Vector2(0, 42 if not num else 38)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if lunghe else TextServer.AUTOWRAP_OFF
		var passivo: bool = (v is String and v in ["fine", "passa", "no", "nessuno", "nessuna"]) or (v is int and v < 0)
		Tema.tasto_carta(b, not passivo and not num and not spazi, Tema.FAZ[f].darkened(0.1))
		b.pressed.connect(rispondi.bind(v))
		box_opz.add_child(b)
		if tag in ["cmd", "decreto"] and v is String:
			var dsc: String = m.descrizione(v, f)
			if dsc != "":
				b.tooltip_text = dsc
				var dl := _lbl_carta(dsc, 14)
				dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				dl.add_theme_color_override("font_color", Tema.INK_DIM)
				box_opz.add_child(dl)
	if spazi and not mappa.candidati.is_empty():
		var h := _lbl_carta("Clicca uno spazio evidenziato sulla mappa, oppure il suo nome qui sotto.", 16)
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box_opz.add_child(h)
		box_opz.move_child(h, 0)
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 4)
		fl.add_theme_constant_override("v_separation", 4)
		fl.custom_minimum_size = Vector2(350, 0)
		for id in mappa.candidati:
			var sb := Button.new()
			sb.text = m.nome_sp(id)
			sb.add_theme_font_size_override("font_size", 16)
			sb.custom_minimum_size = Vector2(0, 32)
			Tema.tasto_carta(sb, false, Tema.FAZ[f].darkened(0.1))
			sb.pressed.connect(rispondi.bind(id))
			sb.mouse_entered.connect(func(): mappa.sopra = id; mappa.queue_redraw())
			fl.add_child(sb)
		box_opz.add_child(fl)
		box_opz.move_child(fl, 1)
	mappa.queue_redraw()


func _click_spazio(id: String) -> void:
	if id in mappa.candidati:
		rispondi(id)


func _sopra_spazio(id: String) -> void:
	if id == "" or m == null:
		info_lbl.text = ""
		return
	var x := m.X(id)
	var parti: Array = [m.nome_sp(id)]
	if m.provincia(id):
		parti.append("Prosperità %d" % m.prosp(id))
		parti.append("Tributaria" if x["trib"] else ("Controllo " + m.breve(x["ctrl"]) if x["ctrl"] != "" else "Indipendente, senza Controllo"))
	var pz: Array = []
	for k in ["t", "g", "q", "ao", "ar", "f", "ro", "rr", "tp", "m"]:
		if int(x[k]) > 0:
			pz.append("%d %s" % [int(x[k]), m.nome_pezzo_stato(k, int(x[k]))])
	info_lbl.text = " · ".join(parti) + (": " + ", ".join(pz) if not pz.is_empty() else ": vuoto")


func _zoom(k: String) -> void:
	match k:
		"zoom_piu":
			mappa.zoom_a(mappa.zoom * 1.25, mappa.size * 0.5)
		"zoom_meno":
			mappa.zoom_a(mappa.zoom / 1.25, mappa.size * 0.5)
		_:
			mappa.adatta()


func _mostra_carta(cid: String) -> void:
	if cid == "" or m == null:
		return
	carta_pop_tex.texture = _tex_carta(cid)
	carta_pop.popup_centered(Vector2(580, 800))


func _mostra_regole() -> void:
	if m == null:
		return
	regole_txt.text = Regolamento.testo(m)
	regole_pop.popup_centered(Vector2(980, 720))


func _fine() -> void:
	_mostra_domanda("")
	var fine: Dictionary = m.s["fine"]
	var v: Array = fine.get("v", [])
	var chi := ("Vince: " + m.nome_faz(v[0])) if v.size() == 1 else ("Parità fra " + ", ".join(v.map(func(x): return m.nome_faz(x))))
	var narr := ""
	if v.size() == 1:
		narr = {"D": "Il Sultanato ha frenato il suo declino: Delhi è stata difesa dai Mongoli e le Province del sud continuano a pagare il tributo.",
			"B": "Il Regno Bahmani ha cospirato con i governatori di Delhi, sfruttato il vantaggio militare e attirato grandi menti da lontano.",
			"V": "L'Impero di Vijayanagara è cresciuto grazie a una popolazione numerosa e a un'economia forte, diffondendo la sua influenza nel Deccan."}[v[0]]
	fine_dlg.dialog_text = "%s\n\n%s\n\n%s" % [chi, fine.get("m", ""), narr]
	fine_dlg.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fine_dlg.get_label().custom_minimum_size = Vector2(560, 0)
	if not online:
		_cancella_locale()
	fine_dlg.popup_centered(Vector2(620, 360))


func _torna_menu() -> void:
	if online and stanza != "":
		rete.remember_room("")
	online = false
	stanza = ""
	_attesa_stanza = false
	partita.visible = false
	menu.visible = true
	m = null
	_aggiorna_menu()


func _process(delta: float) -> void:
	if online and stanza != "" and partita.visible:
		_poll_t += delta
		if _poll_t > 1.5:
			_poll_t = 0.0
			_sync()


# ================================================================ SALVATAGGI

func _dati_salvataggio() -> Dictionary:
	return {"gioco": "vijayanagara", "seme": seme, "opz": opz, "atti": atti, "controllo": controllo, "forza": ia_forza, "v": 2}


func _salva_locale() -> void:
	if online or m == null:
		return
	var f := FileAccess.open(FILE_SALVA, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_dati_salvataggio()))
	if atti.size() % 4 == 0:
		_salva_cloud(true)


func _cancella_locale() -> void:
	if FileAccess.file_exists(FILE_SALVA):
		DirAccess.remove_absolute(FILE_SALVA)


func _riprendi_locale() -> void:
	var f := FileAccess.open(FILE_SALVA, FileAccess.READ)
	if f == null:
		menu_msg.text = "Nessuna partita salvata su questo dispositivo."
		return
	var d = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		menu_msg.text = "Salvataggio illeggibile."
		return
	_carica(d)


func _carica(d: Dictionary) -> void:
	controllo = d.get("controllo", {"D": "umano", "B": "ia", "V": "ia"})
	for k in controllo:
		if controllo[k] == "remoto":
			controllo[k] = "ia"
	ia_forza = int(d.get("forza", ia_forza))
	online = false
	avvia(int(d["seme"]), d.get("opz", {}), d.get("atti", []), [])


var _cloud_occupato := false


func _salva_cloud(silenzioso: bool = false) -> void:
	if online or m == null or _cloud_occupato:
		return
	_cloud_occupato = true
	if not silenzioso:
		info_lbl.text = "Salvataggio online in corso…"
	var dati := _dati_salvataggio()
	dati["quando"] = Time.get_datetime_string_from_system()
	var ok = await rete.salva_partita(dati)
	_cloud_occupato = false
	if not silenzioso:
		info_lbl.text = "Partita salvata online: riprendila da qualsiasi dispositivo." if ok else "Salvataggio online non riuscito: " + rete.last_error


func _riprendi_cloud() -> void:
	menu_msg.text = "Carico il salvataggio online…"
	var d = await rete.carica_partita()
	if d is Dictionary and d.has("seme"):
		_carica(d)
		return
	menu_msg.text = "Nessuna partita salvata online." + ("" if rete.last_error == "" else " (" + rete.last_error + ")")


# ================================================================ ONLINE
# Ogni giocatore occupa un posto con la sua fazione; i posti liberi li gioca l'IA, calcolata dall'host.
# Le decisioni (risposte per atto) vanno in un registro numerato uguale per tutti.

var _cfg_stanza := {}


func _crea_stanza(f: String) -> void:
	menu_msg.text = "Creo la stanza…"
	var nome := nome_edit.text.strip_edges()
	if nome == "":
		nome = "Giocatore"
	var o3 := {"ombra_timur": true} if timur_chk.button_pressed else {}
	var cfg := {"gioco": "vijayanagara", "seme": rng.randi() % 1000000000 + 1, "host": f, "forza": ia_forza, "opz": o3, "liberi": "bot" if scelta_menu.values().has("bot") else "ia", "bot_diff": bot_diff}
	var code = await rete.create_room(nome, cfg)
	if code == "":
		menu_msg.text = "Impossibile creare la stanza: " + rete.last_error
		return
	await rete.db_patch(Rete.ROOT + "/%s/seats/0" % code, {"faz": f})
	stanza = code
	posto = 0
	host = true
	_cfg_stanza = cfg
	rete.remember_room(code, 0)
	btn_avvia_stanza.disabled = false
	_attesa_stanza = true
	while _attesa_stanza and stanza == code:
		var r = await rete.room(code)
		var seats: Dictionary = Rete._as_dict(r.get("seats", {}))
		var chi: Array = []
		for k in seats:
			if seats[k] is Dictionary:
				chi.append("%s (%s)" % [seats[k].get("name", "?"), Nucleo.BREVI.get(seats[k].get("faz", ""), "?")])
		menu_msg.text = "Stanza [%s]. Comunica il codice agli altri: scelgono la loro fazione ed entrano. Seduti: %s. Quando vuoi, premi «Avvia ora»: l'IA prende i posti liberi." % [code, ", ".join(chi)]
		var tutte := true
		var fz := {}
		for k in seats:
			if seats[k] is Dictionary:
				fz[seats[k].get("faz", "")] = true
		for ff in ORDINE_F:
			if not fz.has(ff):
				tutte = false
		if tutte:
			_avvia_stanza()
			return
		await get_tree().create_timer(2.0).timeout


func _avvia_stanza() -> void:
	if not host or stanza == "":
		return
	_attesa_stanza = false
	btn_avvia_stanza.disabled = true
	var r = await rete.room(stanza)
	var seats: Dictionary = Rete._as_dict(r.get("seats", {}))
	var posti := {}
	for k in seats:
		if seats[k] is Dictionary and str(seats[k].get("faz", "")) in ORDINE_F and not posti.has(seats[k]["faz"]):
			posti[seats[k]["faz"]] = int(k)
	var cfg := _cfg_stanza.duplicate()
	cfg["posti"] = posti
	if cfg.get("liberi", "ia") == "bot":
		var bd := {}
		for ff in ORDINE_F:
			if not posti.has(ff):
				bd[ff] = cfg.get("bot_diff", "normale")
		if not bd.is_empty():
			var oo: Dictionary = cfg.get("opz", {}).duplicate()
			oo["bot_diff"] = bd
			cfg["opz"] = oo
	await rete.start_room(stanza, cfg)
	_avvia_online(cfg, 0)


func _entra_stanza(f: String) -> void:
	var code := codice_edit.text.strip_edges().to_upper()
	if code.length() != 4:
		menu_msg.text = "Il codice della stanza ha 4 lettere."
		return
	menu_msg.text = "Entro nella stanza %s…" % code
	var nome := nome_edit.text.strip_edges()
	if nome == "":
		nome = "Ospite"
	var r0 := {}
	if await rete.sign_in():
		r0 = await rete.room(code)
	var seats0: Dictionary = Rete._as_dict(r0.get("seats", {}))
	for k in seats0:
		if seats0[k] is Dictionary and seats0[k].get("faz", "") == f and seats0[k].get("uid", "") != rete.uid:
			menu_msg.text = "La fazione %s è già presa in questa stanza: scegline un'altra." % Nucleo.BREVI[f]
			return
	var p = await rete.join_room(code, nome, 3)
	if p < 0:
		menu_msg.text = "Impossibile entrare nella stanza %s. %s" % [code, rete.last_error]
		return
	await rete.db_patch(Rete.ROOT + "/%s/seats/%d" % [code, p], {"faz": f})
	stanza = code
	posto = p
	host = false
	rete.remember_room(code, p)
	for i in 300:
		var r = await rete.room(code)
		if r.get("status", "") == "playing" and r.has("game"):
			var cfg = JSON.parse_string(str(r["game"]))
			if cfg is Dictionary:
				_avvia_online(cfg, p)
				return
		menu_msg.text = "Nella stanza %s come %s: in attesa che l'host avvii la partita…" % [code, Nucleo.BREVI[f]]
		await get_tree().create_timer(2.0).timeout


func _avvia_online(cfg: Dictionary, mio_posto: int) -> void:
	online = true
	net_k = 0
	net_inviati = {}
	_da_inviare = []
	host = mio_posto == 0
	ia_forza = int(cfg.get("forza", 100))
	var posti: Dictionary = cfg.get("posti", {})
	controllo = {}
	for f in ORDINE_F:
		if posti.has(f) and int(posti[f]) == mio_posto:
			controllo[f] = "umano"
		elif posti.has(f):
			controllo[f] = "remoto"
		else:
			controllo[f] = str(cfg.get("liberi", "ia")) if host else "remoto"
	avvia(int(cfg["seme"]), cfg.get("opz", {}), [])
	var mie: Array = []
	for f in controllo:
		if controllo[f] == "umano":
			mie.append(Nucleo.BREVI[f])
	info_lbl.text = "Online nella stanza %s: tu giochi con %s." % [stanza, ", ".join(mie) if not mie.is_empty() else "nessuna fazione"]


func _rientra_stanza() -> void:
	var ss := rete.load_session()
	var code := str(ss.get("room", ""))
	if code == "":
		menu_msg.text = "Nessuna stanza online da riprendere su questo dispositivo."
		return
	menu_msg.text = "Rientro nella stanza %s…" % code
	if not await rete.sign_in():
		menu_msg.text = "Accesso a Firebase non riuscito: " + rete.last_error
		return
	var r = await rete.room(code)
	if r.is_empty() or not r.has("game"):
		menu_msg.text = "La stanza %s non esiste più o la partita non è iniziata." % code
		return
	var cfg = JSON.parse_string(str(r["game"]))
	if not (cfg is Dictionary):
		return
	var seats: Dictionary = Rete._as_dict(r.get("seats", {}))
	var mio := -1
	for k in seats:
		if seats[k] is Dictionary and seats[k].get("uid", "") == rete.uid:
			mio = int(k)
	if mio < 0:
		menu_msg.text = "Non risulti seduto nella stanza %s." % code
		return
	stanza = code
	posto = mio
	var dd = await rete.get_decisions(code, 0)
	var chiavi: Array = dd.keys()
	chiavi.sort()
	var per_atto := {}
	var ultimo := 0
	for k in chiavi:
		var d: Dictionary = dd[k]
		var n := int(d.get("n", -1))
		var rr: Array = d.get("r", [])
		if not per_atto.has(n) or rr.size() >= (per_atto[n]["r"] as Array).size():
			per_atto[n] = d
		ultimo = int(k) + 1
	var atti_rete: Array = []
	var parziale: Array = []
	var n2 := 0
	while per_atto.has(n2):
		var d2: Dictionary = per_atto[n2]
		if d2.get("c", false):
			atti_rete.append(d2["r"])
		else:
			parziale = d2["r"]
			break
		n2 += 1
	_avvia_online(cfg, mio)
	net_k = ultimo
	avvia(int(cfg["seme"]), cfg.get("opz", {}), atti_rete, parziale)
	info_lbl.text = "Di nuovo nella stanza %s." % code


var _da_inviare: Array = []
var _sync_attivo := false


func _invia_rete(n: int, r: Array, concluso: bool) -> void:
	if not online or stanza == "":
		return
	if r.is_empty() and not concluso:
		return
	var key := "%d:%d" % [n, r.size()]
	if net_inviati.has(key):
		return
	net_inviati[key] = true
	_da_inviare.append({"n": n, "r": r.duplicate(), "c": concluso})
	_sync()


func _sync() -> void:
	if _sync_attivo or not online or stanza == "":
		return
	_sync_attivo = true
	var giri := 0
	while giri < 20:
		giri += 1
		await _leggi_rete()
		if _da_inviare.is_empty():
			break
		var d: Dictionary = _da_inviare[0]
		var ok = await rete.post_decision(stanza, net_k, d)
		if ok:
			net_k += 1
			_da_inviare.pop_front()
	_sync_attivo = false


func _leggi_rete() -> void:
	var dd = await rete.get_decisions(stanza, net_k)
	var chiavi: Array = dd.keys()
	chiavi.sort()
	for k in chiavi:
		if int(k) < net_k:
			continue
		var d: Dictionary = dd[k]
		net_k = int(k) + 1
		var n := int(d.get("n", -1))
		var r: Array = d.get("r", [])
		net_inviati["%d:%d" % [n, r.size()]] = true
		if n == atti.size() and r.size() > ans.size():
			ans = r
			piano = []
			_passo()
