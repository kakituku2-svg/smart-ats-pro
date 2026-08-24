extends RefCounted
class_name GameUISkin

static func panel(accent: Color = Color(0.28, 0.92, 0.78, 1.0), alpha: float = 0.90, radius: int = 20) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.018, 0.060, 0.075, alpha)
    box.border_width_left = 2
    box.border_width_top = 2
    box.border_width_right = 2
    box.border_width_bottom = 2
    box.border_color = Color(accent.r, accent.g, accent.b, 0.62)
    box.corner_radius_top_left = radius
    box.corner_radius_top_right = radius
    box.corner_radius_bottom_left = radius
    box.corner_radius_bottom_right = radius
    box.shadow_color = Color(0, 0, 0, 0.34)
    box.shadow_size = 9
    return box

static func button_normal(accent: Color) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.025, 0.14, 0.16, 0.94)
    box.border_width_left = 2
    box.border_width_top = 2
    box.border_width_right = 2
    box.border_width_bottom = 2
    box.border_color = Color(accent.r, accent.g, accent.b, 0.68)
    box.corner_radius_top_left = 17
    box.corner_radius_top_right = 17
    box.corner_radius_bottom_left = 17
    box.corner_radius_bottom_right = 17
    return box

static func button_hover(accent: Color) -> StyleBoxFlat:
    var box := button_normal(accent)
    box.bg_color = Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 0.96)
    box.border_color = Color(accent.r, accent.g, accent.b, 1.0)
    box.shadow_color = Color(accent.r, accent.g, accent.b, 0.22)
    box.shadow_size = 8
    return box

static func button_pressed(accent: Color) -> StyleBoxFlat:
    var box := button_normal(accent)
    box.bg_color = Color(accent.r * 0.34, accent.g * 0.34, accent.b * 0.34, 0.98)
    box.border_color = Color(1.0, 1.0, 0.86, 0.95)
    return box

static func style_button(button: Button, accent: Color = Color(0.28, 0.92, 0.78, 1.0), font_size: int = 18) -> void:
    if button == null:
        return
    button.add_theme_stylebox_override("normal", button_normal(accent))
    button.add_theme_stylebox_override("hover", button_hover(accent))
    button.add_theme_stylebox_override("pressed", button_pressed(accent))
    button.add_theme_stylebox_override("focus", button_hover(accent))
    button.add_theme_color_override("font_color", Color(0.97, 1.0, 0.93, 1.0))
    button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.65, 1.0))
    button.add_theme_color_override("font_pressed_color", Color.WHITE)
    button.add_theme_color_override("font_outline_color", Color(0.015, 0.07, 0.075, 1.0))
    button.add_theme_constant_override("outline_size", 5)
    button.add_theme_font_size_override("font_size", font_size)

static func style_panel(panel_node: PanelContainer, accent: Color = Color(0.28, 0.92, 0.78, 1.0)) -> void:
    if panel_node != null:
        panel_node.add_theme_stylebox_override("panel", panel(accent))

static func style_heading(label: Label, accent: Color = Color(0.58, 1.0, 0.72, 1.0), font_size: int = 30) -> void:
    if label == null:
        return
    label.add_theme_color_override("font_color", accent)
    label.add_theme_color_override("font_outline_color", Color(0.015, 0.07, 0.07, 1.0))
    label.add_theme_constant_override("outline_size", 7)
    label.add_theme_font_size_override("font_size", font_size)

static func style_body(label: Label, font_size: int = 17) -> void:
    if label == null:
        return
    label.add_theme_color_override("font_color", Color(0.92, 0.98, 0.96, 1.0))
    label.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.05, 0.95))
    label.add_theme_constant_override("outline_size", 3)
    label.add_theme_font_size_override("font_size", font_size)

static func style_slider(slider: HSlider, accent: Color = Color(0.32, 0.92, 0.78, 1.0)) -> void:
    if slider == null:
        return
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0.03, 0.12, 0.14, 0.88)
    bg.corner_radius_top_left = 8
    bg.corner_radius_top_right = 8
    bg.corner_radius_bottom_left = 8
    bg.corner_radius_bottom_right = 8
    slider.add_theme_stylebox_override("slider", bg)
    var area := StyleBoxFlat.new()
    area.bg_color = Color(accent.r, accent.g, accent.b, 0.88)
    area.corner_radius_top_left = 8
    area.corner_radius_top_right = 8
    area.corner_radius_bottom_left = 8
    area.corner_radius_bottom_right = 8
    slider.add_theme_stylebox_override("grabber_area", area)
    slider.add_theme_stylebox_override("grabber_area_highlight", area)
