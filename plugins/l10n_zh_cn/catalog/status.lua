-- Native Lite XL catalogue entries.
-- Source module: status
-- Values are presentation text; IDs and callback data remain unchanged.

local M = { source = "status", categories = {} }

M.categories.status = {
  ["Insert"] = "插入",
  ["Overwrite"] = "覆盖",
  ["Spaces"] = "空格",
  ["Tabs"] = "制表符",
  ["UTF-8"] = "UTF-8",
  ["Unix"] = "Unix",
  ["Windows"] = "Windows",
  ["DOS"] = "DOS",
  ["Read Only"] = "只读",
  ["Modified"] = "已修改",
  ["Saved"] = "已保存",
  ["Untitled"] = "未命名",
  ["Line"] = "行",
  ["Column"] = "列",
  ["Selection"] = "选区",
  ["line : column"] = "行 : 列",
  ["caret position"] = "光标位置",
  ["Line %d, Column %d"] = "第 %d 行，第 %d 列",
  ["Ln %d, Col %d"] = "第 %d 行，第 %d 列",
  ["Tab Size: %d"] = "制表符大小：%d",
  ["Spaces: %d"] = "空格：%d",

}

return M
