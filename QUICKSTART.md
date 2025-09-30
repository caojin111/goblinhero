# 🚀 快速开始指南

## 📋 项目结构

```
A004/
├── A004/
│   ├── Models/
│   │   ├── GameModels.swift      # 核心数据模型（Symbol, Item, GamePhase等）
│   │   └── SymbolLibrary.swift   # 符号库（15种初始符号）
│   │
│   ├── ViewModels/
│   │   └── GameViewModel.swift   # 游戏逻辑控制器（MVVM模式）
│   │
│   ├── Views/
│   │   └── GameView.swift        # 主游戏界面（UI组件）
│   │
│   ├── A004App.swift             # 应用入口
│   └── ContentView.swift         # 根视图
│
├── README.md                     # 项目说明
├── GAME_DESIGN.md               # 游戏设计文档
└── QUICKSTART.md                # 本文件
```

## 🎮 如何运行

### 方法1: 使用Xcode（推荐）
1. 打开 `A004.xcodeproj`
2. 选择模拟器（建议: iPhone 15）
3. 点击运行 `⌘ + R`

### 方法2: 命令行构建
```bash
cd /Users/apple/Documents/A004
xcodebuild -scheme A004 -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## 🎯 游戏玩法速览

### 基础流程
```
1. 游戏开始，玩家先选择第一个符号（3选1）
2. 选择完成后，玩家拥有4个符号开始第一回合
3. 进行10次旋转，每次旋转显示符号（基于符号池种类数量）
4. 10次旋转后需支付房租
5. 支付成功后选择1个新符号加入符号池
6. 进入下一回合，房租增加50%
7. 重复上述流程，挑战更高回合
```

### ⭐️ 重要机制更新
- **符号池大小决定显示数量**：符号池有多少种符号，棋盘就显示多少个符号
- **初期挑战**：3个符号池 → 只显示3个符号，17个空格子
- **渐进增长**：符号池越大，显示的符号越多
- **权重分配**：相同符号在池中数量越多，出现概率越高

### 操作说明
- **无需手动旋转** - 游戏自动执行旋转
- **符号选择** - 点击选择你想要的符号
- **重新开始** - 游戏结束后点击"再来一次"

## 📊 核心数据

### 初始状态
```swift
金币: 10
房租: 50
回合: 1
旋转次数: 10
符号池: [随机3个已解锁符号] (随机选择)
游戏开始: 先选择1个符号 → 拥有4个符号开始第一回合
```

### 符号类型
| 类型 | 图标示例 | 数量 | 收益范围 |
|------|----------|------|----------|
| 水果 | 🍎🍌🍊 | 5种 | 2-4 |
| 金币 | 🪙💰💎 | 4种 | 1-8 |
| 动物 | 🐝🐰🐱 | 3种 | 2-4 |
| 特殊 | 🍀⭐️💎 | 3种 | 5-10 |

## 🔧 代码要点

### 1. 游戏状态管理
```swift
// GameViewModel.swift
class GameViewModel: ObservableObject {
    @Published var currentCoins: Int
    @Published var currentRound: Int
    @Published var gamePhase: GamePhase
}
```

### 2. 符号定义
```swift
// GameModels.swift
struct Symbol {
    let name: String
    let icon: String        // Emoji
    let baseValue: Int      // 基础收益
    let rarity: SymbolRarity
    let type: SymbolType
}
```

### 3. 核心方法
```swift
// 旋转老虎机
func spin()

// 计算收益
func calculateEarnings()

// 检查房租支付
func checkRentPayment()

// 选择符号
func selectSymbol(_ symbol: Symbol)
```

## 📱 UI组件说明

### GameView（主界面）
```swift
├── TopInfoBar          # 顶部信息（金币、回合、房租）
├── SlotMachineView     # 老虎机主体（5×4格子）
├── ControlPanel        # 控制面板（符号池展示）
├── SymbolSelectionView # 符号选择弹窗
└── GameOverView        # 游戏结束弹窗
```

### 关键View组件
- **SlotCellView** - 单个老虎机格子
- **SymbolBadgeView** - 符号徽章（用于符号池展示）
- **TopInfoBar** - 顶部信息栏
- **GameOverView** - 游戏结束界面

## 🎨 UI特性

### 动画效果
```swift
// 旋转动画
.rotationEffect(.degrees(isSpinning ? rotation : 0))

