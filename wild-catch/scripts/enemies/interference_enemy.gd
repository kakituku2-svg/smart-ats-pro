extends CharacterBody3D
class_name InterferenceEnemy

signal defeated(enemy: InterferenceEnemy)
signal damaged(enemy: InterferenceEnemy, health: int)

@export var variant_id: StringName = &"guard_bug"
@export var display_name := "ガードバグ"
@export var max_health := 3
@export var move_speed := 3.8
@export var chase_radius := 9.0
@export var attack_radius := 1.15
@export var attack_cooldown := 1.15
@export var accent_color := Color(1.0, 0.34, 0.22, 1.0)

var health := 3
var _cooldown := 0.0
var _stun := 0.0
var _dead := false
var _time := 0.0
var _spawn_y := 0.0
var _visual: Node3D
var _eye: MeshInstance3D

func _ready() -> void:
    add_to_group("interference_enemy")
    add_to_group("pulse_target")
    _apply_variant_profile()
    health = max_health
    _spawn_y = global_position.y
    _build_visual()
    _build_collision()

func _apply_variant_profile() -> void:
    match variant_id:
        &"wind_stinger":
            display_name = "ウィンドスティンガー"; max_health = 2; move_speed = 5.5; chase_radius = 11.5; attack_radius = 1.55; attack_cooldown = 1.30
        &"glow_leech":
            display_name = "グロウリーチ"; max_health = 3; move_speed = 2.75; chase_radius = 8.5; attack_radius = 2.25; attack_cooldown = 1.70
        _:
            variant_id = &"guard_bug"; display_name = "ガードバグ"; max_health = 3; move_speed = 3.8; chase_radius = 9.0; attack_radius = 1.15; attack_cooldown = 1.15

func _physics_process(delta: float) -> void:
    if _dead: return
    _time += delta
    _cooldown = maxf(0.0, _cooldown - delta)
    _stun = maxf(0.0, _stun - delta)
    _animate_visual()
    if _stun > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
        _apply_vertical_motion(delta); move_and_slide(); return
    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player == null: return
    var offset := player.global_position - global_position
    offset.y = 0.0
    var distance := offset.length()
    if distance <= chase_radius and distance > 0.05:
        var direction := offset / distance
        var desired_speed := move_speed
        if variant_id == &"wind_stinger": desired_speed *= 0.88 + sin(_time * 4.6) * 0.12
        velocity.x = move_toward(velocity.x, direction.x * desired_speed, 13.0 * delta)
        velocity.z = move_toward(velocity.z, direction.z * desired_speed, 13.0 * delta)
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), clampf(delta * 9.0, 0.0, 1.0))
        if distance <= attack_radius and _cooldown <= 0.0:
            _cooldown = attack_cooldown
            _perform_attack(player, direction)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
    _apply_vertical_motion(delta)
    move_and_slide()

func _perform_attack(player: PlayerController, direction: Vector3) -> void:
    match variant_id:
        &"glow_leech": player.apply_slow(0.52, 1.8); player.add_camera_impulse(Vector2(3.0, -2.0)); AudioManager.play_event(&"warning")
        &"wind_stinger":
            if player.take_damage(1, -direction * 1.35): player.add_camera_impulse(Vector2(7.0, -4.0)); AudioManager.play_event(&"warning")
        _:
            if player.take_damage(1, -direction): AudioManager.play_event(&"warning")

func _apply_vertical_motion(delta: float) -> void:
    if variant_id == &"wind_stinger":
        var target_y := _spawn_y + 0.78 + sin(_time * 3.2) * 0.18
        global_position.y = move_toward(global_position.y, target_y, delta * 2.8)
        velocity.y = 0.0; return
    if not is_on_floor(): velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta

func trigger_pulse(target: Vector3) -> bool:
    if _dead or global_position.distance_to(target) > 4.2: return false
    health = maxi(0, health - 1); _stun = 0.80 if variant_id == &"wind_stinger" else 0.62
    AudioManager.play_event(&"enemy_hit"); damaged.emit(self, health); _flash_hit()
    if health <= 0: _defeat()
    return true

