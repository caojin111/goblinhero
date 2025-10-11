# 符号配置完整指南

## 📋 配置文件位置

`A004/Config/SymbolConfig.json`

## 🎯 配置文件结构

```json
{
  "symbols": [
    {
      "id": 1,
      "name": "儿童",
      "icon": "👶",
      "rarity": "normal",
      "types": ["human"],
      "baseValue": 2,
      "weight": 1000,
      "effect": "如果已拥有玩具鸭，则金币+2",
      "effectType": "conditional_bonus",
      "effectParams": {
        "requireSymbol": "玩具鸭",
        "bonus": 2
      }
    }
  ],
  "config": {
    "enableEffects": true,
    "totalWeight": 20000,
    "rarityWeightMultipliers": {
      "normal": 1.0,
      "rare": 0.8,
      "epic": 0.5
    },
    "startingSymbolCount": 3,
    "symbolPoolMaxSize": 100
  }
}
```

## 📝 字段详解

### 符号配置 (symbols)

| 字段 | 类型 | 说明 | 示例 |
|-----|------|------|------|
| `id` | Int | 符号唯一标识符 | `1` |
| `name` | String | 符号名称 | `"儿童"` |
| `icon` | String | 显示图标（emoji） | `"👶"` |
| `rarity` | String | 稀有度 | `"normal"`, `"rare"`, `"epic"`, `"legendary"` |
| `types` | [String] | 类型标签（可多个） | `["human"]`, `["material", "tool"]` |
| `baseValue` | Int | 基础金币值 | `2`, `5`, `10` |
| `weight` | Int | 随机权重（越大越容易出现） | `1000`, `800`, `500` |
| `effect` | String | 效果描述（显示给玩家） | `"如果已拥有玩具鸭，则金币+2"` |
| `effectType` | String | 效果类型（程序识别） | 见下方效果类型表 |
| `effectParams` | Object | 效果参数 | 根据effectType不同而变化 |

### 系统配置 (config)

| 字段 | 类型 | 说明 | 默认值 |
|-----|------|------|-------|
| `enableEffects` | Bool | 是否启用符号效果 | `true` |
| `totalWeight` | Int | 总权重（用于计算） | `20000` |
| `rarityWeightMultipliers` | Object | 稀有度权重倍率 | 见配置 |
| `startingSymbolCount` | Int | 初始符号数量 | `3` |
| `symbolPoolMaxSize` | Int | 符号池最大容量 | `100` |

## 🎮 符号类型 (types)

### 基础类型

| 类型标签 | 说明 | 示例符号 |
|---------|------|---------|
| `human` | 人类 | 儿童、商人、士兵 |
| `material` | 材料 | 玩具鸭、酒瓶、手提箱 |
| `box` | 箱子 | 铁箱子、银箱子 |
| `tool` | 工具 | 锄头、号角、钥匙 |
| `monster` | 怪物 | 花精、狼人、丧尸 |
| `alien` | 外星 | 光线枪、外星头盔、宇宙飞船 |
| `dice` | 骰子 | 骰子一枚 |

**注意：** 一个符号可以有多个类型标签，例如：`["material", "tool"]`

## ⚡ 效果类型 (effectType)

### 1. `none` - 无效果
最简单的类型，符号只提供基础金币。

```json
{
  "effectType": "none",
  "effectParams": {}
}
```

### 2. `conditional_bonus` - 条件奖励
满足条件时额外获得金币。

```json
{
  "effectType": "conditional_bonus",
  "effectParams": {
    "requireSymbol": "玩具鸭",  // 需要拥有的符号
    "bonus": 2                  // 额外金币
  }
}
```
**示例：** 儿童（ID:1）

### 3. `count_bonus` - 计数奖励
根据拥有的特定类型符号数量给予奖励。

```json
{
  "effectType": "count_bonus",
  "effectParams": {
    "countType": "human",     // 计数的类型
    "bonusPerCount": 1        // 每个额外金币
  }
}
```
**示例：** 商人（ID:2）

### 4. `mixed_count_bonus` - 混合计数奖励
根据多种类型符号给予不同奖励。

```json
{
  "effectType": "mixed_count_bonus",
  "effectParams": {
    "bonuses": [
      {"countType": "alien", "bonusPerCount": -1},
      {"countType": "monster", "bonusPerCount": 2}
    ]
  }
}
```
**示例：** 野蛮人（ID:3）

### 5. `eliminate_bonus` - 消除奖励
消除特定类型符号并获得奖励。

```json
{
  "effectType": "eliminate_bonus",
  "effectParams": {
    "eliminateType": "monster",  // 消除的类型
    "bonus": 50                   // 获得金币
  }
}
```
**示例：** 士兵（ID:5）

### 6. `conditional_eliminate` - 条件消除
遇到特定符号时被消除并获得奖励。

```json
{
  "effectType": "conditional_eliminate",
  "effectParams": {
    "triggerSymbol": "商人",  // 触发符号
    "bonus": 20                // 获得金币
  }
}
```
**示例：** 手提箱（ID:8）

