local locale = require "plugins.l10n_zh_cn.locale"
local policy = require "plugins.l10n_zh_cn.policy"

local hooks = {}

local function copy_table(value)
  local result = {}
  for key, item in pairs(value) do result[key] = item end
  return result
end

local function translate(value, category)
  if type(value) ~= "string" then return value end
  local function report(text)
    -- Missing-text diagnostics are opt-in.  Calling core.log_quiet for every
    -- unknown runtime string can populate/open Lite XL's Log View during
    -- normal use, especially when a bundled plugin emits dynamic data.
    if locale.debug ~= true then return end
    local core = package.loaded.core
    if core and core.log_quiet then
      core.log_quiet("l10n_zh_cn: missing translation: %q", text)
    end
  end
  if type(locale.translate_category) == "function" and category then
    return locale.translate_category(value, category, report)
  end
  return locale.translate(value, report)
end

-- Restrict automatic widget/menu translation to Lite XL core and the
-- plugins shipped in its data directory. User-installed plugins are left
-- untouched, even when they happen to use labels such as "Open" or "Save".
local native_plugins = policy.native_plugins
local function native_ui_call(level)
  return policy.is_native_call(level, hooks._allow_unknown)
end

local function translate_heading(value)
  if type(value) ~= "string" then return value end
  if type(locale.translate_section) == "function" then
    local section = locale.translate_section(value)
    if section and section ~= value then return section end
  end
  if type(locale.translate_plugin) == "function" then
    local plugin = locale.translate_plugin(value)
    if plugin and plugin ~= value then return plugin end
  end
  return translate(value)
end

local function patch_command()
  local command = require "core.command"
  if type(command.prettify_name) ~= "function" then return false end
  local original = command.prettify_name
  command.prettify_name = function(name, ...)
    return translate(original(name, ...), "commands")
  end
  return true
end

local function patch_command_view()
  local ok, CommandView = pcall(require, "core.commandview")
  if not ok or type(CommandView.enter) ~= "function" then return false end
  local original = CommandView.enter
  CommandView.enter = function(self, label, ...)
    return original(self, translate(label, "commands"), ...)
  end
  return true
end

local function patch_context_menu()
  local ok, ContextMenu = pcall(require, "core.contextmenu")
  if not ok then return false end

  -- Context menus from bundled plugins may be registered before this plugin
  -- is loaded.  Translate the already registered itemsets lazily when they
  -- are shown, while keeping the command/callback fields untouched.
  local function translate_itemsets(self)
    local ok_style, style = pcall(require, "core.style")
    for _, itemset in ipairs(self.itemset or {}) do
      if not itemset._l10n_zh_cn and itemset.items and itemset.items._l10n_native == true then
        local translated = {}
        local width = 0
        for index, item in ipairs(itemset.items or {}) do
          if item == ContextMenu.DIVIDER then
            translated[index] = item
          elseif type(item) == "table" then
            local copy = copy_table(item)
            copy._l10n_original = item
            copy.text = translate(copy.text, "menus")
            -- `info` normally contains a shortcut or other dynamic value;
            -- keep it verbatim rather than treating it as a translatable UI
            -- label.
            translated[index] = copy
            if ok_style and style and style.font and type(style.font.get_width) == "function" then
              local w = style.font:get_width(copy.text or "")
              if copy.info then w = w + style.padding.x + style.font:get_width(copy.info) end
              width = math.max(width, w)
            end
          else
            translated[index] = item
          end
        end
        itemset.items = translated
        if width > 0 and style then
          itemset.items.width = width + style.padding.x * 2
        end
        itemset._l10n_zh_cn = true
      end
    end
  end

  if type(ContextMenu.register) == "function" then
    local original = ContextMenu.register
    ContextMenu.register = function(self, predicate, items, ...)
      local translated = {}
      local allow_translation = native_ui_call(3)
      for index, item in ipairs(items or {}) do
        if item == ContextMenu.DIVIDER then
          translated[index] = item
        elseif type(item) == "table" then
          local copy = copy_table(item)
          if allow_translation and type(copy.text) == "string" then copy.text = translate(copy.text, "menus") end
          translated[index] = copy
        else
          translated[index] = item
        end
      end
      translated._l10n_native = native_ui_call(3)
      return original(self, predicate, translated, ...)
    end
    -- Keep the display-time pass below as well: register() only affects
    -- registrations made after this wrapper was installed.
    if type(ContextMenu.show) == "function" then
      local show_original = ContextMenu.show
      ContextMenu.show = function(self, x, y, ...)
        translate_itemsets(self)
        return show_original(self, x, y, ...)
      end
    end
    return true
  end
  if type(ContextMenu.show) ~= "function" then return false end
  local original = ContextMenu.show
  ContextMenu.show = function(self, x, y, items, ...)
    local translated = {}
    for index, item in ipairs(items or {}) do
      if item == ContextMenu.DIVIDER then
        translated[index] = item
      elseif type(item) == "table" then
        local copy = copy_table(item)
        if type(copy.text) == "string" then copy.text = translate(copy.text, "menus") end
        translated[index] = copy
      else
        translated[index] = item
      end
    end
    return original(self, x, y, translated, ...)
  end
  return true
