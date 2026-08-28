from __future__ import annotations

import json
import plistlib
import re
import unittest
import xml.etree.ElementTree as ElementTree
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
STRINGS_ENTRY = re.compile(r'^"([^"]+)"\s*=\s*"([^"]*)";$', re.MULTILINE)


def _strings(relative: str) -> tuple[dict[str, str], int]:
    text = (ROOT / relative).read_text(encoding="utf-8")
    entries = STRINGS_ENTRY.findall(text)
    return dict(entries), len(entries)


class NativeShellLocalizationContractTest(unittest.TestCase):
    def test_macos_menu_has_complete_english_and_portuguese_catalogs(self) -> None:
        xib = ElementTree.parse(
            ROOT / "macos/Runner/Base.lproj/MainMenu.xib"
        ).getroot()
        expected_keys = {
            f'{element.attrib["id"]}.title'
            for element in xib.iter()
            if element.get("id") and element.get("title")
        }

        english, english_count = _strings(
            "macos/Runner/en.lproj/MainMenu.strings"
        )
        portuguese, portuguese_count = _strings(
            "macos/Runner/pt.lproj/MainMenu.strings"
        )

        self.assertEqual(english_count, len(english), "duplicate English menu key")
        self.assertEqual(
            portuguese_count, len(portuguese), "duplicate Portuguese menu key"
        )
        self.assertEqual(set(english), expected_keys)
        self.assertEqual(set(portuguese), expected_keys)
        self.assertTrue(all(english.values()))
        self.assertTrue(all(portuguese.values()))
        self.assertFalse(any("APP_NAME" in value for value in english.values()))
        self.assertFalse(any("APP_NAME" in value for value in portuguese.values()))
        self.assertGreaterEqual(
            sum(english[key] != portuguese[key] for key in expected_keys),
            55,
        )
        self.assertEqual(portuguese["5kV-Vb-QxS.title"], "Sobre o Turing Lab")
        self.assertEqual(portuguese["4sb-4s-VLi.title"], "Encerrar Turing Lab")
        self.assertEqual(portuguese["EPT-qC-fAb.title"], "Ajuda")

    def test_macos_project_packages_both_menu_localizations(self) -> None:
        project = (
            ROOT / "macos/Runner.xcodeproj/project.pbxproj"
        ).read_text(encoding="utf-8")

        self.assertIn("path = en.lproj/MainMenu.strings", project)
        self.assertIn("path = pt.lproj/MainMenu.strings", project)
        self.assertRegex(project, r"knownRegions = \(\s*en,\s*pt,\s*Base,")
        variant_group = project.split("/* Begin PBXVariantGroup section */", 1)[1]
        variant_group = variant_group.split("/* End PBXVariantGroup section */", 1)[0]
        self.assertIn("A34500012044000100000001 /* en */", variant_group)
        self.assertIn("A34500022044000100000001 /* pt */", variant_group)

    def test_shell_display_names_follow_branding_contract(self) -> None:
        android = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(
            encoding="utf-8"
        )
        ios = plistlib.loads((ROOT / "ios/Runner/Info.plist").read_bytes())
        macos = plistlib.loads((ROOT / "macos/Runner/Info.plist").read_bytes())
        windows = (ROOT / "windows/runner/Runner.rc").read_text(encoding="utf-8")
        linux = (ROOT / "linux/runner/my_application.cc").read_text(
            encoding="utf-8"
        )
        web = json.loads((ROOT / "web/manifest.json").read_text(encoding="utf-8"))

        self.assertIn('android:label="Turing Lab"', android)
        self.assertEqual(ios["CFBundleDisplayName"], "Turing Lab")
        self.assertEqual(ios["CFBundleName"], "Turing Lab")
        self.assertEqual(macos["CFBundleDisplayName"], "Turing Lab")
        self.assertIn('VALUE "FileDescription", "Turing Lab"', windows)
        self.assertIn('VALUE "ProductName", "Turing Lab"', windows)
        self.assertEqual(linux.count('set_title(window, "Turing Lab")'), 1)
        self.assertIn('set_title(header_bar, "Turing Lab")', linux)
        self.assertEqual(web["short_name"], "Turing Lab")
        self.assertTrue(web["name"].startswith("Turing Lab"))


if __name__ == "__main__":
    unittest.main()
