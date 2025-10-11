# 哥布林配置指南

## 📋 配置文件位置

配置文件位于：`A004/Config/GoblinConfig.json`

## 🎯 配置文件结构

```json
{
  "goblins": [
    {
      "id": 1,
      "name": "勇者哥布林",
      "icon": "⚔️",
      "isFree": true,
      "buff": "每有一个符号被消除，则+1金币",
      "buffType": "on_symbol_eliminate",
      "buffValue": 1,
      "unlockPrice": 0,
      "description": "勇猛的战士，每次消除符号都能额外获得金币奖励"
    }
  ],
  "config": {
    "defaultUnlockedIds": [1, 2, 3],
    "maxGoblins": 5,
    "enableBuffEffects": true
  }
}
```

## 📝 字段说明

### 哥布林配置 (goblins)

| 字段 | 类型 | 说明 | 示例 |
|-----|------|------|------|
| `id` | Int | 哥布林唯一标识符 | `1` |
| `name` | String | 哥布林名称 | `"勇者哥布林"` |
| `icon` | String | 显示图标（emoji） | `"⚔️"` |
| `isFree` | Bool | 是否免费可用 | `true` / `false` |
| `buff` | String | buff描述（显示给玩家） | `"每有一个符号被消除，则+1金币"` |
| `buffType` | String | buff类型（程序识别） | 见下方buff类型表 |
| `buffValue` | Double | buff数值参数 | `1`, `2.0`, `10` |
| `unlockPrice` | Int | 解锁所需金币 | `0`, `100`, `150` |
| `description` | String | 详细描述 | `"勇猛的战士..."` |

### 系统配置 (config)

| 字段 | 类型 | 说明 | 示例 |
|-----|------|------|------|
| `defaultUnlockedIds` | [Int] | 默认解锁的哥布林ID列表 | `[1, 2, 3]` |
| `maxGoblins` | Int | 最大哥布林数量 | `5` |
| `enableBuffEffects` | Bool | 是否启用buff效果 | `true` / `false` |

## 🎮 Buff类型 (buffType)

### 已实现的Buff类型

| buffType | 说明 | buffValue含义 | 示例 |
|----------|------|--------------|------|
| `on_symbol_eliminate` | 消除符号时触发 | 每个符号额外获得金币数 | 勇者哥布林：每个+1金币 |
| `extra_symbol_choice` | 额外符号选择机会 | 额外选择次数 | 工匠哥布林：+1次选择 |
| `dice_probability_boost` | 骰子概率提升 | 概率倍率 | 赌徒哥布林：2.0倍 |

### 预留的Buff类型（待实现）

| buffType | 说明 | buffValue含义 | 示例 |
|----------|------|--------------|------|
| `soldier_bonus` | 士兵符号加成 | 每个士兵额外金币 | 国王哥布林：每个+10金币 |
| `magic_bag_fill` | 魔法袋填充 | 填充数量 | 巫师哥布林：填充1个 |

## 🛠️ 修改配置

### 1. 修改现有哥布林

修改 `GoblinConfig.json` 中对应哥布林的字段即可。

**示例：将勇者哥布林的buff数值从1改为2**

```json
{
  "id": 1,
  "name": "勇者哥布林",
  "buffValue": 2  // 从 1 改为 2
}
```

### 2. 添加新哥布林

在 `goblins` 数组中添加新对象：

```json
{
  "id": 6,
  "name": "商人哥布林",
  "icon": "💰",
  "isFree": false,
  "buff": "每回合获得双倍金币",
  "buffType": "double_coins",
  "buffValue": 2.0,
  "unlockPrice": 200,
  "description": "精明的商人，能让你的收益翻倍"
}
```

**注意：**
1. `id` 必须唯一
2. 如果使用新的 `buffType`，需要在代码中实现对应逻辑
3. 别忘了更新 `maxGoblins` 数量

### 3. 修改默认解锁

修改 `config.defaultUnlockedIds`：

```json
"defaultUnlockedIds": [1, 2, 3, 4]  // 默认解锁前4个
```

### 4. 调整解锁价格

修改对应哥布林的 `unlockPrice`：

```json
{
  "id": 4,
  "unlockPrice": 50  // 从 100 改为 50
}
```

### 5. 禁用所有buff效果（测试用）

