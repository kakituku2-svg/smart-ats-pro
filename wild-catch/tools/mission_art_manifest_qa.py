#!/usr/bin/env python3
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    "aero", "kuru", "vivi", "toto", "nagi",
    "pico", "luna", "doro", "nix", "fufu", "zari", "ema",
    "stage2_skywind", "stage3_neon_swamp", "field_base",
    "guard_bug", "wind_stinger", "glow_leech",
}
ALLOWED = {"runtime_preview", "procedural_preview", "production_glb_added", "validated"}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def main() -> int:
    path = ROOT / "art/mission_asset_manifest_v050.json"
    if not path.exists():
        fail("missing v0.5.0 mission art manifest")
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"manifest JSON invalid: {exc}")
    if payload.get("checkpoint") != "0.5.0":
        fail("mission art manifest checkpoint must be 0.5.0")
    assets = payload.get("assets")
    if not isinstance(assets, list) or len(assets) != 18:
        fail("mission art manifest must contain 18 queued production assets")
    by_id = {str(item.get("id")): item for item in assets if isinstance(item, dict)}
    if set(by_id) != EXPECTED:
        fail(f"mission art manifest IDs mismatch: {sorted(by_id)}")
    for asset_id, item in by_id.items():
        path_value = str(item.get("path", ""))
        if not path_value.startswith("res://art/") or not path_value.endswith(".glb"):
            fail(f"invalid canonical GLB path for {asset_id}: {path_value}")
        if item.get("status") not in ALLOWED:
            fail(f"invalid mission art status for {asset_id}: {item.get('status')}")
        if item.get("type") in {"mimo", "enemy"}:
            animations = item.get("required_animations")
            if not isinstance(animations, list) or len(animations) < 4:
                fail(f"animation contract incomplete for {asset_id}")
    paths = (ROOT / "scripts/art/production_art_paths.gd").read_text(encoding="utf-8")
    for token in ("STAGE2_GLB", "STAGE3_GLB", "HUB_GLB", "interference_scene", "hub_environment_scene"):
        if token not in paths:
            fail(f"production art paths missing {token}")
    for file_name, tokens in {
        "autoload/mission_environment_art_runtime.gd": ("ProductionEnvironmentArt", "mission_environment_scene"),
        "autoload/hub_environment_art_runtime.gd": ("ProductionEnvironmentArt", "hub_environment_scene"),
        "autoload/interference_art_runtime.gd": ("ProductionArt", "interference_scene"),
    }.items():
        text = (ROOT / file_name).read_text(encoding="utf-8") if (ROOT / file_name).exists() else ""
        for token in tokens:
            if token not in text:
                fail(f"{file_name} missing {token}")
    print("PASS: WILD CATCH v0.5.0 mission art manifest")
    print("  queued production assets: 18/18")
    print("  12 Mimo + 3 environments + 3 interference enemies")
    print("  GLB drop-in bridges: stage2/stage3/hub/enemies ready")
    return 0


if __name__ == "__main__":
    sys.exit(main())
