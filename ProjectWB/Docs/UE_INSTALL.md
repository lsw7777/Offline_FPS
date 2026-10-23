# Docs/UE_INSTALL.md — 安装 UE 5.5 与项目交接清单

> 状态：AI 已完成全部可交付的工程骨架；**只剩"装引擎 + 打开工程"由人类操作**。
> 交接点：装完引擎后回到 AI，说"引擎已装好"，AI 接手做 `BuildCookRun` 编译验证与 T-004 剩余验收。

## 步骤（人在本机执行，约 40GB 下载）

1. **装 Epic Games Launcher**（二选一）
   - 图形方式：浏览器打开 <https://store.epicgames.com/zh-CN/download> 下载安装
   - 命令行（本机已装 winget）：
     ```
     winget install --id EpicGames.EpicGamesLauncher -e
     ```
2. **登录** Epic 账号（无账号先注册；Unreal 个人免费）。
3. **安装引擎 5.5**：Launcher → 左侧「虚幻引擎 / Unreal Engine」→「库 / Library」→ 引擎版本页签 → 找 **5.5.x** → 安装。默认路径 `C:\Program Files\Epic Games\UE_5.5`。
4. （可选但建议）首次打开任意项目让引擎完成 shader 缓存。

## 打开本项目

- 双击 `ProjectWB.uproject`，提示缺失模块时选「是 / Yes」让引擎编译 C++。
- 或命令行生成 VS 工程（可选）：
  ```
  "C:\Program Files\Epic Games\UE_5.5\Engine\Build\BatchFiles\GenerateProjectFiles.bat" "C:\A_Projects\A_Game Example\Offline_FPS\ProjectWB\ProjectWB.uproject"
  ```

## 打开后需在编辑器内手动补（代码无法生成 .uasset）

| # | 事项 | 位置 |
|---|---|---|
| 5 | 建白盒关卡 `WB_Greybox`（30×30m + 掩体 + 5 靶位 8/15/30/60/100m） | Content/_WB/Levels/ |
| 6 | 建 Enhanced Input 动作（Move/Look/Fire/Aim/Reload/Melee/Sprint/Crouch/Jump/Swap）+ 一个 InputMappingContext | Content/_WB/UI/Input/ |
| 7 | 建玩家 Character + PlayerController，挂 `UWBFiringComponent`/`UWBLoadoutComponent`/`UWBMeleeComponent` | Content/_WB/ |
| 8 | 建敌人 Character + StateTree（Patrol→Combat→Search）+ `UWBPerceptionComponent` | Content/_WB/Enemies/ |
| 9 | 建第一个 GameMode + HUD（Widget） | Content/_WB/UI/ |

## 验证命令（AI 接手后跑）

```bash
cd "C:\A_Projects\A_Game Example\Offline_FPS\ProjectWB"
python Tools/validate_data.py --strict
python Tools/run_automation_tests.py
# 引擎侧：
"C:\Program Files\Epic Games\UE_5.5\Engine\Build\BatchFiles\RunUAT.bat" BuildCookRun -project="C:\A_Projects\A_Game Example\Offline_FPS\ProjectWB\ProjectWB.uproject" -platform=Win64 -configuration=Development
```

## 环境变量（供 AI 的工具脚本探测引擎）

- `WB_UE_EDITOR_CMD` = `C:\Program Files\Epic Games\UE_5.5\Engine\Binaries\Win64\UnrealEditor-Cmd.exe`（装好后设置，`run_automation_tests.py` 会据此跑 UE Automation Tests）

## 交付物清单（本次 AI 已生成）

```
ProjectWB.uproject
Source/ProjectWB.Target.cs / ProjectWBEditor.Target.cs
Source/ProjectWB/ProjectWB.{h,cpp} / ProjectWB.Build.cs
Source/ProjectWB/Core/WBLog.{h,cpp}
Source/ProjectWB/Combat/WBWeaponTypes.h / WBWeaponDataLibrary.{h,cpp}
Source/ProjectWB/Combat/WBRecoilModel.h / WBFiringComponent.{h,cpp}
Source/ProjectWB/Weapons/WBLoadoutComponent.{h,cpp} / WBMeleeComponent.{h,cpp}
Source/ProjectWB/AI/WBPerceptionComponent.{h,cpp}
Source/ProjectWB/Save/WBSaveGame.{h,cpp} / WBSaveGameSubsystem.{h,cpp}
Config/DefaultEngine.ini / DefaultGame.ini / DefaultInput.ini
```

> ⚠ 这些 C++ 尚未经编译器验证（本机无引擎），首次编译若有 API 偏差属于预期，AI 接手后按报错修正。