// 过渡动画
.transition(.scale)
.animation(.spring(), value: showSymbolSelection)
```

### 颜色系统
- **背景**: 蓝紫渐变
- **普通符号**: 灰色边框
- **稀有符号**: 蓝色边框
- **史诗符号**: 紫色边框
- **传说符号**: 橙色边框

## 🐛 调试技巧

### 打印日志
游戏已内置详细日志，在Xcode Console中可以看到：

```
🎮 [游戏初始化] 开始初始化游戏
🎰 [旋转] 开始旋转 - 回合 1, 剩余次数 10
💰 [收益] 本轮获得: 45 金币
🏠 [房租] 需要支付房租: 50 金币
✅ [选择符号] 玩家选择了: 西瓜
```

### 常见问题

**Q: 游戏一直在旋转？**  
A: 这是正常的，每回合会自动执行10次旋转

**Q: 如何手动旋转？**  
A: 当前版本是自动旋转，无需手动操作

**Q: 符号池太少怎么办？**  
A: 每回合支付房租后可以选择1个新符号

**Q: 如何增加成功率？**  
A: 选择高收益符号，注意符号类型搭配（协同效果）

## 🔍 代码修改指南

### 修改初始金币
```swift
// GameViewModel.swift
func startNewGame() {
    currentCoins = 10  // 改为你想要的数值
}
```

### 修改房租递增
```swift
// GameViewModel.swift - checkRentPayment()
rentAmount = Int(Double(rentAmount) * 1.5)  // 改为其他倍率
```

### 添加新符号
```swift
// SymbolLibrary.swift
Symbol(
    name: "新符号",
    icon: "🎁",
    baseValue: 5,
    rarity: .rare,
    type: .special,
    description: "描述文字"
)
```

### 修改老虎机格子数
```swift
// GameViewModel.swift
private let slotCount = 20  // 改为其他数值（建议保持5的倍数）
```

## 📈 数值调试建议

### 简单难度
```swift
currentCoins = 20        // 初始金币增加
rentAmount = 30          // 初始房租降低
递增倍率 = 1.3           // 房租递增减缓
```

### 困难难度
```swift
currentCoins = 5         // 初始金币减少
rentAmount = 80          // 初始房租提高
递增倍率 = 1.8           // 房租递增加快
```

## 🎯 测试建议

### 功能测试清单
- [ ] 游戏启动正常
- [ ] 老虎机正常旋转
- [ ] 收益计算正确
- [ ] 房租支付逻辑正确
- [ ] 符号选择界面正常
- [ ] 游戏结束提示正常
- [ ] 重新开始功能正常

### 体验测试
- [ ] 动画流畅不卡顿
- [ ] 信息显示清晰
- [ ] 符号识别度高
- [ ] 游戏节奏合理
- [ ] 难度曲线平滑

## 📚 学习资源

### SwiftUI相关
- [Apple SwiftUI 官方文档](https://developer.apple.com/documentation/swiftui)
- [SwiftUI by Example](https://www.hackingwithswift.com/quick-start/swiftui)

### 游戏设计相关
- MVVM架构模式
- 状态管理 (@Published)
- 组合式UI设计

## 🚀 下一步

完成基础体验后，可以尝试：

1. **添加音效** - AVFoundation
2. **增强动画** - 自定义Transition
3. **新增符号** - SymbolLibrary扩展
4. **道具系统** - Item功能实现
5. **数据统计** - 存档和历史记录

## 💡 开发技巧

### 快速测试某个符号
```swift
// 临时修改startingSymbols
static let startingSymbols: [Symbol] = [
    // 添加你想测试的符号
    Symbol(name: "钻石", icon: "💎", baseValue: 10, ...)
]
```

### 跳过前几回合
```swift
// startNewGame()中
currentRound = 5  // 直接从回合5开始
rentAmount = 632  // 对应回合5的房租
```

### 查看所有符号
```swift
// 在GameView中添加调试按钮
Button("显示所有符号") {
    print(SymbolLibrary.allSymbols)
}
```

---

**祝开发愉快！** 🎮✨

有问题随时查看 `GAME_DESIGN.md` 或 `README.md`
