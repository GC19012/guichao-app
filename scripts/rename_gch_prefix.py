#!/usr/bin/env python3
"""
Batch rename: add gch_ prefix to lib/ subdirectory names and .dart filenames.
Directories are renamed deepest-first. All import/part/export paths are rewritten.
Run from the project root: python3 scripts/rename_gch_prefix.py
"""

import os
import re

LIB_ROOT = os.path.abspath("lib")

# ── directory name mapping (exact segment → new segment) ─────────────────────
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

# Directory names to leave as-is
SKIP_DIRS = {
    "crash_report", "shuju_tongji", "fuwuqi", "fuwu", "tigong",
}


def collect_dir_renames():
    """Walk lib tree and build list of (old_path, new_path), deepest-first."""
    renames = []
    for root, dirs, _ in os.walk(LIB_ROOT, topdown=False):
        name = os.path.basename(root)
        if name in SKIP_DIRS or name.startswith("gch_"):
            continue
        if name in DIR_MAP:
            new_name = DIR_MAP[name]
            parent = os.path.dirname(root)
            new_path = os.path.join(parent, new_name)
            renames.append((root, new_path))
    return renames


def collect_file_renames(lib_root_after_dirs):
    """Collect dart files not starting with gch_, skipping generated files."""
    renames = []
    for root, _, files in os.walk(lib_root_after_dirs):
        for fname in files:
            if not fname.endswith(".dart"):
                continue
            if fname.startswith("gch_"):
                continue
            old_path = os.path.join(root, fname)
            new_fname = "gch_" + fname
            new_path = os.path.join(root, new_fname)
            renames.append((old_path, new_path))
    return renames


def build_path_map(dir_renames, file_renames):
    """Build old→new import segment map for rewriting. Returns list of (old_rel, new_rel)."""
    mappings = []
    for old, new in dir_renames + file_renames:
        old_rel = os.path.relpath(old, os.path.dirname(LIB_ROOT))  # relative to project root
        new_rel = os.path.relpath(new, os.path.dirname(LIB_ROOT))
        # Convert to package import path (lib/... → package:guichao/...)
        old_pkg = old_rel.replace(os.sep, "/")
        new_pkg = new_rel.replace(os.sep, "/")
        if old_pkg.startswith("lib/"):
            old_pkg = "package:guichao/" + old_pkg[4:]
            new_pkg = "package:guichao/" + new_pkg[4:]
        # Also handle relative imports by storing the path suffix
        mappings.append((old_rel.replace(os.sep, "/"), new_rel.replace(os.sep, "/")))
    # Sort by length descending so longer paths match before shorter ones
    mappings.sort(key=lambda x: len(x[0]), reverse=True)
    return mappings


def rewrite_imports(all_dart_files, mappings):
    """Rewrite import/part/export/part of lines in all dart files."""
    # Build a set of (old_pkg_suffix, new_pkg_suffix) for matching
    pkg_mappings = []
    for old_rel, new_rel in mappings:
        if old_rel.startswith("lib/"):
            old_pkg = "package:guichao/" + old_rel[4:]
            new_pkg = "package:guichao/" + new_rel[4:]
            pkg_mappings.append((old_pkg, new_pkg))

    pattern = re.compile(
        r"""((?:import|export|part\s+of|part)\s+['"])([^'"]+)(['"])"""
    )

    changed_count = 0
    for dart_file in all_dart_files:
        try:
            with open(dart_file, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception:
            continue

        new_content = content
        for old_pkg, new_pkg in pkg_mappings:
            if old_pkg in new_content:
                new_content = new_content.replace(old_pkg, new_pkg)

        if new_content != content:
            with open(dart_file, "w", encoding="utf-8") as f:
                f.write(new_content)
            changed_count += 1

    print(f"  Rewrote imports in {changed_count} files")


def apply_dir_renames(renames):
    count = 0
    for old, new in renames:
        if not os.path.exists(old):
            print(f"  SKIP (gone): {old}")
            continue
        if os.path.exists(new) and old != new:
            print(f"  SKIP (conflict): {old} → {new} (target exists)")
            continue
        os.rename(old, new)
        print(f"  DIR  {os.path.relpath(old, LIB_ROOT)} → {os.path.relpath(new, LIB_ROOT)}")
        count += 1
    return count


def apply_file_renames(renames):
    count = 0
    for old, new in renames:
        if not os.path.exists(old):
            continue
        if os.path.exists(new):
            print(f"  SKIP (conflict): {old} → {new}")
            continue
        os.rename(old, new)
        print(f"  FILE {os.path.relpath(old, LIB_ROOT)} → {os.path.relpath(new, LIB_ROOT)}")
        count += 1
    return count


def main():
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    print(f"Working dir: {os.getcwd()}")
    print(f"LIB_ROOT:    {LIB_ROOT}")

    print("\n=== Phase 1: Collect directory renames ===")
    dir_renames = collect_dir_renames()
    print(f"  {len(dir_renames)} directories to rename")

    print("\n=== Phase 2: Collect file renames ===")
    file_renames_preview = collect_file_renames(LIB_ROOT)
    print(f"  {len(file_renames_preview)} dart files to rename")

    # Build path map BEFORE doing any renames (paths still exist)
    all_mappings = build_path_map(dir_renames, file_renames_preview)

    print("\n=== Phase 3: Apply directory renames (deepest-first) ===")
    n_dirs = apply_dir_renames(dir_renames)
    print(f"  Renamed {n_dirs} directories")

    print("\n=== Phase 4: Apply file renames ===")
    # Re-collect file renames with updated paths after directory renames
    file_renames_actual = collect_file_renames(LIB_ROOT)
    n_files = apply_file_renames(file_renames_actual)
    print(f"  Renamed {n_files} files")

    print("\n=== Phase 5: Rewrite import paths ===")
    all_dart_files = []
    for root, _, files in os.walk(LIB_ROOT):
        for f in files:
            if f.endswith(".dart"):
                all_dart_files.append(os.path.join(root, f))
    rewrite_imports(all_dart_files, all_mappings)

    print(f"\nDone. {n_dirs} dirs + {n_files} files renamed.")
    print("Run: flutter analyze lib/ 2>&1 | head -80")


if __name__ == "__main__":
    main()