end

local function patch_nag_view()
  local ok, NagView = pcall(require, "core.nagview")
  if not ok or type(NagView.show) ~= "function" then return false end
  local original = NagView.show
  NagView.show = function(self, title, message, options, on_select)
    local translated_options = {}
    local allow_translation = native_ui_call(3)
    for index, option in ipairs(options or {}) do
      if type(option) == "table" then
        local copy = copy_table(option)
        copy._l10n_original = option
        if allow_translation and type(copy.text) == "string" then copy.text = translate(copy.text, "dialogs") end
        translated_options[index] = copy
      else
        translated_options[index] = option
      end
    end
    local callback = on_select
    if type(callback) == "function" then
      callback = function(option, ...)
        if type(option) == "table" and option._l10n_original then
          option = option._l10n_original
        end
        return on_select(option, ...)
      end
    end
    return original(self, translate(title, "dialogs"), translate(message, "dialogs"), translated_options, callback)
  end
  return true
end

local function patch_status_view()
  local ok, StatusView = pcall(require, "core.statusview")
  if not ok then return false end
  local patched = false
  if type(StatusView.show_message) == "function" then
    local original = StatusView.show_message
    StatusView.show_message = function(self, icon, color, text, ...)
      return original(self, icon, color, translate(text, "status"), ...)
    end
    patched = true
  end
  if type(StatusView.show_tooltip) == "function" then
    local original = StatusView.show_tooltip
    StatusView.show_tooltip = function(self, text, ...)
      return original(self, translate(text, "status"), ...)
    end
    patched = true
  end
  if type(StatusView.add_item) == "function" then
    local original = StatusView.add_item
    StatusView.add_item = function(self, options, ...)
      local copy = copy_table(options)
      copy.tooltip = translate(copy.tooltip, "status")
      return original(self, copy, ...)
    end
    patched = true
  end

  -- Status item get_item() methods return styled arrays containing plain
  -- strings (for example "tabs: ", " files", and separators).  They bypass
  -- show_message(), so translate the strings at draw time.  Numeric values,
  -- fonts, colours, filenames and command data are preserved.
  if type(StatusView.draw_items) == "function" then
    local original = StatusView.draw_items
    local function translate_status_piece(text)
      if policy.status_literals[text] then return policy.status_literals[text] end
      -- Status arrays also contain filenames and other user data.  Translate
      -- only catalogue entries here so those values are never logged as
      -- missing or altered.
      if locale.exact and locale.exact[text] ~= nil then
        return translate(text)
      end
      return text
    end
    StatusView.draw_items = function(self, items, ...)
      if type(items) ~= "table" then return original(self, items, ...) end
      local translated = {}
      for index, item in ipairs(items) do
        if type(item) == "string" then
          translated[index] = translate_status_piece(item)
        else
          translated[index] = item
        end
      end
      return original(self, translated, ...)
    end
    patched = true
  end
  local core = package.loaded.core
  if core and core.status_view then
    for _, item in ipairs(core.status_view.items or {}) do
      item.tooltip = translate(item.tooltip)
    end
  end
  return patched
