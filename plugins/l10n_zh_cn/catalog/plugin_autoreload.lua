-- Native Lite XL catalogue entries.
-- Source module: plugins/autoreload.lua
-- Settings labels and descriptions extracted from config_spec.

local M = { source = "plugins/autoreload", categories = {} }

M.categories.settings = {
  ["Always Show Nagview"] = "始终显示提示框",
  ["Alerts you if an opened file changes externally even if you haven't modified it."] = "打开的文件被外部修改时发出提醒。",
}

return M
