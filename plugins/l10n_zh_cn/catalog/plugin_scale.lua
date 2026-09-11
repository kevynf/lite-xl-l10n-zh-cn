-- Native Lite XL catalogue entries.
-- Source module: plugins/scale.lua
-- Settings labels and descriptions extracted from config_spec.

local M = { source = "plugins/scale", categories = {} }

M.categories.settings = {
  ["Everything"] = "全部界面",
  ["Code Only"] = "仅代码",
  ["Autodetect"] = "自动检测",
  ["Default Scale"] = "默认缩放比例",
  ["Use MouseWheel"] = "使用鼠标滚轮",
  ["Allow using CTRL + MouseWheel for changing the scale."] = "允许使用 Ctrl+鼠标滚轮调整缩放。",
  ["The method used to apply the scaling."] = "应用缩放的方式。",
  ["The scaling factor applied to lite-xl."] = "应用于 Lite XL 的缩放比例。",
}

return M