func _defeat() -> void:
    if _dead: return
    _dead = true; velocity = Vector3.ZERO; AudioManager.play_event(&"enemy_down"); remove_from_group("pulse_target"); defeated.emit(self)
    var tween := create_tween().set_parallel(true)
    tween.tween_property(self, "scale", Vector3(1.35, 0.18, 1.35), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    tween.tween_property(self, "rotation:y", rotation.y + TAU, 0.32)
    await get_tree().create_timer(0.34).timeout; queue_free()

func _flash_hit() -> void:
    if _visual == null: return
    var tween := create_tween(); tween.tween_property(_visual, "scale", Vector3.ONE * 1.18, 0.06); tween.tween_property(_visual, "scale", Vector3.ONE, 0.12)

func _animate_visual() -> void:
    if _visual != null:
        var bob_speed := 7.0 if variant_id == &"wind_stinger" else 5.2
        var bob_amount := 0.065 if variant_id == &"wind_stinger" else 0.035
        _visual.position.y = 0.48 + sin(_time * bob_speed) * bob_amount
        if variant_id == &"glow_leech": _visual.rotation.z = sin(_time * 2.2) * 0.08
    if _eye != null:
        var pulse_speed := 9.0 if variant_id == &"wind_stinger" else 7.0
        _eye.scale = Vector3.ONE * (0.95 + sin(_time * pulse_speed) * 0.08)

func _build_collision() -> void:
    var collision := CollisionShape3D.new(); var shape := CapsuleShape3D.new()
    if variant_id == &"wind_stinger": shape.radius = 0.44; shape.height = 0.92; collision.position.y = 0.48
    elif variant_id == &"glow_leech": shape.radius = 0.62; shape.height = 1.06; collision.position.y = 0.54
    else: shape.radius = 0.54; shape.height = 1.15; collision.position.y = 0.58
    collision.shape = shape; add_child(collision)

func _build_visual() -> void:
    _visual = Node3D.new(); _visual.name = "Visual"; add_child(_visual)
    match variant_id:
        &"wind_stinger": _build_wind_stinger_visual()
        &"glow_leech": _build_glow_leech_visual()
        _: _build_guard_bug_visual()

func _build_guard_bug_visual() -> void:
    var shell := _sphere("Shell", Vector3.ZERO, Vector3(1.25,0.72,1.0), Color(0.14,0.17,0.20,1), false, 0.52); shell.position.y=0
    _sphere("Armor", Vector3(0,0.18,0.05), Vector3(1.18,0.45,0.86), accent_color.darkened(0.30), false, 0.44)
    _eye=_sphere("SensorEye",Vector3(0,0.10,-0.50),Vector3.ONE,accent_color.lightened(0.25),true,0.11)
    for side in [-1.0,1.0]:
        for row in [-0.28,0.22]: _limb("Leg",Vector3(side*0.58,-0.18,row),Vector3(0,0,side*-58.0),0.72,Color(0.09,0.11,0.13,1))
        _limb("Antenna",Vector3(side*0.22,0.56,-0.12),Vector3(-22,0,side*-18.0),0.62,accent_color.darkened(0.15))

func _build_wind_stinger_visual() -> void:
    _sphere("Core",Vector3(0,0.10,0),Vector3(0.88,0.72,1.12),Color(0.08,0.16,0.22,1),false,0.44)
    _sphere("Armor",Vector3(0,0.16,-0.06),Vector3(0.82,0.48,0.90),accent_color.darkened(0.20),false,0.38)
    _eye=_sphere("SensorEye",Vector3(0,0.13,-0.47),Vector3(0.86,0.86,0.58),accent_color.lightened(0.32),true,0.10)
    for side in [-1.0,1.0]:
        var wing:=MeshInstance3D.new(); wing.name="WindWing"; var wing_mesh:=PrismMesh.new(); wing_mesh.size=Vector3(0.18,0.62,0.56); wing.mesh=wing_mesh; wing.position=Vector3(side*0.43,0.10,0.06); wing.rotation=Vector3(0.05,0,side*0.78); wing.material_override=_mat(accent_color.lightened(0.18),true); _visual.add_child(wing)
        _limb("Stinger",Vector3(side*0.16,0.56,0.15),Vector3(-18,0,side*-12.0),0.42,accent_color.darkened(0.12))
    var tail:=_limb("TailSpike",Vector3(0,0,0.52),Vector3(75,0,0),0.62,Color(0.18,0.24,0.28,1)); tail.scale=Vector3(0.78,1,0.78)

func _build_glow_leech_visual() -> void:
    _sphere("Body",Vector3(0,-0.02,0),Vector3(1.52,0.66,1.25),Color(0.08,0.13,0.16,1),false,0.54)
    _sphere("GlowBack",Vector3(0,0.22,0.10),Vector3(1.25,0.30,0.92),accent_color.darkened(0.08),true,0.44)
    _eye=_sphere("SensorEye",Vector3(0,0.02,-0.55),Vector3(1.15,0.72,0.50),accent_color.lightened(0.34),true,0.12)
    for i in range(5):
        var angle:=TAU*float(i)/5.0; var tendril:=_limb("Tendril",Vector3(sin(angle)*0.42,-0.22,cos(angle)*0.34),Vector3(62,angle,sin(angle)*18.0),0.58,accent_color.darkened(0.22)); tendril.scale=Vector3(0.70,1,0.70)
    for side in [-1.0,1.0]: _sphere("GlowNode",Vector3(side*0.42,0.11,0.18),Vector3(0.70,0.70,0.70),accent_color.lightened(0.20),true,0.09)

func _sphere(node_name:String,pos:Vector3,scale_value:Vector3,color:Color,emissive:bool,radius:float)->MeshInstance3D:
    var node:=MeshInstance3D.new(); node.name=node_name; node.position=pos; node.scale=scale_value; var mesh:=SphereMesh.new(); mesh.radius=radius; mesh.height=radius*2.0; mesh.radial_segments=10; mesh.rings=5; node.mesh=mesh; node.material_override=_mat(color,emissive); _visual.add_child(node); return node
func _limb(node_name:String,pos:Vector3,rotation_degrees_value:Vector3,height:float,color:Color)->MeshInstance3D:
    var node:=MeshInstance3D.new(); node.name=node_name; node.position=pos; node.rotation_degrees=rotation_degrees_value; var mesh:=CylinderMesh.new(); mesh.top_radius=0.038; mesh.bottom_radius=0.062; mesh.height=height; mesh.radial_segments=6; node.mesh=mesh; node.material_override=_mat(color,false); _visual.add_child(node); return node
func _mat(color:Color,emissive:bool)->StandardMaterial3D:
    var mat:=StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=0.62 if emissive else 0.88
    if emissive: mat.emission_enabled=true; mat.emission=color; mat.emission_energy_multiplier=2.1
    return mat
