-- Runtime formatting patterns for dynamic native messages.

-- Anchored patterns are intentionally narrow.  Captured paths, names and
-- numbers are copied without modification so they remain useful to users and
-- to code which may inspect the resulting message.
local M = { patterns = {
  {
    pattern = "^(.-) to run a command$",
    replace = function(_, key)
      return key .. " 运行命令"
    end,
  },
  {
    pattern = "^(.-) to open a file from the project$",
    replace = function(_, key)
      return key .. " 打开项目中的文件"
    end,
  },
  {
    pattern = "^(.-) to change project folder$",
    replace = function(_, key)
      return key .. " 更改项目文件夹"
    end,
  },
  {
    pattern = "^(.-) to open a project folder$",
    replace = function(_, key)
      return key .. " 打开项目文件夹"
    end,
  },
  {
    pattern = "^Save changes to (.+)%?$",
    replace = function(_, name)
      return "保存对 " .. name .. " 的更改？"
    end,
  },
  {
    pattern = "^Delete ['\"](.+)['\"]%?$",
    replace = function(_, name)
      return "确定删除“" .. name .. "”吗？"
    end,
  },
  {
    pattern = "^Cannot open file: (.+)$",
    replace = function(_, path)
      return "无法打开文件：“" .. path .. "”"
    end,
  },
  {
    pattern = "^Error loading (.+): (.+)$",
    replace = function(_, target, detail)
      return "加载 " .. target .. " 时出错：" .. detail
    end,
  },
  {
    pattern = "^Line (%d+), Column (%d+)$",
    replace = function(_, line, column)
      return "第 " .. line .. " 行，第 " .. column .. " 列"
    end,
  },
  {
    pattern = "^(%d+) lines? selected$",
    replace = function(_, count)
      return "已选择 " .. count .. " 行"
    end,
  },
  {
    pattern = "^Tab Size: (%d+)$",
    replace = function(_, size)
      return "制表符大小：" .. size
    end,
  },
  {
    pattern = "^Spaces: (%d+)$",
    replace = function(_, count)
      return "空格：" .. count
    end,
  },
  {
    pattern = "^Loading (.+)%.%.%.$",
    replace = function(_, target)
      return "正在加载 " .. target .. "……"
    end,
  },
  {
    pattern = "^Result: (%d+) of (%d+)$",
    replace = function(_, current, total)
      return "结果：第 " .. current .. " 项，共 " .. total .. " 项"
    end,
  },
  {
    pattern = "^Total Replaced: (%d+)$",
    replace = function(_, count)
      return "替换总数：" .. count
    end,
  },
  {
    pattern = "^(.+) has changed%. Reload this file%?$",
    replace = function(_, name)
      return name .. " 已发生变化。重新加载此文件吗？"
    end,
  },
  {
    pattern = "^Are you sure you want to delete (.+)%?$",
    replace = function(_, target)
      return "确定要删除" .. target .. "吗？"
    end,
  },
  {
    pattern = "^Found (%d+) results? in (%d+) files?%.?$",
    replace = function(_, results, files)
      return "在 " .. files .. " 个文件中找到 " .. results .. " 个结果"
    end,
  },
  {
    pattern = "^(.+) at line (%d+) %(col (%d+)%)%:$",
    replace = function(_, file, line, col)
      return file .. " 第 " .. line .. " 行（第 " .. col .. " 列）："
    end,
  },
  {
    pattern = "^Specify indent style:?$",
    replace = function() return "指定缩进样式：" end,
  },
  {
    pattern = "^Specify indent size:?$",
    replace = function() return "指定缩进大小：" end,
  },
  {
    pattern = "^copied entry #(%d+) to clipboard%.$",
    replace = function(_, index) return "已将条目 #" .. index .. " 复制到剪贴板。" end,
  },
  {
    pattern = "^Too many symbols in (.+): stopping auto%-complete for this document according to (.+)%.?$",
    replace = function(_, target, setting)
      return target .. " 中的符号过多，已停止自动补全（依据 " .. setting .. "）。"
    end,
  },
  {
    pattern = "^Find To Replace (.+)$",
    replace = function(_, kind) return "查找并替换" .. kind end,
  },
  {
    pattern = "^Find Text In (.+)$",
    replace = function(_, path) return "在 " .. path .. " 中查找文本" end,
  },
  {
    pattern = "^Find Regex In (.+)$",
    replace = function(_, path) return "在 " .. path .. " 中查找正则表达式" end,
  },
  {
    pattern = "^Fuzzy Find Text In (.+)$",
    replace = function(_, path) return "在 " .. path .. " 中模糊查找文本" end,
  },
  {
    pattern = "^Searching ([%d%.]+)%% %((%d+) of (%d+) files, (%d+) matches%) for (.+)%.%.%.$",
    replace = function(_, percent, current, total, matches, query)
      return string.format("正在搜索 %s%%（%s/%s 个文件，%s 个匹配）：“%s”……", percent, current, total, matches, query)
    end,
  },
  {
    pattern = "^Searching %((%d+) files, (%d+) matches%) for (.+)%.%.%.$",
    replace = function(_, files, matches, query)
      return string.format("正在搜索（%s 个文件，%s 个匹配）：“%s”……", files, matches, query)
    end,
  },
  {
    pattern = "^Found (%d+) matches for (.+)$",
    replace = function(_, matches, query)
      return "已找到 " .. matches .. " 个匹配：“" .. query .. "”"
    end,
  },
  {
    pattern = "^(.+) at line (%d+) %(col (%d+)%)%: ?$",
    replace = function(_, file, line, col)
      return file .. " 第 " .. line .. " 行（第 " .. col .. " 列）："
    end,
  },
  {
    pattern = "^Replace (.+) (.+) With$",
    replace = function(_, kind, old) return "将" .. kind .. " " .. old .. " 替换为" end,
  },
  {
    pattern = "^Press (.+) to select the next match%.$",
    replace = function(_, key) return "按 " .. key .. " 选择下一个匹配项。" end,
  },
  {
    pattern = '^Couldn.t save file "(.+)"%. Do you want to save to another location%?$',
    replace = function(_, name) return "无法保存文件“" .. name .. "”。要保存到其他位置吗？" end,
  },
  {
    pattern = '^"(.+)" has unsaved changes%. Quit anyway%?$',
    replace = function(_, name) return "“" .. name .. "”有未保存的更改。仍要退出吗？" end,
  },
  {
    pattern = '^(%d+) docs have unsaved changes%. Quit anyway%?$',
    replace = function(_, count) return "有 " .. count .. " 个文档存在未保存的更改。仍要退出吗？" end,
  },
  {
    pattern = "^(.+) %(default: (.+)%)$",
    replace = function(_, label, value)
      return label .. "（默认：" .. value .. "）"
    end,
  },
}
}

return M
