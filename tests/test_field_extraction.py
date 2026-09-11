"""Regression checks for source-profile and insertion-aware extraction."""

from pathlib import Path
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.extract_lite_xl_fields import extract, source_info


def main() -> None:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        (root / "plugins").mkdir()
        (root / "libraries" / "widget" / "examples").mkdir(parents=True)
        (root / "plugins" / "autocomplete.lua").write_text(
            'config_spec = { name = "Demo", { label = "Visible", description = "Shown", values = {{ "One", "one" }} } }\n'
            'local menu = { { text = "Open", command = "demo:open" } }\n'
            'ContextMenu:register("demo", menu)\n'
            'local data = { label = "Not UI" }\n'
            'core.command_view:enter("Open " .. name)\n', encoding="utf-8")
        (root / "libraries" / "widget" / "numberbox.lua").write_text(
            'local Button = require "libraries.widget.button"\n'
            'Button(nil, "-")\nButton(nil, "+")\n', encoding="utf-8")
        (root / "libraries" / "widget" / "examples" / "demo.lua").write_text(
            'Label(widget, "Example only")\n', encoding="utf-8")
        rows = extract(root, None)
        literals = {row["literal"] for row in rows}
        assert "Visible" in literals and "Shown" in literals and "One" in literals
        assert "Open" in literals and "Not UI" not in literals and "Example only" not in literals
        menu = next(row for row in rows if row["literal"] == "Open")
        assert menu["kind"] == "menu-text" and menu["callback_sensitive"] is True
        assert menu["catalog_placement"] == "missing"
        dynamic = next(row for row in rows if row["kind"] == "command-view")
        assert dynamic["status"] == "dynamic" and dynamic["resolution"] == "expression"
        plus = next(row for row in rows if row["literal"] == "+")
        assert plus["status"] == "non_ui"
        plugin_rows = [row for row in rows if row["source_module"] == "plugins/autocomplete.lua"]
        assert plugin_rows and all(row["source_section"] == "native.plugin.autocomplete" for row in plugin_rows)
        # Core settings use settings.add, not config_spec.  Nested callback
        # data and the second column of selection values are not display text.
        (root / "plugins" / "settings.lua").write_text('''
local NoteBook = require "libraries.widget.notebook"
local MessageBox = require "libraries.widget.messagebox"
settings.add("General", {
  { label = "Font", description = "UI " .. "font",
    values = {{ "System font", "font-id" }},
    on_apply = function() local data = {label = "Callback data"} end },
  { label = "After callback", description = "Second" },
})
local notebook = NoteBook(nil)
notebook:add_pane("internal-pane", "Pane title")
MessageBox.info("Info", {"First\\n" .. "Second"})
renderer.draw_text(style.font, "Draw Only", 0, 0, style.text)
''', encoding="utf-8")
        rows = extract(root, None)
        values = {item["literal"] for item in rows}
        assert {"Font", "UI font", "After callback", "System font", "Pane title", "First\nSecond"} <= values
        assert not {"Callback data", "font-id", "internal-pane", "Draw Only"} & values
        font = next(item for item in rows if item["literal"] == "Font")
        assert font["field_path"] == "settings.add[General].options[1].label"
        assert font["catalog_file"] == "catalog/plugin_settings.lua"
        # Buttons from a local options table, preserving callback literals.
        (root / "plugins" / "autoreload.lua").write_text('''
local function dialog()
  local options = {{text = "Yes"}, {text = "No"}}
  core.nag_view:show("Title", "Message", options, function(item)
    if item.text == "callback-only" then return end
  end)
end
''', encoding="utf-8")
        rows = extract(root, None)
        buttons = [item for item in rows if item["kind"] == "dialog-button"]
        assert {item["literal"] for item in buttons} == {"Yes", "No"}
        assert all(item["callback_sensitive"] for item in buttons)
        assert not any(item["literal"] == "callback-only" for item in rows)
        # A native language plugin may have real settings, while its syntax
        # definitions remain actual data.
        (root / "plugins" / "language_php.lua").write_text('''
syntax.add {name = "PHP Syntax", symbols = { label = "keyword" }}
config.plugins.php = {config_spec = {{label = "SQL Strings"}}}
''', encoding="utf-8")
        rows = extract(root, None)
        assert any(item["literal"] == "SQL Strings" for item in rows)
        assert not any(item["literal"] in {"PHP Syntax", "keyword"} for item in rows)
        # A user extension with the same UI calls is outside the native set.
        (root / "plugins" / "thirdparty.lua").write_text(
            'config_spec = { { label = "Third Party" } }\n', encoding="utf-8")
        assert all(row["literal"] != "Third Party" for row in extract(root, None))
    assert source_info("core/commands/core.lua")[1] == "catalog/commandview.lua"
    assert source_info("plugins/contextmenu.lua")[1] == "catalog/contextmenu.lua"
    with tempfile.TemporaryDirectory() as directory:
        plugin_root = Path(directory) / "plugins"
        plugin_root.mkdir()
        (plugin_root / "autocomplete.lua").write_text('config_spec = {{label = "Native"}}', encoding="utf-8")
        (plugin_root / "thirdparty.lua").write_text('config_spec = {{label = "External"}}', encoding="utf-8")
        rows = extract(plugin_root, None)
        assert any(item["literal"] == "Native" for item in rows)
        assert not any(item["literal"] == "External" for item in rows)
    print("Field extraction checks passed")


if __name__ == "__main__":
    main()
