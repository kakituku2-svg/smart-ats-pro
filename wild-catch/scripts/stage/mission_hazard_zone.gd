extends Node3D
class_name MissionHazardZone

enum Kind { UPDRAFT, GLOW_MUD }

@export var kind := Kind.UPDRAFT
@export var radius := 3.4
@export var strength := 6.2
@export var accent_color := Color(0.34, 0.86, 1.0, 1.0)
@export var affects_mimo := true

var _time := 0.0
var _rings: Array[MeshInstance3D] = []
var _surface: MeshInstance3D

func _ready() -> void:
    add_to_group("mission_hazard")
    _build_visual()

func _process(delta: float) -> void:
    _time += delta
    if kind == Kind.UPDRAFT:
        _tick_updraft(delta)
    else:
        _tick_glow_mud(delta)
    _animate_visual()

func _tick_updraft(delta: float) -> void:
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player != null and _flat_distance(player.global_position, global_position) <= radius:
        player.velocity.y = maxf(player.velocity.y, strength)
        var outward := player.global_position - global_position
        outward.y = 0.0
        if outward.length_squared() > 0.01:
            outward = outward.normalized()
            player.velocity.x += outward.x * delta * 2.0
            player.velocity.z += outward.z * delta * 2.0
    if not affects_mimo:
        return
    for node in get_tree().get_nodes_in_group("mimo"):
        var mimo := node as MimoBase
        if mimo == null or mimo.state == MimoBase.State.CAPTURED:
            continue
        if _flat_distance(mimo.global_position, global_position) <= radius:
            mimo.velocity.y = maxf(mimo.velocity.y, strength * 0.62)
            var tangent := Vector3(-(mimo.global_position.z - global_position.z), 0.0, mimo.global_position.x - global_position.x)
            if tangent.length_squared() > 0.01:
                tangent = tangent.normalized()
                mimo.velocity.x += tangent.x * delta * 3.2
                mimo.velocity.z += tangent.z * delta * 3.2

func _tick_glow_mud(_delta: float) -> void:
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player != null and _flat_distance(player.global_position, global_position) <= radius:
        player.apply_slow(0.56, 0.24)

func _flat_distance(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x - b.x, a.z - b.z).length()

func _animate_visual() -> void:
    if kind == Kind.UPDRAFT:
        for i in range(_rings.size()):
            var ring := _rings[i]
            var phase := fmod(_time * (0.52 + float(i) * 0.06) + float(i) * 0.22, 1.0)
            ring.position.y = 0.18 + phase * 3.8
            var scale_value := 0.74 + phase * 0.72
            ring.scale = Vector3.ONE * scale_value
            var material := ring.material_override as StandardMaterial3D
            if material != null:
                var color := material.albedo_color
                color.a = 0.64 * (1.0 - phase)
                material.albedo_color = color
            ring.rotation.y += 0.012 + float(i) * 0.002
    elif _surface != null:
        var pulse := 0.92 + sin(_time * 2.2) * 0.08
        _surface.scale = Vector3(radius * 2.0 * pulse, 0.08, radius * 2.0 * pulse)
        _surface.rotation.y += 0.002

func _build_visual() -> void:
    if kind == Kind.UPDRAFT:
        for i in range(5):
            var ring := MeshInstance3D.new()
            ring.name = "WindRing%d" % (i + 1)
            var torus := TorusMesh.new()
            torus.inner_radius = radius * 0.54
            torus.outer_radius = radius * 0.60
            torus.rings = 20
            torus.ring_segments = 8
            ring.mesh = torus
            ring.rotation_degrees.x = 90.0
            ring.material_override = _material(accent_color, true, 0.30)
            ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            add_child(ring)
            _rings.append(ring)
    else:
        _surface = MeshInstance3D.new()
        _surface.name = "GlowMudSurface"
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.50
        mesh.bottom_radius = 0.56
        mesh.height = 0.06
        mesh.radial_segments = 28
        _surface.mesh = mesh
        _surface.scale = Vector3(radius * 2.0, 0.08, radius * 2.0)
        _surface.position.y = 0.05
        _surface.material_override = _material(accent_color, true, 0.42)
        _surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(_surface)
        for i in range(8):
            var bubble := MeshInstance3D.new()
            bubble.name = "MudGlow%d" % (i + 1)
            var sphere := SphereMesh.new()
            sphere.radius = 0.08 + float(i % 3) * 0.025
            sphere.height = sphere.radius * 2.0
            sphere.radial_segments = 8
            sphere.rings = 4
            bubble.mesh = sphere
            var angle := TAU * float(i) / 8.0
            var rr := radius * (0.34 + float(i % 3) * 0.18)
            bubble.position = Vector3(sin(angle) * rr, 0.13, cos(angle) * rr)
            bubble.material_override = _material(accent_color.lightened(0.20), true, 0.85)
            bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            add_child(bubble)

func _material(color: Color, emissive: bool, alpha: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(color.r, color.g, color.b, alpha)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.roughness = 0.42 if emissive else 0.86
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.9
    return mat
