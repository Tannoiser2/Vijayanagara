## Aspetto dell'interfaccia: pergamena delle carte, cartigli bruniti, turchese, zafferano e grigio delle tre fazioni.
## Stessa struttura della GUI COIN di Cuba Libre (barra in alto, mappa, pannello azione a destra, registro).
## Caratteri: El Messiri (titoli, come sul tabellone e sulle carte) e Crimson Pro (testi, simile al Minion delle regole).
class_name Tema
extends RefCounted

const BG := Color("13201d")
const BAR := Color("1d1a13")
const BAR_LINE := Color("4a3f28")
const PAPER := Color("efe4c6")
const PAPER_DARK := Color("ddcda3")
const PAPER_EDGE := Color("b29f73")
const INK := Color("2a2118")
const INK_DIM := Color("5e5140")
const INK_FAINT := Color("8f8064")
const GOLD := Color("c9a24a")
const GOLD_HI := Color("f2d27a")
const TEXT := Color("efe4c6")
const TEXT_DIM := Color("b4ab95")
const LOG_BG := Color("1c2622")
const SCROLL := Color("4b3f22")

const FAZ := {"D": Color("4c534d"), "B": Color("17918f"), "V": Color("d39a12"), "M": Color("9b2a22")}
const FAZ_CHIARO := {"D": Color("a9b0a8"), "B": Color("6fd3cf"), "V": Color("f6cc5a"), "M": Color("e07a6a")}

const FONT_DIR := "res://assets/fonts/"
static var _f: Dictionary = {}


static func _font(file: String) -> Font:
	if not _f.has(file):
		_f[file] = load(FONT_DIR + file) if ResourceLoader.exists(FONT_DIR + file) else ThemeDB.fallback_font
	return _f[file]


static func titolo() -> Font: return _font("ElMessiri-SemiBold.ttf")
static func titolo_forte() -> Font: return _font("ElMessiri-Bold.ttf")
static func messiri() -> Font: return _font("ElMessiri-Regular.ttf")
static func ui() -> Font: return _font("CrimsonPro-Regular.ttf")
static func ui_med() -> Font: return _font("CrimsonPro-Medium.ttf")
static func ui_bold() -> Font: return _font("CrimsonPro-SemiBold.ttf")
static func ui_heavy() -> Font: return _font("CrimsonPro-Bold.ttf")
static func ui_it() -> Font: return _font("CrimsonPro-Italic.ttf")
static func ui_bold_it() -> Font: return _font("CrimsonPro-BoldItalic.ttf")


static func box(bg: Color, border: Color, bw: int = 1, radius: int = 4, m: float = 8.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(bw)
	s.border_color = border
	s.content_margin_left = m + 2
	s.content_margin_right = m + 2
	s.content_margin_top = m * 0.5
	s.content_margin_bottom = m * 0.5
	return s


static func carta(m: float = 12.0) -> StyleBoxFlat:
	var s := box(PAPER, Color("c2ad7c"), 1, 6, m)
	s.content_margin_top = m
	s.content_margin_bottom = m
	s.shadow_color = Color(0, 0, 0, 0.4)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	return s


static func tema() -> Theme:
	var t := Theme.new()
	t.default_font = ui()
	t.default_font_size = 18
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("normal", "Button", box(Color("2a2417"), Color("5c4d2c")))
	t.set_stylebox("hover", "Button", box(Color("3a311d"), GOLD))
	t.set_stylebox("pressed", "Button", box(Color("191510"), GOLD))
	t.set_stylebox("disabled", "Button", box(Color("201c14"), Color("3a3220")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GOLD_HI)
	t.set_color("font_pressed_color", "Button", GOLD_HI)
	t.set_color("font_disabled_color", "Button", Color("6d6450"))
	t.set_font("font", "Button", ui_heavy())
	t.set_font_size("font_size", "Button", 18)
	t.set_stylebox("panel", "PanelContainer", carta())
	t.set_stylebox("normal", "LineEdit", box(Color("f8f0dc"), PAPER_EDGE, 1, 4, 8))
	t.set_stylebox("focus", "LineEdit", box(Color("fcf6e8"), GOLD, 2, 4, 8))
	t.set_color("font_color", "LineEdit", INK)
	t.set_font_size("font_size", "LineEdit", 20)
	t.set_stylebox("panel", "PopupPanel", carta(16))
	t.set_stylebox("panel", "AcceptDialog", carta(16))
	t.set_color("font_color", "RichTextLabel", TEXT)
	t.set_font("normal_font", "RichTextLabel", ui())
	t.set_font("bold_font", "RichTextLabel", ui_heavy())
	t.set_font("italics_font", "RichTextLabel", ui_it())
	t.set_font_size("normal_font_size", "RichTextLabel", 17)
	t.set_font_size("bold_font_size", "RichTextLabel", 17)
	t.set_font_size("italics_font_size", "RichTextLabel", 17)
	t.set_stylebox("grabber", "VScrollBar", box(Color("6a5a35"), Color("6a5a35"), 0, 3, 2))
	t.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0.15), Color(0, 0, 0, 0), 0, 3, 2))
	return t


## Tasto su pergamena (pannello azione).
static func tasto_carta(b: Button, primario: bool = false, colore: Color = Color("6b4f1d")) -> void:
	if primario:
		b.add_theme_stylebox_override("normal", box(colore.darkened(0.15), colore.darkened(0.5), 1, 4))
		b.add_theme_stylebox_override("hover", box(colore, GOLD, 2, 4))
		b.add_theme_stylebox_override("pressed", box(colore.darkened(0.3), GOLD, 2, 4))
		b.add_theme_stylebox_override("hover_pressed", box(colore, GOLD, 2, 4))
		b.add_theme_stylebox_override("disabled", box(colore.darkened(0.15).lerp(Color("a89a7a"), 0.55), colore.darkened(0.5), 1, 4))
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.6))
	else:
		b.add_theme_stylebox_override("normal", box(Color("f8f0dc"), Color("8d7a55"), 1, 4))
		b.add_theme_stylebox_override("hover", box(Color("fff8e6"), colore, 2, 4))
		b.add_theme_stylebox_override("pressed", box(PAPER_DARK, colore, 2, 4))
		b.add_theme_stylebox_override("disabled", box(Color("e6dcc4"), Color("c5b590"), 1, 4))
		b.add_theme_color_override("font_color", INK)
		b.add_theme_color_override("font_hover_color", colore.darkened(0.3))
		b.add_theme_color_override("font_pressed_color", INK)
		b.add_theme_color_override("font_hover_pressed_color", INK)
		b.add_theme_stylebox_override("hover_pressed", box(Color("fff8e6"), colore, 2, 4))
		b.add_theme_color_override("font_disabled_color", INK_FAINT)


static func icona(k: String) -> Texture2D:
	var p := "res://assets/icone/%s.png" % k
	return load(p) if ResourceLoader.exists(p) else null
