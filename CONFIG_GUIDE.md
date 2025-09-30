# ⚙️ 游戏配置指南

## 📁 配置文件位置

```
A004/
├── Config/
│   └── GameConfig.json    # 主配置文件
├── Models/
│   └── GameConfig.swift   # 配置管理器
└── Views/
    └── DifficultySelectionView.swift  # 难度选择界面
```

## 🎮 配置文件结构

### GameConfig.json 主要配置项

```json
{
  "rentSettings": {
    "mode": "custom",                    // 配置模式
    "initialRent": 50,                  // 初始房租
    "incrementMultiplier": 1.5,         // 递增倍率
    "customRentSequence": [...],        // 自定义房租序列
    "difficultyPresets": {              // 难度预设
      "easy": { ... },
      "normal": { ... },
      "hard": { ... },
      "extreme": { ... }
    }
  },
  "gameSettings": {
    "initialCoins": 10,                 // 初始金币
    "spinsPerRound": 10,               // 每回合旋转次数
    "slotCount": 20,                    // 老虎机格子数
    "symbolChoiceCount": 3,             // 每次可选符号数量
    "startingSymbolCount": 3            // 初始符号池大小
  },
  "symbolSettings": {
    "displayMultiplier": {              // 符号显示数量映射
      "3": 3, "6": 6, "10": 10, "15": 15, "20": 20
    },
    "rarityWeights": {                  // 稀有度权重
      "common": 0.5, "rare": 0.3, "epic": 0.15, "legendary": 0.05
    }
  },
  "uiSettings": {
    "animationDuration": 1.0,           // 动画时长
    "spinDelay": 0.1,                   // 旋转延迟
    "resultDisplayTime": 1.5            // 结果展示时间
  }
}
```

## 🏠 房租配置详解

### 1. 基础房租设置

```json
"rentSettings": {
  "initialRent": 50,           // 初始房租
  "incrementMultiplier": 1.5   // 递增倍率（1.5 = 50%递增）
}
```

### 2. 自定义房租序列

```json
"customRentSequence": [
  50, 75, 112, 168, 252, 378, 567, 850, 1275, 1912,
  2868, 4302, 6453, 9679, 14518, 21777, 32665, 48997, 73495, 110242
]
```

**说明**：
- 数组中的每个数字对应一个回合的房租
- 如果回合数超出数组长度，会按 `incrementMultiplier` 继续计算
- 例如：第21回合 = 110242 × 1.5 = 165363

### 3. 难度预设

#### 简单难度 (Easy)
```json
"easy": {
  "initialRent": 30,
  "incrementMultiplier": 1.2,
  "customRentSequence": [30, 36, 43, 52, 62, 74, 89, 107, 128, 154]
}
```

#### 普通难度 (Normal)
```json
"normal": {
  "initialRent": 50,
  "incrementMultiplier": 1.5,
  "customRentSequence": [50, 75, 112, 168, 252, 378, 567, 850, 1275, 1912]
}
```

#### 困难难度 (Hard)
```json
"hard": {
  "initialRent": 100,
  "incrementMultiplier": 1.8,
  "customRentSequence": [100, 180, 324, 583, 1050, 1890, 3402, 6124, 11023, 19841]
}
```

#### 极限难度 (Extreme)
```json
"extreme": {
  "initialRent": 200,
  "incrementMultiplier": 2.0,
  "customRentSequence": [200, 400, 800, 1600, 3200, 6400, 12800, 25600, 51200, 102400]
}
```

## 🎯 游戏设置配置

### 基础游戏参数

```json
"gameSettings": {
  "initialCoins": 10,          // 初始金币数量
  "spinsPerRound": 10,         // 每回合旋转次数
  "slotCount": 20,             // 老虎机格子总数
  "symbolChoiceCount": 3,      // 每次可选符号数量
  "startingSymbolCount": 3     // 初始符号池大小
}
```

### 符号显示配置

```json
"symbolSettings": {
  "displayMultiplier": {
    "3": 3,      // 3个符号池 → 显示3个符号
    "6": 6,      // 6个符号池 → 显示6个符号
    "10": 10,    // 10个符号池 → 显示10个符号
    "15": 15,    // 15个符号池 → 显示15个符号
    "20": 20     // 20个符号池 → 显示20个符号
  }
}
```

### 稀有度权重

```json
"rarityWeights": {
  "common": 0.5,      // 普通符号 50%
  "rare": 0.3,        // 稀有符号 30%
  "epic": 0.15,       // 史诗符号 15%
  "legendary": 0.05   // 传说符号 5%
}
```

