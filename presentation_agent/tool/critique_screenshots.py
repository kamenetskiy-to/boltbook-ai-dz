#!/usr/bin/env python3

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: critique_screenshots.py <site_dir> <source_dir>", file=sys.stderr)
        return 64

    site_dir = Path(sys.argv[1]).resolve()
    source_dir = Path(sys.argv[2]).resolve()
    plan = json.loads((site_dir / "presentation_plan.json").read_text())
    slides = plan["slides"]
    screenshot_dir = site_dir / "screenshots"
    screenshots = sorted(screenshot_dir.glob("*.png"))

    critique = {
        "deck_id": plan["deck_id"],
        "viewport": {"width": 1512, "height": 982},
        "checks": [
            "dimensions",
            "contrast",
            "edge_density",
            "dead_space_ratio",
            "scene_similarity",
        ],
        "slides": [],
        "summary": {},
    }

    global_issues = []
    hashes = []

    if len(screenshots) != len(slides):
        global_issues.append(
            f"Ожидалось {len(slides)} кадров, а найдено {len(screenshots)}."
        )

    for index, slide in enumerate(slides):
        image_path = screenshots[index] if index < len(screenshots) else None
        slide_report = {
            "slide_id": slide["slide_id"],
            "route": slide["route"],
            "file": image_path.name if image_path else None,
            "metrics": {},
            "issues": [],
            "repair_suggestion": None,
        }

        if image_path is None:
            slide_report["issues"].append("Кадр отсутствует.")
            slide_report["repair_suggestion"] = "Повторить capture stage до критики."
            critique["slides"].append(slide_report)
            continue

        metrics = analyze_image(image_path)
        slide_report["metrics"] = metrics
        hashes.append(metrics["ahash"])

        if metrics["width"] != 1512 or metrics["height"] != 982:
            slide_report["issues"].append(
                f"Ожидался viewport 1512x982, получен {metrics['width']}x{metrics['height']}."
            )
        if metrics["contrast"] < 28:
            slide_report["issues"].append("Слабый контраст кадра.")
        if metrics["edge_density"] < 0.02 and metrics["contrast"] < 30:
            slide_report["issues"].append("Слишком мало визуальной фактуры.")
        if metrics["dead_space_ratio"] > 0.78:
            slide_report["issues"].append("Слишком много мертвого пространства.")

        if slide_report["issues"]:
            slide_report["repair_suggestion"] = suggest_fix(slide_report["issues"])

        critique["slides"].append(slide_report)

    for idx in range(1, len(critique["slides"])):
        if idx >= len(hashes):
            break
        distance = hamming_distance(hashes[idx - 1], hashes[idx])
        critique["slides"][idx]["metrics"]["distance_from_prev"] = distance
        if distance < 20:
            issue = "Сцена слишком похожа на предыдущий кадр."
            critique["slides"][idx]["issues"].append(issue)
            critique["slides"][idx]["repair_suggestion"] = suggest_fix(
                critique["slides"][idx]["issues"]
            )

    total_slide_issues = sum(len(slide["issues"]) for slide in critique["slides"])
    critique["summary"] = {
        "passed": not global_issues and total_slide_issues == 0,
        "global_issues": global_issues,
        "slide_issue_count": total_slide_issues,
        "captured_slides": len(screenshots),
        "expected_slides": len(slides),
    }

    write_json(site_dir / "screenshot_critique.json", critique)
    write_json(source_dir / "screenshot_critique.json", critique)

    screenshot_files = [f"screenshots/{path.name}" for path in screenshots]
    update_release_files(site_dir, critique, screenshot_files)
    update_release_files(source_dir, critique, screenshot_files)

    if critique["summary"]["passed"]:
        print("Screenshot critique passed")
        return 0

    print("Screenshot critique failed", file=sys.stderr)
    for issue in global_issues:
        print(f"  - {issue}", file=sys.stderr)
    for slide in critique["slides"]:
        for issue in slide["issues"]:
            print(f"  - {slide['route']}: {issue}", file=sys.stderr)
    return 2


