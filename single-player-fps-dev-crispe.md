# `<SPEC>` 单机 FPS — AI 执行规格 v2.0

> **文件性质**：本文件是**给 AI 编码 Agent 的唯一权威规格（Single Source of Truth）**。
> **消费方式**：AI 在会话启动时读取本文件，按 §0 的执行协议工作；人类负责人只回答 AI 提出的阻塞问题。
> **项目代号**：Project WB ｜ **引擎**：Unreal Engine 5.5 ｜ **形态**：纯单机 FPS，PC / Steam 首发
> **硬约束**：画面可让步，**射击手感 / 受击反馈 / 关卡节奏不可让步**。

```yaml
spec_version: "2.0"
target_reader: "AI coding agent"
previous_version: "1.0（人类团队版，已废弃，勿作为依据）"
change_log:
  - "v2.0: 武器名改为现实型号（AK-47 / 沙漠之鹰 / M870 / AWM / MP5 / M249）；全文改为机器可执行规格"
authority: "本文件 > 任何其他 md /聊天记录/口头约定。冲突时必须上报人类，禁止自行推断。"
```

---

## 0. AI 阅读与执行协议（最高优先级，先读本节）

### 0.1 启动序列（每次会话第一步，逐项执行）

```
1. 读取本文件全文（不得只读片段）
2. 读取 Docs/STATE.md    → 当前阶段 / 已完成任务 ID / 已知阻塞
3. 读取 Docs/DECISIONS.md → 已锁定的人类决策（含游戏名、武器清单冻结标记）
4. 若 STATE.md 不存在 → 认定为首次执行，进入 §10 的 T-001，并先创建该文件
5. 按 T-xxx 的依赖顺序领取【唯一一个】任务，完成后更新 STATE.md，再领下一个
```

### 0.2 上下文加载优先级

| 优先级 | 文件 / 内容 | 何时加载 |
|---|---|---|
| P0 | 本文件 + `Docs/STATE.md` + `Docs/DECISIONS.md` | 每次会话，必读 |
| P1 | 当前任务的 **受影响文件清单**（任务卡中已列出） | 领取任务后读 |
| P2 | `Source/ProjectWB/**` 中被 import 的头文件 | 需要接口细节时 |
| P3 | 其他一切 | **默认不读**，避免上下文污染 |

### 0.3 硬规则（违反即视为任务失败）

| ID | 规则 |
|---|---|
| **R1** | **一次只做一个任务**，未通过它的 DoD 不得开启下一个。禁止跨任务批量改代码。 |
| **R2** | **禁止范围蔓延**：不在任务卡中的重构、优化、加需求一律不做。有想法 → 写入 `Docs/BACKLOG.md`，绝不顺手实现。 |
| **R3** | **数值只能来自数据表**（`Config/Data/weapons.json` 等），禁止在代码里硬编码伤害/射速/后坐。硬编码 = 直接判定失败。 |
| **R4** | 每次任务结束必须执行§0.4 的三条命令，全绿才允许提交。不得跳过、不得用"应该没问题"代替实测。 |
| **R5** | 不得修改引擎源码、不得升级 UE 大版本、不得引入 `Config/` 之外的新第三方依赖（新增依赖需人类批准）。 |
| **R6** | 所有代码注释与日志**用英文**（便于批量 grep）；所有玩家可见文本走 `LOCTEXT`，**禁止硬编码中文**。 |
| **R7** | 命名 USD Tolerance：武器/敌人/关卡的资源名必须与本文件 §3 的名称字符串**逐字一致**（含空格与连字符，如 `AK-47`、`M249_SAW`）。 |
| **R8** | 遇到本文件未定义的需求 → **停下来问人类**，写入阻塞记录，禁止自行拍板。 |
| **R9** | 每个新系统必须附带最小测试（UE `AutomationTest` 或 Python 校验脚本），否则不上算完成。 |
| **R10** | 提交信息格式：`T-xxx: <动宾短语>`，一个任务一个 commit，禁止大杂烩提交。 |

### 0.4 每次提交的验收命令（必须全绿）

```bash
Tools/validate_data.py --strict                     # 数据表 schema + 平衡断言
RunUAT BuildCookRun -platform=Win64 -configuration=Development -project=ProjectWB
python Tools/run_automation_tests.py --filter=ProjectWB.Core
```

### 0.5 阻塞上报格式（AI 只能以此方式请求人类输入）

```
[BLOCK] T-xxx | 期望决策：<一句话> | 选项：A/B/C | AI 推荐：A，理由：<一句> | 不决策的后果：<一句>
```

---

## 1. 命名决策（人类输入，AI 只读不决策）

### 1.1 候选与推荐