end

local function patch_empty_view()
  local ok, EmptyView = pcall(require, "core.emptyview")
  if not ok then return false end
  if type(EmptyView.get_name) == "function" then
    local original = EmptyView.get_name
    EmptyView.get_name = function(self, ...)
      return translate(original(self, ...))
    end
  end
  local commands = {}
  for index, item in ipairs(EmptyView.commands or {}) do
    local copy = copy_table(item)
    copy.fmt = translate(copy.fmt, "welcome")
    commands[index] = copy
  end
  if #commands > 0 then EmptyView.commands = commands end

  -- Lite XL 2.1.8 keeps the welcome-page draw strings in a local function.
  -- Temporarily translating draw_text during this view's draw avoids changing
  -- text rendered by documents or other views.
  local renderer = rawget(_G, "renderer")
  if renderer and type(renderer.draw_text) == "function" and type(EmptyView.draw) == "function" then
    local original_draw = EmptyView.draw
    EmptyView.draw = function(self, ...)
      local original_text = renderer.draw_text
      local wrapped_text = function(font, text, ...)
        return original_text(font, translate(text), ...)
      end
      local assigned = pcall(function() renderer.draw_text = wrapped_text end)
      if not assigned then return original_draw(self, ...) end
      local result = { pcall(original_draw, self, ...) }
      pcall(function() renderer.draw_text = original_text end)
      if not result[1] then error(result[2]) end
      return table.unpack(result, 2)
    end
  end
  return true
end

