-- Native Lite XL catalogue entries.
-- Source module: contextmenu
-- Values are presentation text; IDs and callback data remain unchanged.

local M = { source = "contextmenu", categories = {} }

M.categories.menus = {
  ["Open"] = "打开",
  ["Open With"] = "打开方式",
  ["New"] = "新建",
  ["New File"] = "新建文件",
  ["New Directory"] = "新建目录",
  ["Rename"] = "重命名",
  ["Delete"] = "删除",
  ["Copy"] = "复制",
  ["Cut"] = "剪切",
  ["Paste"] = "粘贴",
  ["Duplicate"] = "复制一份",
  ["Refresh"] = "刷新",
  ["Reveal in File Manager"] = "在文件管理器中显示",
  ["Copy Path"] = "复制路径",
  ["Copy Relative Path"] = "复制相对路径",
  ["Open Containing Folder"] = "打开所在文件夹",
  ["Open in System"] = "在系统中打开",
  ["Remove directory"] = "移除目录",
  ["Find in Directory"] = "在目录中查找",

}

return M