| # | 中文名 | 英文名 | Tagline | 推荐度 |
|---|---|---|---|---|
| A | **白噪：霜蚀带** | WHITE NOISE: RIMEBELT | "枪声是这里唯一还活着的语言。" | ⭐ 推荐 |
| B | 沉默回响 | DEAD AIR | "没有人会听见你的枪声，包括你自己。" | ○ |
| C | 深灰协议 | GREY PROTOCOL | "执行到最后一条指令。" | ✗（同质化、SEO 差） |

### 1.2 AI 读取的配置项（`Docs/DECISIONS.md` → `game` 段）

```yaml
game:
  title_zh: "白噪：霜蚀带"          # A/B/C 未定前 = "PLACEHOLDER_TITLE"
  title_en: "WHITE NOISE: RIMEBELT"
  subtitle: "第一章 · 断链节点"
  locked: false                     # human must set true after kickoff
# AI 行为规则：若 locked=false，所有 UI/README/资源前缀必须使用 title_zh 的字面值，
#             且必须同时写入 Docs/RENAME.md 记录所有出现位置（便于一次性改名）。
```

---

## 2. 核心循环与状态定义

**一句话概念**：极地电磁灾变后，你是进入"霜蚀带"隔离区的最后一批清道夫——没有后方，没有无线电，只有有限的子弹和一把刀。

```text
CoreLoop(90–150s):
  EnterZone → Recon(读取敌情/路线)
    → Decision{正面突入(高弹药消耗) | 潜行处决(高风险/省弹药)}
    → Combat(Loop 25–40s: Fire → Cover → Flank → Execute)
    → Sweep(搜刮弹药/解锁)
    → Checkpoint(存档 + 补给 100%)
    → UnlockNextZone → Exit

SubLoop(30–60s): Ammo Budget Decision —— 每个遭遇点必须产出"打 or 绕"的显式选择。
```

**目标玩家**：25–40 岁 PC 单机玩家，玩过 Doom / Dusk / Metro / Tarkov(PvE)；最在意武器重量感、敌人诚实反馈、关卡非走廊。**付费预期 ¥60–100 / 8–12 小时**。

**USP（三选做大，禁止全做）**：① 刀是节奏控制器（省弹药/处决/格挡）；② 每把枪有物理化"脾气"；③ 音频驱动潜行感知（敌人主要靠听，枪声吸引半径 30m）。

**叙事框架**：线性章节 + 半开放节点地图（非开放世界）。每章 0.4–0.8 km² 手工箱庭，含 3–5 个可乱序清理的据点。叙事靠环境 + 录音日志（每章 8–12 条），**无过场动画**。

---

## 3. 武器库设计（现实型号）

### 3.1 命名规则与平衡校验

**命名规则**

- **主名 = 现实通用型号**（`AK-47` / `M4A1` / `MP5` / `Desert Eagle` / `Remington M870` / `AWM` / `M249 SAW`），资源名逐字一致。
- **变体后缀**承载世界观（不另起虚构名）：`-C` 寒区改型（加装防冻机匣，冬季时的唯一可靠选择）/ `-S` 民用短管 / `-T` 战术导轨版 / `Scav` 手工改造。
- **弹药口径作为副标题**（`.50 AE` / `7.62×39mm` / `.338 Lapua` / `12 Gauge`），稀缺度写在弹药上而非枪上。
- ⚠ **法律提示（AI 必须写入 `Docs/LEGAL.md`）**：`AK-47`、`M870`、`M249` 多为通用型号称呼可安全使用；`Desert Eagle`（Magnum Research 商标）、`KA-BAR`（商标）等存在商标风险 → 上线前由人类法务确认，AI 保留 `Docs/LEGAL.md` 中的替换映射表（`display_name` ↔ `safe_name`），确保 1 天内可全局替换。

**平衡五原则（已实现为断言，见 `Tools/validate_data.py`）**

```python
# 每条都会导致 CI 失败，AI 不得修改断言，只能改数据
assert no_omnipotent_weapon()          # 无全能武器：每枪在最优距离带外，有效 DPS 衰减 >= 40%
assert ttk_ladder_ok()                 # TTK 阶梯：突入 0.3–0.6s / 通用 0.7–1.0s / 精准瞬杀但失手惩罚 >=1.2s / 压制 TTK 偏高但 Suppression 最高
assert ammo_scarcity_ok()              # 弹药即平衡：AWM 全局携带上限 40 发；M249 补给仅来自据点
assert unique_feedback_count() >= 2    # 每枪 >= 2 项独有反馈（音色 / 屏震曲线 / 枪机动画 / 枪口 Niagara / 弹壳物理）
assert optimal_scene_is_unique()       # 克制矩阵每格有且仅有一把最优武器
```

**场景克制矩阵**（🎯唯一最优 / ○可用 / ✗禁用）
> 本矩阵不是手写结论，而是 `Tools/validate_data.py` 每次运行实时计算的结果；表格下方"黄金矩阵"是设计意图断言，两者不一致时 CI 直接失败。