## 🎨 UI设置配置

```json
"uiSettings": {
  "animationDuration": 1.0,     // 旋转动画时长（秒）
  "spinDelay": 0.1,            // 每次旋转间隔（秒）
  "resultDisplayTime": 1.5     // 结果展示时间（秒）
}
```

## 🔧 如何修改配置

### 方法1: 直接编辑JSON文件

1. 打开 `A004/Config/GameConfig.json`
2. 修改对应的数值
3. 重新运行游戏

### 方法2: 通过代码修改

```swift
// 在 GameConfigManager 中添加方法
func updateRentSequence(_ sequence: [Int]) {
    // 更新房租序列
}

func updateDifficulty(_ difficulty: String, settings: DifficultyPreset) {
    // 更新难度设置
}
```

### 方法3: 运行时切换难度

```swift
// 在游戏中切换难度
GameConfigManager.shared.setDifficulty("easy")
```

## 📊 配置示例

### 超简单模式
```json
{
  "initialRent": 20,
  "incrementMultiplier": 1.1,
  "customRentSequence": [20, 22, 24, 26, 28, 30, 33, 36, 39, 42]
}
```

### 挑战模式
```json
{
  "initialRent": 200,
  "incrementMultiplier": 2.5,
  "customRentSequence": [200, 500, 1250, 3125, 7812, 19531, 48828, 122070, 305175, 762939]
}
```

### 平衡模式
```json
{
  "initialRent": 40,
  "incrementMultiplier": 1.3,
  "customRentSequence": [40, 52, 68, 88, 114, 148, 192, 250, 325, 422]
}
```

## 🎮 使用配置系统

### 在代码中使用

```swift
// 获取当前房租
let rentAmount = GameConfigManager.shared.getRentAmount(for: currentRound)

// 获取符号显示数量
let displayCount = GameConfigManager.shared.getSymbolDisplayCount(for: symbolPool.count)

// 切换难度
GameConfigManager.shared.setDifficulty("hard")

// 获取游戏设置
let gameSettings = GameConfigManager.shared.getGameSettings()
```

### 在UI中使用

```swift
// 难度选择界面
DifficultySelectionView(isPresented: $showDifficultySelection) { difficulty in
    // 难度选择回调
    GameConfigManager.shared.setDifficulty(difficulty)
}
```

## 🚀 高级配置技巧

### 1. 创建自定义难度

```json
"customDifficulty": {
  "initialRent": 60,
  "incrementMultiplier": 1.4,
  "customRentSequence": [60, 84, 118, 165, 231, 323, 452, 633, 886, 1240]
}
```

### 2. 动态房租计算

```swift
// 在 GameConfigManager 中添加
func calculateDynamicRent(for round: Int) -> Int {
    let baseRent = 50
    let growthRate = 1.2
    return Int(Double(baseRent) * pow(growthRate, Double(round - 1)))
}
```

### 3. 条件房租

```json
"conditionalRent": {
  "round1to5": [50, 75, 100, 125, 150],
  "round6to10": [200, 300, 450, 675, 1012],
  "round11plus": "exponential"
}
```

## 📝 配置验证

### 检查配置有效性

```swift
func validateConfig() -> Bool {
    // 检查房租序列是否递增
    // 检查数值是否合理
    // 检查配置完整性
    return true
}
```

### 配置备份

```swift
func backupConfig() {
    // 备份当前配置
    // 保存到用户偏好设置
}
```

## 🎯 最佳实践

1. **渐进式难度**：确保房租递增不会过于陡峭
2. **平衡性测试**：在不同难度下测试游戏体验
3. **用户友好**：提供清晰的难度说明
4. **可扩展性**：预留配置扩展空间
5. **性能考虑**：避免过于复杂的计算

## 🔍 故障排除

### 常见问题

1. **配置文件加载失败**
   - 检查JSON格式是否正确
   - 确保文件路径正确

2. **房租计算错误**
   - 检查数值类型
   - 验证计算公式

3. **难度切换不生效**
   - 确保调用了正确的方法
   - 检查配置更新逻辑

### 调试技巧

```swift
// 添加调试日志
print("🏠 [配置] 当前难度: \(currentDifficulty)")
print("🏠 [配置] 回合 \(round) 房租: \(rentAmount)")
```

---

**配置系统让你可以轻松调整游戏平衡性，创造不同的游戏体验！** 🎮✨
