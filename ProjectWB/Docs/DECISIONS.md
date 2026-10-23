# Docs/DECISIONS.md — 人类决策台账（AI 只读，不得修改）

> **AI 规则**：本文件只能由人类填写。任何需要决策的事，AI 走 single-player-fps-dev-crispe.md §0.5 的 `[BLOCK]` 格式上报。

## D-001 · 游戏命名

- 状态：**未锁定**
- 候选与推荐见规格 §1.1。当前 `title_zh` 写作推荐值 A，未 `locked` 前所有 UI/README 必须使用该字面值，并在 Docs/RENAME.md 登记出现位置。

## D-002 · 平衡模型 v1 首轮调参（T-003，已由 AI 执行并记录）

首次运行 `validate_data.py` 时，模型判定出 3 类问题并按设计原则修正（**没有放宽任何断言**）：

| 问题 | 依据 | 改动 |
|---|---|---|
| M249 SAW 在 30–80m 与_group_ 双场景都过强，AK-47 失去中距主场 | 无全能武器 + 每格唯一最优 | M249 `spread_mult` 1.2→2.6、持续后坐 1.2°→2.2°、`handling_time_s` 0.8→0.6：远距离精度显著劣化 |
| MP5 在 5 个场景接近最优（全能化） | 每武器最多主导 2 个场景 | MP5 `effective_range_m` 45→35：9mm 出有效射程后伤害归零，只保留近距与潜行两个主场 |
| 12 人群体场景里 AK-47 反超 M249（都不需要换弹时，精度优势压倒弹容） | 压制武器必须有一席之地 | 引入 `area_suppression` 字段并在 `clear` 指标生效：压制/扫射让集群目标停止还击，M249=1.0、AK=0.4、MP5=0.3；Group 场景目标数 6→12 |
| 重甲场景里 MP5 与沙漠之鹰差距过小 | 弹药/穿透承载平衡 | HeavyArmor 场景 `underpen_damage_mult` 0.55→0.40 |

**当前黄金矩阵（由 `Tools/validate_data.py` 实时计算并断言）**

| 场景 | 唯一最优 | 次优 | 比值 |
|---|---|---|---|
| Indoor_Breach_0_8m | Remington_M870 | MP5 | 0.31 |
| Street_8_30m | MP5 | AK-47 | 0.84 |
| Open_Snowfield_30_80m | AK-47 | M249_SAW | 0.68 |
| LongRange_80m_plus | AWM | AK-47 | 0.24 |
| HeavyArmor_3 | Desert_Eagle | MP5 | 0.72 |
| Group_Suppression_5p | M249_SAW | AK-47 | 0.60 |
| Stealth_Assassination | MP5 | Remington_M870 | 0.45 |

> 注意：Street 场景中 MP5 相对 AK-47 的优势仅领先约 16%，这是**当前已知的最脆弱平衡点**。垂直切片期间若玩家反馈 MP5 泛用，优先从这里动刀。

## D-003 · 引擎与技术栈

- 状态：**已从 UE 5.5 切换为 Godot 4.4**（见 D-005）。原 UE 骨架保留在 `ProjectWB/Source/` 待归档，不再维护。

## D-005 · 引擎决策：UE 5.5 → Godot 4.7.2

- 日期：2026-10-23
- 触发：用户要求「改为无引擎方式，或用 AI 能直接下载安装的引擎」。UE 需要 Epic 账号 + Launcher GUI + 40GB 人工安装，AI 无法代做；纯无引擎则要手写整套 FPS 循环（碰撞/输入/渲染），性价比低。
- 结论：**Godot 4.7.2**。理由：
  1. 开源、免账号、单文件即跑，AI 已直接下载到 `%USERPROFILE%\.workbuddy\tools\godot\`；
  2. 支持 `--headless`，AI 能无头导入 + 跑脚本级测试，形成可验证的交付闭环；
  3. **单一数据源不破**：直接读 `ProjectWB/Config/Data/*.json`，平衡模型移植为 GDScript 并与 Python 门禁互证（`test_smoke.gd` 断言黄金矩阵一致）。
- 代价：放弃 UE 的 Nanite/Lumen/MetaSounds 等能力；未来若要主机/高品质渲染再评估回迁（届时数据层与平衡模型可原样迁移）。
- 生效范围：`Godot/` 全部代码；`ProjectWB/Config/Data/` 与 `ProjectWB/Tools/` 保持不变。

## D-004 · 现实武器名的商标风险

- 状态：待法务确认（详见 Docs/LEGAL.md）。在此之前，代码/资源名照常使用资源名 ID。