| 场景 | Desert Eagle | MP5 | AK-47 | M870 | AWM | M249 SAW |
|---|---|---|---|---|---|---|
| 0–8m 室内突入 | ○ | ○ | ○ | 🎯（0.25s 首发即杀） | ✗ | ○ |
| 8–30m 街巷/哨站 | ○ | 🎯 | ○ | ✗ | ✗ | ○ |
| 30–80m 开阔雪原 | ✗ | ✗ | 🎯 | ✗ | ✗ | ○ |
| 80m+ 远程哨戒 | ✗ | ✗ | ○ | ✗ | 🎯 | ✗ |
| 重甲（3 级） | 🎯（穿甲 3 级） | ✗ | ○ | ○ | ○ | ○ |
| 群体压制（12 目标） | ✗ | ✗ | ○ | ✗ | ✗ | 🎯（弹链 + 压制扫射） |
| 潜行（不惊动） | ✗ | 🎯（集成消音 MP5SD） | ✗ | ○ | ✗ | ✗ |

**黄金矩阵（`scenes.json::expected_best`，已成断言）**：室内突入 → `Remington_M870`；街巷 → `MP5`；开阔 → `AK-47`；远程 → `AWM`；重甲 → `Desert_Eagle`；群体 → `M249_SAW`；潜行 → `MP5`。
**已知最脆弱平衡点**：街巷场景 `MP5` 仅领先 `AK-47` 约 16%（见 `Docs/DECISIONS.md` D-002），优先在此动刀。

### 3.2 枪械清单（首批 6 把 · 现实型号）

> 基准：**标准敌人 100 HP**；倍率 躯干 1.0 / 头 2.5 / 四肢 0.7。

| # | 资源名 | 中文/常用名 | 类别 | 定位 | 伤害 | 射速 | 弹匣 | 后坐力（垂直°） | 有效射程 | 获取方式 | 手感关键词 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `Desert_Eagle` | 沙漠之鹰 .50 AE | 重型手枪 | 副武器 / 近距破甲 / 处决补刀 | 65–80 | 半自动，连打上限 300 RPM | 7 | 4.0（恢复 0.35s） | 50m | 第 1 章保险柜（需密码，日志线索） | 像抡一门手炮，一枪后要重新找回目标 |
| 2 | `MP5` | MP5 冲锋枪 9mm | 冲锋枪 | 高射速近距压制 / 清房 / 潜行消音 | 22–27 | 800 RPM | 30 | 0.9（第 15 发后横向漂移） | **35m** | 第 1 章「哨站仓库」武器箱 | 泼水密度中带着可控，3 秒内必须解决 |
| 3 | `AK-47` | AK-47 7.62×39mm | 突击步枪 | 通用主力 / 中远距离 | 38–45 | 600 RPM | 30 | 1.8（前 3 发可控，之后上跳） | 90m | 第 2 章首个据点精英必掉 | 粗暴、金属敲击感，点射有天然节拍 |
| 4 | `Remington_M870` | 雷明顿 M870 12 号径 | 泵动霰弹枪 | 近距清场 / 破门 / 重甲 | 9 弹丸 × 11–13（全中 ≈ 110–117） | 45 RPM（含泵动节拍） | 6 发弹仓 | 3.2（击退目标 0.3m） | 12–18m | 第 1 章中段上锁柜（需撬棍） | 一发定音，能把人推回门里 |
| 5 | `AWM` | AWM .338 拉普阿 | 栓动狙击枪 | 远程定点清除 / 潜行开场 | 130–150（躯干一枪致命；3 级甲需 2 发） | 50 RPM（含拉栓） | 5 | 4.0（上跳后 0.9s 回零） | 300m+ | 第 3 章击杀敌方狙击手掉落 | 慢、重、破空声；开枪后世界安静 1 秒 |
| 6 | `M249_SAW` | M249 SAW 5.56mm | 班用机枪 | 据点防御 / 群体压制 | 42–50 | 550 RPM（前 8 发渐进提速） | 100 弹链 | 极高且持续：spread_mult 2.6 / 持续后坐 2.2°，抬枪 0.6s | 120m | 第 4 章据点防御战军械箱 | 泼铝、持续轰鸣，小腿肚能感到钢板共振 |

**共用射线/投掷物规则（所有枪一致，禁止特例）**

