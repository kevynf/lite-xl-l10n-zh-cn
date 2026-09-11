-- Deterministic transformations for native strings assembled at runtime.
-- Exact catalogue lookup remains in locale.lua; this module only handles
-- known formats while preserving captured filenames, paths, values and keys.

local transforms = {}
local unpack_values = table.unpack or unpack

function transforms.apply(text, catalog)
  local colon_label = text:match("^(.-):$")
  if colon_label then
    local base = catalog.exact[colon_label]
    if base ~= nil then return base .. ":" end
  end

  local default_label, default_value = text:match("^(.-)%s*%(%s*default%s*:%s*(.-)%s*%)$")
  if not default_label then
    default_label, default_value = text:match("^(.-)%s*%(%s*默认%s*[:：]%s*(.-)%s*%)$")
  end
  if default_label then
    local base = catalog.exact[default_label]
    if base ~= nil then return base .. "（默认：" .. default_value .. "）" end
  end

  local group, action = text:match("^([^:]+): (.+)$")
  if group and action then
    local group_key = group:lower():gsub("[-%s]+", "_")
    local action_key = action:lower():gsub("%s+", "-")
    local group_text = catalog.command_groups[group_key]
    local action_text = catalog.command_actions[action_key]
    if not action_text then
      local tab_number = action_key:match("^switch%-to%-tab%-(%d+)$")
      if tab_number then action_text = "切换到第 " .. tab_number .. " 个标签页" end
    end
    if group_text and action_text then return group_text .. "：" .. action_text end
  end

  for _, entry in ipairs(catalog.patterns) do
    local captures = { string.match(text, entry.pattern) }
    if #captures > 0 then
      local ok, result = pcall(entry.replace, text, unpack_values(captures))
      if ok and type(result) == "string" then return result end
      break
    end
  end

  return nil
end

return transforms
