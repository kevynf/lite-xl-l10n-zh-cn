-- Native Lite XL catalogue entries.
-- Source module: plugins/autocomplete.lua
-- Settings labels and descriptions extracted from config_spec.

local M = { source = "plugins/autocomplete", categories = {} }

M.categories.settings = {
  ["Minimum Length"] = "最小长度",
  ["Maximum Height"] = "最大高度",
  ["Maximum Suggestions"] = "最大建议数",
  ["Maximum Symbols"] = "最大符号数",
  ["Description Font Size"] = "描述字体大小",
  ["Amount of characters that need to be written for autocomplete to popup."] = "输入达到此字符数后显示自动补全。",
  ["The maximum amount of visible items."] = "可见项目的最大数量。",
  ["The maximum amount of scrollable items."] = "可滚动项目的最大数量。",
  ["Maximum amount of symbols to cache per document."] = "每个文档缓存的最大符号数。",
  ["Font size of the description box."] = "描述框的字体大小。",
}

return M
