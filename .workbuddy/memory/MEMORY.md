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
- HUD 的 `Control` 挂在 `CanvasLayer` 下必须显式 `size = get_viewport_rect().size`；只设 anchors 不设 size 会让子控件尺寸为 0、右对齐按钮跑到屏幕外。
- **无头模式下 viewport 只有 64×64**（不是 1280×720），靠 `get_viewport_rect().size` 算出的右上角坐标会变负 → 用 `maxf(0, vp.x - N)` 夹取，否则无头测试会误报"按钮出屏"。
- 3D 血条用 `QuadMesh` + `StandardMaterial3D`（unshaded + BILLBOARD_ENABLED + no_depth_test）最省事，改 `QuadMesh.size.x` 即可做血量条。
- **全屏 HUD 根 Control 必须 `mouse_filter = MOUSE_FILTER_IGNORE`**：默认 STOP + 全屏 size 会吞掉所有鼠标事件 → 视角转不动、点击不开火。子控件仍被独立命中，设置按钮照常可点。
- 第一人称视角旋转用 **`_input(event)` 而非 `_unhandled_input`**：`_input` 在 GUI 之前，全屏控件吞不掉；再用 `Input.mouse_mode == MOUSE_MODE_CAPTURED` 作门槛。
- **无头测试盲区**：无头没有光标，`gui_get_hovered_control()` 恒 null、`Input.mouse_mode` 恒 0（设不成 CAPTURED）→ 光标/命中相关 bug 必须用**真实窗口**跑一次集成测试（不加 `--headless`）。
- 地图全部代码生成在 `Godot/scripts/map_builder.gd`：`_wall_line(axis,fixed,start,end,gaps,...)` 做带门洞分段墙、`_stack()` 堆箱、`_box(...,rot)` 做斜坡；改地图只动这一个文件。
- 换弹/切枪动画在 `weapon_model.gd`：`_anim` 状态机（reload/switch）+ 按 `_class` 分支不同曲线；`play_reload(reload_s)` 绑 `begin_reload`，`play_switch()` 绑 `equip`。霰弹枪不丢弹匣。
- 出生点要防"生在墙里"：集成测试有 `_spawn_clear()` 做 0.7×1.8×0.7 AABB 重叠检查；**旋转斜坡**用 AABB 近似会误判，出生点别贴着斜坡。
- **新增 `class_name` 的脚本后必须跑一次 `--import`**，否则其他脚本报 `Identifier "X" not declared`（global_script_class_cache 未更新）。
- 贴花（弹孔/刀痕）：`QuadMesh` + `StandardMaterial3D`(unshaded+alpha+albedo_texture)，`Basis(x,y,n)` 让 +Z 对齐法线、沿法线偏移 0.012；挂到命中的 `StaticBody3D` 下随地图释放，并做数量上限（140）回收。
- 真实感走**运行时 PBR**（`wb_tex.gd` / `WBTex`）：64×64 的 albedo+roughness+normal（法线由高度场环绕 sobel 生成），`pbr_for(col)` 按颜色自动归类 metal/steel/wood/polymer；重建模型后遍历子节点批量替换材质，不用改构建代码。
- 环境光效在 `map_builder._env()`：`ssao_enabled/ssr_enabled/glow_enabled/tonemap_mode=ACES`；相机下挂一盏 `OmniLight3D` 做武器补光（暗图也能看清枪）。
- 检视动画（中键）用多轴旋转 + 拉近 + 缩放 + 专属 `OmniLight3D`；每帧开头 `scale=ONE`、灯光 `move_toward→0` 防状态残留。