-- The bundled settings UI and widget library create most labels after plugins
-- have loaded.  Translating Widget:set_label/set_tooltip at the boundary
-- catches settings panes, buttons, checkboxes and file pickers while keeping
-- command identifiers and callback values untouched.
local function patch_widgets()
  local ok, Widget = pcall(require, "libraries.widget")
  if not ok or type(Widget) ~= "table" then return false end
  local patched = false
  if type(Widget.set_label) == "function" and not Widget._l10n_zh_cn_label then
    local original = Widget.set_label
    Widget.set_label = function(self, value, ...)
      -- FontDialog previews use the selected font itself.  Keep this ASCII
      -- placeholder in English because the selected font may have no CJK
      -- glyphs, which would render the translated label as tofu boxes.
      if native_ui_call(4) and type(value) == "string" and not policy.is_font_preview(value) then
        value = translate(value, "widgets")
      end
      return original(self, value, ...)
    end
    Widget._l10n_zh_cn_label = true
    patched = true
  end
  if type(Widget.set_tooltip) == "function" and not Widget._l10n_zh_cn_tooltip then
    local original = Widget.set_tooltip
    Widget.set_tooltip = function(self, value, ...)
      if native_ui_call(4) and type(value) == "string" then value = translate(value, "widgets") end
      return original(self, value, ...)
    end
    Widget._l10n_zh_cn_tooltip = true
    patched = true
  end
  if type(Widget.draw_text_multiline) == "function" and not Widget._l10n_zh_cn_multiline then
    local original = Widget.draw_text_multiline
    Widget.draw_text_multiline = function(self, font, value, ...)
      if native_ui_call(4) and type(value) == "string" then
        value = translate(value, "widgets")
      elseif native_ui_call(4) and type(value) == "table" then
        local copy = {}
        for i, line in ipairs(value) do copy[i] = type(line) == "string" and translate(line, "widgets") or line end
        value = copy
      end
      return original(self, font, value, ...)
    end
    Widget._l10n_zh_cn_multiline = true
    patched = true
  end
  local function patch_label_method(class, key)
    if type(class) ~= "table" or type(class.set_label) ~= "function" or rawget(class, key) then return false end
    local original = class.set_label
    class.set_label = function(self, value, ...)
      if native_ui_call(4) and type(value) == "string" and not policy.is_font_preview(value) then
        value = translate(value, "widgets")
      end
      return original(self, value, ...)
    end
    class[key] = true
    return true
  end
  for _, spec in ipairs {
    {"libraries.widget.label", "_l10n_zh_cn_label"},
    {"libraries.widget.button", "_l10n_zh_cn_button"},
    {"libraries.widget.checkbox", "_l10n_zh_cn_checkbox"},
    {"libraries.widget.toggle", "_l10n_zh_cn_toggle"},
    {"libraries.widget.selectbox", "_l10n_zh_cn_selectbox"},
  } do
    local ok_class, class = pcall(require, spec[1])
    if ok_class then patch_label_method(class, spec[2]) end
  end
  local ok_list, ListBox = pcall(require, "libraries.widget.listbox")
  if ok_list and type(ListBox) == "table" and type(ListBox.add_column) == "function" and not ListBox._l10n_zh_cn_columns then
    local original = ListBox.add_column
    ListBox.add_column = function(self, name, ...)
      return original(self, native_ui_call(4) and type(name) == "string" and translate(name, "widgets") or name, ...)
    end
    ListBox._l10n_zh_cn_columns = true
    patched = true
  end
  local ok_select, SelectBox = pcall(require, "libraries.widget.selectbox")
  if ok_select and type(SelectBox) == "table" and type(SelectBox.add_option) == "function"
      and not SelectBox._l10n_zh_cn_options then
    local original = SelectBox.add_option
    SelectBox.add_option = function(self, text, data, ...)
      -- Keep `data` untouched: settings callbacks use the original English
      -- value (for example "grayscale" or "docview").  Only the visible row
      -- label is translated.
      if native_ui_call(4) and type(text) == "string" then text = translate(text, "widgets") end
      return original(self, text, data, ...)
    end
    SelectBox._l10n_zh_cn_options = true
    patched = true
  end
  local ok_text, TextBox = pcall(require, "libraries.widget.textbox")
  if ok_text and type(TextBox) == "table" and type(TextBox.new) == "function" and not TextBox._l10n_zh_cn_placeholder then
    local original = TextBox.new
    TextBox.new = function(self, parent, text, placeholder, ...)
      if native_ui_call(4) and type(placeholder) == "string" then placeholder = translate(placeholder, "widgets") end
      return original(self, parent, text, placeholder, ...)
    end
    TextBox._l10n_zh_cn_placeholder = true
    patched = true
  end
  local ok_fold, FoldingBook = pcall(require, "libraries.widget.foldingbook")
  if ok_fold and type(FoldingBook) == "table" and type(FoldingBook.add_pane) == "function" and not FoldingBook._l10n_zh_cn_panes then
    local original = FoldingBook.add_pane
    FoldingBook.add_pane = function(self, name, label, ...)
      local value = native_ui_call(4) and type(label) == "string" and translate_heading(label) or label
      return original(self, name, value, ...)
    end
    FoldingBook._l10n_zh_cn_panes = true
    patched = true
  end
  local ok_note, NoteBook = pcall(require, "libraries.widget.notebook")
  if ok_note and type(NoteBook) == "table" and type(NoteBook.add_pane) == "function" and not NoteBook._l10n_zh_cn_panes then
    local original = NoteBook.add_pane
    NoteBook.add_pane = function(self, name, label, ...)
      local value = native_ui_call(4) and type(label) == "string" and translate_heading(label) or label
      return original(self, name, value, ...)
    end
    NoteBook._l10n_zh_cn_panes = true
    patched = true
  end
  return patched
end

