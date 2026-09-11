-- Structured catalogue loader for the native Lite XL UI.
--
-- Catalogue modules declare a source and UI categories. This loader builds
-- category lookups for translation and source indexes for maintenance.

local modules = {
  "sections", "settings", "commandview", "dialogs", "contextmenu",
  "welcome", "status", "widget", "plugin_l10n_zh_cn",
  "plugin_autocomplete", "plugin_autoreload", "plugin_drawwhitespace",
  "plugin_lineguide", "plugin_linewrapping", "plugin_scale",
  "plugin_language_php",
  "plugin_settings", "plugin_treeview", "plugin_trimwhitespace",
}

local native = {
  by_source = {},
  by_kind = {},
  sources = {},
  duplicates = {},
}

for _, module_name in ipairs(modules) do
  local module = require("plugins.l10n_zh_cn.catalog." .. module_name)
  local source = module.source or module_name
  native.by_source[source] = native.by_source[source] or {}
  native.sources[#native.sources + 1] = source
  for category, entries in pairs(module.categories or {}) do
    native[category] = native[category] or {}
    native.by_source[source][category] = entries
    native.by_kind[category] = native.by_kind[category] or {}
    for key, value in pairs(entries) do
      -- Duplicate presentation keys are rejected by the test suite.  Keeping
      -- the first source here makes runtime behavior deterministic as well.
      if native[category][key] == nil then
        native[category][key] = value
        native.by_kind[category][key] = {
          text = value,
          source = source,
          catalog = "catalog/" .. module_name .. ".lua",
        }
      else
        native.duplicates[#native.duplicates + 1] = {
          category = category,
          key = key,
          source = source,
        }
      end
    end
  end
end

return native

