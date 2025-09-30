# 🎯 符号配置系统指南

## 📁 配置文件结构

```
A004/
├── Config/
│   ├── GameConfig.json        # 游戏主配置
│   └── SymbolConfig.json      # 符号配置文件 ⭐️ 新增
├── Models/
│   ├── SymbolConfigManager.swift  # 符号配置管理器 ⭐️ 新增
│   └── SymbolLibrary.swift        # 符号库（已更新）
└── Views/
    └── SymbolConfigView.swift     # 符号配置界面 ⭐️ 新增
```

## 🎮 符号配置系统特性

### ✨ 主要功能
- **JSON配置** - 所有符号通过JSON文件配置
- **分类管理** - 6大符号分类（水果、金币、动物、特殊、宝石、魔法）
- **稀有度系统** - 4级稀有度（普通、稀有、史诗、传说）
- **解锁机制** - 基于等级的符号解锁系统
- **效果系统** - 支持多种符号特殊效果
- **可视化界面** - 符号配置管理界面

### 🎯 符号分类

| 分类 | 英文ID | 颜色 | 图标 | 描述 |
|------|--------|------|------|------|
| 水果类 | fruit | #4CAF50 | 🍎 | 基础收益符号 |
| 金币类 | coin | #FFD700 | 💰 | 直接金币收益 |
| 动物类 | animal | #8BC34A | 🐝 | 特殊效果生物 |
| 特殊类 | special | #9C27B0 | ⭐️ | 稀有强力符号 |
| 宝石类 | gem | #00BCD4 | 💎 | 高价值宝石 |
| 魔法类 | magic | #E91E63 | 🔮 | 魔法效果符号 |

### 🌟 稀有度系统

| 稀有度 | 英文ID | 权重 | 颜色 | 描述 |
|--------|--------|------|------|------|
| 普通 | common | 50% | #9E9E9E | 最常见符号 |
| 稀有 | rare | 30% | #2196F3 | 较为稀有 |
| 史诗 | epic | 15% | #9C27B0 | 非常稀有 |
| 传说 | legendary | 5% | #FF9800 | 极其稀有 |

## 📝 符号配置格式

### 基础符号配置
```json
{
  "id": "apple",
  "name": "苹果",
  "icon": "🍎",
  "category": "fruit",
  "rarity": "common",
  "baseValue": 2,
  "description": "基础水果，提供2金币",
  "effects": [],
  "unlockLevel": 1,
  "isEnabled": true
}
```

### 带效果的符号配置
```json
{
  "id": "bee",
  "name": "蜜蜂",
  "icon": "🐝",
  "category": "animal",
  "rarity": "common",
  "baseValue": 2,
  "description": "蜜蜂，相邻水果额外+1金币",
  "effects": [
    {
      "type": "adjacent_bonus",
      "targetCategory": "fruit",
      "bonusValue": 1,
      "description": "相邻水果符号+1金币"
    }
  ],
  "unlockLevel": 2,
  "isEnabled": true
}
```

## 🔧 符号效果类型

### 1. 相邻加成 (adjacent_bonus)
```json
{
  "type": "adjacent_bonus",
  "targetCategory": "fruit",
  "bonusValue": 1,
  "description": "相邻水果符号+1金币"
}
```

### 2. 倍率加成 (multiplier)
```json
{
  "type": "multiplier",
  "targetCategory": "all",
  "multiplier": 1.2,
  "description": "所有符号收益+20%"
}
```

### 3. 彩虹奖励 (rainbow_bonus)
```json
{
  "type": "rainbow_bonus",
  "description": "集齐7种不同颜色符号时额外+50金币"
}
```

### 4. 龙息 (dragon_breath)
```json
{
  "type": "dragon_breath",
  "description": "清除所有空格子，用随机符号填充"
}
```

### 5. 重生 (rebirth)
```json
{
  "type": "rebirth",
  "description": "游戏失败时有一次重生机会"
}
```

## 🎮 使用方法

### 1. 添加新符号

在 `SymbolConfig.json` 的 `symbols` 数组中添加：

```json
{
  "id": "new_symbol",
  "name": "新符号",
  "icon": "🆕",
  "category": "special",
  "rarity": "epic",
  "baseValue": 8,
  "description": "全新的符号",
  "effects": [],
  "unlockLevel": 5,
  "isEnabled": true
}
```

### 2. 修改符号属性

直接编辑JSON文件中的对应字段：
- `baseValue` - 修改基础收益
- `rarity` - 修改稀有度
- `unlockLevel` - 修改解锁等级
- `isEnabled` - 启用/禁用符号

### 3. 添加新分类

在 `symbolCategories` 中添加：

