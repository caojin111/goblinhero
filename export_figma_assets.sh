#!/bin/bash
# Figma 资源导出辅助脚本
# 使用方法：将导出的 PNG 文件放在 Downloads 文件夹，然后运行此脚本

echo "📥 Figma 资源导入脚本"
echo "===================="
echo ""

# 检查 Downloads 文件夹中的资源文件
DOWNLOADS_DIR="$HOME/Downloads"
SIGN_IN_DIR="A004/Assets.xcassets/sign_in"

# 检查并移动背景图片
if [ -f "$DOWNLOADS_DIR/sign_in_background.png" ]; then
    echo "✅ 找到背景图片，正在移动..."
    cp "$DOWNLOADS_DIR/sign_in_background.png" "$SIGN_IN_DIR/background.imageset/"
    echo "   → $SIGN_IN_DIR/background.imageset/sign_in_background.png"
fi

if [ -f "$DOWNLOADS_DIR/sign_in_background@2x.png" ]; then
    cp "$DOWNLOADS_DIR/sign_in_background@2x.png" "$SIGN_IN_DIR/background.imageset/"
    echo "   → $SIGN_IN_DIR/background.imageset/sign_in_background@2x.png"
fi

if [ -f "$DOWNLOADS_DIR/sign_in_background@3x.png" ]; then
    cp "$DOWNLOADS_DIR/sign_in_background@3x.png" "$SIGN_IN_DIR/background.imageset/"
    echo "   → $SIGN_IN_DIR/background.imageset/sign_in_background@3x.png"
fi

# 检查并移动奖励背景
if [ -f "$DOWNLOADS_DIR/sign_in_reward_bg.png" ]; then
    echo "✅ 找到奖励背景，正在移动..."
    cp "$DOWNLOADS_DIR/sign_in_reward_bg.png" "$SIGN_IN_DIR/reward_bg.imageset/"
    echo "   → $SIGN_IN_DIR/reward_bg.imageset/sign_in_reward_bg.png"
fi

if [ -f "$DOWNLOADS_DIR/sign_in_reward_bg@2x.png" ]; then
    cp "$DOWNLOADS_DIR/sign_in_reward_bg@2x.png" "$SIGN_IN_DIR/reward_bg.imageset/"
    echo "   → $SIGN_IN_DIR/reward_bg.imageset/sign_in_reward_bg@2x.png"
fi

if [ -f "$DOWNLOADS_DIR/sign_in_reward_bg@3x.png" ]; then
    cp "$DOWNLOADS_DIR/sign_in_reward_bg@3x.png" "$SIGN_IN_DIR/reward_bg.imageset/"
    echo "   → $SIGN_IN_DIR/reward_bg.imageset/sign_in_reward_bg@3x.png"
fi

# 检查并移动按钮背景
if [ -f "$DOWNLOADS_DIR/sign_in_button_bg.png" ]; then
    echo "✅ 找到按钮背景，正在移动..."
    cp "$DOWNLOADS_DIR/sign_in_button_bg.png" "$SIGN_IN_DIR/button_bg.imageset/"
    echo "   → $SIGN_IN_DIR/button_bg.imageset/sign_in_button_bg.png"
fi

if [ -f "$DOWNLOADS_DIR/sign_in_button_bg@2x.png" ]; then
    cp "$DOWNLOADS_DIR/sign_in_button_bg@2x.png" "$SIGN_IN_DIR/button_bg.imageset/"
    echo "   → $SIGN_IN_DIR/button_bg.imageset/sign_in_button_bg@2x.png"
fi

if [ -f "$DOWNLOADS_DIR/sign_in_button_bg@3x.png" ]; then
    cp "$DOWNLOADS_DIR/sign_in_button_bg@3x.png" "$SIGN_IN_DIR/button_bg.imageset/"
    echo "   → $SIGN_IN_DIR/button_bg.imageset/sign_in_button_bg@3x.png"
fi

echo ""
echo "✨ 完成！请确保在 Xcode 中将文件添加到项目 target。"
