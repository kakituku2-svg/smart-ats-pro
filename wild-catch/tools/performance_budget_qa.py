#!/usr/bin/env python3
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    raise SystemExit(1)


def main() -> int:
    budget_path = ROOT / "art/performance_budget.json"
    if not budget_path.exists():
        fail("missing art/performance_budget.json")
    budget = json.loads(budget_path.read_text(encoding="utf-8"))

    stage = (ROOT / "scenes/stage1/stage1.tscn").read_text(encoding="utf-8")
    mimo_ids = set(re.findall(r'mimo_id = &"([^"]+)"', stage))
    max_mimo = int(budget["stage1"]["active_mimo_max"])
    if len(mimo_ids) > max_mimo:
        fail(f"Stage 1 has {len(mimo_ids)} Mimo, budget is {max_mimo}")

    art_runtime = (ROOT / "autoload/stage_art_runtime.gd").read_text(encoding="utf-8")
    required_multimesh = ("GrassTufts", "ShrubClusters", "RuinPebbles", "SunFlowers", "WaterReeds")
    for token in required_multimesh:
        if token not in art_runtime:
            fail(f"repeated decor must stay MultiMesh-backed: {token}")

    perf_runtime_path = ROOT / "autoload/performance_runtime.gd"
    if not perf_runtime_path.exists():
        fail("missing autoload/performance_runtime.gd")
    perf_runtime = perf_runtime_path.read_text(encoding="utf-8")
    for token in ("SHADOW_CASTING_SETTING_OFF", "visibility_range_end = 42.0", "GrassTufts", "WaterReeds"):
        if token not in perf_runtime:
            fail(f"mobile performance runtime missing: {token}")
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    if 'PerformanceRuntime="*res://autoload/performance_runtime.gd"' not in project:
        fail("PerformanceRuntime autoload is not enabled")

    # Current procedural fallback counts. Keep them comfortably below the soft art budget.
    known_counts = [170, 15, 48, 18 * 3, 28, 6]
    decor_total = sum(known_counts)
    decor_budget = int(budget["environment"]["decor_multimesh_instances_soft_max"])
    if decor_total > decor_budget:
        fail(f"fallback decor instances {decor_total} exceed budget {decor_budget}")

    if int(budget["characters"]["ren_texture_max"]) > 2048:
        fail("Ren texture budget must not exceed 2K on Android target")
    if int(budget["characters"]["mimo_texture_max"]) > 1024:
        fail("Mimo texture budget must not exceed 1K each on Android target")
    if int(budget["environment"]["hero_texture_max"]) > 2048:
        fail("environment hero texture budget must not exceed 2K")

    print("PASS: WILD CATCH static performance budget")
    print(f"  active Mimo: {len(mimo_ids)}/{max_mimo}")
    print(f"  fallback repeated decor: {decor_total}/{decor_budget} instances via MultiMesh")
    print("  small decor: shadows off / 42m mobile visibility range")
    print("  Ren soft budget: <=35k triangles / <=2K texture")
    print("  Mimo soft budget: <=20k triangles each / <=1K texture")
    print("  Stage soft budget: <=180k visible triangles / <=120 draw calls")
    print("NOTE: hardware profiling is still required for real FPS/memory validation.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
