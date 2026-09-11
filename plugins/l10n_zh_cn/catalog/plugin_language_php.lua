-- Native Lite XL catalogue entries.
-- Source module: plugins/language_php.lua
-- Syntax rules remain data; only config_spec presentation text is translated.

local M = { source = "plugins/language_php", categories = {} }

M.categories.settings = {
  ["Language PHP"] = "PHP 语言",
  ["Highlight as SQL, strings starting with sql statements, depends on language_psql."] =
    "将以 SQL 语句开头的字符串高亮为 SQL，依赖 language_psql。",
}

return M
