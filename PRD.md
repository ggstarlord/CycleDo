# CycleDo - 产品需求文档

## 一句话介绍
智能循环任务管理器 — 基于实际完成日期自动推算下次周期，再也不怕忘事。

## 解决什么问题
生活中有很多循环任务不是按固定日历来的：
- 净水器滤芯每月换一次，但你晚了5天才换 — 下次应该从你**实际换的那天**开始算，而不是原来的日期
- 现有日历App（Google Calendar、iOS 提醒事项、滴答清单）的重复任务都是按**原始日期**重置，不是按**实际完成日期**推算
- 很多人忘了维护任务，直到东西坏了才想起来

## 解决方案
CycleDo 管理"基于完成日期"的循环任务。点完成后，下次到期日自动按实际完成日推算。

## 目标用户
- 房主（净水滤芯、空调清洗、除虫）
- 宠物主人（驱虫、疫苗、洗澡）
- 车主（换机油、轮胎、年检）
- 健康管理（洗牙、体检、配眼镜）
- 所有有循环维护需求的人

## 核心功能（MVP v1.0）

### 1. 任务管理
- 创建循环任务：名称、周期（如每2个月）、分类
- 任务列表按"距到期天数"排序
- 颜色标记紧急程度：绿色(>7天) → 黄色(3-7天) → 红色(已过期)

### 2. 智能完成
- 点"完成" → 记录实际完成日期
- 自动推算下次到期日 = 完成日 + 周期间隔
- 保留完成历史记录

### 3. 推送通知
- 到期前X天提醒（用户可配置）
- 自定义提醒时间（如每天9:00）
- 过期任务每天提醒直到完成

### 4. 分类和模板
- 内置模板：
  - 🏠 家居：净水滤芯、空调清洗、除虫
  - 🐕 宠物：驱虫、疫苗、洗澡
  - 🚗 汽车：换机油、换轮胎、年检
  - 🏥 健康：洗牙、体检、配镜
- 支持自定义分类

### 5. 用户账号
- 注册/登录（Google、Apple、邮箱）
- 多设备数据同步

## 暂不做的功能（未来版本）
- 家庭共享（多成员）
- 购买链接（如"买这个滤芯" → 京东/亚马逊）
- 维护费用追踪
- 照片附件（如拍滤芯型号）
- 日历视图
- 桌面小组件（iOS/Android）
- Apple Watch 支持

## 技术方案

### 当前版本（Telegram Mini App）
- **前端**：纯HTML/CSS/JS，部署在 Cloudflare Pages (checkdom.pages.dev)
- **后端**：Supabase（PostgreSQL数据库 + 认证）
- **通知**：pg_cron 每分钟检查 → 通过 Telegram Bot 推送
- **Bot**：@CheckDomAppBot

### 未来 App 版本
- **前端**：React Native + Expo（一套代码出 iOS + Android）
- **后端**：继续用 Supabase
- **通知**：Expo Push Notifications（原生推送）

### 数据库结构

```sql
-- 家庭
CREATE TABLE households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT '我的别墅',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 用户资料（Telegram ID 作为主键）
CREATE TABLE profiles (
  id BIGINT PRIMARY KEY,               -- Telegram user ID
  first_name TEXT,
  username TEXT,
  household_id UUID REFERENCES households(id),
  role TEXT DEFAULT 'member',           -- 'owner' 或 'member'
  language TEXT DEFAULT 'ru',           -- 'zh', 'en', 'ru'
  timezone TEXT DEFAULT 'UTC',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 循环任务
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id),
  name TEXT NOT NULL,
  date TEXT NOT NULL,                   -- 下次到期日 (YYYY-MM-DD)
  freq INTEGER NOT NULL DEFAULT 1,     -- 周期数值
  unit TEXT NOT NULL,                   -- 周期单位（月、周、年、天）
  history JSONB DEFAULT '[]'::jsonb,   -- 完成历史记录
  notify_days_before INTEGER DEFAULT 0,
  notify_time TEXT DEFAULT '09:00',
  notifications_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 通知流程
1. Supabase pg_cron 每分钟执行 `check_and_notify_telegram()`
2. 检查哪些任务 `到期日 - 今天 <= 提前提醒天数`
3. 匹配当前时间与用户设置的 `notify_time`（按用户时区）
4. 通过 Telegram Bot API 发送通知
5. 错误处理：单个用户出错跳过继续，不会影响其他人

## 盈利模式（App 版本）
- **免费版**：最多5个任务
- **付费版（$2.99/月 或 $24.99/年）**：无限任务、自定义分类
- 通过 App Store / Google Play 内购

## 关键文件
- `PRD.md` — 本文档（产品需求）
- `cycledo-schema.sql` — 完整数据库结构 + 通知函数代码
- `checkdom-original.html` — 原始前端代码（985行，Telegram Mini App）

## Supabase 项目信息
- 项目名：checkdom
- Reference ID：sytlwramamwttvrcxxtt
- 区域：West EU (Ireland)
- 数据库定时任务：pg_cron 每分钟执行通知检查

## 开发阶段

### 第一阶段 — 当前（Telegram Mini App）
- [x] 基础任务管理（增删改查）
- [x] 完成后自动推算下次日期
- [x] Telegram 推送通知
- [x] 多语言支持（中/英/俄）
- [x] 家庭成员共享
- [x] 日历视图

### 第二阶段 — App 版本
- [ ] React Native + Expo 搭建
- [ ] Apple/Google 登录
- [ ] 原生推送通知
- [ ] 内置分类模板
- [ ] 上架 App Store + Google Play

### 第三阶段 — 增长
- [ ] 桌面小组件
- [ ] 费用追踪
- [ ] 购买链接
- [ ] 更多语言支持

## 设计原则
1. **极简** — 创建一个任务不超过10秒
2. **一目了然** — 打开就知道什么快到期了
3. **可靠** — 通知必须准时，绝不漏发
4. **克制** — 不堆功能，把一件事做好
