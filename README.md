# Project WB — 《白噪：霜蚀带》（WHITE NOISE: RIMEBELT）

> 一款**单机第一人称射击（FPS）**游戏原型。极地电磁灾变后的隔离区里，你是最后一批清道夫——没有后方，没有无线电，只有有限的子弹和一把刀。

当前处于 **P0 原型期**：已跑通「移动 + 6 把枪（含枪体/枪口火光/曳光弹）+ 近战 + 敌人 AI + 三张主题地图 + HUD」的可玩原型，平衡由数据驱动并受 CI 门禁保护。

## 当前可玩内容

| 类别 | 已实现 |
|---|---|
| **四张地图** | **炽热沙城**（参考 CS：长通道 / 中路 / 高台斜坡 / 堆叠木箱 / 三层掩体）、**运输船**（参考 CF：集装箱走廊 + 双层堆箱 + 侧面栈桥 + 舰桥）、**迷宫**（自研：房间网格 + 交错门洞 + 中央立柱 + 高台）、**靶场**（无敌人，10/20/35/50m 靶位，专供测试武器）；各有独立天空、雾、光照 |
| 枪体 | 第一人称程序化枪模（多部件）+ 双手手臂，每类枪外形不同（手枪/冲锋枪/步枪/霰弹/狙击/机枪） |
| **换弹/切枪动画** | 每类枪**独立**换弹动作（手枪翻腕、步枪换弹匣+拉栓、霰弹枪泵动、狙击枪拉栓、机枪换弹箱）+ 独立切枪抬枪动作；换弹时会掉出弹匣 |
| **弹孔 / 刀痕** | 射击墙体/道具留下**弹孔**，近战挥砍留下**刀痕**（程序化贴花，附着于被击中的物体，上限 140 个自动回收） |
| **检视动作** | **鼠标中键**检视当前武器：枪械侧转展示、刀具缓慢旋转展示 |
| **近战模式** | **V 键切换近战/远程**；近战模式下显示 3 把刀（**M9 刺刀 / KA-BAR / 蝴蝶刀**），**1/2/3 切刀**，左键挥砍（带挥刀动作） |
| **瞄准 (ADS)** | 右键**切换**瞄准：抬枪到准星、FOV 拉近、**命中率显著提高**、**移速降至 55%**；再次右键取消；仅枪械可瞄准 |
| 开火特效 | 枪口火光 + 弹道曳光弹 + **右侧抛壳动画** + 命中反馈 |
| 准星 | 动态准星：静止 / 开火（瞬间张开）/ 瞄准（收紧）三态不同 |
| 敌人 | 程序化人形敌人（头盔/护甲/四肢/武器），始终追击 + 绕障 + 行走动画 + **头顶血条** + **攻击挥臂动作**，可击杀 |
| **结算画面** | **清光一张地图全部敌人 → 弹出「地区清除」结算**（击杀数 + 用时），可选「下一张地图」或「重玩本图」 |
| 场景元素 | 墙体 / 掩体 / 箱子 / 集装箱 |
| 玩家 | 生命值 + 受伤红屏 + **受击镜头抖动** + 死亡/坠落自动重生（回满血弹） |
| 设置面板 | 右上角「设置」：**音量滑条** + **四张地图切换**（切图/坠落/死亡均回满血满弹） |

---

## 一句话概念

> 在一场摧毁了所有无线电的极地电磁灾变之后，你是最后一批进入"霜蚀带"隔离区的清道夫——枪声是这里唯一还活着的语言。

**核心循环**（90–150s）：进场侦察 → 潜行/突入抉择 → 交战 → 搜刮 → 检查点 → 解锁下一区域。
**差异化卖点（三选做大）**：① 刀是节奏控制器（省弹药/处决/格挡）；② 每把枪有物理化"脾气"；③ 音频驱动潜行（敌人主要靠听）。

---

## 快速开始

| 方式 | 操作 |
|---|---|
| 一键开玩 | 双击根目录 `run_game.bat`（Windows） |
| PowerShell | `& "$env:USERPROFILE\.workbuddy\tools\godot\Godot_v4.7.2-stable_win64.exe" --path "C:\A_Projects\A_Game Example\Offline_FPS"` |

操作：WASD 移动 · 鼠标瞄准 · 左键射击/挥刀 · **右键 瞄准/取消** · **中键 检视武器** · R 换弹 · **1–6 切枪 / 近战时 1–3 切刀** · **V 切换近战↔远程** · Shift 冲刺 · **Esc 释放鼠标 → 点右上角「设置」**。

> 完整说明见 [`Docs/HOW_TO_RUN.md`](Docs/HOW_TO_RUN.md)。

---

## 技术栈