def analyze_image(image_path: Path) -> dict[str, float | int | str]:
    with Image.open(image_path) as image:
        grayscale = np.asarray(image.convert("L"), dtype=np.float32)
        width, height = image.size

    contrast = float(np.std(grayscale))
    gx = np.abs(np.diff(grayscale, axis=1))
    gy = np.abs(np.diff(grayscale, axis=0))
    edge_density = float((((gx > 14).mean()) + ((gy > 14).mean())) / 2)
    dead_space_ratio = estimate_dead_space(grayscale)

    hash_bits = average_hash(grayscale)
    return {
        "width": width,
        "height": height,
        "contrast": round(contrast, 3),
        "edge_density": round(edge_density, 5),
        "dead_space_ratio": round(dead_space_ratio, 5),
        "ahash": hash_bits,
    }


def estimate_dead_space(grayscale: np.ndarray) -> float:
    block = 48
    height, width = grayscale.shape
    scores = []
    for y in range(0, height, block):
        for x in range(0, width, block):
            patch = grayscale[y : min(y + block, height), x : min(x + block, width)]
            scores.append(float(np.std(patch)) < 10.0)
    return float(sum(scores) / len(scores))


def average_hash(grayscale: np.ndarray) -> str:
    image = Image.fromarray(grayscale.astype(np.uint8)).resize((16, 16), Image.Resampling.LANCZOS)
    sample = np.asarray(image, dtype=np.float32)
    threshold = float(sample.mean())
    return "".join("1" if value > threshold else "0" for value in sample.flatten())


def hamming_distance(left: str, right: str) -> int:
    return sum(1 for a, b in zip(left, right) if a != b)


def suggest_fix(issues: list[str]) -> str:
    if any("похож" in issue.lower() for issue in issues):
        return "Сменить композицию или перераспределить крупные визуальные массы."
    if any("мертв" in issue.lower() for issue in issues):
        return "Уплотнить сцену: добавить опорный визуальный блок или переразбить пустое поле."
    if any("контраст" in issue.lower() for issue in issues):
        return "Усилить светотеневой разрыв между фоном и главным содержимым."
    return "Пересобрать сцену и повторить render -> screenshot -> critique."


def update_release_files(base_dir: Path, critique: dict, screenshot_files: list[str]) -> None:
    manifest_path = base_dir / "manifest.json"
    if manifest_path.exists():
        manifest = json.loads(manifest_path.read_text())
        manifest["screenshots"] = screenshot_files
        manifest["screenshot_critique"] = "screenshot_critique.json"
        manifest["summary"] = (
            "Подготовлен reviewer-facing выпуск с narrative brief, scene plan, "
            "fit validation и блокирующей screenshot critique перед /deck."
        )
        write_json(manifest_path, manifest)

    run_trace_path = base_dir / "run_trace.json"
    if run_trace_path.exists():
        run_trace = json.loads(run_trace_path.read_text())
        run_trace["screenshots"] = screenshot_files
        run_trace["screenshot_critique"] = critique
        for stage in run_trace.get("stages", []):
            if stage["name"] == "render_and_capture":
                stage["status"] = "completed"
                stage["summary"] = (
                    f"Снято {len(screenshot_files)} кадров по маршрутам deck."
                )
            if stage["name"] == "screenshot_critique":
                stage["status"] = "completed" if critique["summary"]["passed"] else "failed"
                stage["summary"] = (
                    "Послесборочная критика по снимкам "
                    + ("пройдена без замечаний." if critique["summary"]["passed"] else "обнаружила замечания.")
                )
        run_trace["review_scores"] = {
            "contrast_floor_ok": critique["summary"]["slide_issue_count"] == 0,
            "visual_clarity": round(
                max(0.0, 1.0 - (critique["summary"]["slide_issue_count"] / max(1, len(screenshot_files) * 4))),
                3,
            ),
            "scene_diversity": round(scene_diversity_score(critique["slides"]), 3),
        }
        write_json(run_trace_path, run_trace)


def scene_diversity_score(slides: list[dict]) -> float:
    distances = [
        slide["metrics"].get("distance_from_prev", 32)
        for slide in slides[1:]
        if slide["metrics"].get("distance_from_prev") is not None
    ]
    if not distances:
        return 1.0
    return min(1.0, float(sum(distances)) / (len(distances) * 32))


def write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    raise SystemExit(main())