```ini
Spread_Standing=0.1°  Spread_Walk=0.6°  Spread_Run=1.4°  Spread_Air=2.5°
Spread_Multiplier: DesertEagle 0.5 | MP5 1.0 | AK47 0.8 | M870 1.6 | AWM 2.0 | M249 2.6
HandlingTime_s: MP5 0.15 | AWM 0.9 | M249 0.6 | M870 0.25 | AK-47 0.25 | DesertEagle 0.35
AreaSuppression(仅 clear 指标): M249 1.0 | AK-47 0.4 | MP5 0.3 | M870 0.1 | DesertEagle 0 | AWM 0

> 本表所有数值的最终来源是 Config/Data/weapons.json；两者冲突时以 JSON 为准，并回头修本表。
FirstShotBonus: 静止 0.35s 后首发扩散 -50%
ArmorDR: 1级 15% | 2级 30% | 3级 45%；M870 独头弹与 AWM 穿甲弹 -> DR 减半
ReloadEmptyPenalty: +0.5s   ReloadCancelable: true（保留已装填弹数）
```

### 3.3 近战刀清单（首批 3 把 · 现实型号）

| # | 资源名 | 中文/常用名 | 定位 | 伤害 | 攻击间隔 | 范围 | 特殊机制 | 获取方式 |
|---|---|---|---|---|---|---|---|---|
| 1 | `M9_Bayonet` | M9 刺刀 | **潜行处决** | 55（轻击）/ 220（背刺 ×4） | 0.55s | 1.6m | 目标未警觉时，从背后 120° / 1.6m 内触发**即时处决**（无声、无视剩余 HP）；每次处决返还当前主武器弹药 2 发 | 序章默认携带 |
| 2 | `KA-BAR` | KA-BAR 卡巴战斗刀 | **正面格挡** | 45 | 0.40s | 1.4m | 举刀格挡，前 0.25s 为**完美格挡窗口**：弹反正面子弹 / 架开近战并使目标硬直 1.2s；每次消耗体力 25 | 第 2 章近战精英必掉 |
| 3 | `Balisong` | 蝴蝶刀 Balisong | **高机动** | 30 | 0.25s（三连段） | 1.2m | 击杀后 1.5s 内移速 +20% 且可**取消任意射击后摇**；空中挥砍命中可重置一次二段跳 | 第 3 章隐藏宝箱（音频解谜，3 条日志线索） |

**近战共用规则**：处决期获得 0.6s 无敌帧但**不可取消**（防无脑连杀）；近战不吃弹药，吃**体力条 100 点 / 1.2s 回满**。

### 3.4 数据表格式（AI 必须按此 schema 生成，不得自定义）

```jsonc
// Config/Data/weapons.json
{
  "schema": "wb.weapon/1",
  "items": [
    {
      "id": "AK-47",
      "class": "AssaultRifle",
      "display_name_zh": "AK-47",
      "ammo": "7.62x39mm",
      "damage": [38, 45],
      "rpm": 600,
      "magazine": 30,
      "recoil_v_deg": 1.8,
      "recoil_h_deg": 0.35,
      "recoil_recover_deg_per_s": 9.0,
      "spread_mult": 0.8,
      "effective_range_m": 90,
      "reload_tactical_s": 2.3,
      "weight": 4,
      "acquire": { "chapter": 2, "method": "EliteDrop", "guaranteed": true },
      "feedback_tags": ["metal_clang", "heavy_stock", "shell_eject_45deg"],
      "distance_band": "mid"
    }
  ]
}
```

### 3.5 携带与切换规则（`Config/Data/loadout.json`）

```jsonc
{
  "slots": { "primary": 2, "secondary": 1, "melee": 1,
             "throwable": { "types": 2, "counts": { "FragGrenade": 2, "NoiseDecoy": 1 } } },
  "primary_rule": "两把主武器必须落在不同的 distance_band（near<25m / mid 25-80m / far>80m），三选二",
  "melee_rule": "全程不可丢弃",
  "weight": { "max": 12,
              "move_speed_mult": "1.0 - 0.020 * TotalWeight",
              "swap_time_mult":  "1.0 + 0.030 * TotalWeight" },
  "swap_time_s": { "to_primary": 0.55, "to_secondary": 0.35, "to_melee": 0.25, "back_to_gun": 0.45 },
  "cancel_rule": "换枪动画可被近战 windup 取消，不可被射击取消（防连点宏）"
}
```

### 3.6 平衡的可执行化（已落地）

| 文件 | 作用 |
|---|---|
| `Config/Data/weapons.json` / `melee.json` / `scenes.json` / `loadout.json` / `level_rules.json` | 唯一数值来源 |
| `ProjectWB/Tools/validate_data.py` | 确定性平衡模型 + 断言（唯一最优场景 / 全能武器拦截 / TTK 阶梯 / 弹药稀缺 / 独有反馈数） |
| `ProjectWB/Tools/tests/test_validate_data.py` + `Tools/fixtures/*` | 8 条回归测试，含 6 组负向夹具（注入错误数据必须报错） |
| `ProjectWB/Docs/DECISIONS.md` D-002 | 首轮调参记录与当前最脆弱平衡点 |

