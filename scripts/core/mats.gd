class_name Mats
extends RefCounted
## Shared material factory so identical materials are reused.

const TOON := preload("res://shaders/toon.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")
const WATER := preload("res://shaders/water.gdshader")

static var _cache := {}
static var _detail: Texture2D


static func detail_texture() -> Texture2D:
	if _detail != null:
		return _detail
	var img := Image.create(32, 32, false, Image.FORMAT_L8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for y in range(32):
		for x in range(32):
			var v := 0.5 + rng.randf_range(-0.22, 0.22)
			# a few darker speckles for grass blades / pebbles
			if rng.randf() < 0.08:
				v -= 0.25
			if rng.randf() < 0.05:
				v += 0.2
			img.set_pixel(x, y, Color(v, v, v))
	img.generate_mipmaps()
	_detail = ImageTexture.create_from_image(img)
	return _detail


## Vertex coloured, cel-shaded material for merged world meshes.
static func world(detail := 0.0, sway := 0.0) -> ShaderMaterial:
	var key := "world_%.2f_%.2f" % [detail, sway]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("use_vertex_color", true)
	m.set_shader_parameter("albedo", Color.WHITE)
	if detail > 0.0:
		m.set_shader_parameter("detail_tex", detail_texture())
		m.set_shader_parameter("detail_strength", detail)
	m.set_shader_parameter("sway", sway)
	_cache[key] = m
	return m


## Solid colour cel material, optionally with an outline pass.
static func solid(c: Color, outline := true, outline_width := 0.035) -> ShaderMaterial:
	var key := "solid_%s_%s_%.3f" % [c.to_html(), outline, outline_width]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("use_vertex_color", false)
	m.set_shader_parameter("albedo", c)
	m.set_shader_parameter("rim_strength", 0.15)
	if outline:
		var o := ShaderMaterial.new()
		o.shader = OUTLINE
		o.set_shader_parameter("width", outline_width)
		m.next_pass = o
	_cache[key] = m
	return m


## Emissive (glowing) solid colour – windows, lanterns, fire.
static func glow(c: Color, energy := 1.0) -> ShaderMaterial:
	var key := "glow_%s_%.2f" % [c.to_html(), energy]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("use_vertex_color", false)
	m.set_shader_parameter("albedo", c)
	m.set_shader_parameter("emission_color", c)
	m.set_shader_parameter("emission_energy", energy)
	_cache[key] = m
	return m


static func unshaded(c: Color, transparent := false) -> StandardMaterial3D:
	var key := "unshaded_%s_%s" % [c.to_html(), transparent]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.vertex_color_use_as_albedo = true
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_cache[key] = m
	return m


static func water() -> ShaderMaterial:
	if _cache.has("water"):
		return _cache["water"]
	var m := ShaderMaterial.new()
	m.shader = WATER
	_cache["water"] = m
	return m
