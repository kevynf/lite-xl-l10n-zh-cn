-- priority:1
-- mod-version:3

local config = require "core.config"
local locale = require "plugins.l10n_zh_cn.locale"


config.plugins = config.plugins or {}
config.plugins.l10n_zh_cn = config.plugins.l10n_zh_cn or {}
local settings = config.plugins.l10n_zh_cn

-- Expose the plugin's own options to the native Settings page.  The options
-- are deliberately declarative so settings.lua can render them without this
-- plugin depending on the settings implementation at load time.
settings.config_spec = {
  name = "Chinese Localization",
  {
    label = "Enabled",
    description = "Enable or disable the Chinese localization plugin. Restart Lite XL after changing this option.",
    path = "enabled",
    type = "toggle",
    default = true,
  },
  {
    label = "Language",
    description = "The language used for native Lite XL interface text.",
    path = "locale",
    type = "selection",
    default = "zh-CN",
    values = {{ "简体中文", "zh-CN" }, { "English", "en" }},
    on_apply = function(value)
      locale.set_locale(value)
    end,
  },
  {
    label = "Use Bundled CJK Font",
    description = "Use the bundled Noto Sans CJK SC font for Chinese characters.",
    path = "use_bundled_font",
    type = "toggle",
    default = true,
  },
  {
    label = "CJK Font",
    description = "Optional font file used as a fallback for Chinese characters. Overrides the bundled font.",
    path = "font_path",
    type = "file",
    default = nil,
    exists = true,
    filters = { "%.ttf$", "%.otf$", "%.ttc$" },
  },
  {
    label = "Debug Missing Text",
    description = "Log native interface strings that are not in the catalog.",
    path = "debug",
    type = "toggle",
    default = false,
  },
}

if settings.enabled == nil then settings.enabled = true end
if settings.locale == nil then settings.locale = "zh-CN" end
if settings.use_bundled_font == nil then settings.use_bundled_font = true end
if settings.debug == nil then settings.debug = false end

if settings.enabled == false then
  return { name = "l10n_zh_cn", enabled = false }
end

local hooks = require "plugins.l10n_zh_cn.hooks"

locale.set_locale(settings.locale or "zh-CN")
locale.debug = settings.debug == true
hooks.install()

local function bundled_font_path()
  local source = debug and debug.getinfo and debug.getinfo(1, "S").source or ""
  if type(source) ~= "string" or source:sub(1, 1) ~= "@" then return nil end
  local init_path = source:sub(2):gsub("[/\\]", "/")
  local plugin_dir = init_path:match("^(.*)/init%.lua$")
  if not plugin_dir then return nil end
  return plugin_dir .. "/fonts/NotoSansCJKsc-Regular.otf"
end

local function configure_font(path)
  if type(path) ~= "string" or path == "" then return false end
  local renderer = rawget(_G, "renderer") or package.loaded.renderer
  local style = package.loaded["core.style"]
  if not renderer or not style or not style.font or not renderer.font then return false end
  if type(renderer.font.load) ~= "function" or type(renderer.font.group) ~= "function" then return false end
  if type(style.font.get_size) ~= "function" then return false end
  local ok_font, cjk = pcall(renderer.font.load, path, style.font:get_size())
  if not ok_font or not cjk then return false end
  style.font = renderer.font.group { style.font, cjk }
  if style.big_font and type(cjk.copy) == "function" then
    style.big_font = renderer.font.group { style.big_font, cjk:copy(style.big_font:get_size()) }
  end
  if style.code_font and type(cjk.copy) == "function" then
    style.code_font = renderer.font.group { style.code_font, cjk:copy(style.code_font:get_size()) }
  end
  return true
end

-- An explicit user font wins. Otherwise the bundled OFL font is used when
-- enabled; a missing/incompatible font uses Lite XL's original font.
local selected_font = settings.font_path
if type(selected_font) ~= "string" or selected_font == "" then
  if settings.use_bundled_font ~= false then selected_font = bundled_font_path() end
end
configure_font(selected_font)

return {
  name = "l10n_zh_cn",
  translate = locale.translate,
  reload = function()
    locale.reset_missing()
    hooks.install()
  end
}