```bash
cd ProjectWB
python Tools/validate_data.py --strict        # 数据与平衡门禁，红灯禁止提交
python Tools/validate_data.py                 # 打印实时克制矩阵
python Tools/run_automation_tests.py          # 回归测试（无引擎时 UE 部分跳过）
```

**AI 规则**：修改 JSON 后必须重跑上面第一条；改的红了只能改数据，不许改断言；若确实要改设计意图，先写 `Docs/DECISIONS.md` 再改 `expected_best`。

---

## 4. 技术选型

> ⚠ **引擎已切换（2026-10-23，D-005）**：从 UE 5.5 改为 **Godot 4.4**——因 UE 需人工装 Launcher/账号，AI 无法代装；Godot 开源免账号、AI 可直接下载并用无头模式验证。原 UE C++ 骨架保留在 `ProjectWB/Source/` 待归档。
> **数据层与平衡模型完全不变**：`ProjectWB/Config/Data/*.json`（单一数值来源）+ `ProjectWB/Tools/validate_data.py`（门禁）继续有效；Godot 侧 `Godot/scripts/wb_balance.gd` 是门禁的运行时孪生，`test_smoke.gd` 保证两者黄金矩阵一致。

```yaml
engine: "Godot 4.7.2"                    # 已下载到 %USERPROFILE%\.workbuddy\tools\godot\
language: "GDScript（原型）+ 数据外置 JSON"
runtime_dir: "Godot/scripts/"
data_source: "ProjectWB/Config/Data/*.json"   # 唯一数值来源，禁止硬编码
gate: "ProjectWB/Tools/validate_data.py --strict"
plugins_forbidden: ["任何网络/多人", "EOS", "EAC"]
vcs: "Git + Git LFS"
ci: "validate_data.py --strict + godot --headless test_smoke + test_integration"
platform_first: "Windows 10/11 x64（原型期；Steam 发布再评估）"
```

> 原 UE 版技术选型（下段）**仅作归档参考，不再执行**。

**仓库结构（AI 必须遵守的路径）**

```text
ProjectWB/
├─ Source/ProjectWB/
│   ├─ Combat/      {FiringComponent, RecoilModel, DamageResolver, ReloadStateMachine}
│   ├─ Weapons/     {WeaponBase, WeaponInstance, LoadoutComponent, MeleeResolver}
│   ├─ AI/          {StateTree tasks, PerceptionConfig, SuppressionSubsystem}
│   ├─ Save/        {SaveGameSubsystem, CheckpointVolume}
│   └─ Core/        {WBSettings, WBLog}
├─ Content/_WB/
│   ├─ Weapons/{AK-47,MP5,Desert_Eagle,Remington_M870,AWM,M249_SAW}/{Mesh,SFX,VFX,Anims}
│   ├─ Melee/{M9_Bayonet,KA-BAR,Balisong}
│   ├─ Enemies/ Levels/ UI/ Audio/
├─ Config/Data/*.json        # 唯一数值来源（见 R3）
├─ Tools/                    # validate_data.py / run_automation_tests.py / 数据导出
└─ Docs/{STATE.md,DECISIONS.md,BACKLOG.md,LEGAL.md,RENAME.md}
```

**性能预算（不可突破）**：1080p/60 → Game Thread ≤ 8ms · Render Thread ≤ 8ms · GPU ≤ 14ms · 内存 ≤ 6GB · 同屏敌人 ≤ 12。
**最低配置**：i5-8400 / R5 2600 · 16GB · GTX 1060 6GB / RX 580 8GB · SSD 必需。

---

## 5. 阶段与任务 DAG（AI 按表执行）

| 阶段 | 周期 | 交付物 | 验收标准（可量化 / 可执行） |
|---|---|---|---|
| **P0 原型** | W1–W2 | 移动 + 射击 + `Desert_Eagle` + `M9_Bayonet` + 1 种敌人 + 白盒房 | 输入→画面延迟 `<50ms`；1080p 稳定 60 FPS；5 分钟无崩溃（Log Error = 0）；10 名外部试玩 3 分钟内理解"射—砍—捡" |
| **P1 垂直切片** | W3–W8 | 1 关（20–25min）+ 3 枪 + 1 刀 + 1 敌 + 1 精英 + HUD + 检查点存档 | 首通中位数 22±5min；无引导完成率 ≥80%；存档读写 100 次循环零损坏；GPU ≤14ms |
| **P2 Alpha** | W9–W16 | 6 枪 3 刀 + 6 种敌人 + 3 关 + 弹药经济 + 音频基础层 | `validate_data.py --strict` 全绿；任意两敌行为可被口述区分；帧时间波动 <15% |
| **P3 Beta** | W17–W24 | 5–6 关 + 手柄适配 + 本地化 + 成就 | Steam Input 认证清单通过；加载 ≤8s(SSD)；崩溃 <1 次/10h；LOCTEXT 覆盖率 100% |
| **P4 RC** | W25–W32 | 平衡冻结 + 性能优化 + Demo | 最低配置机 1% Low ≥50；Wishlist→Demo 转化 ≥8%；P0/P1 Bug = 0 |
| **P5 发布** | W33–W36 | 正式版 + Day-1 热修预案 | Day-1 崩溃率 <1%；差评 TOP3 无"手感/迷路/闪退" |

