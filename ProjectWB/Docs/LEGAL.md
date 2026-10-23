# Docs/LEGAL.md — 现实武器命名的商标风险台账

> 规格要求（§3.1）：本表必须保持可用，确保任何时候都能在 **1 天内完成全局改名**。
> **AI 规则**：代码与资源只用 `id`（资源名）列；面向玩家的文本读 `display_name_zh` / `safe_name`，替换时只改这两个字段与 VT/UI 表，**不许动 id**（否则资源引用全断）。

## 风险分级

| id | display_name_zh | 风险 | 说明 | safe_name（如需替换） |
|---|---|---|---|---|
| `AK-47` | AK-47 | 低 | 通用型号称呼，非厂商商标 | — |
| `MP5` | MP5 | 低 | 型号通称；厂商名为 Heckler & Koch，本作 UI 未使用该厂商名 | — |
| `Remington_M870` | 雷明顿 M870 | 中 | "Remington" 为商标 → UI 只显示型号 | M870 |
| `M249_SAW` | M249 SAW | 低 | 美军编号，公有领域称呼 | — |
| `AWM` | AWM | 低 | Arctic Warfare Magnum 通称 | — |
| `Desert_Eagle` | 沙漠之鹰 | **高** | "Desert Eagle" 是 Magnum Research 注册商标 | 「沙漠之鹫」（自拟） |
| `KA-BAR` | KA-BAR 卡巴战斗刀 | **高** | "KA-BAR" 是注册商标 | 「USMC 战斗刀」 |
| `M9_Bayonet` | M9 刺刀 | 低 | 美军编号通称 | — |
| `Balisong` | 蝴蝶刀 Balisong | 低 | 通用刃型名 | — |

## 替换执行清单（法务确认后再做）

1. 改 `Config/Data/weapons.json` / `melee.json` 的 `display_name_zh` 与 `safe_name`
2. 全局 grep `Tools/` 与 UI 本地化表，确认无硬编码显示名
3. 跑 `python Tools/validate_data.py --strict`（只看 id，改名不应影响通过）
4. 更新本文件的 `display_name_zh` 列，并记录批准日期与批准人

## 记录

- 2026-10-23：表格初始化，等待人类法务确认（DECISIONS D-004）。
