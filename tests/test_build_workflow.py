import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = REPO_ROOT / ".github" / "workflows" / "build-model.yml"


class BuildWorkflowTests(unittest.TestCase):
    def test_workflow_uses_canonical_build_script(self):
        workflow_text = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("bash scripts/build-model.sh", workflow_text)
        self.assertNotIn('PRUSA_SLICER_BIN="$(command -v prusa-slicer)"', workflow_text)


if __name__ == "__main__":
    unittest.main()
