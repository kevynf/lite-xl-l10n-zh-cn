-- Native Lite XL catalogue entries.
-- Source module: plugins/lineguide.lua
-- Settings labels and descriptions extracted from config_spec.

local M = { source = "plugins/lineguide", categories = {} }

M.categories.settings = {
  ["Ruler Positions"] = "标尺位置",
  ["Width"] = "宽度",
  ["Disable or enable drawing of the line guide."] = "启用或禁用标尺绘制。",
  ["The different column numbers for the line guides to draw."] = "要绘制标尺的列号。",
  ["Width in pixels of the line guide."] = "标尺宽度（像素）。",
}

return M
