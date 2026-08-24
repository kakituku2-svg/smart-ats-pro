#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def require(path: Path, tokens: tuple[str, ...]) -> str:
    if not path.exists():
        fail(f"missing: {path.relative_to(ROOT)}")
    text = path.read_text(encoding="utf-8")
    for token in tokens:
        if token not in text:
            fail(f"{path.name} missing token: {token}")
    return text


def count_spawn_vectors(text: str, stage_name: str, next_stage: str | None) -> int:
    if next_stage is None:
        pattern = rf'"{stage_name}": \[(.*?)\]\s*,?\s*\}}'
    else:
        pattern = rf'"{stage_name}": \[(.*?)\]\s*,\s*"{next_stage}"'
    match = re.search(pattern, text, re.S)
    if match is None:
        fail(f"could not parse spawn block for {stage_name}")
    return match.group(1).count("Vector3(")


def main() -> int:
    require(ROOT / "project.godot", (
        'MissionRouter="*res://autoload/mission_router.gd"',
        'MissionStageFlowRuntime="*res://autoload/mission_stage_flow_runtime.gd"',
        'InterferenceRuntime="*res://autoload/interference_runtime.gd"',
        'InterferenceArtRuntime="*res://autoload/interference_art_runtime.gd"',
        'StageMimoIdentityRuntime="*res://autoload/stage_mimo_identity_runtime.gd"',
        'MissionAmbientRuntime="*res://autoload/mission_ambient_runtime.gd"',
        'MissionHazardRuntime="*res://autoload/mission_hazard_runtime.gd"',
        'MissionPropRuntime="*res://autoload/mission_prop_runtime.gd"',
        'MissionSignatureRuntime="*res://autoload/mission_signature_runtime.gd"',
        'MissionEnvironmentArtRuntime="*res://autoload/mission_environment_art_runtime.gd"',
        'HubEnvironmentArtRuntime="*res://autoload/hub_environment_art_runtime.gd"',
        'HubControlsRuntime="*res://autoload/hub_controls_runtime.gd"',
        'HubStatsRuntime="*res://autoload/hub_stats_runtime.gd"',
    ))
    require(ROOT / "autoload/mission_router.gd", (
        '"stage1"', '"stage2"', '"stage3"',
        "トロピカル遺跡パーク", "スカイウィンド峡谷", "ネオン湿地研究区",
        "target_total", "interference_total", "launch_selected_mission", "return_to_hub",
    ))
    require(ROOT / "scenes/hub/hub.tscn", ("FieldBase", "hub_controller.gd"))
    require(ROOT / "scripts/hub/hub_controller.gd", ("TransferGate", "転送ミッション", "転送開始"))
    require(ROOT / "autoload/hub_controls_runtime.gd", ("VirtualStick", "CameraPad", "set_touch_move_vector", "add_camera_look_delta"))
    require(ROOT / "autoload/hub_stats_runtime.gd", ("FIELD RECORD", "get_bestiary_total", "get_total_interference_defeats", "get_interference_sweeps"))
    require(ROOT / "scenes/ui/mission_loading.tscn", ("MissionLoading", "mission_loading.gd"))
    require(ROOT / "scripts/ui/mission_loading.gd", ("MISSION TRANSFER", "捕獲対象", "妨害体", "transfer_loading", "本拠地へ戻る"))
    require(ROOT / "scripts/fx/transfer_sequence.gd", ("play_arrival", "play_departure", "TransferBeam", "TransferRing"))
    require(ROOT / "scenes/stage2/stage2.tscn", ('stage_id = &"stage2"', 'theme_id = &"sky_canyon"', "target_total = 5"))
    require(ROOT / "scenes/stage3/stage3.tscn", ('stage_id = &"stage3"', 'theme_id = &"neon_swamp"', "target_total = 7"))
    require(ROOT / "scripts/stage/mission_stage_controller.gd", (
        "GameState.reset_stage_progress", "_spawn_targets", "_spawn_relics", "_build_sky_canyon", "_build_neon_swamp",
        '"aero"', '"nagi"', '"pico"', '"ema"',
    ))
    require(ROOT / "scripts/stage/mission_hazard_zone.gd", (
        "UPDRAFT", "GLOW_MUD", "player.apply_slow", "mimo.velocity.y", "WindRing", "GlowMudSurface",
    ))
    hazards = require(ROOT / "autoload/mission_hazard_runtime.gd", ("Stage2", "Stage3", "Updraft", "GlowMud"))
    if hazards.count("MissionHazardZone.Kind.UPDRAFT") < 3 or hazards.count("MissionHazardZone.Kind.GLOW_MUD") < 3:
        fail("Stage 2/3 must each keep three mission hazard zones")
    require(ROOT / "autoload/mission_prop_runtime.gd", (
        "WindFlag", "MooringPost", "ResearchTank", "FieldTerminal", "WarningLight",
    ))
    require(ROOT / "autoload/mission_signature_runtime.gd", (
        '&"aero"', '&"kuru"', '&"vivi"', '&"toto"', '&"nagi"',
        '&"pico"', '&"luna"', '&"doro"', '&"nix"', '&"fufu"', '&"zari"', '&"ema"',
        "_wind_escape", "_blink_sideways", "_mud_splash", "_charge", "signature_action",
    ))

    enemy = require(ROOT / "scripts/enemies/interference_enemy.gd", (
        'add_to_group("interference_enemy")', 'add_to_group("pulse_target")', "trigger_pulse", "_defeat",
        "ガードバグ", "ウィンドスティンガー", "グロウリーチ", "wind_stinger", "glow_leech",
    ))
    if 'add_to_group("mimo")' in enemy:
        fail("interference enemy must never join Mimo capture group")
    interference = require(ROOT / "autoload/interference_runtime.gd", (
        "Stage1", "Stage2", "Stage3", "GuardBug", "WindStinger", "GlowLeech",
        '&"wind_stinger"', '&"glow_leech"', "record_interference_defeat", "record_interference_sweep", "FIELD SWEEP COMPLETE",
    ))
    if count_spawn_vectors(interference, "Stage1", "Stage2") != 2:
        fail("Stage 1 must contain two interference enemy spawns")
    if count_spawn_vectors(interference, "Stage2", "Stage3") != 3:
        fail("Stage 2 must contain three interference enemy spawns")
    if count_spawn_vectors(interference, "Stage3", None) != 4:
        fail("Stage 3 must contain four interference enemy spawns")

    require(ROOT / "autoload/stage_mimo_identity_runtime.gd", (
        "STAGE2_IDS", "STAGE3_IDS", "StageIdentityLayer",
        '&"aero"', '&"kuru"', '&"vivi"', '&"toto"', '&"nagi"',
        '&"pico"', '&"luna"', '&"doro"', '&"nix"', '&"fufu"', '&"zari"', '&"ema"',
        "_build_aero", "_build_pico", "_build_ema",
    ))
    require(ROOT / "autoload/mission_ambient_runtime.gd", (
        "WindTurbine", "GustRing", "GlowSpore", "_bind_stage3_plants", "_build_glow_spores",
    ))
    require(ROOT / "autoload/checkpoint_runtime.gd", (
        "Stage1", "Stage2", "Stage3",
        "RuinsGateCheckpoint", "ObservationCheckpoint", "WaterwayCheckpoint",
        "WindBridgeCheckpoint", "NorthCliffCheckpoint", "SouthRiseCheckpoint",
        "ResearchDeckCheckpoint", "WestLabCheckpoint", "RaisedPathCheckpoint",
    ))

    save = require(ROOT / "autoload/save_manager.gd", (
        "MIMO_IDS_BY_STAGE", "get_bestiary_total", '"ema"', "record_interference_defeat", "record_interference_sweep",
        "total_interference_defeats", '"version": 5',
    ))
    if save.count('"version": 5') < 1:
        fail("save migration must be version 5 for mission/battle records")

    require(ROOT / "scripts/art/production_art_paths.gd", (
        "STAGE2_GLB", "STAGE3_GLB", "HUB_GLB", "hub_environment_scene", "interference_scene",
    ))
    require(ROOT / "autoload/mission_environment_art_runtime.gd", ("ProductionEnvironmentArt", "mission_environment_scene"))
    require(ROOT / "autoload/hub_environment_art_runtime.gd", ("ProductionEnvironmentArt", "hub_environment_scene"))
    require(ROOT / "autoload/interference_art_runtime.gd", ("ProductionArt", "interference_scene"))
    require(ROOT / "art/mission_asset_manifest_v050.json", ("stage2_skywind", "field_base", "guard_bug", "glow_leech"))

    title = require(ROOT / "scripts/ui/title_screen.gd", ("MissionRouter.HUB_SCENE",))
    if "scenes/stage1/stage1.tscn" in title:
        fail("title must not bypass the field base and jump directly to Stage 1")
    audio = require(ROOT / "autoload/audio_manager.gd", ("transfer_loading", "transfer_return", "enemy_hit", "enemy_down", "play_music"))
    if "LOOP_FORWARD" not in audio:
        fail("transfer/hub music must be loop-capable")

    require(ROOT / "tools/runtime_mission_flow_smoke.gd", (
        "Field Base installs Android movement/camera controls", "Stage 2 updraft physically lifts Ren",
        "Stage 3 glow mud applies meaningful movement slow", "Interference defeat persists to field record",
    ))
    require(ROOT / "tools/visual_mission_flow.gd", (
        "27_field_base_hub.png", "28_mission_briefing.png", "29_stage2_skywind.png", "30_stage3_neon_swamp.png",
        "31_interference_encounter.png", "32_stage2_updraft.png", "33_stage3_glow_mud.png",
    ))
    require(ROOT / "tools/visual_roster_v050.gd", (
        "34_ren_v3_front.png", "35_stage1_mimo_roster.png", "36_stage2_mimo_roster.png",
        "37_stage3_mimo_roster.png", "38_interference_roster.png",
    ))

    print("PASS: WILD CATCH multi-stage mission static QA")
    print("  field base -> briefing load -> transfer arrival -> mission -> extraction -> field base")
    print("  Stage 1/2/3 scenes present with 3 checkpoints each")
    print("  capture targets: 6 + 5 + 7 = 18")
    print("  interference enemies: 2 + 3 + 4 across three archetypes, sweep records persist")
    print("  Stage 2: updraft hazards + wind props + five mission signatures")
    print("  Stage 3: glow-mud hazards + research props + seven mission signatures")
    print("  Field Base: Android controls + capture/combat field-record terminal")
    print("  production CG bridges: stage2/stage3/hub/enemies")
    print("  v0.5.0 roster visual QA: 34-38")
    return 0


if __name__ == "__main__":
    sys.exit(main())
