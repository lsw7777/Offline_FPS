# Docs/HOW_TO_RUN.md — Godot 版运行与测试指南

> 引擎：Godot **4.7.2**（已下载到 `%USERPROFILE%\.workbuddy\tools\godot\`，免账号、免安装包）
> 数据单一来源：`ProjectWB/Config/Data/*.json`（继续被 `Tools/validate_data.py` 门禁校验）

## 直接开玩

**方式一（推荐）**：双击根目录的 **`run_game.bat`**（用 cmd 启动，已用 CRLF 换行修正双击失效问题）。

**方式二（PowerShell）**：在 PowerShell 里执行：

```powershell
& "$env:USERPROFILE\.workbuddy\tools\godot\Godot_v4.7.2-stable_win64.exe" --path "C:\A_Projects\A_Game Example\Offline_FPS"
```

> ⚠ `.ps1` 脚本双击默认不会运行（Windows 出于安全会用编辑器打开）。要用 `.ps1`，请右键 →「使用 PowerShell 运行」，或先执行 `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` 再双击。
> 若你之前看到 `“--”运算符仅适用于变量`，是因为把 `.bat` 的 `%USERPROFILE%`（cmd 语法）贴进了 PowerShell；PS 里要用 `$env:USERPROFILE` + `&` 调用符。

## 用编辑器打开（调试 / 改场景）

```powershell
& "$env:USERPROFILE\.workbuddy\tools\godot\Godot_v4.7.2-stable_win64.exe" --editor --path "C:\A_Projects\A_Game Example\Offline_FPS"
```

## 操作

| 键 | 动作 |
|---|---|
| WASD | 移动 |
| 鼠标 | 瞄准 |
| 左键 | 射击 |
| 右键 | 瞄准 / 取消瞄准（切换 ADS：更准、移速降低、有抬枪动作） |
| R | 换弹 |
| 1–6 | 切枪（沙漠之鹰 / MP5 / AK-47 / M870 / AWM / M249） |
| V | 近战（M9 刺刀） |
| Shift | 冲刺 |
| Ctrl | 蹲（减速） |
| Space | 跳跃 |
| Esc | 释放鼠标（之后点右上角「设置」：调音量 / 切地图；切图会回满血满弹） |

## 测试（无头，提交前必跑）

```powershell
cd "C:\A_Projects\A_Game Example\Offline_FPS"
# 1) Python 数据门禁（平衡断言 + 黄金矩阵）
python ProjectWB/Tools/validate_data.py --strict
# 2) GDScript 平衡模型冒烟（与 Python 门禁结果必须一致）
& "$env:USERPROFILE\.workbuddy\tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://Godot/scripts/test_smoke.gd
# 3) 无头集成测试（实例化场景 / 射击 / 目标死亡）
& "$env:USERPROFILE\.workbuddy\tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://Godot/scenes/test_integration.tscn
```

三条全绿才算可提交。

## 目录结构

```
project.godot                     Godot 工程（根 = 工作区）
run_game.bat / run_game.ps1       一键启动（cmd / PowerShell）
Godot/scripts/                    全部 GDScript
  wb_data.gd      读取同一份 JSON（单一数据源）
  wb_balance.gd   平衡模型（validate_data.py 的运行时孪生）
  player.gd       FPS 控制器（鼠标视角 + 后坐恢复）
  weapon_system.gd  开火/后坐/散布/换弹/切枪
  melee_system.gd   近战
  target.gd        靶子（100 HP，死亡销毁）
  hud.gd           准星/弹药/枪名
  main.gd          代码构建灰盒场景
  test_smoke.gd    平衡模型无头冒烟
  test_integration.gd  无头集成测试
Godot/scenes/main.tscn            主场景
ProjectWB/Config/Data/*.json      ← 数值唯一来源
ProjectWB/Tools/validate_data.py  ← Python 门禁
```

## 为什么是 Godot（而非 UE / 纯无引擎）

1. **免账号、免 GUI 安装**：单文件即跑，AI 能直接下载并用无头模式验证（UE 需要 Epic 账号 + Launcher GUI + 40GB，纯无引擎则要手写整套 FPS 循环）。
2. **单一数据源不破**：Godot 直接读 `ProjectWB/Config/Data/*.json`，平衡模型移植成 GDScript 并与 Python 门禁互证。
3. **原 UE C++ 骨架**：已保留在 `ProjectWB/Source/`，不再维护（见 STATE.md / DECISIONS.md D-005）。
