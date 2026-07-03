#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Design Slicer

A pragmatic image slicing tool for turning design mockups (Figma/Sketch exports)
into Flutter-ready assets.

Features
- Multiple slicing modes:
  - spec: arbitrary rectangles from a JSON/YAML spec
  - grid: uniform grid slicing
  - nine: 9-slice (3x3) by insets
  - autocrop: crop by alpha/content bbox
- Output normalization:
  - convert format (png/jpg/webp)
  - generate @1x/@2x/@3x variants
  - optional padding / safe clipping
- Compression for app delivery:
  - PNG: optimize + optional adaptive palette quantization
  - WebP: lossless or lossy with quality control
  - JPEG: progressive + optimize

Typical usage
  python design_slicer.py spec --input design.png --spec slices.json --out assets/

Spec schema (JSON/YAML)
{
  "defaults": {
    "format": "png",
    "variants": [1,2,3],
    "scale_base": 3,
    "compression": {"png": {"quantize": false, "colors": 256}, "webp": {"lossless": true, "quality": 95}}
  },
  "slices": [
    {"name": "btn_primary", "box": [120, 800, 420, 920], "format": "png"},
    {"name": "bg_header", "box": {"x":0,"y":0,"w":1080,"h":320}, "format": "webp", "compression": {"webp": {"lossless": true}}}
  ]
}

Box formats
- [left, top, right, bottom]
- {x,y,w,h}

Outputs
- assets/btn_primary.png, assets/btn_primary@2x.png, assets/btn_primary@3x.png (if variants enabled)

"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Sequence, Tuple, Union

from PIL import Image


# ------------------------- Utilities -------------------------

def _eprint(*args: Any) -> None:
    print(*args, file=sys.stderr)


def _ensure_dir(p: str) -> None:
    os.makedirs(p, exist_ok=True)


def _safe_int(x: Any) -> int:
    if isinstance(x, (int,)):
        return int(x)
    if isinstance(x, float):
        return int(round(x))
    if isinstance(x, str) and x.strip() != "":
        return int(round(float(x)))
    raise ValueError(f"Cannot convert to int: {x!r}")


