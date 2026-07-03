#!/usr/bin/env python3
"""
Fix relative imports after gch_ prefix rename.
Maps old directory/file names to new ones in relative import paths.
Run from project root: python3 scripts/fix_relative_imports.py
"""
import os
import re

LIB_ROOT = os.path.abspath("lib")

DIR_MAP = {
    "model":           "gch_model",
    "ctrl":            "gch_ctrl",
    "widget":          "gch_widget",
    "widgets":         "gch_widget",
    "repo":            "gch_repo",
    "service":         "gch_svc",
    "services":        "gch_svc",
    "svc":             "gch_svc",
    "providers":       "gch_providers",
    "viewmodel":       "gch_vm",
    "dao":             "gch_dao",
    "browse":          "gch_browse",
    "storage":         "gch_storage",
    "utils":           "gch_utils",
    "util":            "gch_utils",
    "view":            "gch_view",
    "api":             "gch_api",
    "live":            "gch_live",
    "strategy":        "gch_strategy",
    "strategies":      "gch_strategies",
    "entity":          "gch_entity",
    "guard":           "gch_guard",
    "policy":          "gch_policy",
    "collector":       "gch_collector",
    "coordinator":     "gch_coordinator",
    "controller":      "gch_controller",
    "handler":         "gch_handler",
    "client":          "gch_client",
    "json":            "gch_json",
    "config":          "gch_config",
    "internal":        "gch_internal",
    "common":          "gch_common",
    "models":          "gch_models",
    "endpoint":        "gch_endpoint",
    "repository":      "gch_repo",
    "map":             "gch_map",
    "bankendapi":      "gch_bankendapi",
    "in_app_purchase": "gch_iap",
    "ios":             "gch_ios",
    "skin":            "gch_skin",
    "palette":         "gch_palette",
    "seal":            "gch_seal",
    "keyswap":         "gch_keyswap",
    "cipher":          "gch_cipher",
    "shield":          "gch_shield",
    "captcha":         "gch_captcha",
    "grpc":            "gch_grpc",
    "core":            "gch_core",
    "proto":           "gch_proto",
    "spec":            "gch_spec",
}

IMPORT_RE = re.compile(
    r"""((?:import|export|part\s+of|part)\s+['"])([^'"]+)(['"])"""
)


def transform_rel_path(rel_path: str) -> str:
    """Transform a relative import path by applying DIR_MAP to segments and gch_ to filename."""
    parts = rel_path.split("/")
    new_parts = []
    for i, part in enumerate(parts):
        is_last = (i == len(parts) - 1)
        if is_last:
            # It's a filename (may have extension)
            name, _, ext = part.rpartition(".")
            if ext and not name.startswith("gch_"):
                new_parts.append("gch_" + part)
            else:
                new_parts.append(part)
        else:
            # It's a directory segment
            new_parts.append(DIR_MAP.get(part, part))
    return "/".join(new_parts)


def fix_import_line(match, dart_file_dir: str) -> str:
    prefix = match.group(1)
    path = match.group(2)
    suffix = match.group(3)

    # Only handle relative imports (no scheme)
    if ":" in path:
        return match.group(0)

    # Compute new path
    new_path = transform_rel_path(path)
    if new_path == path:
        return match.group(0)

    # Verify new path exists (resolve against file directory)
    abs_new = os.path.normpath(os.path.join(dart_file_dir, new_path))
    abs_old = os.path.normpath(os.path.join(dart_file_dir, path))

    # Accept the rewrite if: old doesn't exist AND new does, OR if old already doesn't exist
    if os.path.exists(abs_old):
        return match.group(0)  # old still exists, no need to rewrite

    if os.path.exists(abs_new):
        return f"{prefix}{new_path}{suffix}"

    # Neither exists — still apply the transform (may be .g.dart not yet generated)
    return f"{prefix}{new_path}{suffix}"


def process_file(dart_file: str) -> bool:
    try:
        with open(dart_file, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        return False

    dart_dir = os.path.dirname(dart_file)

    def replacer(m):
        return fix_import_line(m, dart_dir)

    new_content = IMPORT_RE.sub(replacer, content)

    if new_content != content:
        with open(dart_file, "w", encoding="utf-8") as f:
            f.write(new_content)
        return True
    return False


def main():
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    print(f"Working dir: {os.getcwd()}")

    dart_files = []
    for root, _, files in os.walk(LIB_ROOT):
        for f in files:
            if f.endswith(".dart"):
                dart_files.append(os.path.join(root, f))

    changed = 0
    for f in dart_files:
        if process_file(f):
            changed += 1
            print(f"  fixed: {os.path.relpath(f, LIB_ROOT)}")

    print(f"\nFixed relative imports in {changed}/{len(dart_files)} files.")


if __name__ == "__main__":
    main()
