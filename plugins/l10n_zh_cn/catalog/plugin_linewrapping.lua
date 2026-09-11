-- Native Lite XL catalogue entries.
-- Source module: plugins/linewrapping.lua
-- Settings labels and descriptions extracted from config_spec.

local M = { source = "plugins/linewrapping", categories = {} }

M.categories.settings = {
  ["Guide"] = "辅助线",
  ["Indent"] = "缩进",
  ["Enable by Default"] = "默认启用",
  ["Require Tokenization"] = "需要词法分析",
  ["The type of wrapping to perform."] = "要执行的换行类型。",
  ["Use tokenization when applying wrapping."] = "换行时使用词法分析。",
  ["Whether or not to draw a guide."] = "是否绘制辅助线。",
  ["Whether or not to enable wrapping by default when opening files."] = "打开文件时是否默认启用换行。",
  ["Whether or not to follow the indentation of wrapped line."] = "是否遵循换行后的缩进。",
}

return M