local function patch_settings()
  -- settings.lua is a bundled optional plugin; never force-load it here.
  local settings = package.loaded["plugins.settings"]
  if type(settings) ~= "table" then return false end
  -- Section names are used as table keys and notebook pane labels. Rename
  -- the already-registered plugin sections so this plugin's own page and
  -- native plugin pages do not retain their English heading.
  local function translate_plugin_sections()
    local sections = settings.plugin_sections or {}
    local plugins = settings.plugins or {}
    for index, section in ipairs(sections) do
      local entries = plugins[section]
      local allowed = false
      if type(entries) == "table" then
        for plugin_name in pairs(entries) do
          if plugin_name == "l10n_zh_cn" or native_plugins[plugin_name] then
            allowed = true
            break
          end
        end
      end
      if allowed then
        local translated = translate_heading(section)
        if translated ~= section and plugins[translated] == nil and plugins[section] ~= nil then
          plugins[translated] = plugins[section]
          plugins[section] = nil
          sections[index] = translated
        end
      end
    end
  end
  translate_plugin_sections()

  local function translate_options(groups)
    for _, sections in pairs(groups or {}) do
      for plugin_name, options in pairs(sections or {}) do
        -- In settings.core the key is a numeric option index. In
        -- settings.plugins it is the plugin id; only bundled plugins and
        -- this localization plugin are in scope.
        local allowed = type(plugin_name) ~= "string"
          or native_plugins[plugin_name] == true
          or plugin_name == "l10n_zh_cn"
        local category = plugin_name == "l10n_zh_cn" and "localization" or "settings"
        if allowed and type(options) == "table" and options.label then
          options.label = translate(options.label, category)
          options.description = translate(options.description, category)
        elseif allowed and type(options) == "table" then
          for _, option in ipairs(options) do
            if type(option) == "table" then
              option.label = translate(option.label, category)
              option.description = translate(option.description, category)
            end
          end
        end
      end
    end
  end
  translate_options(settings.core)
  translate_options(settings.plugins)
  if type(settings.add) == "function" and not settings._l10n_zh_cn_add then
    local original = settings.add
    settings.add = function(section, options, plugin_name, overwrite, ...)
      local allowed = plugin_name == nil or plugin_name == "l10n_zh_cn" or native_plugins[plugin_name] == true
      if allowed then
        local category = plugin_name == "l10n_zh_cn" and "localization" or "settings"
        for _, option in ipairs(options or {}) do
          if type(option) == "table" then
            option.label = translate(option.label, category)
            option.description = translate(option.description, category)
          end
        end
      end
      return original(allowed and translate_heading(section) or section, options, plugin_name, overwrite, ...)
    end
    settings._l10n_zh_cn_add = true
  end
  -- Native settings controls are translated at construction and in settings.add.
  -- Do not recursively rewrite the completed tree: it can contain controls
  -- contributed by third-party plugins outside this release's scope.
  return true
end

function hooks.install()
  -- The module is loaded once by Lite XL, so these patches are intentionally
  -- installed once during plugin initialization.
  if hooks._installed then return end
  hooks._installed = true
  local function safe_patch(name, fn)
    local ok, err = pcall(fn)
    if not ok then
      local core = package.loaded.core
      if core and core.log_quiet then
        core.log_quiet("l10n_zh_cn: %s hook failed: %s", name, tostring(err))
      end
    end
  end
  safe_patch("command", patch_command)
  safe_patch("commandview", patch_command_view)
  safe_patch("contextmenu", patch_context_menu)
  safe_patch("nagview", patch_nag_view)
  safe_patch("statusview", patch_status_view)
  safe_patch("emptyview", patch_empty_view)
  safe_patch("widgets", patch_widgets)
  -- Existing settings/widgets are handled by their source-specific registries
  -- and constructors below. Do not recursively walk arbitrary returned plugin
  -- tables: they also contain contributor names, URLs and runtime data.
  -- The bundled settings plugin may be loaded after this plugin depending on
  -- the loader's priority scan.  Defer one tick so its option tables and UI
  -- exist before we translate them; the immediate pass covers runtimes
  -- without a scheduler.
  local core = package.loaded.core
  if core and type(core.add_thread) == "function" then
    local ok, err = pcall(core.add_thread, function()
      -- Settings and plugin widgets can be created at different points in
      -- core.run().  Retry for a short startup window so descriptions added
      -- after the first tick are still translated.  The pass is cheap and
      -- only touches known UI fields.
      for _ = 1, 30 do
        safe_patch("settings", patch_settings)
        safe_patch("widgets", patch_widgets)
        core.redraw = true
        if coroutine and coroutine.running and coroutine.running() and coroutine.yield then
          coroutine.yield()
        end
      end
    end)
    if not ok and core.log_quiet then
      core.log_quiet("l10n_zh_cn: deferred hook failed: %s", tostring(err))
    end
  else
    safe_patch("settings", patch_settings)
  end
end

return hooks

