#!/usr/bin/env python3
"""Core static QA for WILD CATCH v0.5.0 JP."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_INPUTS = (
    "move_left", "move_right", "move_forward", "move_back",
    "jump", "dash", "net", "scan", "lure", "pulse", "drone", "field_log", "pause_game",
)
STAGE1_MIMOS = {"lumi", "goro", "boka", "nera", "moku", "raku"}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def read(path: str) -> str:
    p = ROOT / path
    if not p.exists():
        fail(f"missing required file: {path}")
    return p.read_text(encoding="utf-8", errors="replace")


def require(path: str, tokens: tuple[str, ...], label: str | None = None) -> str:
    text = read(path)
    for token in tokens:
        if token not in text:
            fail(f"{label or path} missing token: {token}")
    return text


def validate_res_refs() -> None:
    missing: list[tuple[str, str]] = []
    pattern = re.compile(r'res://([^"\s\)\]]+)')
    for path in ROOT.rglob("*"):
        if path.suffix not in {".gd", ".tscn", ".godot"}:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for match in pattern.finditer(text):
            ref = match.group(1)
            if ref.startswith("build/") or ref.startswith("art/"):
                continue
            if not (ROOT / ref).exists():
                missing.append((str(path.relative_to(ROOT)), ref))
    if missing:
        for owner, ref in missing:
            print(f"  missing: {owner} -> res://{ref}")
        fail(f"{len(missing)} unresolved res:// reference(s)")


def main() -> int:
    project = require("project.godot", (
        'run/main_scene="res://scenes/ui/title_screen.tscn"',
        'GameState="*res://autoload/game_state.gd"',
        'SaveManager="*res://autoload/save_manager.gd"',
        'SettingsManager="*res://autoload/settings_manager.gd"',
        'MissionRouter="*res://autoload/mission_router.gd"',
        'MissionStageFlowRuntime="*res://autoload/mission_stage_flow_runtime.gd"',
        'InterferenceRuntime="*res://autoload/interference_runtime.gd"',
        'MissionHazardRuntime="*res://autoload/mission_hazard_runtime.gd"',
        'MissionPropRuntime="*res://autoload/mission_prop_runtime.gd"',
        'MissionSignatureRuntime="*res://autoload/mission_signature_runtime.gd"',
        'MissionEnvironmentArtRuntime="*res://autoload/mission_environment_art_runtime.gd"',
        'HubControlsRuntime="*res://autoload/hub_controls_runtime.gd"',
        'HubStatsRuntime="*res://autoload/hub_stats_runtime.gd"',
        'StageArtRuntime="*res://autoload/stage_art_runtime.gd"',
        'PerformanceRuntime="*res://autoload/performance_runtime.gd"',
        "textures/vram_compression/import_etc2_astc=true",
    ), "project.godot")
    for action in REQUIRED_INPUTS:
        if f"{action}={{" not in project:
            fail(f"missing input action: {action}")

    validate_res_refs()

    stage1 = read("scenes/stage1/stage1.tscn")
    ids = set(re.findall(r'mimo_id = &"([^"]+)"', stage1))
    if ids != STAGE1_MIMOS:
        fail(f"Stage 1 Mimo IDs mismatch: {sorted(ids)}")
    require("scenes/stage2/stage2.tscn", ('stage_id = &"stage2"', "target_total = 5"), "Stage 2 scene")
    require("scenes/stage3/stage3.tscn", ('stage_id = &"stage3"', "target_total = 7"), "Stage 3 scene")

    require("scripts/ui/title_screen.gd", ("MissionRouter.HUB_SCENE",), "title route")
    require("scenes/ui/title_screen.tscn", ("探索を開始！", "title_fx.gd"), "Japanese title")
    require("scripts/ui/mobile_hud.gd", ("フィールドログ", "ミモ図鑑", "捕獲ネット", "JapaneseText"), "mobile HUD")
    require("scripts/ui/virtual_stick.gd", ("deadzone", "clear_input", "_draw_direction_tick"), "virtual stick")
    require("scripts/player/player_controller.gd", (
        "set_touch_move_vector", "add_camera_look_delta", "_normalize_mobile_look_delta",
        "take_damage", "_knock_out", "SettingsManager.camera_sensitivity",
    ), "player controls")
    require("autoload/settings_manager.gd", ("0.65", "set_camera_sensitivity", "camera_shake", "hitstop"), "settings")

    require("autoload/save_manager.gd", (
        "MIMO_IDS_BY_STAGE", "get_bestiary_total", "record_stage_result",
        "record_interference_defeat", "record_interference_sweep", '"version": 5',
    ), "save/progression")
    require("autoload/game_state.gd", ("record_capture", "stage_result_ready", "stage_cleared"), "game state")
    require("autoload/mission_router.gd", (
        "トロピカル遺跡パーク", "スカイウィンド峡谷", "ネオン湿地研究区",
        "launch_selected_mission", "return_to_hub",
    ), "mission router")
    require("scripts/ui/mission_loading.gd", ("MISSION TRANSFER", "捕獲対象", "妨害体", "transfer_loading"), "mission loading")
    require("scripts/fx/transfer_sequence.gd", ("play_arrival", "play_departure", "TransferBeam"), "transfer sequence")

    require("scripts/ai/mimo_base.gd", ("apply_lure", "apply_pulse", "attempt_capture", "GameState.mark_captured"), "Mimo AI")
    require("scripts/ai/signature_action_director.gd", ("grass_hide", "stone_throw", "counter_charge", "spark_burst", "sleep_cloud", "decoy_split"), "Stage 1 signatures")
    require("autoload/mission_signature_runtime.gd", ("aero", "nagi", "pico", "ema", "_blink_sideways", "_mud_splash"), "Stage 2/3 signatures")
    require("scripts/enemies/interference_enemy.gd", ("guard_bug", "wind_stinger", "glow_leech", "trigger_pulse", "_defeat"), "interference enemies")
    require("scripts/stage/mission_hazard_zone.gd", ("UPDRAFT", "GLOW_MUD", "player.apply_slow", "mimo.velocity.y"), "mission hazards")
    require("autoload/checkpoint_runtime.gd", ("Stage1", "Stage2", "Stage3", "RuntimeCheckpoints"), "checkpoints")

    require("scripts/art/production_art_paths.gd", (
        "ren_scene", "stage1_scene", "mimo_scene", "try_load_first",
        "STAGE2_GLB", "STAGE2_GLTF", "STAGE3_GLB", "STAGE3_GLTF", "mission_environment_scene",
    ), "art paths")
    require("scripts/art/player_visual_controller.gd", ("Net_1", "Net_2", "Net_3", "Scan", "swing_started"), "Ren art bridge")
    require("scripts/art/mimo_visual_controller.gd", ("Alert", "Run", "Tired", "Recover", "Capture"), "Mimo art bridge")
    require("autoload/stage_art_runtime.gd", ("MultiMesh", "GrassTufts", "SunFlowers", "WaterReeds"), "Stage 1 art runtime")
    require("autoload/mission_environment_art_runtime.gd", (
        "ProductionArtPaths.mission_environment_scene", "ProductionEnvironmentArt", "production_environment_active", "_hide_procedural_visuals",
    ), "Stage 2/3 production environment bridge")
    require("autoload/mission_prop_runtime.gd", ("WindFlag", "ResearchTank", "WarningLight"), "Stage 2/3 prop art")
    require("autoload/stage_mimo_identity_runtime.gd", ("STAGE2_IDS", "STAGE3_IDS", "StageIdentityLayer"), "new Mimo CG identities")

    require("tools/runtime_mobile_input_smoke.gd", ("touch joystick moves the player", "single-frame camera rotation is hard-capped"), "mobile input QA")
    require("tools/runtime_mission_flow_smoke.gd", ("Stage 2 updraft physically lifts Ren", "Stage 3 glow mud applies meaningful movement slow"), "mission runtime QA")
    require("tools/visual_mission_flow.gd", ("27_field_base_hub.png", "33_stage3_glow_mud.png"), "mission visual QA")

    export = require("export_presets.cfg", ('platform="Android"', 'name="Android Debug"', 'version/name="0.5.0"', "version/code=11"), "Android export")
    if 'architectures/arm64-v8a=true' not in export:
        fail("Android arm64 export must stay enabled")

    print("PASS: WILD CATCH v0.5.0 core static QA")
    print("  3D Field Base + mission loading/transfer loop: present")
    print("  missions: Stage 1 / Stage 2 / Stage 3")
    print("  capture targets: 6 + 5 + 7 = 18")
    print("  Stage 2/3 hazards, props, signatures and checkpoints: present")
    print("  non-capturable interference enemies + persistent sweep records: present")
    print("  Android mobile-input safety regression coverage: present")
    print("  Stage 1/2/3 drop-in production environment bridges: present")
    print("  character production art bridge + Android performance guards: present")
    print("  Android Debug export: v0.5.0 / code 11")
    print("NOTE: Godot engine/runtime and device profiling are still required.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
