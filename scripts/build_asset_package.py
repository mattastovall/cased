#!/usr/bin/env python3
"""Build a provenance-preserving asset package from local generation logs."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any
from zipfile import ZIP_DEFLATED, ZipFile


URL_RE = re.compile(r"https://[^\s\"']+")
MEDIA_HOST_RE = re.compile(r"^https://(v3b\.fal\.media|vxdmipbkwsbsmnxzdppz\.supabase\.co)/")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="Directory containing .txt logs")
    parser.add_argument("--out-dir", default="dist", help="Output directory")
    parser.add_argument(
        "--version-date",
        default=None,
        help="Date tag for archive name (YYYY-MM-DD). Defaults to local date.",
    )
    parser.add_argument("--project-tag", default="cased-chestplate-assets", help="Archive prefix")
    parser.add_argument("--timeout", type=int, default=45, help="Per-request timeout in seconds")
    return parser.parse_args()


def infer_ext(url: str, content_type: str | None) -> str:
    if content_type:
        ctype = content_type.split(";")[0].strip().lower()
        if ctype == "video/mp4":
            return ".mp4"
        if ctype == "image/png":
            return ".png"
        if ctype == "image/jpeg":
            return ".jpg"
    path = url.split("?")[0]
    suffix = Path(path).suffix.lower()
    return suffix if suffix else ".bin"


def extract_section(text: str, label: str) -> str | None:
    idx = text.find(label)
    if idx < 0:
        return None
    brace_start = text.find("{", idx)
    if brace_start < 0:
        return None
    depth = 0
    for i in range(brace_start, len(text)):
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return text[brace_start : i + 1]
    return None


def walk_urls(obj: Any) -> list[str]:
    found: list[str] = []
    if isinstance(obj, dict):
        for value in obj.values():
            found.extend(walk_urls(value))
    elif isinstance(obj, list):
        for value in obj:
            found.extend(walk_urls(value))
    elif isinstance(obj, str) and obj.startswith("https://"):
        found.append(obj)
    return found


def load_logs(root: Path) -> list[dict[str, Any]]:
    logs: list[dict[str, Any]] = []
    for path in sorted(root.glob("*.txt")):
        text = path.read_text(encoding="utf-8")
        endpoint = None
        req_id = None
        prompt = None
        input_json: dict[str, Any] = {}
        output_json: dict[str, Any] = {}

        m = re.search(r"Endpoint\s+([^\n]+)", text)
        if m:
            endpoint = m.group(1).strip()
        m = re.search(r"Request ID\s+([^\n]+)", text)
        if m:
            req_id = m.group(1).strip()

        input_blob = extract_section(text, "Input")
        if input_blob:
            try:
                input_json = json.loads(input_blob)
                prompt = input_json.get("prompt")
            except json.JSONDecodeError:
                input_json = {}

        output_blob = extract_section(text, "Output")
        if output_blob:
            try:
                output_json = json.loads(output_blob)
            except json.JSONDecodeError:
                output_json = {}

        input_urls = [u for u in walk_urls(input_json) if MEDIA_HOST_RE.match(u)]
        output_urls = [u for u in walk_urls(output_json) if MEDIA_HOST_RE.match(u)]

        logs.append(
            {
                "source_file": path.name,
                "endpoint": endpoint,
                "request_id": req_id,
                "prompt": prompt,
                "input_urls": sorted(set(input_urls)),
                "output_urls": sorted(set(output_urls)),
                "raw_url_matches": sorted(
                    {
                        u.rstrip("),")
                        for u in URL_RE.findall(text)
                        if MEDIA_HOST_RE.match(u.rstrip("),"))
                    }
                ),
            }
        )
    return logs


def build_manifest(logs: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_url: dict[str, dict[str, Any]] = {}
    for log in logs:
        for url in log["raw_url_matches"]:
            ent = by_url.setdefault(
                url,
                {
                    "url": url,
                    "source_files": [],
                    "request_ids": [],
                    "endpoints": [],
                    "prompts": [],
                    "roles": set(),
                },
            )
            if log["source_file"] not in ent["source_files"]:
                ent["source_files"].append(log["source_file"])
            if log["request_id"] and log["request_id"] not in ent["request_ids"]:
                ent["request_ids"].append(log["request_id"])
            if log["endpoint"] and log["endpoint"] not in ent["endpoints"]:
                ent["endpoints"].append(log["endpoint"])
            if log["prompt"] and log["prompt"] not in ent["prompts"]:
                ent["prompts"].append(log["prompt"])

            if url in log["output_urls"]:
                ent["roles"].add("output")
            elif url in log["input_urls"]:
                ent["roles"].add("input")
            else:
                ent["roles"].add("reference")

    manifest: list[dict[str, Any]] = []
    for url, ent in sorted(by_url.items()):
        roles = ent.pop("roles")
        role = "output" if "output" in roles else ("input" if "input" in roles else "reference")
        asset_id = hashlib.sha1(url.encode("utf-8")).hexdigest()[:12]
        manifest.append(
            {
                "asset_id": asset_id,
                "role": role,
                "source_url": url,
                "source_files": ent["source_files"],
                "request_ids": ent["request_ids"],
                "endpoints": ent["endpoints"],
                "prompts": ent["prompts"],
                "content_type": None,
                "expected_ext": infer_ext(url, None),
                "status": "pending",
                "http_status": None,
                "file_size": None,
                "sha256": None,
                "stored_relpath": None,
                "error": None,
            }
        )
    return manifest


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def download_assets(
    manifest: list[dict[str, Any]],
    staging_dir: Path,
    timeout: int,
) -> list[dict[str, Any]]:
    raw_dir = staging_dir / "raw"
    tmp_dir = raw_dir / "_tmp"
    hash_dir = raw_dir / "by_hash"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    hash_dir.mkdir(parents=True, exist_ok=True)
    report: list[dict[str, Any]] = []

    for item in manifest:
        url = item["source_url"]
        tmp_path = tmp_dir / f"{item['asset_id']}.bin"
        status = None
        content_type = None
        try:
            # Prefer curl in this environment since direct Python DNS can be restricted.
            hdr_path = tmp_dir / f"{item['asset_id']}.headers"
            curl_cmd = [
                "curl",
                "-s",
                "-L",
                "--fail",
                "--show-error",
                "--connect-timeout",
                str(timeout),
                "--max-time",
                str(timeout * 2),
                "-D",
                str(hdr_path),
                "-o",
                str(tmp_path),
                "-w",
                "%{http_code}",
                url,
            ]
            cp = subprocess.run(curl_cmd, capture_output=True, text=True, check=False)
            if cp.returncode != 0:
                raise RuntimeError((cp.stderr or cp.stdout).strip() or "curl failed")
            status = int((cp.stdout or "0").strip()[-3:] or "0")
            if hdr_path.exists():
                for line in hdr_path.read_text(encoding="utf-8", errors="ignore").splitlines():
                    if line.lower().startswith("content-type:"):
                        content_type = line.split(":", 1)[1].strip()
                hdr_path.unlink(missing_ok=True)

            digest = sha256_file(tmp_path)
            ext = infer_ext(url, content_type)
            canonical = hash_dir / f"{digest}{ext}"
            if not canonical.exists():
                shutil.move(str(tmp_path), canonical)
            else:
                tmp_path.unlink(missing_ok=True)

            relpath = canonical.relative_to(staging_dir).as_posix()
            size = canonical.stat().st_size
            item.update(
                {
                    "status": "downloaded",
                    "http_status": status,
                    "content_type": content_type,
                    "expected_ext": ext,
                    "file_size": size,
                    "sha256": digest,
                    "stored_relpath": relpath,
                    "error": None,
                }
            )
        except Exception as e:  # noqa: BLE001
            item.update(
                {
                    "status": "failed",
                    "http_status": status,
                    "content_type": content_type,
                    "file_size": 0,
                    "sha256": None,
                    "stored_relpath": None,
                    "error": f"{type(e).__name__}: {e}",
                }
            )
            tmp_path.unlink(missing_ok=True)

        report.append(
            {
                "asset_id": item["asset_id"],
                "source_url": item["source_url"],
                "status": item["status"],
                "http_status": item["http_status"],
                "file_size": item["file_size"],
                "sha256": item["sha256"],
                "error": item["error"],
            }
        )

    return report


def write_checksums(base_dir: Path, target_path: Path) -> None:
    lines: list[str] = []
    for path in sorted(base_dir.rglob("*")):
        if path.is_file():
            rel = path.relative_to(base_dir).as_posix()
            digest = sha256_file(path)
            lines.append(f"{digest}  {rel}")
    target_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def build_package(
    root: Path,
    out_dir: Path,
    logs: list[dict[str, Any]],
    manifest: list[dict[str, Any]],
    version_date: str,
    project_tag: str,
) -> dict[str, Path]:
    pkg_name = f"{project_tag}-{version_date}-v1"
    package_dir = out_dir / pkg_name
    assets_out = package_dir / "assets" / "outputs"
    assets_in = package_dir / "assets" / "inputs"
    assets_ref = package_dir / "assets" / "references"
    metadata_dir = package_dir / "metadata"
    txt_dir = metadata_dir / "original-txt"

    if package_dir.exists():
        shutil.rmtree(package_dir)
    assets_out.mkdir(parents=True, exist_ok=True)
    assets_in.mkdir(parents=True, exist_ok=True)
    assets_ref.mkdir(parents=True, exist_ok=True)
    txt_dir.mkdir(parents=True, exist_ok=True)

    for log in logs:
        src = root / log["source_file"]
        shutil.copy2(src, txt_dir / src.name)

    for item in manifest:
        if item["status"] != "downloaded" or not item["stored_relpath"]:
            continue
        src = out_dir / "staging" / item["stored_relpath"]
        ext = item["expected_ext"]
        target_base = item["asset_id"] + ext
        if item["role"] == "output":
            dest = assets_out / target_base
        elif item["role"] == "input":
            dest = assets_in / target_base
        else:
            dest = assets_ref / target_base
        shutil.copy2(src, dest)
        item["package_relpath"] = dest.relative_to(package_dir).as_posix()

    manifest_path = metadata_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    report = {
        "generated_at": dt.datetime.now().isoformat(),
        "log_count": len(logs),
        "asset_count": len(manifest),
        "downloaded_count": sum(1 for m in manifest if m["status"] == "downloaded"),
        "failed_count": sum(1 for m in manifest if m["status"] == "failed"),
        "output_count": sum(1 for m in manifest if m["role"] == "output"),
        "input_count": sum(1 for m in manifest if m["role"] == "input"),
        "reference_count": sum(1 for m in manifest if m["role"] == "reference"),
    }
    (metadata_dir / "summary.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    readme = package_dir / "README.md"
    readme.write_text(
        "\n".join(
            [
                "# Chestplate Asset Package",
                "",
                f"- Generated: {dt.datetime.now().isoformat()}",
                f"- Source logs: {len(logs)}",
                f"- Total assets in manifest: {len(manifest)}",
                f"- Downloaded assets: {report['downloaded_count']}",
                f"- Failed assets: {report['failed_count']}",
                "",
                "## Structure",
                "",
                "- `assets/outputs/`: final generated deliverables",
                "- `assets/inputs/`: source images used for generation",
                "- `assets/references/`: other referenced media URLs",
                "- `metadata/manifest.json`: asset-level provenance",
                "- `metadata/original-txt/`: copied source generation logs",
                "- `checksums.sha256`: checksums for all files in this package",
                "",
                "## Validation",
                "",
                "Run `shasum -a 256 -c checksums.sha256` from this directory.",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    write_checksums(package_dir, package_dir / "checksums.sha256")
    zip_path = out_dir / f"{pkg_name}.zip"
    if zip_path.exists():
        zip_path.unlink()
    with ZipFile(zip_path, "w", compression=ZIP_DEFLATED) as zf:
        for path in sorted(package_dir.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(package_dir.parent))

    zip_sha = sha256_file(zip_path)
    (out_dir / f"{pkg_name}.zip.sha256").write_text(f"{zip_sha}  {zip_path.name}\n", encoding="utf-8")

    return {"package_dir": package_dir, "zip_path": zip_path}


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    out_dir = (root / args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    staging_dir = out_dir / "staging"
    staging_dir.mkdir(parents=True, exist_ok=True)

    version_date = args.version_date or dt.date.today().isoformat()

    logs = load_logs(root)
    if not logs:
        print("No .txt logs found in the target root.", file=sys.stderr)
        return 1

    manifest = build_manifest(logs)
    download_report = download_assets(manifest, staging_dir=staging_dir, timeout=args.timeout)

    (staging_dir / "download_report.json").write_text(json.dumps(download_report, indent=2), encoding="utf-8")
    (staging_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    outputs = build_package(
        root=root,
        out_dir=out_dir,
        logs=logs,
        manifest=manifest,
        version_date=version_date,
        project_tag=args.project_tag,
    )

    downloaded = sum(1 for m in manifest if m["status"] == "downloaded")
    failed = sum(1 for m in manifest if m["status"] == "failed")
    print(f"Logs processed: {len(logs)}")
    print(f"Assets in manifest: {len(manifest)}")
    print(f"Downloaded: {downloaded}")
    print(f"Failed: {failed}")
    print(f"Manifest: {staging_dir / 'manifest.json'}")
    print(f"Download report: {staging_dir / 'download_report.json'}")
    print(f"Package dir: {outputs['package_dir']}")
    print(f"Zip: {outputs['zip_path']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