---

## 6. 核心系统规格（含接口与参数）

### 6.1 射击手感（最高优先级）

```ini
; Config/DefaultGame.ini 段；AI 只能改值，不能改键名
[/Script/ProjectWB.WBCombatSettings]
Hitmarker_ShowTime=0.08
CameraShake_Fire=0.15..0.60            ; per-weapon from weapons.json
HitStop_Target=0.060                    ; 命中时目标动画微停 60ms
HitStop_Kill=0.090
Tracer_Lifetime=0.060
ImpactDecal_PoolSize=256                ; 必须池化
RecoilModel=CameraAndSpreadDualChannel
RecoilPattern_FixedRatio=0.6            ; 60% 固定 + 40% 随机（可学但不完美）
RecoilCompensation_Enabled=1            ; 压枪必须有回报
ReloadTactical.Desert_Eagle=1.9
ReloadTactical.MP5=2.1
ReloadTactical.AK-47=2.3
ReloadTactical.M870=0.45                ; per shell
ReloadTactical.AWM=3.0
ReloadTactical.M249_SAW=6.5
```

```cpp
// Source/ProjectWB/Combat/FiringComponent.h —— AI 必须实现的最小接口
UCLASS(ClassGroup=(Combat), meta=(BlueprintSpawnableComponent))
class UWBFiringComponent : public UActorComponent
{
    GENERATED_BODY()
public:
    void TryFire();                                     // 由 EnhancedInput 驱动
    void BeginReload();
    void CancelReload();                                // 保留已装填进度
protected:
    // 射线 + 命中判决：返回 nullptr 表示未命中；bKillingBlow 用于触发 HitStop_Kill
    FHitResult TraceShot(float SpreadDeg, bool& bKillingBlow) const;
    void ApplyRecoilStep(const FWeaponData& Data);      // 60/40 pattern
    void RecoverRecoil(float DeltaSeconds);             // 9.0 deg/s 向首发收敛
private:
    FWeaponData CachedData;                             // 来自 DataAsset，加载自 weapons.json（禁止硬编码）
    int32 AmmoInMag; float RecoilAccumV, RecoilAccumH;
    TWeakObjectPtr<UNiagaraComponent> PooledMuzzleFx;   // 池化，禁止 Spawn
};
```

**逐条不可妥协清单（写进 PR 模板）**
1. 扣扳机 → 屏幕出现变化 ≤ 1 帧 + 16ms；
2. 命中必须**同时**触发三件套：Hitmarker + 命中音 + 目标动画扭曲；
3. 击杀必须有明确终结反馈（专属死亡动画 或 布娃娃受力方向明确）。

### 6.2 敌人 AI（StateTree）

```text
States: Idle → Patrol → Suspicious → Search → Combat → Suppressed → Flank → Cover → Melee → Retreat → Dead
每种敌人 = 纯数据资产配置（不改代码）

Perception.SightCone      = 100°, 30m（暗中 12m）
Perception.Hearing_foot   = 6m（走）/ 12m（跑）
Perception.Hearing_gun    = 30m（未消音）; 消音 8m      # 「白噪」玩法核心
ReactionTime              = Easy 0.75s / Normal 0.55s / Hard 0.35s
FirstShotAccuracyCap      = Easy 35% / Normal 55% / Hard 75%   # 必须留反应窗口
Suppression               = 2m 内连续掠过 5 发 → Suppressed：命中率 -60%，持续 1.5s（赋予 M249 存在意义）
Differentiation           = 6 种敌人必须在{移动模式, 交战距离, 协同方式}三维互不相同
```

### 6.3 关卡设计（`Config/Data/level_rules.json`）

```
节拍：战斗 90–120s → 低压期 20–40s（搜刮 / 环境叙事 / 音频喘息）交替
空间：每个主战场 ≥ 2 层垂直 + ≥ 3 条进攻路径（正面 / 侧翼 / 高处或管道）
经济：敌人掉落弹药 = 该遭遇预计消耗的 70%；检查点补至 100%
引导：唯一光源 = 唯一正确路线；禁止纯走廊；每区必须有"用子弹换效率 or 潜行换风险"的抉择点
存档：每 8–12 分钟一个自动检查点；Boss 前强制手动检查点
```

### 6.4 存档结构