```json
"new_category": {
  "name": "新分类",
  "description": "新分类的描述",
  "color": "#FF5722",
  "icon": "🆕"
}
```

### 4. 调整稀有度权重

在 `raritySettings` 中修改：

```json
"common": {
  "name": "普通",
  "weight": 0.6,  // 修改权重
  "color": "#9E9E9E",
  "description": "最常见的符号类型"
}
```

## 🎯 解锁系统

### 解锁等级要求
- **等级1** - 游戏开始（基础符号）
- **等级2** - 通过第2回合
- **等级3** - 通过第5回合
- **等级4** - 通过第8回合
- **等级5** - 通过第12回合
- **等级6** - 通过第15回合
- **等级7** - 通过第18回合
- **等级8** - 通过第20回合
- **等级9** - 通过第25回合
- **等级10** - 通过第30回合
- **等级12** - 通过第40回合
- **等级15** - 通过第50回合

### 代码中设置解锁等级
```swift
// 设置解锁等级
SymbolLibrary.setUnlockLevel(5)

// 获取当前解锁等级
let currentLevel = SymbolLibrary.getCurrentUnlockLevel()

// 获取已解锁的符号
let unlockedSymbols = SymbolConfigManager.shared.getUnlockedSymbols()
```

## 🎨 可视化配置界面

### 符号配置界面功能
- **分类筛选** - 按符号分类查看
- **稀有度筛选** - 按稀有度查看
- **解锁等级显示** - 显示符号解锁要求
- **状态指示** - 显示符号启用状态
- **解锁设置** - 调整解锁等级

### 访问配置界面
```swift
// 在游戏界面中添加配置按钮
NavigationLink("符号配置") {
    SymbolConfigView()
}
```

## 📊 配置验证

### 自动验证规则
- 每个分类符号数量不超过限制
- 每个稀有度符号数量不超过限制
- 符号基础收益在合理范围内
- 解锁等级在有效范围内

### 手动验证
```swift
// 验证配置
let isValid = SymbolConfigManager.shared.validateConfig()

// 打印配置摘要
SymbolLibrary.printConfigSummary()
```

## 🔄 配置更新流程

### 1. 修改JSON文件
编辑 `SymbolConfig.json` 文件

### 2. 重新加载配置
```swift
// 重新加载配置
SymbolConfigManager.shared.config = SymbolConfigManager.loadDefaultConfig()
```

### 3. 验证配置
```swift
// 验证新配置
if SymbolConfigManager.shared.validateConfig() {
    print("✅ 配置验证通过")
} else {
    print("❌ 配置验证失败")
}
```

## 🎯 最佳实践

### 1. 符号平衡
- 普通符号：基础收益 1-4 金币
- 稀有符号：基础收益 3-6 金币
- 史诗符号：基础收益 5-10 金币
- 传说符号：基础收益 10-25 金币

### 2. 解锁节奏
- 初期（1-3级）：基础符号
- 中期（4-8级）：特殊效果符号
- 后期（9+级）：强力传说符号

### 3. 效果设计
- 相邻加成：适合动物类符号
- 倍率加成：适合魔法类符号
- 特殊能力：适合传说符号

### 4. 分类特色
- **水果类** - 稳定收益，协同效果
- **金币类** - 直接收益，无特殊效果
- **动物类** - 相邻加成效果
- **特殊类** - 独特能力
- **宝石类** - 高价值收益
- **魔法类** - 全局效果

## 🚀 高级功能

### 1. 动态符号生成
```swift
// 根据配置生成随机符号
let randomSymbols = SymbolLibrary.getRandomSymbols(count: 3)
```

### 2. 符号效果处理
```swift
// 处理符号效果
let configSymbol = SymbolConfigManager.shared.getSymbol(by: "bee")
let finalValue = SymbolConfigManager.shared.processSymbolEffects(
    configSymbol!, 
    adjacentSymbols: adjacentSymbols
)
```

### 3. 配置热更新
```swift
// 运行时更新配置
SymbolConfigManager.shared.config = newConfig
```

## 📝 配置示例

### 完整符号配置示例
```json
{
  "symbols": [
    {
      "id": "dragon",
      "name": "龙",
      "icon": "🐉",
      "category": "magic",
      "rarity": "legendary",
      "baseValue": 15,
      "description": "传说中的龙，提供15金币",
      "effects": [
        {
          "type": "dragon_breath",
          "description": "清除所有空格子，用随机符号填充"
        }
      ],
      "unlockLevel": 12,
      "isEnabled": false
    }
  ]
}
```

---

**通过这个配置系统，你可以完全控制游戏中的所有符号！** 🎮✨