def _load_spec(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    # Try YAML if available
    if path.lower().endswith((".yml", ".yaml")):
        try:
            import yaml  # type: ignore
        except Exception as e:
            raise RuntimeError("YAML spec requires PyYAML. Install with: pip install pyyaml") from e
        return yaml.safe_load(text)

    return json.loads(text)


def _parse_box(box: Union[Sequence[Any], Dict[str, Any]]) -> Tuple[int, int, int, int]:
    """Return (l, t, r, b)"""
    if isinstance(box, (list, tuple)):
        if len(box) != 4:
            raise ValueError("box list/tuple must have 4 items: [l,t,r,b]")
        l, t, r, b = (_safe_int(box[0]), _safe_int(box[1]), _safe_int(box[2]), _safe_int(box[3]))
        return l, t, r, b
    if isinstance(box, dict):
        if all(k in box for k in ("x", "y", "w", "h")):
            x = _safe_int(box["x"])
            y = _safe_int(box["y"])
            w = _safe_int(box["w"])
            h = _safe_int(box["h"])
            return x, y, x + w, y + h
        if all(k in box for k in ("l", "t", "r", "b")):
            return _safe_int(box["l"]), _safe_int(box["t"]), _safe_int(box["r"]), _safe_int(box["b"])
    raise ValueError(f"Unsupported box format: {box!r}")


def _clip_box(l: int, t: int, r: int, b: int, w: int, h: int, pad: int = 0) -> Tuple[int, int, int, int]:
    l2 = max(0, l - pad)
    t2 = max(0, t - pad)
    r2 = min(w, r + pad)
    b2 = min(h, b + pad)
    if r2 <= l2 or b2 <= t2:
        raise ValueError(f"Invalid/empty crop box after clipping: {(l2,t2,r2,b2)}")
    return l2, t2, r2, b2


def _autocrop_box(img: Image.Image, threshold: int = 0, pad: int = 0) -> Optional[Tuple[int, int, int, int]]:
    """Compute bbox by alpha if exists; else by luminance threshold."""
    if img.mode in ("RGBA", "LA"):
        alpha = img.getchannel("A")
        bbox = alpha.point(lambda a: 255 if a > threshold else 0).getbbox()
    else:
        gray = img.convert("L")
        bbox = gray.point(lambda p: 255 if p > threshold else 0).getbbox()
    if bbox is None:
        return None
    l, t, r, b = bbox
    return _clip_box(l, t, r, b, img.width, img.height, pad=pad)


# ------------------------- Compression -------------------------

@dataclass
class PngCompression:
    quantize: bool = False
    colors: int = 256
    optimize: bool = True


@dataclass
class WebpCompression:
    lossless: bool = True
    quality: int = 95
    method: int = 6


@dataclass
class JpegCompression:
    quality: int = 85
    optimize: bool = True
    progressive: bool = True


@dataclass
class CompressionConfig:
    png: PngCompression = field(default_factory=PngCompression)
    webp: WebpCompression = field(default_factory=WebpCompression)
    jpg: JpegCompression = field(default_factory=JpegCompression)

    @staticmethod
    def from_dict(d: Optional[Dict[str, Any]]) -> "CompressionConfig":
        cfg = CompressionConfig()
        if not d:
            return cfg
        if "png" in d and isinstance(d["png"], dict):
            p = d["png"]
            cfg.png = PngCompression(
                quantize=bool(p.get("quantize", cfg.png.quantize)),
                colors=_safe_int(p.get("colors", cfg.png.colors)),
                optimize=bool(p.get("optimize", cfg.png.optimize)),
            )
        if "webp" in d and isinstance(d["webp"], dict):
            w = d["webp"]
            cfg.webp = WebpCompression(
                lossless=bool(w.get("lossless", cfg.webp.lossless)),
                quality=_safe_int(w.get("quality", cfg.webp.quality)),
                method=_safe_int(w.get("method", cfg.webp.method)),
            )
        if "jpg" in d and isinstance(d["jpg"], dict):
            j = d["jpg"]
            cfg.jpg = JpegCompression(
                quality=_safe_int(j.get("quality", cfg.jpg.quality)),
                optimize=bool(j.get("optimize", cfg.jpg.optimize)),
                progressive=bool(j.get("progressive", cfg.jpg.progressive)),
            )
        return cfg


def _save_image(img: Image.Image, out_path: str, fmt: str, comp: CompressionConfig) -> None:
    fmt_l = fmt.lower()
    ext = os.path.splitext(out_path)[1].lower().lstrip(".")
    if ext and ext != fmt_l:
        # Keep extension consistent with chosen format
        out_path = os.path.splitext(out_path)[0] + "." + fmt_l

    if fmt_l == "png":
        out_img = img
        if out_img.mode not in ("RGB", "RGBA"):
            out_img = out_img.convert("RGBA")
        if comp.png.quantize:
            # Adaptive palette; keep alpha when present
            if out_img.mode == "RGBA":
                # Quantize requires conversion; Pillow handles alpha via RGBA->P with transparency
                out_img = out_img.quantize(colors=comp.png.colors, method=Image.Quantize.FASTOCTREE)
            else:
                out_img = out_img.convert("RGB").quantize(colors=comp.png.colors, method=Image.Quantize.FASTOCTREE)
        out_img.save(out_path, format="PNG", optimize=comp.png.optimize)
        return

    if fmt_l in ("webp", "webp-lossless", "webp_lossless"):
        out_img = img
        if out_img.mode not in ("RGB", "RGBA"):
            out_img = out_img.convert("RGBA")
        out_img.save(
            out_path,
            format="WEBP",
            lossless=comp.webp.lossless,
            quality=int(comp.webp.quality),
            method=int(comp.webp.method),
        )
        return

    if fmt_l in ("jpg", "jpeg"):
        out_img = img
        if out_img.mode == "RGBA":
            # Composite onto white by default for JPEG
            bg = Image.new("RGB", out_img.size, (255, 255, 255))
            bg.paste(out_img, mask=out_img.getchannel("A"))
            out_img = bg
        else:
            out_img = out_img.convert("RGB")
        out_img.save(
            out_path,
            format="JPEG",
            quality=int(comp.jpg.quality),
            optimize=comp.jpg.optimize,
            progressive=comp.jpg.progressive,
        )
        return

    raise ValueError(f"Unsupported output format: {fmt}")


# ------------------------- Slicing core -------------------------

def _resize_variant(img: Image.Image, scale: float) -> Image.Image:
    if scale == 1.0:
        return img
    w = max(1, int(round(img.width * scale)))
    h = max(1, int(round(img.height * scale)))
    return img.resize((w, h), resample=Image.LANCZOS)


def _variant_suffix(scale: int) -> str:
    return "" if scale == 1 else f"@{scale}x"


def slice_by_spec(
    img: Image.Image,
    spec: Dict[str, Any],
    out_dir: str,
    dry_run: bool = False,
) -> List[str]:
    _ensure_dir(out_dir)

    defaults = spec.get("defaults", {}) if isinstance(spec.get("defaults", {}), dict) else {}
    default_format = str(defaults.get("format", "png"))
    variants = defaults.get("variants", [1])
    if not isinstance(variants, list) or not variants:
        variants = [1]
    variants = [int(v) for v in variants]

    scale_base = int(defaults.get("scale_base", 1))  # typically 3 if design exported at @3x
    pad = int(defaults.get("pad", 0))
    threshold = int(defaults.get("autocrop_threshold", 0))

    default_comp = CompressionConfig.from_dict(defaults.get("compression", None))

    outputs: List[str] = []
    slices = spec.get("slices", [])
    if not isinstance(slices, list):
        raise ValueError("spec.slices must be a list")

    for s in slices:
        if not isinstance(s, dict):
            raise ValueError("each slice must be an object")
        name = s.get("name")
        if not name or not isinstance(name, str):
            raise ValueError("slice missing valid name")

        fmt = str(s.get("format", default_format))
        comp = CompressionConfig.from_dict(_deep_merge(defaults.get("compression", None), s.get("compression", None)))

        mode = str(s.get("mode", "box"))
        if mode == "autocrop":
            bbox = _autocrop_box(img, threshold=int(s.get("threshold", threshold)), pad=int(s.get("pad", pad)))
            if bbox is None:
                _eprint(f"[WARN] autocrop bbox not found for {name}; skipped")
                continue
            l, t, r, b = bbox
        else:
            box = s.get("box")
            if box is None:
                raise ValueError(f"slice {name} missing box")
            l, t, r, b = _parse_box(box)
            l, t, r, b = _clip_box(l, t, r, b, img.width, img.height, pad=int(s.get("pad", pad)))

        cropped = img.crop((l, t, r, b))

        # Variants: interpret design as exported at scale_base; produce requested scales.
        # Example: scale_base=3 and variants [1,2,3] => output 1x=1/3, 2x=2/3, 3x=1.
        for v in variants:
            scale = v / scale_base
            out_img = _resize_variant(cropped, scale)
            out_name = f"{name}{_variant_suffix(v)}.{fmt.lower()}"
            out_path = os.path.join(out_dir, out_name)
            outputs.append(out_path)
            if dry_run:
                continue
            _save_image(out_img, out_path, fmt, comp)

    return outputs


def slice_grid(
    img: Image.Image,
    out_dir: str,
    rows: int,
    cols: int,
    name_prefix: str = "tile",
    fmt: str = "png",
    margin: int = 0,
    gutter: int = 0,
    comp: Optional[CompressionConfig] = None,
    dry_run: bool = False,
) -> List[str]:
    _ensure_dir(out_dir)
    comp = comp or CompressionConfig()

    usable_w = img.width - 2 * margin - (cols - 1) * gutter
    usable_h = img.height - 2 * margin - (rows - 1) * gutter
    if usable_w <= 0 or usable_h <= 0:
        raise ValueError("Invalid margin/gutter leading to non-positive usable area")

    cell_w = usable_w / cols
    cell_h = usable_h / rows

    outputs: List[str] = []
    for r in range(rows):
        for c in range(cols):
            l = margin + int(round(c * (cell_w + gutter)))
            t = margin + int(round(r * (cell_h + gutter)))
            rr = margin + int(round((c + 1) * cell_w + c * gutter))
            bb = margin + int(round((r + 1) * cell_h + r * gutter))
            l, t, rr, bb = _clip_box(l, t, rr, bb, img.width, img.height, pad=0)
            cropped = img.crop((l, t, rr, bb))
            out_name = f"{name_prefix}_r{r}_c{c}.{fmt.lower()}"
            out_path = os.path.join(out_dir, out_name)
            outputs.append(out_path)
            if dry_run:
                continue
            _save_image(cropped, out_path, fmt, comp)

    return outputs


def slice_nine(
    img: Image.Image,
    out_dir: str,
    name_prefix: str,
    insets: Tuple[int, int, int, int],
    fmt: str = "png",
    comp: Optional[CompressionConfig] = None,
    dry_run: bool = False,
) -> List[str]:
    """9-slice into 3x3 pieces by (left, top, right, bottom) insets.

    insets specify fixed borders. Middle parts are the stretchable areas.
    Outputs: name_prefix_{tl,t, tr, l, c, r, bl, b, br}.*
    """
    _ensure_dir(out_dir)
    comp = comp or CompressionConfig()

    left, top, right, bottom = insets
    if left < 0 or top < 0 or right < 0 or bottom < 0:
        raise ValueError("Insets must be non-negative")
    if left + right >= img.width or top + bottom >= img.height:
        raise ValueError("Insets too large for image")

    x0, x1, x2, x3 = 0, left, img.width - right, img.width
    y0, y1, y2, y3 = 0, top, img.height - bottom, img.height

    regions = {
        "tl": (x0, y0, x1, y1),
        "t": (x1, y0, x2, y1),
        "tr": (x2, y0, x3, y1),
        "l": (x0, y1, x1, y2),
        "c": (x1, y1, x2, y2),
        "r": (x2, y1, x3, y2),
        "bl": (x0, y2, x1, y3),
        "b": (x1, y2, x2, y3),
        "br": (x2, y2, x3, y3),
    }

    outputs: List[str] = []
    for key, box in regions.items():
        cropped = img.crop(box)
        out_name = f"{name_prefix}_{key}.{fmt.lower()}"
        out_path = os.path.join(out_dir, out_name)
        outputs.append(out_path)
        if dry_run:
            continue
        _save_image(cropped, out_path, fmt, comp)

    return outputs


def _deep_merge(a: Optional[Dict[str, Any]], b: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    if a is None and b is None:
        return None
    if a is None:
        return b
    if b is None:
        return a
    if not isinstance(a, dict) or not isinstance(b, dict):
        return b
    out = dict(a)
    for k, v in b.items():
        if k in out and isinstance(out[k], dict) and isinstance(v, dict):
            out[k] = _deep_merge(out[k], v)
        else:
            out[k] = v
    return out


# ------------------------- CLI -------------------------

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="design_slicer",
        description="Slice design images into app assets (Flutter-ready).",
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    # spec
    ps = sub.add_parser("spec", help="Slice by JSON/YAML spec (arbitrary rectangles).")
    ps.add_argument("--input", "-i", required=True, help="Input design image (png/jpg/webp).")
    ps.add_argument("--spec", required=True, help="Spec file path (.json/.yml).")
    ps.add_argument("--out", "-o", required=True, help="Output directory.")
    ps.add_argument("--dry-run", action="store_true", help="Only print outputs, do not write files.")

    # grid
    pg = sub.add_parser("grid", help="Slice into a uniform grid.")
    pg.add_argument("--input", "-i", required=True)
    pg.add_argument("--out", "-o", required=True)
    pg.add_argument("--rows", type=int, required=True)
    pg.add_argument("--cols", type=int, required=True)
    pg.add_argument("--name-prefix", default="tile")
    pg.add_argument("--format", default="png", choices=["png", "webp", "jpg", "jpeg"])
    pg.add_argument("--margin", type=int, default=0)
    pg.add_argument("--gutter", type=int, default=0)
    pg.add_argument("--dry-run", action="store_true")
    pg.add_argument("--png-quantize", action="store_true")
    pg.add_argument("--png-colors", type=int, default=256)
    pg.add_argument("--webp-lossless", action="store_true")
    pg.add_argument("--webp-quality", type=int, default=95)
    pg.add_argument("--jpeg-quality", type=int, default=85)

    # nine
    pn = sub.add_parser("nine", help="9-slice (3x3) by insets.")
    pn.add_argument("--input", "-i", required=True)
    pn.add_argument("--out", "-o", required=True)
    pn.add_argument("--name-prefix", required=True)
    pn.add_argument("--insets", required=True, help="Insets as 'left,top,right,bottom' (pixels).")
    pn.add_argument("--format", default="png", choices=["png", "webp", "jpg", "jpeg"])
    pn.add_argument("--dry-run", action="store_true")
    pn.add_argument("--png-quantize", action="store_true")
    pn.add_argument("--png-colors", type=int, default=256)
    pn.add_argument("--webp-lossless", action="store_true")
    pn.add_argument("--webp-quality", type=int, default=95)
    pn.add_argument("--jpeg-quality", type=int, default=85)

    # autocrop
    pa = sub.add_parser("autocrop", help="Auto-crop by alpha/content and save a single output.")
    pa.add_argument("--input", "-i", required=True)
    pa.add_argument("--out", "-o", required=True, help="Output file path (extension decides format unless --format).")
    pa.add_argument("--format", default=None, choices=[None, "png", "webp", "jpg", "jpeg"], nargs="?")
    pa.add_argument("--threshold", type=int, default=0, help="Alpha/luma threshold (0-255).")
    pa.add_argument("--pad", type=int, default=0)
    pa.add_argument("--dry-run", action="store_true")
    pa.add_argument("--png-quantize", action="store_true")
    pa.add_argument("--png-colors", type=int, default=256)
    pa.add_argument("--webp-lossless", action="store_true")
    pa.add_argument("--webp-quality", type=int, default=95)
    pa.add_argument("--jpeg-quality", type=int, default=85)

    return p


def _comp_from_args(args: argparse.Namespace) -> CompressionConfig:
    cfg = CompressionConfig()
    if hasattr(args, "png_quantize"):
        cfg.png.quantize = bool(args.png_quantize)
        cfg.png.colors = int(getattr(args, "png_colors", cfg.png.colors))
    if hasattr(args, "webp_lossless"):
        cfg.webp.lossless = bool(args.webp_lossless)
        cfg.webp.quality = int(getattr(args, "webp_quality", cfg.webp.quality))
    if hasattr(args, "jpeg_quality"):
        cfg.jpg.quality = int(args.jpeg_quality)
    return cfg


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.cmd == "spec":
        img = Image.open(args.input)
        spec = _load_spec(args.spec)
        outputs = slice_by_spec(img, spec, args.out, dry_run=bool(args.dry_run))
        for p in outputs:
            print(p)
        return 0

    if args.cmd == "grid":
        img = Image.open(args.input)
        comp = _comp_from_args(args)
        outputs = slice_grid(
            img,
            out_dir=args.out,
            rows=int(args.rows),
            cols=int(args.cols),
            name_prefix=str(args.name_prefix),
            fmt=str(args.format),
            margin=int(args.margin),
            gutter=int(args.gutter),
            comp=comp,
            dry_run=bool(args.dry_run),
        )
        for p in outputs:
            print(p)
        return 0

    if args.cmd == "nine":
        img = Image.open(args.input)
        comp = _comp_from_args(args)
        parts = [s.strip() for s in str(args.insets).split(",")]
        if len(parts) != 4:
            raise SystemExit("--insets must be 'left,top,right,bottom'")
        insets = tuple(int(_safe_int(x)) for x in parts)  # type: ignore
        outputs = slice_nine(
            img,
            out_dir=args.out,
            name_prefix=str(args.name_prefix),
            insets=insets,  # type: ignore
            fmt=str(args.format),
            comp=comp,
            dry_run=bool(args.dry_run),
        )
        for p in outputs:
            print(p)
        return 0

    if args.cmd == "autocrop":
        img = Image.open(args.input)
        bbox = _autocrop_box(img, threshold=int(args.threshold), pad=int(args.pad))
        if bbox is None:
            _eprint("[WARN] autocrop bbox not found; nothing to save")
            return 2
        cropped = img.crop(bbox)
        comp = _comp_from_args(args)
        fmt = args.format
        if fmt is None:
            ext = os.path.splitext(args.out)[1].lower().lstrip(".")
            fmt = ext if ext else "png"
        if args.dry_run:
            print(args.out)
            return 0
        _ensure_dir(os.path.dirname(os.path.abspath(args.out)) or ".")
        _save_image(cropped, args.out, str(fmt), comp)
        print(args.out)
        return 0

    raise SystemExit("Unknown command")


if __name__ == "__main__":
    raise SystemExit(main())
