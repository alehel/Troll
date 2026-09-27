class_name UiTheme
extends RefCounted
## Cosy pixel-art UI theme built in code (cream paper panels, brown ink).

const INK := Color(0.25, 0.17, 0.13)
const INK_SOFT := Color(0.45, 0.35, 0.28)
const PAPER := Color(0.98, 0.94, 0.85)
const PAPER_DARK := Color(0.9, 0.83, 0.7)
const BORDER := Color(0.32, 0.21, 0.15)
const ACCENT := Color(0.82, 0.32, 0.27)
const GREEN := Color(0.36, 0.58, 0.3)
const NIGHT := Color(0.13, 0.12, 0.16, 0.9)

const FONT_SIZE := 11
const SMALL := 9
const BIG := 16
const HUGE := 32

static var font: FontFile
static var font_bold: FontFile
static var theme: Theme


static func _prep_font(path: String) -> FontFile:
	var f: FontFile = load(path)
	f = f.duplicate()
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.multichannel_signed_distance_field = false
	f.generate_mipmaps = false
	return f


static func box(bg: Color, border: Color, bw := 2, radius := 3, shadow := true, margin := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.corner_detail = 2
	s.anti_aliasing = false
	s.set_content_margin_all(margin)
	if shadow:
		s.shadow_color = Color(0.1, 0.06, 0.04, 0.35)
		s.shadow_size = 1
		s.shadow_offset = Vector2(2, 2)
	return s


static func get_theme() -> Theme:
	if theme != null:
		return theme
	font = _prep_font("res://assets/fonts/PixelifySans-Regular.woff2")
	font_bold = _prep_font("res://assets/fonts/PixelifySans-Bold.woff2")
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = FONT_SIZE
	t.set_stylebox("panel", "PanelContainer", box(PAPER, BORDER))
	t.set_stylebox("panel", "Panel", box(PAPER, BORDER))
	t.set_color("font_color", "Label", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font("normal_font", "RichTextLabel", font)
	t.set_font("bold_font", "RichTextLabel", font_bold)
	t.set_font_size("normal_font_size", "RichTextLabel", FONT_SIZE)
	t.set_font_size("bold_font_size", "RichTextLabel", FONT_SIZE)
	t.set_constant("line_separation", "RichTextLabel", 1)
	t.set_constant("line_spacing", "Label", 1)
	# buttons
	t.set_stylebox("normal", "Button", box(PAPER_DARK, BORDER, 2, 3, false, 4))
	t.set_stylebox("hover", "Button", box(Color(1.0, 0.97, 0.88), BORDER, 2, 3, false, 4))
	t.set_stylebox("pressed", "Button", box(Color(0.82, 0.74, 0.6), BORDER, 2, 3, false, 4))
	t.set_stylebox("disabled", "Button", box(Color(0.85, 0.82, 0.76), Color(0.6, 0.55, 0.5), 2, 3, false, 4))
	var focus := box(Color(0, 0, 0, 0), ACCENT, 2, 3, false, 4)
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_focus_color", "Button", ACCENT.darkened(0.2))
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.5, 0.45))
	t.set_constant("h_separation", "Button", 4)
	# line edit
	t.set_stylebox("normal", "LineEdit", box(Color(1, 1, 1), BORDER, 2, 2, false, 4))
	t.set_stylebox("focus", "LineEdit", focus)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("caret_color", "LineEdit", ACCENT)
	# sliders / progress
	var track := box(PAPER_DARK, BORDER, 1, 2, false, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", box(ACCENT, BORDER, 1, 2, false, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(ACCENT.lightened(0.2), BORDER, 1, 2, false, 0))
	t.set_stylebox("background", "ProgressBar", box(PAPER_DARK, BORDER, 1, 2, false, 0))
	t.set_stylebox("fill", "ProgressBar", box(GREEN, BORDER, 1, 2, false, 0))
	t.set_color("font_color", "ProgressBar", INK)
	t.set_stylebox("panel", "TooltipPanel", box(PAPER, BORDER))
	t.set_color("font_color", "CheckButton", INK)
	t.set_color("font_hover_color", "CheckButton", INK)
	t.set_color("font_focus_color", "CheckButton", ACCENT.darkened(0.2))
	t.set_color("font_pressed_color", "CheckButton", INK)
	t.set_stylebox("focus", "CheckButton", focus)
	t.set_stylebox("normal", "CheckButton", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, false, 3))
	t.set_stylebox("hover", "CheckButton", box(Color(1, 1, 1, 0.3), Color(0, 0, 0, 0), 0, 0, false, 3))
	t.set_stylebox("pressed", "CheckButton", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, false, 3))
	theme = t
	return t


static func label(text: String, size := FONT_SIZE, color := INK, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		get_theme()
		l.add_theme_font_override("font", font_bold)
	return l


static func icon(id: String, size := 16) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Icons.get_texture(id)
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return r


static func panel(bg := PAPER, border := BORDER) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border))
	return p


static func button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	return b
