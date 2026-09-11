-- Simplified Chinese message catalogue for Lite XL.
--
-- The catalogue deliberately translates presentation strings only.  Command
-- identifiers, paths and values used by callbacks remain in their original
-- form; callers should pass the text they are about to display to translate().

local catalog = {}
catalog.locale = "zh-CN"

-- Context-specific labels are maintained by the catalogue loader.
local native = require "plugins.l10n_zh_cn.catalog"
catalog.sections = native.sections or {}
catalog.plugins = native.plugins or {}

function catalog.translate_section(value)
  return catalog.locale == "zh-CN" and catalog.sections[value] or value
end

function catalog.translate_plugin(value)
  return catalog.locale == "zh-CN" and catalog.plugins[value] or value
end

-- Keep a small locale API even though the first release ships one locale.  It
-- lets init.lua validate user configuration without making translation calls
-- depend on a global setting.
function catalog.set_locale(locale)
  if locale == nil or locale == "zh-CN" or locale == "zh_CN" then
    catalog.locale = "zh-CN"
    return true
  end
  if locale == "en" or locale == "en-US" then
    catalog.locale = "en"
    return true
  end
  return false
end

-- Strings which are emitted verbatim by core and bundled plugins.
-- Native strings are maintained by source module in catalog/*.lua.
catalog.native = native
catalog.exact = {}
local native_categories = { "settings", "commands", "dialogs", "menus", "welcome", "status", "widgets", "localization" }
for _, category_name in ipairs(native_categories) do
  local category = native[category_name] or {}
  for key, value in pairs(category) do
    catalog.exact[key] = value
  end
end

-- Category-aware lookup is available to hooks that know the originating UI
-- surface. The generic translate() API remains the general lookup path.
function catalog.translate_category(text, category, logger)
  if type(text) ~= "string" or catalog.locale ~= "zh-CN" then return text end
  local entries = native[category]
  if type(entries) == "table" and entries[text] ~= nil then return entries[text] end
  return catalog.translate(text, logger)
end

local command_runtime = require "plugins.l10n_zh_cn.runtime.commands"
catalog.command_groups = command_runtime.command_groups
catalog.command_actions = command_runtime.command_actions
catalog.patterns = require "plugins.l10n_zh_cn.runtime.patterns".patterns

local missing = {}
local transforms = require "plugins.l10n_zh_cn.transforms"

local function report_missing(logger, text)
  if missing[text] or logger == nil then return end
  missing[text] = true

  -- A function is the preferred logger API.  Accept common logger tables as a
  -- convenience, while swallowing logger failures so translation never breaks
  -- the editor UI.
  if type(logger) == "function" then
    pcall(logger, text)
  elseif type(logger) == "table" then
    local fn = logger.warn or logger.debug or logger.log
    if type(fn) == "function" then pcall(fn, logger, "missing translation: " .. text) end
  end
end

--- Translate one presentation string, preserving unknown text verbatim.
-- @param text string to translate
-- @param logger optional callback (or logger table) for missing strings
-- @return translated string
function catalog.translate(text, logger)
  if type(text) ~= "string" then return text end
  if catalog.locale ~= "zh-CN" then return text end
  local translated = catalog.exact[text]
  if translated ~= nil then return translated end

  local transformed = transforms.apply(text, catalog)
  if transformed ~= nil then return transformed end

  -- Labels may already be translated when a settings/widget tree is rebuilt;
  -- leave non-ASCII text unchanged without reporting it as an English miss.
  if text:find("[%128-%255]") then return text end
  report_missing(logger, text)
  return text
end

-- Useful for deterministic tests and for callers that replace their logger at
-- runtime.  This does not alter the catalogue itself.
function catalog.reset_missing()
  missing = {}
end

return catalog



