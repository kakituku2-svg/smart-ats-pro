extends RefCounted
class_name ProductionArtPaths

const REN_GLB := "res://art/characters/ren/ren.glb"
const REN_GLTF := "res://art/characters/ren/ren.gltf"
const REN_PREVIEW := "res://art/characters/ren/ren_preview_v3.tscn"
const REN_PREVIEW_V2 := "res://art/characters/ren/ren_preview_v2.tscn"
const REN_PREVIEW_LEGACY := "res://art/characters/ren/ren_preview.tscn"
const STAGE1_GLB := "res://art/environment/stage1/stage1_set.glb"
const STAGE1_GLTF := "res://art/environment/stage1/stage1_set.gltf"
const STAGE1_PREVIEW := "res://art/environment/stage1/stage1_preview_v2.tscn"
const STAGE1_PREVIEW_LEGACY := "res://art/environment/stage1/stage1_preview.tscn"
const STAGE2_GLB := "res://art/environment/stage2/stage2_skywind.glb"
const STAGE2_GLTF := "res://art/environment/stage2/stage2_skywind.gltf"
const STAGE3_GLB := "res://art/environment/stage3/stage3_neon_swamp.glb"
const STAGE3_GLTF := "res://art/environment/stage3/stage3_neon_swamp.gltf"
const HUB_GLB := "res://art/environment/hub/field_base_set.glb"
const HUB_GLTF := "res://art/environment/hub/field_base_set.gltf"
const MIMO_SHARED_PREVIEW := "res://art/mimo/mimo_preview_base_v2.tscn"
const MIMO_SHARED_PREVIEW_LEGACY := "res://art/mimo/mimo_preview_base.tscn"
const LUMI_PREVIEW := "res://art/mimo/lumi/lumi_preview_v3.tscn"
const LUMI_PREVIEW_V2 := "res://art/mimo/lumi/lumi_preview_v2.tscn"

# Backward-compatible primary constants used by docs/QA.
const REN_SCENE := REN_GLB
const STAGE1_SCENE := STAGE1_GLB

static func ren_scene() -> PackedScene:
    return try_load_first([REN_GLB, REN_GLTF, REN_PREVIEW, REN_PREVIEW_V2, REN_PREVIEW_LEGACY])

static func stage1_scene() -> PackedScene:
    return try_load_first([STAGE1_GLB, STAGE1_GLTF, STAGE1_PREVIEW, STAGE1_PREVIEW_LEGACY])

static func mission_environment_scene(stage_id: StringName) -> PackedScene:
    match stage_id:
        &"stage1": return try_load_first([STAGE1_GLB, STAGE1_GLTF])
        &"stage2": return try_load_first([STAGE2_GLB, STAGE2_GLTF])
        &"stage3": return try_load_first([STAGE3_GLB, STAGE3_GLTF])
    return null

static func mission_environment_paths(stage_id: StringName) -> Array[String]:
    match stage_id:
        &"stage1": return [STAGE1_GLB, STAGE1_GLTF]
        &"stage2": return [STAGE2_GLB, STAGE2_GLTF]
        &"stage3": return [STAGE3_GLB, STAGE3_GLTF]
    return []

static func hub_environment_scene() -> PackedScene:
    return try_load_first([HUB_GLB, HUB_GLTF])

static func interference_scene(variant_id: StringName) -> PackedScene:
    var id := String(variant_id).to_lower()
    return try_load_first([
        "res://art/enemies/%s/%s.glb" % [id, id],
        "res://art/enemies/%s/%s.gltf" % [id, id],
    ])

static func mimo_scene_path(mimo_id: StringName) -> String:
    var id := String(mimo_id).to_lower()
    return "res://art/mimo/%s/%s.glb" % [id, id]

static func mimo_scene(mimo_id: StringName) -> PackedScene:
    var id := String(mimo_id).to_lower()
    var candidates: Array = [
        "res://art/mimo/%s/%s.glb" % [id, id],
        "res://art/mimo/%s/%s.gltf" % [id, id],
    ]
    if id == "lumi":
        candidates.append(LUMI_PREVIEW)
        candidates.append(LUMI_PREVIEW_V2)
    candidates.append("res://art/mimo/%s/%s_preview.tscn" % [id, id])
    candidates.append(MIMO_SHARED_PREVIEW)
    candidates.append(MIMO_SHARED_PREVIEW_LEGACY)
    return try_load_first(candidates)

static func try_load_first(paths: Array) -> PackedScene:
    for path_value in paths:
        var scene := try_load_scene(String(path_value))
        if scene != null:
            return scene
    return null

static func try_load_scene(path: String) -> PackedScene:
    if not ResourceLoader.exists(path):
        return null
    var resource := load(path)
    return resource as PackedScene
