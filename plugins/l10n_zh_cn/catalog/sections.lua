-- Native Lite XL catalogue entries.
-- Source module: sections
-- Values are presentation text; IDs and callback data remain unchanged.

local M = { source = "sections", categories = {} }

M.categories.sections = {
  General = "常规", Graphics = "图形", ["User Interface"] = "用户界面",
  Editor = "编辑器", Development = "开发", ["Status Bar"] = "状态栏",
  Core = "核心", Colors = "颜色", Plugins = "插件", Keybindings = "快捷键",
  About = "关于", Installed = "已安装",
}

M.categories.plugins = {
  Autocomplete = "自动补全", Autoreload = "自动重载",
  ["Draw Whitespace"] = "显示空白字符", ["Line Guide"] = "行标尺",
  ["Line Wrapping"] = "自动换行", Scale = "缩放", Treeview = "目录树",
  ["Trim Whitespace"] = "清理空白", ["Project Search"] = "项目搜索",
  ["Detect Indent"] = "检测缩进", ["Context Menu"] = "上下文菜单",
  Macro = "宏", Quote = "引用", Reflow = "重排文本",
  Tabularize = "表格化", ["Toolbar View"] = "工具栏视图", Workspace = "工作区",
}

return M
