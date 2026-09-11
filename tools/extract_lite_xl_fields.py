"""Inventory native Lite XL UI insertion points.

The extractor is deliberately source driven.  A text is reported only when a
known native file uses a known UI API or a known table shape to insert it.  It
does not search arbitrary English strings and it never executes Lua.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Iterable

try:
    from .lua_source import Call, Field, Source
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from tools.lua_source import Call, Field, Source


# Lite XL 2.1.8's bundled plugin set. Unknown plugin names are ignored when
# the field-extraction command is pointed at a user plugin directory.
NATIVE_PLUGINS = {
    "autocomplete", "autoreload", "contextmenu", "detectindent", "drawwhitespace",
    "lineguide", "linewrapping", "macro", "open_ext", "projectsearch", "quote",
    "reflow", "scale", "settings", "tabularize", "toolbarview", "treeview",
    "trimwhitespace", "workspace",
}


def profile_for(relative: str) -> dict[str, str] | None:
    """Return the source profile for an installed native file."""
    rel = relative.replace("\\", "/")
    parts = set(rel.split("/"))
    if {"examples", "docs"} & parts:
        return None
    if rel.startswith("core/commands/") or rel == "core/commandview.lua":
        return {"source": rel, "section": "core.commandview", "catalog": "catalog/commandview.lua"}
    if rel in {"core/contextmenu.lua", "plugins/contextmenu.lua"}:
        return {"source": rel, "section": "native.contextmenu", "catalog": "catalog/contextmenu.lua"}
    if rel in {"core/nagview.lua", "core/init.lua", "libraries/widget/dialog.lua",
               "libraries/widget/messagebox.lua", "libraries/widget/inputdialog.lua",
               "libraries/widget/fontdialog.lua", "libraries/widget/colorpickerdialog.lua"}:
        return {"source": rel, "section": "native.dialogs", "catalog": "catalog/dialogs.lua"}
    if rel in {"core/statusview.lua", "core/commands/statusbar.lua", "core/logview.lua"}:
        return {"source": rel, "section": "native.status", "catalog": "catalog/status.lua"}
    if rel == "core/emptyview.lua":
        return {"source": rel, "section": "native.welcome", "catalog": "catalog/welcome.lua"}
    if rel.startswith("core/"):
        return {"source": rel, "section": "native.core", "catalog": "catalog/dialogs.lua"}
    if rel == "plugins/settings.lua":
        return {"source": rel, "section": "native.settings", "catalog": "catalog/plugin_settings.lua"}
    if rel.startswith("libraries/widget/"):
        return {"source": rel, "section": "native.widget", "catalog": "catalog/widget.lua"}
    if rel.startswith("plugins/"):
        stem = Path(rel).stem
        if not stem.startswith("language_") and stem not in NATIVE_PLUGINS:
            return None
        return {"source": rel, "section": f"native.plugin.{stem}", "catalog": f"catalog/plugin_{stem}.lua"}
    return None


def source_info(relative: str) -> tuple[str, str]:
    profile = profile_for(relative)
    return (str(profile["source"]), str(profile["catalog"])) if profile else (relative.replace("\\", "/"), "")


def catalog_keys(catalog_root: Path | None) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    if catalog_root is None or not catalog_root.is_dir():
        return result
    for path in catalog_root.glob("*.lua"):
        source = Source(path.read_text(encoding="utf-8"))
        ts = source.tokens
        for i in range(len(ts) - 6):
            if ([t.value for t in ts[i:i + 4]] == ["M", ".", "categories", "."]
                    and ts[i + 5].value == "=" and ts[i + 6].value == "{"
                    and i + 6 in source.pairs):
                for field in source.table_fields(i + 6, source.pairs[i + 6] + 1):
                    if isinstance(field.key, str) and source.literal_concat(field.value_start, field.value_end) is not None:
                        result.setdefault(field.key, []).append(path.name)
    return result


def static_value(source: Source, bounds: tuple[int, int]) -> str | None:
    return source.literal_concat(*bounds)


def is_non_ui_literal(kind: str, literal: str) -> bool:
    """Return true for static values that are data rather than presentation.

    Selection tables commonly use symbols and numeric percentages as their
    display labels.  They are valid UI values, but adding them to a language
    catalogue would only duplicate the original value and make the report
    report look untranslated.  Keep this rule deliberately narrow: it applies
    only to setting choices, where the source structure identifies the value
    as option data.
    """
    # Standalone +/- controls are widget data regardless of the constructor
    # that owns them.  Percentages are option labels and are only ignored when
    # extracted from a setting choice table.
    if literal in {"+", "-"}:
        return True
    if kind != "setting-choice":
        return False
    return bool(re.fullmatch(r"\d+(?:\.\d+)?%", literal))


def row(source: Source, profile: dict[str, str], catalog: dict[str, list[str]],
        kind: str, insertion: str, field_path: str, bounds: tuple[int, int],
        *, callback_sensitive: bool = False, catalog_file: str | None = None) -> dict[str, object]:
    expression = source.expression(*bounds).strip()
    literal = static_value(source, bounds)
    strings = source.strings(*bounds)
    if literal is None:
        status = "dynamic"
    elif not literal or literal.startswith("#") or is_non_ui_literal(kind, literal):
        status = "non_ui"
    elif literal in catalog:
        status = "translated"
    else:
        status = "untranslated"
    target_file = catalog_file or profile["catalog"]
    matches = catalog.get(literal, []) if literal is not None else []
    placement = "dynamic" if literal is None else ("missing" if not matches else ("target" if Path(target_file).name in matches else "other"))
    return {
        "source_module": profile["source"],
        "source_section": profile["section"],
        "catalog_file": catalog_file or profile["catalog"],
        "line": source.tokens[bounds[0]].line if bounds[0] < len(source.tokens) else 1,
        "kind": kind,
        "insertion": insertion,
        "owner_api": insertion,
        "field_path": field_path,
        "expression": expression,
        "literal": literal,
        "literals": strings,
        "dynamic": literal is None,
        "status": status,
        "catalog_matches": matches,
        "catalog_placement": placement,
        "callback_sensitive": callback_sensitive,
    }


def is_table(source: Source, bounds: tuple[int, int]) -> bool:
    a, b = bounds
    return a < b and source.tokens[a].value == "{" and source.pairs.get(a) == b - 1


def lhs_before(source: Source, position: int) -> str:
    """Read an assignment target immediately before its equals sign."""
    ts = source.tokens
    end = position
    i = end - 1
    if i < 0:
        return ""
    if ts[i].value == "]":
        i = source.pairs[i] - 1
    if i < 0 or ts[i].kind != "identifier":
        return ""
    while i >= 2 and ts[i - 1].value == "." and ts[i - 2].kind == "identifier":
        i -= 2
    return "".join(t.value for t in ts[i:end])


class Extractor:
    def __init__(self, source: Source, profile: dict[str, str], catalog: dict[str, list[str]]):
        self.source, self.profile, self.catalog = source, profile, catalog
        self.result: list[dict[str, object]] = []
        self.calls = source.calls()
        self.types: dict[str, str] = {}
        self.bindings: list[tuple[str, int, tuple[int, int]]] = []
        ts = source.tokens
        for i, token in enumerate(ts[:-1]):
            if token.value == "=" and ts[i + 1].value == "{" and i + 1 in source.pairs:
                self.bindings.append((lhs_before(source, i), i, (i + 1, source.pairs[i + 1] + 1)))
        # Resolve import aliases and the UI objects built with them.  These are
        # type hints from source declarations, not guesses based on names.
        for call in self.calls:
            if call.start > 0 and ts[call.start - 1].value == "=":
                lhs = lhs_before(source, call.start - 1)
                if call.name == "require" and call.args:
                    module = source.literal_concat(*call.args[0])
                    if module:
                        self.types[lhs] = module
                elif call.name in self.types:
                    self.types[lhs] = self.types[call.name]
                elif call.name.endswith(":extend") and call.name[:-7] in self.types:
                    self.types[lhs] = self.types[call.name[:-7]]
                elif call.name in {"renderer.font.load", "renderer.font.group"}:
                    pass
        rel = profile["source"]
        if rel.startswith("libraries/widget/"):
            self.types["self"] = rel[:-4].replace("/", ".")
        elif rel == "core/statusview.lua":
            self.types["self"] = "core.statusview"
        elif rel == "core/contextmenu.lua":
            self.types["self"] = "core.contextmenu"

    def canonical(self, name: str) -> str:
        # Keep method punctuation, as dot/colon have different argument slots.
        for alias in sorted(self.types, key=len, reverse=True):
            if name == alias:
                return self.types[alias]
            if name.startswith(alias + ".") or name.startswith(alias + ":"):
                return self.types[alias] + name[len(alias):]
        return name

    def scope(self, position: int) -> tuple[int, ...]:
        return tuple(start for start, end in sorted(self.source.blocks.items()) if start < position < end)

    def tables(self, bounds: tuple[int, int], at: int) -> list[tuple[str, tuple[int, int]]]:
        if is_table(self.source, bounds):
            return [("", bounds)]
        name = self.source.expression(*bounds).strip()
        if not re.fullmatch(r"[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*", name):
            return []
        target_scope = self.scope(at)
        visible = [(lhs, pos, table) for lhs, pos, table in self.bindings if pos < at
                   and (lhs == name or lhs.startswith(name + "["))
                   and target_scope[:len(self.scope(pos))] == self.scope(pos)]
        base = [item for item in visible if item[0] == name]
        if not base:
            return []
        last = base[-1]
        result = [(name, last[2])]
        result.extend((lhs, table) for lhs, pos, table in visible if pos > last[1] and lhs != name)
        for call in self.calls:
            if last[1] < call.start < at and call.name == "table.insert" and len(call.args) >= 2:
                if self.source.expression(*call.args[0]).strip() == name and is_table(self.source, call.args[-1]):
                    result.append((name + "[append]", call.args[-1]))
        return result

    def emit(self, kind: str, api: str, field_path: str, bounds: tuple[int, int],
             *, target: str | None = None, sensitive: bool = False, **metadata: object) -> None:
        item = row(self.source, self.profile, self.catalog, kind, api, field_path,
                   bounds, catalog_file=target, callback_sensitive=sensitive)
        item.update(metadata)
        item["resolution"] = "static" if item["literal"] is not None else "expression"
        if not item["literals"] and item["dynamic"]:
            item["resolution"] = "unresolved"
        self.result.append(item)

    def fields(self, bounds: tuple[int, int]) -> dict[object, Field]:
        return {f.key: f for f in self.source.table_fields(*bounds)} if is_table(self.source, bounds) else {}

    def settings(self, bounds: tuple[int, int], api: str, base: str, at: int, heading: bool = False) -> None:
        tables = self.tables(bounds, at)
        if not tables:
            self.emit("settings-reference", api, base, bounds)
            self.result[-1]["status"] = "unresolved"
            self.result[-1]["resolution"] = "unresolved"
        for origin, table in tables:
            fields = self.fields(table)
            if heading and "name" in fields:
                f = fields["name"]
                self.emit("setting-section", api, base + ".name", (f.value_start, f.value_end))
            for index, field in fields.items():
                if not isinstance(index, int):
                    continue
                option = self.fields((field.value_start, field.value_end))
                prefix = f"{base}[{index}]"
                for key in ("label", "description"):
                    if key in option:
                        f = option[key]
                        self.emit("setting-" + key, api, prefix + "." + key,
                                  (f.value_start, f.value_end), declaration=origin or base)
                if "values" in option:
                    f = option["values"]
                    for choice_index, choice in self.fields((f.value_start, f.value_end)).items():
                        label = self.fields((choice.value_start, choice.value_end)).get(1)
                        if label:
                            self.emit("setting-choice", api, f"{prefix}.values[{choice_index}][1]",
                                      (label.value_start, label.value_end), sensitive=True)

    def items(self, bounds: tuple[int, int], api: str, base: str, at: int, kind: str, target: str) -> None:
        tables = self.tables(bounds, at)
        if not tables:
            self.emit(kind + "-reference", api, base, bounds, target=target)
        for origin, table in tables:
            fields = self.fields(table)
            entries = [(origin, table)] if "text" in fields else [
                (f"{base}[{key}]", (f.value_start, f.value_end)) for key, f in fields.items() if isinstance(key, int)]
            for prefix, entry in entries:
                text = self.fields(entry).get("text")
                if text:
                    self.emit(kind, api, prefix + ".text", (text.value_start, text.value_end),
                              target=target, sensitive=True, declaration=origin or base)

    def message(self, bounds: tuple[int, int], api: str, path: str) -> None:
        if is_table(self.source, bounds):
            for key, f in self.fields(bounds).items():
                if isinstance(key, int) and self.source.strings(f.value_start, f.value_end):
                    self.emit("dialog-message", api, f"{path}[{key}]", (f.value_start, f.value_end), target="catalog/dialogs.lua")
        else:
            self.emit("dialog-message", api, path, bounds, target="catalog/dialogs.lua")

    def run(self) -> list[dict[str, object]]:
        ts = self.source.tokens
        rel = self.profile["source"]
        # Explicit configuration schema, including bundled language plugins
        # that expose options.  Their syntax/token definition tables are ignored.
        for i in range(len(ts) - 2):
            if ts[i].kind == "identifier" and ts[i].value == "config_spec" and ts[i + 1].value == "=" and ts[i + 2].value == "{":
                self.settings((i + 2, self.source.pairs[i + 2] + 1), "config_spec", "config_spec", i, heading=True)
        if Path(rel).name.startswith("language_"):
            return self.result
        widget_constructors = {
            "libraries.widget.label": (1, "widget-label", "catalog/widget.lua"), "libraries.widget.button": (1, "widget-label", "catalog/widget.lua"),
            "libraries.widget.checkbox": (1, "widget-label", "catalog/widget.lua"), "libraries.widget.toggle": (1, "widget-label", "catalog/widget.lua"),
            "libraries.widget.selectbox": (1, "widget-label", "catalog/widget.lua"), "libraries.widget.textbox": (2, "placeholder", "catalog/widget.lua"),
            "libraries.widget.dialog": (0, "dialog-title", "catalog/dialogs.lua"), "libraries.widget.inputdialog": (0, "dialog-title", "catalog/dialogs.lua"),
        }
        widget_methods = {"set_label": (0, "widget-label"), "set_tooltip": (0, "tooltip"),
                          "set_placeholder": (0, "placeholder"), "set_title": (0, "dialog-title"),
                          "add_column": (0, "column-label"), "add_pane": (1, "pane-label"),
                          "set_pane_label": (1, "pane-label"), "add_button": (0, "dialog-button")}
        for call in self.calls:
            name = self.canonical(call.name)
            args = call.args
            path = call.name
            if name in {"settings.add", "plugins.settings.add"} and len(args) > 1:
                section = static_value(self.source, args[0]) or "?"
                self.emit("setting-section", "settings.add", f"settings.add[{section}].section", args[0], target="catalog/sections.lua")
                self.settings(args[1], "settings.add", f"settings.add[{section}].options", call.start)
            if name in {"core.command_view:enter", "command_view:enter"} and args:
                self.emit("command-view", "CommandView:enter", path + ".label", args[0], target="catalog/commandview.lua")
            if name in {"core.nag_view:show", "nag_view:show"}:
                if args:
                    self.emit("dialog-title", "NagView:show", path + ".title", args[0], target="catalog/dialogs.lua")
                if len(args) > 1:
                    self.message(args[1], "NagView:show", path + ".message")
                if len(args) > 2:
                    self.items(args[2], "NagView:show", path + ".options", call.start, "dialog-button", "catalog/dialogs.lua")
            if name.startswith("libraries.widget.messagebox.") and name.rsplit(".", 1)[1] in {"alert", "info", "warning", "error"}:
                if args:
                    self.emit("dialog-title", "MessageBox." + name.rsplit(".", 1)[1], path + ".title", args[0], target="catalog/dialogs.lua")
                if len(args) > 1:
                    self.message(args[1], "MessageBox." + name.rsplit(".", 1)[1], path + ".message")
            if name in {"core.status_view:show_message", "status_view:show_message"} and len(args) > 2:
                self.emit("status-text", "StatusView:show_message", path + ".text", args[2], target="catalog/status.lua")
            if name in {"core.status_view:show_tooltip", "status_view:show_tooltip"} and args:
                self.emit("status-tooltip", "StatusView:show_tooltip", path + ".text", args[0], target="catalog/status.lua")
            if name in {"core.statusview:add_item", "core.status_view:add_item"} and args:
                fields = self.fields(args[0])
                if "tooltip" in fields:
                    f = fields["tooltip"]
                    self.emit("status-tooltip", "StatusView:add_item", path + ".options.tooltip", (f.value_start, f.value_end), target="catalog/status.lua")
                if "get_item" in fields:
                    f = fields["get_item"]
                    self.emit("status-provider", "StatusView:add_item", path + ".options.get_item", (f.value_start, f.value_end), target="catalog/status.lua", provider=True)
                    self.result[-1]["literals"] = []  # callback body contains code and actual data
                    self.result[-1]["resolution"] = "unresolved"
            if name in {"core.contextmenu:register", "plugins.contextmenu:register", "ContextMenu:register", "menu:register"} and len(args) > 1:
                self.items(args[1], "ContextMenu:register", path + ".items", call.start, "menu-text", "catalog/contextmenu.lua")
            if name in widget_constructors:
                index, kind, target = widget_constructors[name]
                if len(args) > index:
                    self.emit(kind, name, path + f".arg[{index + 1}]", args[index], target=target)
            if name.endswith(".super.new"):
                base = name[:-10]
                if base in widget_constructors:
                    index, kind, target = widget_constructors[base]
                    if len(args) > index + 1:
                        self.emit(kind, base + ".super.new", path + f".arg[{index + 2}]", args[index + 1], target=target)
            if name.startswith("libraries.widget.") and ":" in name:
                method = name.rsplit(":", 1)[1]
                if method in widget_methods:
                    index, kind = widget_methods[method]
                    if len(args) > index:
                        target = "catalog/dialogs.lua" if kind in {"dialog-title", "dialog-button"} else "catalog/widget.lua"
                        self.emit(kind, name, path + f".arg[{index + 1}]", args[index], target=target)
        if rel == "core/emptyview.lua":
            for lhs, pos, table in self.bindings:
                if lhs == "lines":
                    for key, f in self.fields(table).items():
                        fmt = self.fields((f.value_start, f.value_end)).get("fmt")
                        if fmt:
                            self.emit("welcome-template", "EmptyView.lines", f"lines[{key}].fmt", (fmt.value_start, fmt.value_end))
            for i, token in enumerate(ts):
                if (token.value == "function" and i + 3 < len(ts)
                        and ts[i + 1].value == "EmptyView" and ts[i + 2].value == ":"
                        and ts[i + 3].value == "get_name"):
                    end = self.source.blocks[i]
                    for j in range(i + 1, end):
                        if ts[j].value == "return" and j + 1 < end:
                            self.emit("welcome-title", "EmptyView:get_name", "EmptyView:get_name.return", (j + 1, end))
                            break
        unique = {}
        for item in self.result:
            key = (item["source_module"], item["insertion"], item["field_path"], item["line"], item["expression"])
            unique.setdefault(key, item)
        return list(unique.values())


def extract_file(path: Path, root: Path, catalog: dict[str, list[str]], prefix: str = "") -> list[dict[str, object]]:
    relative = prefix + path.relative_to(root).as_posix()
    profile = profile_for(relative)
    if profile is None:
        return []
    source = Source(path.read_text(encoding="utf-8"))
    return Extractor(source, profile, catalog).run()

def extract(root: Path, catalog_root: Path | None = None) -> list[dict[str, object]]:
    if not root.is_dir():
        raise ValueError(f"source directory does not exist: {root}")
    data_root = root / "data" if (root / "data").is_dir() else root
    catalog = catalog_keys(catalog_root)
    prefix = "plugins/" if data_root.name == "plugins" else ""
    # A user plugin directory contains one subdirectory per extension.  Its
    # files are not the Lite XL distribution sources and must not be treated
    # as native merely because their parent folder is named ``plugins``.
    paths = sorted(data_root.glob("*.lua")) if data_root.name == "plugins" else sorted(data_root.rglob("*.lua"))
    return [item for path in paths for item in extract_file(path, data_root, catalog, prefix)]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--json", type=Path)
    parser.add_argument("--catalog", type=Path)
    parser.add_argument(
        "--fail-on-missing",
        action="store_true",
        help="exit with status 1 when a static UI literal is missing from the catalogue",
    )
    args = parser.parse_args()
    rows = extract(args.source, args.catalog)
    summary: dict[str, dict[str, int]] = {}
    by_source: dict[str, dict[str, int]] = {}
    for item in rows:
        for target, key in ((summary, str(item["kind"])), (by_source, str(item["source_section"]))):
            bucket = target.setdefault(key, {"total": 0, "translated": 0, "dynamic": 0, "non_ui": 0, "untranslated": 0, "unresolved": 0})
            bucket["total"] += 1
            bucket[str(item["status"])] += 1
    payload = {"source": str(args.source), "count": len(rows), "summary": summary, "by_source": by_source, "items": rows}
    text = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    if args.json:
        args.json.write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    if args.fail_on_missing:
        missing = [item for item in rows if item["status"] == "untranslated"]
        if missing:
            print(f"catalog-sync-check: {len(missing)} untranslated static UI field(s)", file=sys.stderr)
            for item in missing:
                print(
                    f"  {item['source_module']}:{item['line']} "
                    f"{item['field_path']}: {item['literal']!r}",
                    file=sys.stderr,
                )
            raise SystemExit(1)


if __name__ == "__main__":
    main()
