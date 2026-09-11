-- Native Lite XL catalogue entries.
-- Source module: plugins/drawwhitespace.lua
-- Settings labels and descriptions extracted from config_spec.

local M = { source = "plugins/drawwhitespace", categories = {} }

M.categories.settings = {
  ["Show Leading"] = "显示行首空白",
  ["Show Middle"] = "显示中间空白",
  ["Show Trailing"] = "显示行尾空白",
  ["Show Trailing as Error"] = "将行尾空白显示为错误",
  ["Disable or enable the drawing of white spaces."] = "启用或禁用空白字符的绘制。",
  ["Draw whitespaces on the end of a line."] = "显示行尾空白字符。",
  ["Draw whitespaces on the middle of a line."] = "显示行中空白字符。",
  ["Draw whitespaces starting at the beginning of a line."] = "显示行首空白字符。",
  ["Uses an error square to spot them easily, requires 'Show Trailing' enabled."] = "使用错误方块标记，需先启用“显示行尾空白”。",
}

return M
