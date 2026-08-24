#!/usr/bin/env python3
"""Static QA for the v0.4.4 HUD/product-UI pass."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def read(path: str) -> str:
    p = ROOT / path
    if not p.exists():
        fail(f"missing: {path}")
    return p.read_text(encoding="utf-8")


def require(text: str, token: str, owner: str) -> None:
    if token not in text:
        fail(f"{owner} missing token: {token}")


def forbid(text: str, token: str, owner: str) -> None:
    if token in text:
        fail(f"{owner} contains deprecated UI token: {token}")


def main() -> int:
    hud_scene = read("scenes/ui/mobile_hud.tscn")
    icon_button = read("scripts/ui/game_icon_button.gd")
    stage = read("scripts/stage/stage1_controller.gd")
    drone = read("scripts/gadgets/scout_drone.gd")
    drone_feedback = read("scripts/vfx/drone_reveal_feedback.gd")
    title = read("scenes/ui/title_screen.tscn")
    title_fx = read("scripts/ui/title_fx.gd")
    pause = read("scripts/ui/pause_menu.gd")
    achievements = read("autoload/achievement_overlay.gd")
    vitals = read("autoload/vitals_overlay.gd")
    stick = read("scripts/ui/virtual_stick.gd")
    polish = read("scripts/ui/hud_polish_runtime.gd")
    skin = read("scripts/ui/game_ui_skin.gd")

    for token in (
        'game_icon_button.gd', 'icon_kind = "lure"', 'icon_kind = "pulse"', 'icon_kind = "drone"',
        'icon_kind = "jump"', 'icon_kind = "dash"', 'icon_kind = "net"', 'icon_kind = "scan"',
        'hud_polish_runtime.gd', 'GadgetBar" type="Control"',
    ):
        require(hud_scene, token, "mobile_hud.tscn")

    for token in ("get_cooldown_ratio", "draw_arc", "_draw_lure", "_draw_pulse", "_draw_drone", "_draw_net", "_draw_scan"):
        require(icon_button, token, "game_icon_button.gd")

    forbid(stage, "ドローンマップ", "stage1_controller.gd")
    forbid(stage, 'hud.show_gadget_status("1 誘導ポッド', "stage1_controller.gd")
    require(stage, "drone_feedback.reveal(payloads)", "stage1_controller.gd")
    forbid(stage, "hud.show_scan(nearest)", "stage1_controller.gd")
    require(drone, 'payload["world_position"]', "scout_drone.gd")
    require(drone_feedback, "DroneTargetMarker", "drone_reveal_feedback.gd")

    require(title, "title_fx.gd", "title_screen.tscn")
    require(title, "探索を開始！", "title_screen.tscn")
    require(title_fx, "Floating gadget", "title_fx.gd")

    for owner, text in (("pause_menu.gd", pause), ("achievement_overlay.gd", achievements)):
        require(text, "GameUISkin.style_button", owner)
        require(text, "GameUISkin.style_panel", owner)
    require(vitals, "GameUISkin.panel", "vitals_overlay.gd")
    require(stick, "_draw_direction_tick", "virtual_stick.gd")
    require(polish, "FieldLogButton", "hud_polish_runtime.gd")
    require(skin, "class_name GameUISkin", "game_ui_skin.gd")

    print("PASS: WILD CATCH UI static QA")
    print("  gadget shortcuts: icon-only + floating + radial cooldown")
    print("  action controls: icon-only")
    print("  radar/list-style drone HUD: removed")
    print("  title / pause / achievements / vitals / field log: themed")
    print("  virtual stick: animated game presentation")
    return 0


if __name__ == "__main__":
    sys.exit(main())
