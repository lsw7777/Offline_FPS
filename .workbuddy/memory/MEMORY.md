# MEMORY.md — 长期记忆（跨会话）

## 用户与工作环境

- 用户使用简体中文沟通，Windows 环境，**默认 shell 是 PowerShell**（不是 cmd/bash）。
- 给用户的运行命令要按 PowerShell 语法写：环境变量用 `$env:VAR`，调用带参 exe 用 `& "path" --arg`；不要给 `%VAR%`（那是 cmd 语法，贴进 PS 会报 `“--”运算符仅适用于变量`）。
- 提供"双击即用"的启动脚本时，同时给 `.bat`（cmd 用）和 `.ps1`（PowerShell 用）两份。
- **`.bat` 必须 CRLF 换行**（LF-only 会让 cmd 对多行 if 块解析出错、双击失效）；`.ps1` 双击默认不运行（Windows 安全策略用编辑器打开），需右键「使用 PowerShell 运行」。

## 项目：单机 FPS（Offline_FPS）

- 工作区根：`C:\A_Projects\A_Game Example\Offline_FPS\`
- 规格文档：`single-player-fps-dev-crispe.md`（v2.0，AI 执行规格）
- **引擎：Godot 4.7.2**（已从 UE 5.5 切换，见 DECISIONS D-005）。Godot 二进制在 `%USERPROFILE%\.workbuddy\tools\godot\`。
- **单一数值来源**：`ProjectWB/Config/Data/*.json`，由 `ProjectWB/Tools/validate_data.py --strict` 门禁校验；Godot 运行时直接读同一份（不 fork）。
- **平衡模型双实现互证**：Python 门禁 ↔ `Godot/scripts/wb_balance.gd`，`test_smoke.gd` 断言黄金矩阵一致。
- 黄金矩阵（每把枪唯一最优场景）：室内→M870、街巷→MP5、开阔→AK-47、远程→AWM、重甲→沙漠之鹰、群体12人→M249、潜行→MP5。
- 项目尚未 `git init`（需用户确认建仓粒度）。

## Godot 开发关键约定（踩坑记录）

- Godot `JSON.parse_string` 数字统一为 float，`str(0.0)` 返回 `"0.0"`；用字典键访问 armor_dr 等时要 `str(int(x))`。
- `extends SceneTree` 的 `--script` 模式里 `add_child` 不触发子节点 `_ready`；集成测试用 `extends Node` + `await get_tree().process_frame`。
- `extends Node`（非 Node3D）没有 `get_world_3d()`，需经 `player.get_world_3d()`；射线排除用 `player.get_rid()`。
- `--headless --import` 会刷 progress_dialog 报错，属无害噪音。
