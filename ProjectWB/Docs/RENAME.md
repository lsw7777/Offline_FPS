# Docs/RENAME.md — 游戏名尚未锁定期间的出现位置台账

> 用途：`Docs/DECISIONS.md` 中 `game.locked = false` 时，所有对外文案必须使用 `title_zh` 的字面值，并把出现位置登记在本文件，便于 Kickoff 定名后一次性替换（规格 R7 / §1.2）。
> 锁定后本文件冻结，改名需人类重新决策并记录。

## 当前字面值

- `title_zh`：白噪：霜蚀带（候选 A，`locked = false`）
- `title_en`：WHITE NOISE: RIMEBELT
- `subtitle`：第一章 · 断链节点

## 出现位置清单

| 位置 | 类型 | 备注 |
|---|---|---|
| — | — | 尚无 UI/文案落地（T-004 起才会产生） |

## 替换流程（locked = true 当天执行）

1. 人类把最终名写入 `Docs/DECISIONS.md::game`
2. AI 按上表逐个替换，并在替换后执行 `grep -r "PLACEHOLDER_TITLE\|旧名"` 确认零残留
3. 跑 `python Tools/validate_data.py --strict` 与 `python Tools/run_automation_tests.py`
4. 在本文件标注"已锁定"，后续改名需人类书面同意