```cpp
USTRUCT()
struct FWBProgressSave { GENERATED_BODY()
    int32 SchemaVersion = 1;        // 迁移用
    FString ChapterId; float PlayTimeSec;
    TArray<uint8> CompressedPayload; // LZ4
    uint32 Crc32;                    // payload CRC
    int32 AmmoRedundant[4];          // 关键数值双字段冗余，不一致即回滚
};
```

规则：`.sav` + `.sav.bak` 双备份（写入前备份上一次）· CRC 失败 → 弹窗回滚，**绝不静默清空** · 字段错序 + XOR 混淆（目标是挡手贱，不是挡黑客）。

### 6.5 UI / HUD

极简：无准星扩散 UI 图示（由武器动画表达）、血量 = 单条 + 红色 vignette、弹药 = 大数字 + 弹匣图形。
层级：武器数据（常驻）→ 任务目标（按住 Tab）→ 地图（长按 Tab）→ 改装（仅检查点开放）。
无障碍：色盲 3 模式 · 字幕 3 档 · HUD 透明度可调 · 可关屏幕震动。

---

## 7. 单机特化约束

1. **无网络** → 逻辑全在 Game Thread 定帧运行；不用网络预测 / RPC / 回滚；AI 与物理可"作弊式"简化。
2. **不引入任何反作弊**（无 EAC / EOS）。
3. **存档防篡改**：错序 + XOR + CRC32 + 双备份 + 关键数值冗余交叉校验。
4. **作弊控制台隔离**：Console 仅在 `Development/DebugGame` 可用；Shipping 用宏彻底剥离；一旦本局启用过控制台 → 本局不计成就（session 标记）。
5. **离线 100% 可玩**：不依赖任何首日补丁与在线校验；Steam 离线模式解锁的成就须自动同步。
6. **工时红利**：省下的多人同步工时，全部投入手感与关卡密度——这是本项目唯一能赢的战场。

---

## 8. 风险与 AI 看门狗

| 风险 | 概率 | 影响 | AI 应执行的动作 |
|---|---|---|---|
| 范围蔓延 | 高 | 高 | 任何任务卡外的新需求 → 写 `Docs/BACKLOG.md`，不实现。WBS 冻结至 W8。 |
| 手感调校失控 | 高 | 高 | W2 起每日 15min 品鉴；W6 **冻结 AK-47 基线**，其余枪以它为派生模板，禁止并行打磨。 |
| 性能瓶颈 | 中 | 高 | W4 起每周三固定路线跑测；DrawCall / Nanite overdraw / 雪粒子为三大观察项。 |
| 美术资源缺口 | 高 | 高 | 单材质族 + Kitbash；每关新增独特资产 ≤ 15；优先外部资产商店占位。 |
| 武器同质化 | 中 | 高 | 新增枪前必须先填 §3.1 矩阵，填不出唯一最优场景 → 不开工。 |
| AI 行为单一 | 中 | 中 | ≤6 种敌人但行为签名互异；用 2 人协同小组脚本降低单体复杂度。 |
| 单点程序员故障 | 高 | 极高 | 上层逻辑 70% 蓝图化；核心 C++ 每周五强制 Code Review 并文档化接口。 |
| 引擎升级返工 | 中 | 中 | 锁 UE 5.5，RC 前不动大版本。 |
| 市场可见度 | 中 | 高 | 垂直切片完成即刻做 Demo 上 Steam Next Fest。 |

---

## 9. MVP 范围（越界即写 BACKLOG，不得实现）

| ✅ 必须有 | 🟡 可以有（Alpha 后评估） | ⛔ 明确不做 |
|---|---|---|
| 6 枪 3 刀（§3 清单） | M4A1（低后坐替代 AR）／巴雷特 M82 | 多人 / 合作模式 |
| 1 个垂直切片关卡 20–25min | 武器改装台 / 配件系统 | 开放世界 / 大地图 |
| 6 种差异化敌人 + 1 精英 | 技能树（仅资源富余时） | 捏脸 / 换装 / 载具驾驶 |
| 检查点 + 3 槽位存档 + CRC | 饥饿 / 体温系统（只保留"体温 debuff"一层） | 过场动画 / 全程配音演出 |
| HUD + 键鼠 + 手柄适配 | Boss 战（先用强化精英代打） | PvP / 排行榜 / 在线内容 |
| 手感三件套（后坐 / 命中 / 换弹） | 可破坏场景（先做木箱 + 油桶） | Day-1 主机移植 |
| 基础音频层（枪声 / 脚步 / 风噪） | MetaSounds 电台噪音解谜 | 无尽遭遇模式 |
| 三层弹药经济（掉落 / 拾取 / 补给） | 二周目 New Game+ | 任何需联网的功能 |

**放行判据**：Demo 上线后核心循环主观 ≥7.5/10 且"枪手感"好评占比 >60% → 才允许进 P2 扩内容；否则回 P0，**禁止扩量**。

---

