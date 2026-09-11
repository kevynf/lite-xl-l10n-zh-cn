local catalog = require "plugins.l10n_zh_cn.locale"
local function tokens(value)
  local result = {}
  for token in value:gmatch("%%[%d%.]*[sdqif]") do result[#result + 1] = token end
  return table.concat(result, "|")
end
local checked = 0
for category_name, category in pairs(catalog.native or {}) do
  -- Loader metadata is indexed separately from translation categories.
  if type(category) == "table" and category_name ~= "by_source" and category_name ~= "by_kind" and category_name ~= "sources" and category_name ~= "duplicates" then
    for key, value in pairs(category) do
      assert(type(key) == "string" and type(value) == "string", category_name)
      assert(tokens(key) == tokens(value), category_name .. ": placeholder mismatch: " .. key)
      assert(value ~= "", category_name .. ": empty translation: " .. key)
      checked = checked + 1
    end
  end
end
for _, entry in ipairs(catalog.patterns or {}) do
  assert(type(entry.pattern) == "string" and type(entry.replace) == "function")
end
print("Catalog checks passed: " .. checked .. " entries")
