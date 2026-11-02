import json
import subprocess
import unittest
from unittest.mock import patch

import generate_site


def asset(name, state="uploaded"):
    return {"name": name, "size": 14 * 1024 * 1024, "state": state,
            "browser_download_url": f"https://github.com/owner/repo/releases/download/android-games/{name}"}


class GenerateSiteTests(unittest.TestCase):
    def response(self, value):
        return subprocess.CompletedProcess([], 0, stdout=json.dumps(value))

    @patch("generate_site.subprocess.run")
    def test_all_pages_are_included_and_non_games_are_filtered(self, run):
        games = [asset(f"RaylibGame{i:03}2026.apk") for i in range(151)]
        pages = [games[:100], games[100:] + [asset("RaylibBattleCity.apk"),
                 asset("RaylibCoreBasicWindow.apk"), asset("checksums.txt"),
                 asset("RaylibIncomplete2026.apk", "starter")]]
        run.side_effect = [self.response({"id": 7, "draft": False}), self.response(pages)]
        entries = generate_site.list_apks()
        self.assertEqual(len(entries), 152)
        html = generate_site.build_html(entries)
        self.assertEqual(html.count("Download APK"), 152)
        self.assertIn(games[-1]["browser_download_url"], html)
        self.assertNotIn("RaylibCoreBasicWindow", html)
        self.assertNotIn("RaylibIncomplete", html)
        self.assertIn("--paginate", run.call_args.args[0])
        self.assertIn("--slurp", run.call_args.args[0])

    @patch("generate_site.subprocess.run")
    def test_draft_release_cannot_replace_public_page(self, run):
        run.return_value = self.response({"id": 7, "draft": True})
        with self.assertRaisesRegex(RuntimeError, "Publish the release"):
            generate_site.list_apks()

    @patch("generate_site.subprocess.run")
    def test_empty_release_cannot_replace_public_page(self, run):
        run.side_effect = [self.response({"id": 7, "draft": False}), self.response([[]])]
        with self.assertRaisesRegex(RuntimeError, "empty page"):
            generate_site.list_apks()

    @patch("generate_site.subprocess.run")
    def test_api_failure_is_not_treated_as_empty_inventory(self, run):
        run.side_effect = subprocess.CalledProcessError(1, "gh")
        with self.assertRaises(subprocess.CalledProcessError):
            generate_site.list_apks()


if __name__ == "__main__":
    unittest.main()