## 10. 执行序列：第一批任务卡（AI 从 T-001 开始）

> 每张卡：`< 1 个 AI 会话`；完成后更新 `Docs/STATE.md`；失败用 §0.5 格式上报。

| ID | 依赖 | 任务 | DoD（可验证） | 受影响文件 |
|---|---|---|---|---|
| **T-001** | — | 初始化仓库骨架：Directory 结构（§4）+ `Docs/{STATE,DECISIONS,BACKLOG,LEGAL,RENAME}.md` 空模板 | 目录树与 §4 完全一致；5 个 md 存在且含规定标题 | 全仓库根 |
| **T-002** | T-001 | 建 `Config/Data/weapons.json` + `melee.json` + `loadout.json`，按 §3.4 schema 填 6 枪 3 刀 | `validate_data.py --strict` 通过（含平衡五断言） | Config/Data/* |
| **T-003** | T-001 | 实现 `validate_data.py`：schema 校验 + §3.1 五条断言 + 克制矩阵去重检查 | 故意注入错误数据能全部报错 | Tools/ |
| **T-004** | T-002 | UE 项目初始化：Enhanced Input 绑定 移动/冲刺/滑铲/跳/开火/瞄准/换弹/切枪/近战 | 键鼠与手柄两套映射均可触发；`stat unit` 无异常 | Source/ProjectWB/Core |
| **T-005** | T-004 | 白盒房 30×30m：地面 + 掩体 + 5 个距离靶位（8/15/30/60/100m） | 关卡可 Play-in-Editor；5 靶位距离误差 <0.5m | Content/_WB/Levels |
| **T-006** | T-003 | `FiringComponent`：射线 + 伤害结算 + 弹药 + 换弹状态机（读 weapons.json） | 有 `AutomationTest` 覆盖：命中/未命中/空仓/取消换弹 | Source/ProjectWB/Combat |
| **T-007** | T-006 | `RecoilModel`：60/40 pattern + 9°/s 收敛 + 步伐扩散 + 首发精度奖励 | 连打 30 发后相机垂直误差在预测值 ±10% 内 | Source/ProjectWB/Combat |
| **T-008** | T-006 | `Desert_Eagle` 数据资产 + 占位 Mesh/枪机动画/金属音色/枪口 Niagara（池化） | 单发记录 ballistic 延迟 <50ms；连开 100 发 Niagara 实例数不增长 | Content/_WB/Weapons/Desert_Eagle |
| **T-009** | T-005 | `M9_Bayonet` 近战：射线判定 + 背刺 120° 检测 + 处决逻辑 + 弹药返还 | 正面挥砍不触发处决；背刺返还正好 2 发；有测试 | Source/ProjectWB/Weapons |
| **T-010** | T-005 | 第 1 个敌人：StateTree（Patrol→Combat→Search）+ 感知配置 + 受击反应 + 死亡 | 敌人从发现玩家到开火的时间落在 ReactionTime ±0.1s；5 分钟压测无 AI 卡死 | Source/ProjectWB/AI |
| **T-011** | T-008/009/010 | 集成手感白盒：三件套反馈（Hitmarker + 音效 + 动画扭曲）统一管线 | 命中时三者在同一帧触发（日志时间戳验证） | Source/ProjectWB/Combat |
| **T-012** | T-011 | **P0 门**：构建 + 自动化跑测 + 5 分钟崩溃（Log Error=0）+ 延迟测量报告 | §0.4 三条命令全绿；报告写入 `Docs/STATE.md` | CI |

**执行状态（以 `ProjectWB/Docs/STATE.md` 为准）**：T-001 / T-002 / T-003 **已完成**（数据表 + 平衡门禁落地，`--strict` 绿灯，8 条回归测试通过）；**T-004 及之后全部阻塞**——本机未安装 UE 5.5，见 STATE.md `BLOCK-001`，等待人类决策。

**T-012 之后**：AI 必须停下来，把 `[BLOCK]` 清单交给人类评审手感，再领取 P1 批次任务卡（T-013 起）。

---

## 附：提交前自检（PR 模板，必须逐条勾选）

- [ ] 只做了一张任务卡的事（R1）
- [ ] 无硬编码数值，全部来自 `Config/Data/*`（R3）
- [ ] 资源名与 §3 逐字一致（R7）
- [ ] 玩家可见文本全走 LOCTEXT（R6）
- [ ] 新增/修改了测试，且通过（R9）
- [ ] `Tools/validate_data.py --strict` + `BuildCookRun` + `AutomationTest` 三条命令全绿（R4）
- [ ] 性能预算未被突破：Game/Render ≤8ms，GPU ≤14ms，同屏敌人 ≤12
- [ ] commit msg 形如 `T-xxx: <动宾短语>`（R10）
- [ ] 越界想法已写入 `Docs/BACKLOG.md` 而非顺手实现（R2）