| 项 | 选型 |
|---|---|
| 引擎 | **Godot 4.7.2**（开源、免账号、单文件即跑） |
| 语言 | GDScript（原型期） |
| 数据 | **JSON 单一数值来源** `ProjectWB/Config/Data/*.json` |
| 门禁 | Python 脚本 `ProjectWB/Tools/validate_data.py --strict` |
| 目标 | Windows 10/11 x64（Steam 发布再评估） |

> 引擎从 UE 5.5 切换而来（见 [`ProjectWB/Docs/DECISIONS.md`](ProjectWB/Docs/DECISIONS.md) D-005）。原 UE C++ 骨架保留在 `ProjectWB/Source/` 待归档。

---

## 武器库（首批 6 枪 + 3 刀）

| 槽位 | 武器 | 定位 |
|---|---|---|
| 手枪 | **沙漠之鹰** Desert Eagle .50 AE | 近距破甲 / 处决补刀 |
| 冲锋枪 | **MP5** 9mm | 高射速近距压制 / 潜行消音 |
| 突击步枪 | **AK-47** 7.62×39 | 通用主力 / 中远距离 |
| 霰弹枪 | **雷明顿 M870** 12 Gauge | 近距清场 / 破门 / 重甲 |
| 狙击枪 | **AWM** .338 Lapua | 远程定点清除 |
| 机枪 | **M249 SAW** 5.56 | 据点防御 / 群体压制 |
| 刀 | M9 刺刀 / KA-BAR 战斗刀 / 蝴蝶刀 | 潜行处决 / 正面格挡 / 高机动 |

**平衡原则**：每把枪有且仅有一个"唯一最优场景"（室内→M870、街巷→MP5、开阔→AK-47、远程→AWM、重甲→沙漠之鹰、群体→M249、潜行→MP5）。无全能武器。

**换弹时间**（战术换弹，秒）：沙漠之鹰 1.00 · MP5 1.25 · AK-47 1.50 · M870 2.00 · AWM 2.50 · M249 3.00。轻武器更快，重武器仍保留长换弹代价。

---

## 数据驱动设计（单一数值来源）

所有武器数值只存一份 JSON，被 **两套实现互证**：

```
ProjectWB/Config/Data/weapons.json ──┬── ProjectWB/Tools/validate_data.py  (Python CI 门禁)
                                     └── Godot/scripts/wb_balance.gd        (运行时孪生)
```

- 改数值 → 只改 JSON → 重跑门禁 + `test_smoke.gd`，两者黄金矩阵必须一致。
- 平衡模型是**确定性数学**（命中概率 / 伤害 / TTK / 场景得分），见 `wb_balance.gd` 文档头。

---

## 目录结构

```
├─ project.godot                  Godot 工程（根 = 工作区）
├─ run_game.bat / run_game.ps1    一键启动
├─ single-player-fps-dev-crispe.md  AI 执行规格（v2.0）
├─ Godot/
│  ├─ scripts/                    GDScript：player / weapon_system / melee_system /
│  │                              wb_data / wb_balance / hud / target / main / 测试
│  └─ scenes/                     main.tscn（主场景）
├─ ProjectWB/
│  ├─ Config/Data/*.json          ← 数值唯一来源
│  ├─ Tools/validate_data.py      ← 数据 + 平衡门禁
│  ├─ Docs/                       STATE / DECISIONS / BACKLOG / LEGAL / RENAME
│  └─ Source/                     （UE 骨架，已弃用待归档）
└─ Docs/HOW_TO_RUN.md             运行与测试指南
```

---

## 测试

```powershell
# 1) 数据 + 平衡门禁
python ProjectWB/Tools/validate_data.py --strict
# 2) GDScript 平衡模型冒烟（与 Python 门禁互证）
& "$env:USERPROFILE\.workbuddy\tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://Godot/scripts/test_smoke.gd
# 3) 无头集成测试
& "$env:USERPROFILE\.workbuddy\tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://Godot/scenes/test_integration.tscn
```

---

## 开发阶段

| 阶段 | 状态 |
|---|---|
| P0 原型期 | ✅ 可玩（6 枪 + 近战 + 靶位 + HUD） |
| P1 垂直切片 | ⏳ 待手感评审后启动 |
| P2 Alpha → 发布 | 规划见规格文档 §5 |

---

## 已知事项

- 手感（灵敏度 / 后坐 / 散布）需在真实窗口内试玩后调参，数值改动只落在 `weapons.json`。
- 敌人 AI / 命中三件套（音效+动画）/ 存档仍未接入（灰盒阶段）。
- 项目尚未 `git init`（待确认建仓粒度）。

---

## 许可与版权提示

武器名含现实型号：`AK-47`/`MP5`/`M870`/`M249`/`AWM` 为通用型号称呼；`Desert Eagle`、`KA-BAR` 为注册商标，上线前需法务确认替换映射（见 `ProjectWB/Docs/LEGAL.md`）。