### 7. `random_spawn` - 随机生成
概率性生成其他符号。

```json
{
  "effectType": "random_spawn",
  "effectParams": {
    "options": [
      {"symbol": "花精", "probability": 0.5},
      {"symbol": "丧尸", "probability": 0.5}
    ]
  }
}
```
**示例：** 锄头（ID:9）

### 8. `spawn_multiple` - 批量生成
生成多个指定符号。

```json
{
  "effectType": "spawn_multiple",
  "effectParams": {
    "symbol": "士兵",  // 生成的符号
    "count": 5         // 生成数量
  }
}
```
**示例：** 号角（ID:10）

### 9. `unlock_bonus` - 解锁奖励
消除特定符号并获得奖励。

```json
{
  "effectType": "unlock_bonus",
  "effectParams": {
    "unlockSymbol": "铁箱子",  // 解锁的符号
    "bonus": 10                 // 获得金币
  }
}
```
**示例：** 铁钥匙（ID:13）

### 10. `universal_unlock` - 万能解锁
可以解锁任意类型的箱子。

```json
{
  "effectType": "universal_unlock",
  "effectParams": {
    "unlockTypes": ["box"],  // 可解锁的类型
    "bonusMultiplier": 1     // 奖励倍率
  }
}
```
**示例：** 万能钥匙（ID:15）

### 11. `infect_and_bonus` - 感染与奖励
感染其他符号并根据感染数量获得奖励。

```json
{
  "effectType": "infect_and_bonus",
  "effectParams": {
    "infectType": "human",      // 感染的类型
    "countType": "丧尸",         // 计数的符号
    "bonusPerCount": 5          // 每个额外金币
  }
}
```
**示例：** 丧尸（ID:18）

### 12. `diminishing_value` - 递减价值
每次被挖出价值递减。

```json
{
  "effectType": "diminishing_value",
  "effectParams": {
    "initialValue": 6,  // 初始价值
    "decrement": 1,     // 每次递减
    "minValue": 0       // 最小价值
  }
}
```
**示例：** 独眼怪物（ID:19）

### 13. `random_eliminate_bonus` - 随机消除奖励
随机消除一个符号并获得奖励。

```json
{
  "effectType": "random_eliminate_bonus",
  "effectParams": {
    "excludeSelf": true,  // 排除自身
    "bonus": 30           // 获得金币
  }
}
```
**示例：** 哥莫拉（ID:20）

### 14. `combo_bonus` - 组合奖励
与特定符号组合时获得奖励。

```json
{
  "effectType": "combo_bonus",
  "effectParams": {
    "comboSymbols": ["外星头盔", "宇宙飞船"],  // 组合符号
    "bonus": 40,                               // 奖励金币
    "onceOnly": true                           // 只计算一次
  }
}
```
**示例：** 光线枪（ID:21）

### 15. `spawn_random` - 随机生成符号
生成随机符号。

```json
{
  "effectType": "spawn_random",
  "effectParams": {
    "count": 3  // 生成数量
  }
}
```
**示例：** 精神控制器（ID:24）

### 16. `dice_bonus` - 骰子奖励
增加骰子点数。

```json
{
  "effectType": "dice_bonus",
  "effectParams": {
    "diceBonus": 1  // 增加点数
  }
}
```
**示例：** 骰子一枚（ID:26）

### 17. `spawn_random_multiple` - 随机数量生成
生成随机数量的符号。

```json
{
  "effectType": "spawn_random_multiple",
  "effectParams": {
    "minCount": 2,  // 最少数量
    "maxCount": 5   // 最多数量
  }
}
```
**示例：** 魔法袋（ID:27）

## 🎨 稀有度配置

### 稀有度等级

| 等级 | 配置值 | 颜色 | 推荐权重 | 推荐金币值 |
|-----|--------|------|----------|-----------|
| 普通 | `"normal"` | 灰色 | 1000 | 2-3 |
| 稀有 | `"rare"` | 蓝色 | 800 | 3-4 |
| 史诗 | `"epic"` | 紫色 | 500 | 5-6 |
| 传说 | `"legendary"` | 橙色 | 200 | 10+ |

## ⚖️ 权重系统

### 权重计算公式

```
出现概率 = 符号权重 / 总权重
```

### 权重示例

```json
{
  "name": "儿童",
  "weight": 1000,    // 10% 概率 (1000/10000)
  "rarity": "normal"
}
```

```json
{
  "name": "士兵",
  "weight": 500,     // 5% 概率 (500/10000)
  "rarity": "epic"
}
```

### 权重建议

- **普通符号**: 800-1000
- **稀有符号**: 600-800
- **史诗符号**: 400-600
- **传说符号**: 100-300
- **特殊符号**（如魔法袋）: 0（不随机出现）

## 🛠️ 修改配置

### 1. 修改现有符号

只需修改JSON中对应字段即可。

**示例：提高儿童的奖励**
```json
{
  "id": 1,
  "name": "儿童",
  "baseValue": 3,  // 从2改为3
  "effectParams": {
    "bonus": 5      // 从2改为5
  }
}
```

