#!/usr/bin/env python3
"""
图像格式批量转换 WebP 工具

支持格式: png, jpg, jpeg, bmp, tiff, gif, svg, ico, webp(重压缩)

用法:
  # 转换单个文件
  python scripts/to_webp.py assets/images/logo.png

  # 转换整个目录（递归）
  python scripts/to_webp.py assets/images/

  # 指定质量 (1-100, 默认 80)
  python scripts/to_webp.py assets/images/ -q 90

  # 无损压缩
  python scripts/to_webp.py assets/images/ --lossless

  # 转换后删除原文件
  python scripts/to_webp.py assets/images/ --delete

  # 只转换 png 和 jpg
  python scripts/to_webp.py assets/images/ --only png,jpg

  # 预览模式（不实际转换，只显示会处理哪些文件）
  python scripts/to_webp.py assets/images/ --dry-run

  # 限制最大尺寸（长边不超过指定像素）
  python scripts/to_webp.py assets/images/ --max-size 1024

依赖:
  pip install Pillow cairosvg
  (cairosvg 仅 SVG 转换需要，不用 SVG 可不装)
"""

import argparse
import os
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("错误: 需要安装 Pillow\n  pip install Pillow")
    sys.exit(1)

SUPPORTED_RASTER = {".png", ".jpg", ".jpeg", ".bmp", ".tiff", ".tif", ".gif", ".ico", ".webp"}
SUPPORTED_VECTOR = {".svg"}
ALL_SUPPORTED = SUPPORTED_RASTER | SUPPORTED_VECTOR


def convert_svg(src: Path, dst: Path, quality: int, lossless: bool, max_size: int | None) -> bool:
    """SVG -> WebP (需要 cairosvg)"""
    try:
        import cairosvg
    except ImportError:
        print(f"  跳过 {src} (SVG 转换需要 cairosvg: pip install cairosvg)")
        return False

    import io

    png_data = cairosvg.svg2png(url=str(src))
    img = Image.open(io.BytesIO(png_data))

    if max_size:
        img = _resize(img, max_size)

    params = {"lossless": lossless}
    if not lossless:
        params["quality"] = quality

    img.save(dst, "WEBP", **params)
    return True


def convert_raster(src: Path, dst: Path, quality: int, lossless: bool, max_size: int | None) -> bool:
    """光栅图 -> WebP"""
    img = Image.open(src)

    # 处理动图 (GIF)
    if getattr(img, "n_frames", 1) > 1 and src.suffix.lower() == ".gif":
        return _convert_animated_gif(img, dst, quality, lossless)

    # RGBA 保留透明通道，否则转 RGB
    if img.mode in ("RGBA", "LA", "PA"):
        img = img.convert("RGBA")
    elif img.mode != "RGB":
        img = img.convert("RGB")

    if max_size:
        img = _resize(img, max_size)

    params = {"lossless": lossless}
    if not lossless:
        params["quality"] = quality

    img.save(dst, "WEBP", **params)
    return True


def _convert_animated_gif(img: Image.Image, dst: Path, quality: int, lossless: bool) -> bool:
    """动态 GIF -> 动态 WebP"""
    frames = []
    durations = []

    try:
        while True:
            frame = img.copy().convert("RGBA")
            frames.append(frame)
            durations.append(img.info.get("duration", 100))
            img.seek(img.tell() + 1)
    except EOFError:
        pass

    if not frames:
        return False

    params = {"save_all": True, "append_images": frames[1:], "duration": durations, "loop": 0, "lossless": lossless}
    if not lossless:
        params["quality"] = quality

    frames[0].save(dst, "WEBP", **params)
    return True


def _resize(img: Image.Image, max_size: int) -> Image.Image:
    """等比缩放，长边不超过 max_size"""
    w, h = img.size
    if max(w, h) <= max_size:
        return img
    ratio = max_size / max(w, h)
    new_w, new_h = int(w * ratio), int(h * ratio)
    return img.resize((new_w, new_h), Image.LANCZOS)


def _file_size_str(size_bytes: int) -> str:
    if size_bytes < 1024:
        return f"{size_bytes}B"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.1f}KB"
    else:
        return f"{size_bytes / (1024 * 1024):.1f}MB"


