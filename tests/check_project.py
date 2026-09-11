"""Dependency-free structural checks for the Lite XL localization package."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "plugins" / "l10n_zh_cn"


def check_manifest() -> None:
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    assert isinstance(manifest.get("addons"), list) and len(manifest["addons"]) == 1
    addon = manifest["addons"][0]
    assert addon["id"] == "l10n_zh_cn"
    assert addon["type"] == "plugin"
    assert addon["mod_version"] == "3"
    assert addon["path"] == "plugins/l10n_zh_cn"
    assert re.fullmatch(r"\d+\.\d+\.\d+", addon["version"])


def check_lua_sources() -> None:
    required = ["init.lua", "locale.lua", "hooks.lua", "catalog.lua"]
    for name in required:
        text = (PLUGIN / name).read_text(encoding="utf-8")
        assert text, f"empty Lua source: {name}"
    init = (PLUGIN / "init.lua").read_text(encoding="utf-8")
    hooks = (PLUGIN / "hooks.lua").read_text(encoding="utf-8")
    locale = (PLUGIN / "locale.lua").read_text(encoding="utf-8")
    native = (PLUGIN / "catalog.lua").read_text(encoding="utf-8")
    assert "-- mod-version:3" in init
    assert init.index("-- priority:1") < init.index("-- mod-version:3")
    assert "config.plugins.l10n_zh_cn" in init
    assert "renderer.font.group" in init
    for symbol in ("prettify_name", "ContextMenu", "NagView", "CommandView"):
        assert symbol in hooks
    assert "function catalog.translate" in locale
    assert "function catalog.set_locale" in locale
    assert "catalog.exact" in locale and "catalog.patterns" in locale
    assert 'runtime.commands' in locale and 'runtime.patterns' in locale
    assert (PLUGIN / "runtime" / "commands.lua").is_file()
    assert (PLUGIN / "runtime" / "patterns.lua").is_file()
    assert (ROOT / "tools" / "lua_source.py").is_file()
    extractor = (ROOT / "tools" / "extract_lite_xl_fields.py").read_text(encoding="utf-8")
    assert "source_section" in extractor
    assert "field_path" in extractor
    assert '"catalog/"' in native and 'by_source' in native
    catalog_files = sorted((PLUGIN / "catalog").glob("*.lua"))
    assert len(catalog_files) >= 9
    # Every source file declares one source owner and a category table.  Keep
    # duplicate detection local to each file; identical labels may legitimately
    # occur in separate native modules and are merged by the loader.
    for path in catalog_files:
        text = path.read_text(encoding="utf-8")
        assert re.search(r'local M = \{ source = "[^"]+"', text), path.name
        for match in re.finditer(r'^M\.categories\.(\w+)\s*=\s*\{', text, re.MULTILINE):
            stop_match = re.search(r'^M\.categories\.\w+\s*=\s*\{', text[match.end():], re.MULTILINE)
            stop = match.end() + stop_match.start() if stop_match else len(text)
            body = text[match.end():stop]
            keys = re.findall(r'^\s*(?:\["((?:\\.|[^"\\])*)"\]|([A-Za-z_][A-Za-z0-9_]*))\s*=\s*([^,]+),?\s*$', body, re.MULTILINE)
            flattened = [a or b for a, b, _ in keys if (a or b)]
            assert len(flattened) == len(set(flattened)), f"duplicate key in {path.name}"
            assert all(value.strip() not in ("nil", "\"\"") for _, _, value in keys), f"empty value in {path.name}"
    assert (PLUGIN / "fonts" / "NotoSansCJKsc-Regular.otf").stat().st_size > 1000000
    assert (ROOT / "licenses" / "OFL-1.1.txt").stat().st_size > 1000
    assert not (ROOT / ".field-extraction-cache").exists(), "generated field cache must stay outside the project"
    assert not (ROOT / "plugins" / "l10n_zh_cn.lua").exists(), "keep the lpm directory plugin self-contained"
    assert not (ROOT / "--help").exists(), "command output must not be stored in the project"


if __name__ == "__main__":
    check_manifest()
    check_lua_sources()
    print("Lite XL localization package checks passed")
