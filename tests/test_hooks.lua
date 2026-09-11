package.path = "./?.lua;./?/init.lua;" .. package.path

local command = {
  prettify_name = function(name) return name end,
}
local commandview = {
  enter = function(self, label, ...) self.label = label; return label, ... end,
}
local divider = {}
local contextmenu = {
  DIVIDER = divider,
  register = function(self, predicate, items, ...) self.items = items; return true, ... end,
}
local nagview = {
  show = function(self, title, message, options, callback)
    self.title, self.message, self.options, self.callback = title, message, options, callback
    return true
  end,
}
local statusview = {
  show_message = function(self, icon, color, message) self.message = message end,
  show_tooltip = function(self, message) self.tooltip = message end,
}

package.loaded["core.command"] = command
package.loaded["core.commandview"] = commandview
package.loaded["core.contextmenu"] = contextmenu
package.loaded["core.nagview"] = nagview
package.loaded["core.statusview"] = statusview
local settings_plugin = { core = {}, plugins = {}, plugin_sections = {} }
settings_plugin.add = function(section, options, plugin_name) settings_plugin.last_section, settings_plugin.last_options, settings_plugin.last_plugin = section, options, plugin_name end
package.loaded["plugins.settings"] = settings_plugin
package.loaded["core.config"] = { plugins = {} }
local log_count = 0
package.loaded["core"] = {
  log_quiet = function(_, ...) log_count = log_count + 1 end,
}
local function fake_font(size)
  return { get_size = function() return size end, copy = function(self, value) return fake_font(value) end }
end
package.loaded["core.style"] = { font = fake_font(15), big_font = fake_font(24), code_font = fake_font(15) }
package.loaded["renderer"] = { font = {
  load = function(path, size) assert(type(path) == "string"); return fake_font(size) end,
  group = function(fonts) return fake_font(fonts[1]:get_size()) end,
} }

local hooks = require "plugins.l10n_zh_cn.hooks"
hooks._allow_unknown = true
local locale = require "plugins.l10n_zh_cn.locale"
hooks.install()
local plugin = require "plugins.l10n_zh_cn.init"
assert(plugin.name == "l10n_zh_cn")
local cfg = package.loaded["core.config"].plugins.l10n_zh_cn
assert(type(cfg.config_spec) == "table")
assert(cfg.config_spec[3].path == "use_bundled_font")
settings_plugin.add("Chinese Localization", cfg.config_spec, "l10n_zh_cn")
assert(settings_plugin.last_section == "中文本地化")
assert(cfg.config_spec[1].label == "已启用")
assert(cfg.config_spec[3].label == "使用内置 CJK 字体")
local third_party_option = { label = "Open", description = "Open" }
settings_plugin.add("Third Party", { third_party_option }, "thirdparty")
assert(settings_plugin.last_section == "Third Party")
assert(third_party_option.label == "Open" and third_party_option.description == "Open")
assert(locale.translate_category("Font", "settings") == "字体")
assert(locale.translate("Font:") == "字体:")
assert(locale.translate("The maximum amount of visible document tabs. (default: 8)") == "可见文档标签页的最大数量。（默认：8）")

assert(command.prettify_name("Core: Open File") == "核心：打开文件")
assert(locale.translate("Doc: Upper Case") == "文档：转为大写")
assert(locale.translate("third-party: unknown-command") == "third-party: unknown-command")
assert(locale.debug ~= true)
locale.translate("definitely-untranslated-runtime-text")
assert(log_count == 0)
locale.debug = true
local explicit_logs = 0
locale.translate("another-untranslated-runtime-text", function() explicit_logs = explicit_logs + 1 end)
assert(explicit_logs == 1)
locale.debug = false
assert(locale.translate("The maximum amount of visible items.") == "可见项目的最大数量。")
assert(locale.translate("Result: 2 of 5") == "结果：第 2 项，共 5 项")
assert(locale.translate("Total Replaced: 3") == "替换总数：3")
assert(locale.translate("Choose File") == "选择文件")
assert(locale.translate_section("User Interface") == "用户界面")
assert(locale.translate_plugin("Line Wrapping") == "自动换行")
commandview:enter("Search commands")
assert(commandview.label == "搜索命令")

contextmenu:register(function() return true end, { divider, { text = "Open", command = "core:open-file" } })
assert(contextmenu.items[1] == divider)
assert(contextmenu.items[2].text == "打开")
assert(contextmenu.items[2].command == "core:open-file")

local selected
nagview:show("Warning", "File has been modified", { { text = "Yes" } }, function(option)
  selected = option
end)
assert(nagview.title == "警告")
assert(nagview.message == "文件已修改")
assert(nagview.options[1].text == "是")
nagview.callback(nagview.options[1])
assert(selected.text == "Yes")

statusview:show_message("info", {}, "Saved")
statusview:show_tooltip("Read Only")
assert(statusview.message == "已保存")
assert(statusview.tooltip == "只读")

print("Lite XL hook tests passed")