def collect_files(path: Path, only_exts: set[str] | None) -> list[Path]:
    """收集需要转换的文件"""
    allowed = only_exts if only_exts else ALL_SUPPORTED
    files = []

    if path.is_file():
        if path.suffix.lower() in allowed:
            files.append(path)
    elif path.is_dir():
        for f in sorted(path.rglob("*")):
            if f.is_file() and f.suffix.lower() in allowed:
                files.append(f)

    return files


def convert_file(src: Path, quality: int, lossless: bool, max_size: int | None, delete: bool, dry_run: bool) -> dict:
    """转换单个文件，返回结果信息"""
    dst = src.with_suffix(".webp")
    src_size = src.stat().st_size
    ext = src.suffix.lower()

    # 跳过已经是 webp 且目标就是自己的情况（除非要重压缩）
    if ext == ".webp" and not delete:
        # 重压缩到临时文件
        dst = src.with_name(src.stem + "_recompressed.webp")

    result = {
        "src": str(src),
        "dst": str(dst),
        "src_size": src_size,
        "dst_size": 0,
        "saved": 0,
        "status": "skip",
    }

    if dry_run:
        result["status"] = "dry-run"
        return result

    try:
        if ext in SUPPORTED_VECTOR:
            ok = convert_svg(src, dst, quality, lossless, max_size)
        else:
            ok = convert_raster(src, dst, quality, lossless, max_size)

        if not ok:
            result["status"] = "failed"
            return result

        dst_size = dst.stat().st_size
        result["dst_size"] = dst_size
        result["saved"] = src_size - dst_size
        result["status"] = "ok"

        # 删除原文件（仅当不是同名 webp 时）
        if delete and src != dst and src.exists():
            src.unlink()

    except Exception as e:
        result["status"] = f"error: {e}"

    return result


def main():
    parser = argparse.ArgumentParser(description="图像批量转换 WebP")
    parser.add_argument("path", help="文件或目录路径")
    parser.add_argument("-q", "--quality", type=int, default=80, help="压缩质量 1-100 (默认 80)")
    parser.add_argument("--lossless", action="store_true", help="无损压缩")
    parser.add_argument("--delete", action="store_true", help="转换后删除原文件")
    parser.add_argument("--dry-run", action="store_true", help="预览模式，不实际转换")
    parser.add_argument("--max-size", type=int, default=None, help="最大尺寸（长边像素）")
    parser.add_argument("--only", type=str, default=None, help="只转换指定格式，逗号分隔 (如: png,jpg)")

    args = parser.parse_args()
    target = Path(args.path)

    if not target.exists():
        print(f"错误: 路径不存在 {target}")
        sys.exit(1)

    only_exts = None
    if args.only:
        only_exts = {"." + e.strip().lower().lstrip(".") for e in args.only.split(",")}

    files = collect_files(target, only_exts)

    if not files:
        print("没有找到可转换的文件")
        return

    print(f"找到 {len(files)} 个文件")
    if args.dry_run:
        print("(预览模式)\n")

    total_src = 0
    total_dst = 0
    ok_count = 0

    for f in files:
        result = convert_file(f, args.quality, args.lossless, args.max_size, args.delete, args.dry_run)
        status = result["status"]
        src_str = _file_size_str(result["src_size"])

        if status == "ok":
            dst_str = _file_size_str(result["dst_size"])
            saved_pct = (result["saved"] / result["src_size"] * 100) if result["src_size"] > 0 else 0
            print(f"  ✅ {result['src']}  {src_str} -> {dst_str}  ({saved_pct:+.0f}%)")
            total_src += result["src_size"]
            total_dst += result["dst_size"]
            ok_count += 1
        elif status == "dry-run":
            print(f"  📋 {result['src']}  ({src_str})")
        else:
            print(f"  ❌ {result['src']}  ({status})")

    print(f"\n完成: {ok_count}/{len(files)} 个文件")
    if ok_count > 0:
        saved = total_src - total_dst
        print(f"总计: {_file_size_str(total_src)} -> {_file_size_str(total_dst)}  (节省 {_file_size_str(saved)})")


if __name__ == "__main__":
    main()
