#!/usr/bin/env bash
# 改完代码后运行此脚本，彻底清理签名缓存并重建。
# 解决：objective_c.framework 签名失效 / framework binary 找不到 等安装失败问题。
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# ── 1. Flutter 清理 ───────────────────────────────────────────────────────────
echo "▶ flutter clean"
flutter clean

# ── 2. 清理 Xcode DerivedData ─────────────────────────────────────────────────
echo "▶ 清理 Xcode DerivedData"
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# ── 3. 依赖安装 ───────────────────────────────────────────────────────────────
echo "▶ flutter pub get"
flutter pub get

echo "▶ pod install"
(cd ios && pod install)

# ── 4. xcodebuild 验证 ────────────────────────────────────────────────────────
echo "▶ xcodebuild（签名验证）"

BUILD_LOG=$(mktemp)
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | tee "$BUILD_LOG" | \
  grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)" || true

# 从 log 判断结果（不依赖 grep 退出码）
if grep -q "BUILD SUCCEEDED" "$BUILD_LOG"; then
  rm -f "$BUILD_LOG"
  echo ""
  echo "✅ 完成。在 Xcode 里直接 ⌘R 安装到真机即可。"
else
  echo ""
  echo "❌ BUILD FAILED，最后 30 行日志："
  tail -30 "$BUILD_LOG"
  rm -f "$BUILD_LOG"
  exit 1
fi
