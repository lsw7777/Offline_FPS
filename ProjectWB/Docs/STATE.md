# Docs/STATE.md — AI 每次会话必读的运行时台账

> 规格：`single-player-fps-dev-crispe.md` v2.0 ｜ 负责人：<人类> ｜ 执行者：AI Agent

## 当前状态（2026-10-23）

| 项 | 值 |
|---|---|
| 引擎 | **Godot 4.7.2**（已从 UE 5.5 切换，见 DECISIONS D-005） |
| 阶段 | **P0 原型期 — 可玩原型已跑通** |
| 可玩 | 双击 `run_game.bat`：移动 + 射击 6 枪 + 近战 + 换弹/切枪 + 5 靶位 + HUD |
| 上次门禁 | `validate_data.py --strict` → OK（0 error） |
| 上次测试 | Python 8 passed · Godot 平衡冒烟 PASS · 无头集成 PASS |
| **阻塞** | 无阻塞（引擎已解决）。遗留：`git init`（见 BACKLOG）、UE 骨架待归档 |

## 任务台账

| ID | 任务 | 状态 | 备注 |
|---|---|---|---|
| T-001 | 仓库骨架 + Docs | ✅ done | |
| T-002 | Config/Data 数据表 | ✅ done | 单一数值来源 |
| T-003 | validate_data.py + 回归测试 | ✅ done | 平衡五断言 + 黄金矩阵 |
| T-004 | 引擎工程 + 输入 | ✅ done（Godot） | project.godot + input_setup + FPS 控制器 |
| T-005 | 灰盒房 | ✅ done（Godot） | main.gd 代码构建 5 靶位 + 掩体 + 墙 |
| T-006 | 射击 + 伤害结算 | ✅ done（Godot） | weapon_system.gd 射线 + 伤害 |
| T-007 | 后坐模型 | ✅ done（Godot） | player.apply_recoil（60/40 + 恢复） |
| T-008 | 武器资产/反馈 | 🟡 占位 | 无美术资产，命中仅日志 + 准星 |
| T-009 | 近战 | ✅ done（Godot） | melee_system.gd（M9 刺刀） |
| T-010 | 敌人 AI | 🟡 占位 | 仅静态靶子；StateTree 敌人待补 |
| T-011 | 命中三件套 | 🟡 占位 | 无音效/动画，仅有逻辑命中 |
| T-012 | P0 门 | ⏳ 待人类手感评审 | 需真实窗口内试玩反馈 |

## 关键交接

- **引擎**：Godot 4.7.2 在 `%USERPROFILE%\.workbuddy\tools\godot\`，免安装。运行见 `Docs/HOW_TO_RUN.md`。
- **单一数据源**：`ProjectWB/Config/Data/*.json` 同时被 Python 门禁 + Godot 运行时读取，改数值只改这一处。
- **平衡模型双实现互证**：`ProjectWB/Tools/validate_data.py`（CI 门禁）↔ `Godot/scripts/wb_balance.gd`（运行时孪生），`test_smoke.gd` 断言两者黄金矩阵一致。
- **UE C++ 骨架**：`ProjectWB/Source/` 已弃用，保留待归档，不再维护。

## 常用命令

```bash
cd "C:\A_Projects\A_Game Example\Offline_FPS"
python ProjectWB/Tools/validate_data.py --strict        # 数据门禁
python ProjectWB/Tools/run_automation_tests.py          # Python 回归
"%USERPROFILE%\.workbuddy\tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://Godot/scripts/test_smoke.gd
"%USERPROFILE%\.workbuddy\tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://Godot/scenes/test_integration.tscn
```

## 改动日志

- 2026-10-23 · T-001~T-003：仓库骨架 + 数据表 + Python 门禁
- 2026-10-23 · 方案 A 尝试：生成 UE 工程骨架（uproject/C++/Config），因需人工装引擎而搁置
- 2026-10-23 · **D-005 切换 Godot 4.7.2**：下载引擎、移植平衡模型、实现可玩原型并跑通无头测试
