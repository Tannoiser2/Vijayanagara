## Screenshot: godot --path . -s res://tools/screenshot.gd -- modo(menu|demo|D) frames file [atti]
extends SceneTree
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var scena = load("res://scenes/main.tscn").instantiate()
	root.add_child(scena)
	root.size = Vector2i(1600, 900)
	await process_frame
	await process_frame
	if a[0] != "menu":
		if a[0] == "demo":
			scena._nuova_locale(true)
		elif a[0] == "bot":
			scena.scelta_menu = {"D": "umano", "B": "bot", "V": "bot"}
			scena._nuova_locale(false)
		else:
			scena.scelta_menu = {"D": "ia", "B": "ia", "V": "ia"}
			scena.scelta_menu[a[0]] = "umano"
			scena._nuova_locale(false)
	var n := int(a[1])
	var t0 := Time.get_ticks_msec()
	var atti := int(a[3]) if a.size() > 3 else 0
	while scena.m != null and scena.atti.size() < atti and Time.get_ticks_msec() - t0 < 120000:
		await process_frame
		if scena.m.need != null and scena.controllo.get(scena.m.need["f"], "") == "umano":
			var o: Array = scena.m.need["opz"]
			scena.rispondi(o[randi() % o.size()]["v"])
	if a.size() > 4 and scena.mappa:
		var c: Vector2 = scena.mappa.size * Vector2(float(a[4]), float(a[5]))
		scena.mappa.zoom_a(scena.mappa.zoom * 2.6, c)
	for i in n:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(a[2])
	print("salvato ", a[2], " atti ", scena.atti.size() if scena.m else -1)
	quit()
