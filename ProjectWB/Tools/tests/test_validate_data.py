"""Project WB - regression tests for the data gate.

Plain unittest (no pytest dependency):
    python Tools/tests/test_validate_data.py
    python -m unittest discover -s Tools/tests -v
"""

import io
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "Tools"
sys.path.insert(0, str(TOOLS))

import validate_data as vd  # noqa: E402

DATA = ROOT / "Config" / "Data"
FX = TOOLS / "fixtures"


def errors_for(folder: str) -> list[str]:
    rep = vd.Report()
    weapons_doc = vd.load_json(FX / folder / "weapons.json")
    melee_doc = vd.load_json(FX / folder / "melee.json")
    scenes_doc = vd.load_json(FX / folder / "scenes.json")
    vd._DEFAULTS = weapons_doc.get("defaults", {})
    vd.validate_schema(rep, weapons_doc["items"], melee_doc["items"], weapons_doc)
    vd.validate_unique_feedback(rep, weapons_doc["items"], 2)
    vd.validate_ammo_scarcity(rep, weapons_doc["items"], scenes_doc.get("balance_rules", {}))
    if rep.errors:
        return rep.errors
    matrix = vd.build_matrix(weapons_doc["items"], scenes_doc["scenes"], vd._DEFAULTS)
    vd.validate_balance(rep, weapons_doc["items"], scenes_doc["scenes"],
                        scenes_doc.get("balance_rules", {}), matrix, quiet=True)
    return rep.errors


class TestGoldenData(unittest.TestCase):
    def test_default_data_passes(self):
        self.assertEqual(vd.run(DATA, strict=False, quiet=True), 0)

    def test_every_weapon_has_a_home_scene(self):
        """设计意图矩阵：每把枪必须至少拥有一个唯一最优场景。"""
        weapons_doc = vd.load_json(DATA / "weapons.json")
        scenes_doc = vd.load_json(DATA / "scenes.json")
        matrix = vd.build_matrix(weapons_doc["items"], scenes_doc["scenes"], vd._DEFAULTS or weapons_doc["defaults"])
        winners = {max(row, key=row.get) for row in matrix.values()}
        for w in weapons_doc["items"]:
            self.assertIn(w["id"], winners, "武器缺少专属最优场景 -> 同质化")


class TestGateCatchesBadData(unittest.TestCase):
    def assert_gate_fails(self, folder: str, expected_keyword: str):
        errs = errors_for(folder)
        self.assertTrue(errs, f"{folder}: 期望校验失败，实际通过（校验器失效）")
        joined = " | ".join(errs)
        self.assertIn(expected_keyword, joined, f"{folder}: 未命中预期错误类型。实际: {joined}")

    def test_missing_required_fields(self):
        self.assert_gate_fails("bad_schema", "missing field")

    def test_duplicate_weapon_id(self):
        self.assert_gate_fails("duplicate_id", "duplicate weapon id")

    def test_missing_melee_field(self):
        self.assert_gate_fails("bad_melee", "missing field")

    def test_omnipotent_weapon_blocked(self):
        self.assert_gate_fails("omnipotent", "dominates")

    def test_golden_matrix_enforced(self):
        self.assert_gate_fails("wrong_golden", "expected")

    def test_ammo_scarcity_enforced(self):
        self.assert_gate_fails("ammo_violation", "ammo_cap_global")


if __name__ == "__main__":
    unittest.main(verbosity=2)
