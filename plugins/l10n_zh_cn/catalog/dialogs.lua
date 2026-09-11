-- Native Lite XL catalogue entries.
-- Source module: dialogs
-- Values are presentation text; IDs and callback data remain unchanged.

local M = { source = "dialogs", categories = {} }

M.categories.dialogs = {
  ["Yes"] = "是",
  ["No"] = "否",
  ["No Selection"] = "无选区",
  ["None"] = "无",
  ["OK"] = "确定",
  ["Cancel"] = "取消",
  ["Close"] = "关闭",
  ["Save"] = "保存",
  ["Don't Save"] = "不保存",
  ["Discard"] = "放弃",
  ["Retry"] = "重试",
  ["Reload"] = "重新加载",
  ["Error"] = "错误",
  ["Warning"] = "警告",
  ["Information"] = "信息",
  ["Confirm"] = "确认",
  ["Are you sure you want to quit?"] = "确定要退出吗？",
  ["Save changes to %s?"] = "保存对 %s 的更改？",
  ["Delete %s?"] = "确定删除 %s 吗？",
  ["File has been modified"] = "文件已修改",
  ["File changed on disk"] = "文件已在磁盘上发生变化",
  ["Saving failed"] = "保存失败",
  ["Unsaved Changes"] = "未保存的更改",
  ["File Changed"] = "文件已更改",
  ["Exit"] = "退出",
  ["Continue"] = "继续",
  ["Current window"] = "当前窗口",
  ["New window"] = "新窗口",
  ["Edit Item"] = "编辑项目",
  ["Add Item"] = "添加项目",
  ["Can not remove row"] = "无法删除行",
  ["Rows can not be removed when the list is filtered."] = "筛选列表时无法删除行。",

  ["The font cache is already been built,\nstatus will be logged on the core log."] =
    "字体缓存已经在构建中，\n状态将记录到核心日志。",
  ["Re-building the font cache can take some time,\nit is needed when you have installed new fonts\nwhich are not listed on the font picker tool.\n\nDo you want to continue?"] =
    "重新构建字体缓存可能需要一些时间，\n当你安装了字体选择器中未列出的新字体时需要执行此操作。\n\n要继续吗？",
  ["A lightweight text editor written in Lua, adapted from lite."] =
    "一款使用 Lua 编写、基于 lite 改进的轻量级文本编辑器。",
  ["version "] = "版本 ",
}

return M
