-- Native Lite XL catalogue entries.
-- Source module: localization
-- Values are presentation text; IDs and callback data remain unchanged.

local M = { source = "localization", categories = {} }

M.categories.localization = {
  ["Chinese Localization"] = "中文本地化",
  ["Language"] = "语言",
  ["Use Bundled CJK Font"] = "使用内置 CJK 字体",
  ["CJK Font"] = "CJK 字体",
  ["Debug Missing Text"] = "调试未翻译文本",
  ["Enable or disable the Chinese localization plugin. Restart Lite XL after changing this option."] = "启用或禁用中文本地化插件。修改后请重启 Lite XL。",
  ["The language used for native Lite XL interface text."] = "原生 Lite XL 界面使用的语言。",
  ["Use the bundled Noto Sans CJK SC font for Chinese characters."] = "使用内置的 Noto Sans CJK SC 字体显示中文字符。",
  ["Optional font file used as a fallback for Chinese characters. Overrides the bundled font."] = "可选的中文字符回退字体文件。指定后将覆盖内置字体。",
  ["Log native interface strings that are not in the catalog."] = "记录词典中未登记的原生界面文本。",
}

return M
