# MemoSyncer

> AI 驱动的离线优先双语闪卡复习 App，让碎片化时间变成持久记忆。

## 简介

MemoSyncer 是一款基于 AI 大模型的渐进式双语闪卡复习应用。你只需要粘贴一段文本，AI 就会自动将其提炼为中英双语的记忆卡片，再通过科学的间隔重复算法（SM-2）驱动日常复习，帮你利用碎片时间建立长期知识记忆。

## 核心功能

### AI 智能生成闪卡
- 粘贴任意长文本（笔记、文章、教材等），AI 自动提炼 5-15 张核心闪卡
- 每张卡片自动生成中英文双语问题和答案
- 自动提取知识标签（如 `#计算机网络`、`#生物学`）
- 支持配置 API Key，兼容通义千问等 OpenAI 兼容接口

### 沉浸式复习体验
- 3D 翻转卡片：正面看问题，点击翻转看答案
- 支持中/英双语一键切换，同时记忆知识点和对应英文表达
- 三个记忆反馈按钮：遗忘（1分）、勉强（3分）、记住（5分）
- 复习完成后显示本次总结

### SM-2 间隔重复算法
- 基于标准 SM-2 算法动态调整复习间隔
- 根据用户评分自动计算难度系数（easiness factor）
- 完全遗忘的卡片自动重置，重新开始学习周期
- 下次复习日期纯日期格式，精准调度

### 复习数据看板
- **月度热力图**：按日历格子显示当月复习记录，颜色深浅代表复习强度，支持月份切换
- **今日统计**：今日已复习卡片数
- **掌握进度**：已掌握卡片总数（连续正确 ≥ 3 次）
- **打卡激励**：连续复习天数

### 浅色/深色主题
- 支持白色主题和深色主题一键切换
- 主题选择自动保存，下次打开恢复

### 离线优先
- 所有数据存储在本地 Hive 数据库，无需联网即可复习
- 仅 AI 生成卡片时需要网络，复习功能完全离线可用

## 技术架构

```
lib/
├── main.dart                     # 应用入口
├── app.dart                      # MaterialApp + 主题 + 底部导航
├── models/
│   ├── deck.dart                 # 卡片集模型
│   ├── flashcard.dart            # 闪卡模型（中英双语）
│   └── review_state.dart         # SM-2 复习状态
├── services/
│   ├── ai_service.dart           # 通义千问 AI 接口
│   ├── database_service.dart     # Hive 本地数据库 CRUD
│   └── sm2_service.dart          # SM-2 间隔重复算法
├── screens/
│   ├── home_screen.dart          # 主页（热力图 + 统计）
│   ├── input_screen.dart         # 文本输入 & AI 生成
│   ├── review_screen.dart        # 3D 翻转复习
│   └── deck_list_screen.dart     # 卡片集列表
└── providers/
    └── providers.dart            # Riverpod 状态管理
```

### 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | Flutter 3.44.0 |
| 状态管理 | flutter_riverpod |
| 本地数据库 | Hive |
| AI 接口 | 通义千问 qwen3-max-preview（OpenAI 兼容） |
| 算法 | SM-2 间隔重复算法 |

## 使用方法

### 1. 安装
下载 `app-release.apk` 安装到 Android 手机。

### 2. 配置 API Key
打开 App → 点击底部「输入」→ 点击右上角 🔑 图标 → 输入通义千问 API Key。

> API Key 获取：[阿里云百炼平台](https://bailian.console.aliyun.com/)

### 3. 生成闪卡
在输入框粘贴文本 → 点击「生成卡片」→ AI 自动生成双语闪卡集。

### 4. 开始复习
进入「卡片集」→ 点击卡片集 → 点击卡片翻转 → 评分 → 下一张。

### 5. 查看数据
进入「主页」→ 查看热力图和统计数据，左右箭头切换月份。

## 数据模型

### Deck（卡片集）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识 |
| title | String | AI 自动生成的标题 |
| createdAt | DateTime | 创建时间 |

### Flashcard（闪卡）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识 |
| deckId | String | 关联卡片集 |
| questionZh / questionEn | String | 中/英文问题 |
| answerZh / answerEn | String | 中/英文答案 |
| knowledgeTag | String | 知识标签 |

### ReviewState（复习状态）
| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| cardId | String | - | 关联闪卡 |
| easinessFactor | double | 2.5 | 难度系数 |
| interval | int | 0 | 复习间隔天数 |
| repetitions | int | 0 | 连续正确次数 |
| nextReview | DateTime | Today | 下次复习日期 |

## 构建

```bash
# 安装依赖
flutter pub get

# 生成 Hive 代码
dart run build_runner build --delete-conflicting-outputs

# 构建 APK
flutter build apk --release
```

## 开源协议

MIT License
