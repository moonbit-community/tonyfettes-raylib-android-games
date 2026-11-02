import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("upload_apks.sh")


class UploadTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "bin").mkdir()
        (self.root / "apks").mkdir()
        self.log = self.root / "calls.jsonl"
        gh = self.root / "bin/gh"
        gh.write_text("""#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
with open(os.environ['TEST_LOG'], 'a') as log:
    log.write(json.dumps(args) + '\\n')
created = Path(os.environ['TEST_LOG'] + '.created')
if args[:2] == ['release', 'view']:
    if '--json' in args:
        print('true' if created.exists() else 'false')
    elif not created.exists() and not os.environ.get('TEST_EXISTS'):
        sys.exit(1)
elif args[:2] == ['release', 'create']:
    created.touch()
elif args[:2] == ['release', 'upload'] and os.environ.get('TEST_UPLOAD_FAIL'):
    sys.exit(1)
""")
        gh.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.root / 'bin'}:{os.environ['PATH']}",
                        APK_DIR=str(self.root / "apks"), TEST_LOG=str(self.log),
                        GH_REPO="test-owner/test-repo", RELEASE_TAG="test-games")

    def run_upload(self, script=SCRIPT, *args):
        result = subprocess.run(["bash", str(script), *args], env=self.env,
                                text=True, capture_output=True)
        calls = [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []
        return result, calls

    def test_no_apks_does_not_create_or_modify_release(self):
        result, calls = self.run_upload()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [])

    def test_new_release_is_published_only_after_all_uploads(self):
        for name in ["RaylibBattleCity.apk", "RaylibExample2026.apk"]:
            (self.root / "apks" / name).write_bytes(b"test apk")
        result, calls = self.run_upload()
        self.assertEqual(result.returncode, 0, result.stderr)
        operations = [call[1] for call in calls]
        self.assertEqual(operations, ["view", "create", "upload", "upload", "view", "edit"])
        self.assertIn("--draft", calls[1])
        self.assertIn("--draft=false", calls[-1])

    def test_failed_upload_leaves_new_release_unpublished(self):
        (self.root / "apks/RaylibBattleCity.apk").write_bytes(b"test apk")
        self.env["TEST_UPLOAD_FAIL"] = "1"
        result, calls = self.run_upload()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("edit", [call[1] for call in calls])

    def test_existing_release_only_replaces_selected_assets(self):
        (self.root / "apks/RaylibBattleCity.apk").write_bytes(b"test apk")
        self.env["TEST_EXISTS"] = "1"
        result, calls = self.run_upload()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call[1] for call in calls], ["view", "upload", "view"])
        self.assertIn("--clobber", calls[1])
        self.assertEqual(Path(calls[1][3]).name, "RaylibBattleCity.apk")

    def test_local_build_is_uploaded_under_project_name(self):
        scripts = self.root / "scripts"
        scripts.mkdir()
        shutil.copy(SCRIPT, scripts / SCRIPT.name)
        project = self.root / "RaylibBattleCity"
        build = project / "app/build/outputs/apk/debug"
        build.mkdir(parents=True)
        (project / "gradlew").touch()
        (build / "app-debug.apk").write_bytes(b"test apk")
        del self.env["APK_DIR"]
        result, calls = self.run_upload(scripts / SCRIPT.name, project.name)
        self.assertEqual(result.returncode, 0, result.stderr)
        upload = next(call for call in calls if call[1] == "upload")
        self.assertEqual(Path(upload[3]).name, "RaylibBattleCity.apk")


if __name__ == "__main__":
    unittest.main()
