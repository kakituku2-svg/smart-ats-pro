#!/usr/bin/env python3
"""Static QA for WILD CATCH production-art bridges through v0.5.0."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_ASSETS = {
    "ren": "res://art/characters/ren/ren.glb",
    "lumi": "res://art/mimo/lumi/lumi.glb",
    "goro": "res://art/mimo/goro/goro.glb",
    "boka": "res://art/mimo/boka/boka.glb",
    "nera": "res://art/mimo/nera/nera.glb",
    "moku": "res://art/mimo/moku/moku.glb",
    "raku": "res://art/mimo/raku/raku.glb",
    "stage1_set": "res://art/environment/stage1/stage1_set.glb",
}
ALLOWED_STATUS = {
    "awaiting_production_glb", "preview_scene_added", "preview_gltf_added",
    "production_glb_added", "validated",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def require(path: str, tokens: tuple[str, ...]) -> str:
    p = ROOT / path
    if not p.exists():
        fail(f"missing: {path}")
    text = p.read_text(encoding="utf-8")
    for token in tokens:
        if token not in text:
            fail(f"{path} missing token: {token}")
    return text


def res_to_path(resource_path: str) -> Path:
    if not resource_path.startswith("res://"):
        fail(f"invalid resource path: {resource_path}")
    return ROOT / resource_path.removeprefix("res://")


def validate_manifest() -> None:
    path = ROOT / "art/production_asset_manifest.json"
    if not path.exists():
        fail("missing: art/production_asset_manifest.json")
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"production asset manifest JSON invalid: {exc}")
    if payload.get("checkpoint") != "0.4.3":
        fail("production asset manifest checkpoint must stay 0.4.3 for the original art subsystem")
    assets = payload.get("assets")
    if not isinstance(assets, list) or len(assets) != 8:
        fail("production asset manifest must contain exactly 8 original canonical assets")
    by_id = {str(item.get("id")): item for item in assets if isinstance(item, dict)}
    if set(by_id) != set(EXPECTED_ASSETS):
        fail(f"production asset manifest IDs mismatch: {sorted(by_id)}")
    preview_count = 0
    for asset_id, expected_path in EXPECTED_ASSETS.items():
        item = by_id[asset_id]
        if item.get("path") != expected_path:
            fail(f"manifest path mismatch for {asset_id}: {item.get('path')}")
        status = item.get("status")
        if status not in ALLOWED_STATUS:
            fail(f"manifest status invalid for {asset_id}: {status}")
        if status in {"preview_scene_added", "preview_gltf_added"}:
            preview_path = item.get("preview_path")
            if not isinstance(preview_path, str) or not preview_path:
                fail(f"preview_path missing for {asset_id}")
            if not res_to_path(preview_path).exists():
                fail(f"preview asset missing for {asset_id}: {preview_path}")
            preview_count += 1
        required = item.get("required_animations")
        if not isinstance(required, list):
            fail(f"required_animations must be a list for {asset_id}")
        if asset_id == "ren" and not {"Idle", "Run", "Jump"}.issubset(required):
            fail("Ren manifest must require Idle / Run / Jump")
        if item.get("type") == "mimo" and not {"Idle", "Run", "Tired", "Capture"}.issubset(required):
            fail(f"{asset_id} manifest must require Idle / Run / Tired / Capture")
    if preview_count < 7:
        fail(f"expected Ren + six Mimo preview art to be installed, found {preview_count}")
    if by_id["ren"].get("preview_path") != "res://art/characters/ren/ren_preview_v3.tscn":
        fail("Ren current preview must be V3")
    if by_id["lumi"].get("preview_path") != "res://art/mimo/lumi/lumi_preview_v3.tscn":
        fail("Lumi current preview must be V3")
    for id_value in ("goro", "boka", "nera", "moku", "raku"):
        if by_id[id_value].get("preview_path") != "res://art/mimo/mimo_preview_base_v2.tscn":
            fail(f"{id_value} must use shared Mimo Preview V2")


def main() -> int:
    require("scripts/art/production_art_paths.gd", (
        "REN_GLB", "REN_PREVIEW", "REN_PREVIEW_V2", "STAGE1_GLB", "STAGE1_PREVIEW",
        "STAGE2_GLB", "STAGE3_GLB", "HUB_GLB",
        "MIMO_SHARED_PREVIEW", "MIMO_SHARED_PREVIEW_LEGACY", "LUMI_PREVIEW",
        "ren_scene", "stage1_scene", "mission_environment_scene", "hub_environment_scene", "interference_scene",
    ))
    require("scripts/art/player_visual_controller.gd", (
        "ProductionArtPaths.ren_scene()", "_animate_placeholder", "_drive_production_animation",
        "Net_1", "Net_2", "Net_3", "Scan", "swing_started",
    ))
    require("scripts/art/mimo_visual_controller.gd", (
        "ProductionArtPaths.mimo_scene", "_animate_placeholder", "_state_semantic",
        "Alert", "Run", "Tired", "Recover", "Capture", "$ArmL", "$ArmR",
    ))
    require("art/characters/ren/ren_preview_v3.tscn", (
        "Nose", "HairTopA", "HairFrontM", "VestPanelL", "ChestBadge", "PackStrapL", "WristButton", "ShoeAccentL",
    ))
    require("art/mimo/lumi/lumi_preview_v3.tscn", (
        "EyeSparkL", "ForeheadLeaf", "BellyPatch", "TailLeafL", "ChestSeed",
    ))
    require("art/mimo/mimo_preview_base_v2.tscn", (
        "EyeHighlightL", "EarInnerL", "MuzzlePatch", "NoseTip", "BellyPatchBase", "FootPadL",
    ))
    require("art/mimo/mimo_preview_base.tscn", (
        "mimo_preview_art.gd", "AnimationPlayer", "Idle", "Run", "Tired", "Capture",
        "StoneBand", "BoxerBand", "SparkFin", "SleepyLeaf", "TrickTail",
    ))
    require("autoload/stage_art_runtime.gd", (
        "ProductionArtPaths.stage1_scene()", "RuntimeEnvironmentPolish", "MultiMesh",
        "GrassTufts", "ShrubClusters", "RuinPebbles", "SunFlowers", "WaterReeds",
    ))
    require("autoload/mission_environment_art_runtime.gd", (
        "ProductionArtPaths.mission_environment_scene", "ProductionEnvironmentArt", "_hide_procedural_visuals",
    ))
    require("autoload/hub_environment_art_runtime.gd", (
        "ProductionArtPaths.hub_environment_scene", "ProductionEnvironmentArt", "_hide_placeholder_architecture",
    ))
    require("autoload/interference_art_runtime.gd", (
        "ProductionArtPaths.interference_scene", "ProductionArt", "production_art_active",
    ))
    require("art/mission_asset_manifest_v050.json", (
        '"checkpoint": "0.5.0"', "stage2_skywind", "stage3_neon_swamp", "field_base", "guard_bug", "wind_stinger", "glow_leech",
    ))
    require("art/README.md", (
        "Production Art Drop-in Contract v0.5.0", "Skinned Mesh", "18体",
        "art/environment/stage2/stage2_skywind.glb", "art/environment/stage3/stage3_neon_swamp.glb",
        "art/environment/hub/field_base_set.glb",
    ))
    validate_manifest()
    require("tools/runtime_v043_smoke.gd", (
        "ProductionArtPaths.stage1_scene()", "HEX NET swing drives Ren net_1 action semantic", "ECHO SCAN drives Ren scan action semantic",
    ))
    require("tools/visual_roster_v050.gd", (
        "34_ren_v3_front.png", "35_stage1_mimo_roster.png", "36_stage2_mimo_roster.png", "37_stage3_mimo_roster.png", "38_interference_roster.png",
    ))
    require("export_presets.cfg", ('version/name="0.5.0"', "version/code=11"))

    print("PASS: WILD CATCH production-art static QA")
    print("  original canonical asset manifest: 8/8")
    print("  Ren Preview V3 / Lumi Preview V3 / shared Mimo Preview V2: active")
    print("  18-target production art resolution: ready")
    print("  Stage 1/2/3 + Field Base environment GLB bridges: ready")
    print("  three interference enemy GLB bridges: ready")
    print("  visual roster QA 34-38: ready")
    print("  release milestone: v0.5.0 / Android code 11")
    return 0


if __name__ == "__main__":
    sys.exit(main())
