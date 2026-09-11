# Lite XL 简体中文本地化 / Simplified Chinese Localization

[中文说明](#中文) · [English](#english)

## 中文

这是面向 Lite XL 2.1.x 的简体中文插件，主要验收版本为 Lite XL 2.1.8，使用 `mod_version: 3`。插件只翻译 Lite XL 核心和发行版自带插件，不修改核心源码，也不处理第三方插件。

### 安装

```sh
lpm add https://github.com/kevynf/lite-xl-l10n-zh-cn
lpm --mod-version=3 install l10n_zh_cn --assume-yes
```

安装后重启 Lite XL。lpm 可从 [Lite XL Plugin Manager](https://github.com/lite-xl/lite-xl-plugin-manager) 获取。

### 配置

```lua
config.plugins.l10n_zh_cn = {
  enabled = true,
  locale = "zh-CN",
  use_bundled_font = true,
  font_path = nil,
  debug = false,
}
```

- `enabled`：启用或关闭插件；修改后重启 Lite XL。
- `locale`：`"zh-CN"` 或 `"en"`；切换语言后建议重启以刷新全部界面。
- `use_bundled_font`：使用插件内置的 Noto Sans CJK SC 字体。
- `font_path`：可选字体路径；设置后优先使用该字体。
- `debug`：记录词典中未登记的原生界面文本，默认关闭。

插件自带 Noto Sans CJK SC 常规字体，不需要另行下载字体。命令 ID、快捷键、路径、文件名、搜索内容、实际数据和回调字段保持原样。

### 翻译范围

插件处理命令面板、设置页、右键菜单、消息框、确认对话框、状态栏、欢迎页和原生控件。动态文本只处理已知模板，变量内容不会被改写。未登记文本保留英文。

词典按原生来源保存在 [`plugins/l10n_zh_cn/catalog/`](plugins/l10n_zh_cn/catalog/)，由 [`catalog.lua`](plugins/l10n_zh_cn/catalog.lua) 加载。运行时策略和动态转换分别位于 [`policy.lua`](plugins/l10n_zh_cn/policy.lua) 与 [`transforms.lua`](plugins/l10n_zh_cn/transforms.lua)。

### 开发检查

字段提取工具按原生文件、UI 插入 API 和字段结构提取文本，不搜索任意英文字符串：

```sh
python tools/extract_lite_xl_fields.py "C:\Program Files\Lite XL" \
  --catalog plugins/l10n_zh_cn/catalog \
  --fail-on-missing
```

完整检查：

```sh
python tests/check_project.py
python tests/test_lua_source.py
python tests/test_field_extraction.py
lpm exec tests/check_catalog.lua
lpm exec tests/test_hooks.lua
```

Lite XL 更新后重新运行字段提取，并按 `catalog_file`、`source_module` 和 `field_path` 登记新增静态字段。自动检查不能替代 Lite XL 中的实际界面验证。

### 许可证

插件采用 [MIT License](LICENSE)。内置字体采用 SIL Open Font License 1.1，许可证文件见 [`licenses/OFL-1.1.txt`](licenses/OFL-1.1.txt) 和 [`plugins/l10n_zh_cn/fonts/OFL-1.1.txt`](plugins/l10n_zh_cn/fonts/OFL-1.1.txt)。

## English

This plugin provides Simplified Chinese localization for Lite XL 2.1.x, with Lite XL 2.1.8 and `mod_version: 3` as the primary target. It localizes Lite XL core UI and bundled plugins without modifying Lite XL itself.

### Install

```sh
lpm add https://github.com/kevynf/lite-xl-l10n-zh-cn
lpm --mod-version=3 install l10n_zh_cn --assume-yes
```

Restart Lite XL after installation. The package is a standalone lpm repository and has no third-party plugin dependencies.

### Configuration

```lua
config.plugins.l10n_zh_cn = {
  enabled = true,
  locale = "zh-CN",
  use_bundled_font = true,
  font_path = nil,
  debug = false,
}
```

`enabled` and `locale` are persisted by the native Settings plugin. Restart Lite XL after changing them so every native view is rebuilt. The bundled Noto Sans CJK SC font is enabled by default; set `use_bundled_font = false` or provide `font_path` to use another setup.

### Scope and extension

Only native Lite XL UI fields are translated. Commands, callback values, paths, filenames, URLs, user data and third-party plugin text stay unchanged. Static entries are grouped by source under [`plugins/l10n_zh_cn/catalog/`](plugins/l10n_zh_cn/catalog/). Add a new source catalogue there and register it in [`catalog.lua`](plugins/l10n_zh_cn/catalog.lua); use [`runtime/patterns.lua`](plugins/l10n_zh_cn/runtime/patterns.lua) only for a known dynamic message format.

Run the field extractor and checks after changing the catalogue. The extractor is source-aware and reports the UI field, source module and catalogue destination so additions remain reviewable.

### License

The plugin is released under the [MIT License](LICENSE). The bundled font is distributed under the SIL Open Font License 1.1.

[Back to 中文](#中文)
