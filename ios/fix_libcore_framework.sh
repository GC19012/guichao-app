#!/bin/bash

# 修复 GchCore.framework 的 iOS 结构和签名问题
# 此脚本将 macOS 风格的 framework 转换为 iOS 扁平结构

set -e

XCFRAMEWORK_PATH="$(dirname "$0")/Frameworks/GchCore.xcframework"
FRAMEWORKS=("ios-arm64" "ios-arm64_x86_64-simulator")

echo "=== 修复 GchCore.xcframework 结构 ==="

for ARCH in "${FRAMEWORKS[@]}"; do
    FRAMEWORK_PATH="$XCFRAMEWORK_PATH/$ARCH/GchCore.framework"

    if [ ! -d "$FRAMEWORK_PATH" ]; then
        echo "跳过: $FRAMEWORK_PATH 不存在"
        continue
    fi

    echo "处理: $FRAMEWORK_PATH"

    # 检查是否是 macOS 风格结构
    if [ -d "$FRAMEWORK_PATH/Versions" ]; then
        echo "  检测到 macOS 风格结构，转换为 iOS 扁平结构..."

        # 创建临时目录
        TEMP_DIR=$(mktemp -d)

        # 复制实际内容（从 Versions/A 目录）
        if [ -d "$FRAMEWORK_PATH/Versions/A" ]; then
            cp -R "$FRAMEWORK_PATH/Versions/A/"* "$TEMP_DIR/"
        fi

        # 删除原 framework
        rm -rf "$FRAMEWORK_PATH"

        # 创建新的扁平结构
        mkdir -p "$FRAMEWORK_PATH"

        # 移动文件到根目录（iOS 扁平结构）
        if [ -f "$TEMP_DIR/GchCore" ]; then
            cp "$TEMP_DIR/GchCore" "$FRAMEWORK_PATH/GchCore"
        fi

        if [ -d "$TEMP_DIR/Headers" ]; then
            cp -R "$TEMP_DIR/Headers" "$FRAMEWORK_PATH/Headers"
        fi

        if [ -d "$TEMP_DIR/Modules" ]; then
            cp -R "$TEMP_DIR/Modules" "$FRAMEWORK_PATH/Modules"
        fi

        # 创建正确的 Info.plist
        cat > "$FRAMEWORK_PATH/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>GchCore</string>
    <key>CFBundleIdentifier</key>
    <string>io.guichao.gchcore</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>GchCore</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>3.1.8</string>
    <key>CFBundleVersion</key>
    <string>3.1.8</string>
    <key>MinimumOSVersion</key>
    <string>15.0</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
</dict>
</plist>
EOF

        # 清理临时目录
        rm -rf "$TEMP_DIR"

        echo "  转换完成"
    else
        echo "  已是 iOS 扁平结构"

        # 确保 Info.plist 存在且正确
        if [ ! -f "$FRAMEWORK_PATH/Info.plist" ] || [ ! -s "$FRAMEWORK_PATH/Info.plist" ]; then
            echo "  创建 Info.plist..."
            cat > "$FRAMEWORK_PATH/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>GchCore</string>
    <key>CFBundleIdentifier</key>
    <string>io.guichao.gchcore</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>GchCore</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>3.1.8</string>
    <key>CFBundleVersion</key>
    <string>3.1.8</string>
    <key>MinimumOSVersion</key>
    <string>15.0</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
</dict>
</plist>
EOF
        fi
    fi

    # 显示最终结构
    echo "  最终结构:"
    ls -la "$FRAMEWORK_PATH"
done

echo ""
echo "=== 修复完成 ==="
echo ""
echo "下一步操作："
echo "1. 在 Xcode 中执行 Clean Build Folder (Shift+Cmd+K)"
echo "2. 删除 DerivedData: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo "3. 重新 Archive 并上传"
echo ""
echo "注意: 确保在 Xcode 中 GuichaoPacketTunnel target 的 Build Settings 中:"
echo "  - 'Always Embed Swift Standard Libraries' = NO"
echo "  - Framework 设置为 'Embed & Sign'"