### 2. 添加新符号

在 `symbols` 数组中添加新对象：

```json
{
  "id": 28,
  "name": "新符号",
  "icon": "🎯",
  "rarity": "rare",
  "types": ["special"],
  "baseValue": 4,
  "weight": 700,
  "effect": "描述效果",
  "effectType": "none",
  "effectParams": {}
}
```

### 3. 禁用符号

将权重设为 0：

```json
{
  "id": 27,
  "weight": 0  // 不会随机出现
}
```

### 4. 调整游戏难度

**简单模式：**
```json
{
  "config": {
    "startingSymbolCount": 5,  // 更多初始符号
    "rarityWeightMultipliers": {
      "normal": 1.5,
      "rare": 1.2,
      "epic": 1.0
    }
  }
}
```

**困难模式：**
```json
{
  "config": {
    "startingSymbolCount": 2,  // 更少初始符号
    "rarityWeightMultipliers": {
      "normal": 0.8,
      "rare": 0.6,
      "epic": 0.4
    }
  }
}
```

## 📊 完整符号列表

| ID | 名称 | 稀有度 | 类型 | 金币 | 权重 | 效果简述 |
|----|------|--------|------|------|------|---------|
| 1 | 儿童 | normal | human | 2 | 1000 | 有玩具鸭+2 |
| 2 | 商人 | normal | human | 2 | 1000 | 每人类+1 |
| 3 | 野蛮人 | rare | human | 3 | 800 | 外星-1，怪物+2 |
| 4 | 农民 | rare | human | 3 | 800 | 每工具+2 |
| 5 | 士兵 | epic | human | 5 | 500 | 消除怪物+50 |
| 6 | 玩具鸭 | normal | material | 2 | 1000 | 无 |
| 7 | 酒瓶 | normal | material | 2 | 1000 | 无 |
| 8 | 手提箱 | rare | material | 3 | 800 | 遇商人+20 |
| 9 | 锄头 | rare | material, tool | 3 | 800 | 50%花精/丧尸 |
| 10 | 号角 | epic | material, tool | 5 | 500 | +5士兵 |
| 11 | 铁箱子 | normal | box | 2 | 1000 | 无 |
| 12 | 银箱子 | rare | box | 3 | 800 | 无 |
| 13 | 铁钥匙 | normal | box, tool | 2 | 1000 | 开铁箱+10 |
| 14 | 银钥匙 | rare | box, tool | 3 | 800 | 开银箱+20 |
| 15 | 万能钥匙 | epic | box, tool | 5 | 500 | 开任意箱 |
| 16 | 花精 | normal | monster | 2 | 1000 | 无 |
| 17 | 狼人 | normal | monster | 2 | 1000 | 无 |
| 18 | 丧尸 | rare | monster | 3 | 800 | 感染+每个+5 |
| 19 | 独眼怪物 | rare | monster | 6 | 800 | 递减价值 |
| 20 | 哥莫拉 | epic | monster | 5 | 500 | 随机消除+30 |
| 21 | 光线枪 | normal | alien, tool | 2 | 1000 | 三件套+40 |
| 22 | 外星头盔 | normal | alien | 2 | 1000 | 三件套+40 |
| 23 | 宇宙飞船 | rare | alien | 3 | 800 | 三件套+40 |
| 24 | 精神控制器 | rare | alien, tool | 3 | 800 | +3随机符号 |
| 25 | 陨石 | epic | alien | 5 | 500 | 消除哥莫拉+30 |
| 26 | 骰子一枚 | epic | dice, tool | 5 | 500 | 骰子+1 |
| 27 | 魔法袋 | epic | material | 5 | 0 | 2-5随机符号 |

## 🐛 故障排查

### 常见错误

**1. JSON格式错误**
```
❌ [符号配置] 解析配置文件失败
```
→ 使用JSON验证器检查语法

**2. 找不到配置文件**
```
❌ [符号配置] 找不到配置文件
```
→ 确认文件在 `A004/Config/` 目录

**3. 符号效果不生效**
→ 检查 `enableEffects` 是否为 `true`
→ 确认 `effectType` 拼写正确

## 💡 设计建议

### 1. 平衡性原则
- 高价值符号应该有低权重
- 强力效果应该有限制条件
- 避免过于复杂的效果链

### 2. 类型协同
- 设计互相配合的符号组
- 人类 + 工具
- 箱子 + 钥匙
- 怪物 + 士兵

### 3. 效果多样性
- 直接收益（金币）
- 生成符号
- 消除符号
- 条件触发

### 4. 进阶策略
- 前期：高权重基础符号
- 中期：组合效果符号
- 后期：强力传说符号

## 🔄 热更新

```swift
SymbolConfigManager.shared.reloadConfig()
```

## 📚 相关文档

- [游戏设计文档](GAME_DESIGN.md)
- [哥布林配置指南](GOBLIN_CONFIG_GUIDE.md)
- [快速开始](QUICKSTART.md)

---

**提示：** 修改配置文件后需要重新运行应用才能生效。建议先备份原配置文件！

