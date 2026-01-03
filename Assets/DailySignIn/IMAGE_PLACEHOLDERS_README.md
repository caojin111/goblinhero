# 七日签到页面图片占位符说明

## 当前临时样式说明

由于无法直接下载 Figma 图片资源，我已经将所有图片位置替换为临时的几何图形和颜色，方便您查看页面布局和功能。

## 需要替换的图片资源

### 1. 背景图片
- `daily_sign_in_bg.png` - 主背景图片 (当前用白色背景代替)

### 2. 标题栏
- `header_bg.png` - 标题栏背景 (当前用灰色半透明背景代替)

### 3. 按钮
- `close_button.png` - 关闭按钮 (当前用蓝色圆形加文字代替)

### 4. 天数标签
- `day_label_normal.png` - 普通天数标签背景
- `day_label_today.png` - 今日天数标签背景  
- `day_label_claimed.png` - 已签到天数标签背景
(当前都用圆角矩形加对应颜色代替)

### 5. 奖励背景
- `reward_bg_normal.png` - 普通奖励背景
- `reward_bg_today.png` - 今日奖励背景
- `reward_bg_claimed.png` - 已签到奖励背景
(当前都用圆形加对应颜色代替)

### 6. 连接线
- `connection_line.png` - 普通连接线
- `connection_line_highlighted.png` - 高亮连接线
(当前用灰色/蓝色条形代替)

### 7. 信息面板
- `reward_info_bg.png` - 奖励信息面板背景
- `reward_type_bg.png` - 奖励类型标签背景
(当前用圆角矩形代替)

### 8. 底部面板
- `bottom_panel_bg.png` - 底部面板背景
(当前用灰色半透明背景代替)

### 9. 签到按钮
- `sign_in_button.png` - 签到按钮
(当前用蓝色圆角矩形代替)

## 替换步骤

1. 从 Figma 下载所有上述图片资源
2. 将图片文件放到 `/Users/lazyg/Documents/goblinhero/Assets/DailySignIn/` 目录
3. 确保文件名与代码中引用的名称完全一致
4. 在 Xcode 中添加图片到 Assets.xcassets
5. 重新编译运行应用

## 页面尺寸

根据您提供的 UIView 代码，页面设计尺寸为：
- 宽度: 1202px
- 高度: 2622px
- 背景: 白色

代码已适配屏幕尺寸，会根据设备屏幕进行缩放适配。
