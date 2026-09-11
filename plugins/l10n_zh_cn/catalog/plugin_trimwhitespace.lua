-- Native Lite XL catalogue entries.
-- Source module: plugins/trimwhitespace.lua
-- Settings labels and descriptions extracted from config_spec.

local M = { source = "plugins/trimwhitespace", categories = {} }

M.categories.settings = {
  ["Trim Empty End Lines"] = "删除末尾空行",
  ["Disable or enable the trimming of white spaces by default."] = "默认启用或禁用空白清理。",
  ["Remove any empty new lines at the end of documents."] = "删除文档末尾的空行。",
}

return M