```json
"enableBuffEffects": false
```

## 🎨 设计新哥布林的建议

### Icon选择（推荐emoji）

- 战斗类：⚔️ 🛡️ 🗡️ 🏹 🔫
- 魔法类：🧙 ✨ 🔮 ⚡ 🌟
- 职业类：🔨 👑 💼 🎨 📚
- 动物类：🦊 🐉 🦅 🐺 🦁

### Buff设计原则

1. **平衡性**：付费哥布林应该强于免费，但不能过于强大
2. **独特性**：每个哥布林应有独特的玩法
3. **可扩展性**：buff类型应该容易实现和调试

### 推荐配置方案

**简单模式（新手友好）：**
```json
"defaultUnlockedIds": [1, 2, 3, 4, 5]  // 全部免费
"enableBuffEffects": true
```

**困难模式（有挑战）：**
```json
"defaultUnlockedIds": [1]  // 只有勇者免费
"unlockPrice": 200  // 提高解锁价格
```

**测试模式：**
```json
"enableBuffEffects": false  // 禁用buff效果
```

## 🔄 热更新

如果需要在运行时重新加载配置，可以调用：

```swift
GoblinConfigManager.shared.reloadConfig()
```

**注意：** 这会影响新游戏，正在进行的游戏不受影响。

## 🐛 故障排查

### 配置文件不生效？

1. 检查 JSON 格式是否正确（使用 JSON 验证器）
2. 确认文件名为 `GoblinConfig.json`
3. 确认文件位于 `A004/Config/` 目录
4. 查看 Xcode 控制台的日志输出

### 常见错误

**错误1：JSON 格式错误**
```
❌ [哥布林配置] 解析配置文件失败
```
→ 检查 JSON 语法，确保所有括号、逗号正确

**错误2：找不到配置文件**
```
❌ [哥布林配置] 找不到配置文件: GoblinConfig.json
```
→ 确认文件已添加到 Xcode 项目

**错误3：未知buff类型**
```
⚠️ [哥布林Buff] 未知的buff类型: xxx
```
→ 该 buffType 需要在代码中实现

## 📊 配置示例

### 示例1：平衡配置
```json
{
  "goblins": [
    {"id": 1, "unlockPrice": 0, "buffValue": 1},
    {"id": 2, "unlockPrice": 0, "buffValue": 1},
    {"id": 3, "unlockPrice": 0, "buffValue": 2.0},
    {"id": 4, "unlockPrice": 100, "buffValue": 10},
    {"id": 5, "unlockPrice": 150, "buffValue": 1}
  ],
  "config": {
    "defaultUnlockedIds": [1, 2, 3],
    "maxGoblins": 5,
    "enableBuffEffects": true
  }
}
```

### 示例2：简单模式（全免费）
```json
{
  "config": {
    "defaultUnlockedIds": [1, 2, 3, 4, 5],
    "maxGoblins": 5,
    "enableBuffEffects": true
  }
}
```

### 示例3：困难模式（高价格）
```json
{
  "goblins": [
    {"id": 1, "unlockPrice": 0, "buffValue": 0.5},
    {"id": 2, "unlockPrice": 50, "buffValue": 1},
    {"id": 3, "unlockPrice": 100, "buffValue": 1.5},
    {"id": 4, "unlockPrice": 200, "buffValue": 15},
    {"id": 5, "unlockPrice": 300, "buffValue": 2}
  ],
  "config": {
    "defaultUnlockedIds": [1],
    "maxGoblins": 5,
    "enableBuffEffects": true
  }
}
```

## 🎯 快速参考

```bash
# 配置文件位置
A004/Config/GoblinConfig.json

# 配置管理器
GoblinConfigManager.shared.getAllGoblins()
GoblinConfigManager.shared.getDefaultUnlockedIds()
GoblinConfigManager.shared.reloadConfig()

# 日志标签
🎭 [哥布林配置]
⚔️ [勇者哥布林]
🔨 [工匠哥布林]
🎲 [赌徒哥布林]
👑 [国王哥布林]
🧙 [巫师哥布林]
```

---

## 💡 提示

- 修改配置文件后需要重新运行应用
- 建议备份原配置文件再修改
- 可以创建多个配置文件用于不同难度
- 使用 JSON 编辑器可以避免格式错误

