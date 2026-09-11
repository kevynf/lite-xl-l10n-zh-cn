-- Translation boundary policy.
--
-- This module contains scope and data-safety decisions only.  It does not
-- translate text and it does not call Lite XL APIs, which keeps the rules
-- testable and prevents presentation hooks from growing more exceptions.

local policy = {}

policy.native_plugins = {
  autocomplete = true, autoreload = true, contextmenu = true, detectindent = true,
  drawwhitespace = true, lineguide = true, linewrapping = true, macro = true,
  projectsearch = true, open_ext = true, quote = true, reflow = true, scale = true,
  tabularize = true, toolbarview = true, treeview = true, trimwhitespace = true,
  workspace = true, settings = true,
}

function policy.is_native_call(level, allow_unknown)
  if allow_unknown then return true end
  if not debug or type(debug.getinfo) ~= "function" then return false end
  local first = level or 3
  for depth = first, first + 6 do
    local info = debug.getinfo(depth, "S")
    local source = info and info.source or ""
    if type(source) == "string" and source ~= "" then
      source = source:gsub("\\", "/")
      local plugin = source:match("/data/plugins/([^/]+)%.lua$")
      if plugin then return policy.native_plugins[plugin] == true end
      if source:find("/data/plugins/", 1, true) then return true end
      if source:find("/core/", 1, true) or source:find("/libraries/widget/", 1, true) then
        return true
      end
      if source:find("/%.config/lite%-xl/plugins/")
          or source:find("/config/lite%-xl/plugins/") then
        return source:find("/plugins/l10n_zh_cn/", 1, true) ~= nil
      end
    end
  end
  return false
end

function policy.is_font_preview(value)
  return value == "No Font Selected" or value == "No font selected"
end

policy.status_literals = {
  ["tabs: "] = "制表符：",
  ["spaces: "] = "空格：",
  [" lines"] = " 行",
  [" files"] = " 个文件",
}

return policy
