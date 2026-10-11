# Codex CLI最高性价比安装skill

一个面向 Windows 的 Codex Skill：在用户指定的位置安装本地 Codex CLI，并接入 DeepSeek API。它不改动 Codex 桌面端配置，API Key 使用 Windows DPAPI 加密保存在本机。

安装结果包含：

- 本地 npm 安装的 Codex CLI 与 DeepSeek Pro / Flash 模型目录；
- 代码编辑、终端命令、DOCX/XLSX/PPTX/PDF 生成；
- 简体中文、繁体中文、英文图片与扫描 PDF OCR；
- 公开网页搜索、读取和截图；
- PDF 视觉分析和任意长度 PDF 分批汇总；
- 网页、PDF、图片文本归档为 Markdown。

使用时让 Codex 调用 `$codex-cli-best-value-install`。Skill 会先询问安装位置，再运行 `scripts/Install-CodexDeepSeek.ps1`。完成后，目标目录根部只保留两个入口：`启动-Codex CLI.cmd` 与 `配置-DeepSeek API Key.cmd`。

## 前提

Windows 10/11、联网、Node.js/npm、Python 3.10+。缺少 Node 或 Python 时，安装脚本会尝试通过 winget 安装；若系统没有 winget，会停止并说明缺失项。DeepSeek API Key 由用户在本机交互输入。

## 排错：Tesseract OCR

- 如果安装器发现旧版 `Tesseract-OCR`，请先卸载旧版，并确认 `C:\Program Files\Tesseract-OCR` 及其卸载登记均已消失；不要反复运行安装器，否则会重复进入卸载向导。
- 部分 NSIS 安装器会忽略自定义安装目录并安装到 C 盘。安装脚本会检测该情况并将 OCR 本体复制到目标 CLI 的 `tools\tesseract`，但会保留 C 盘副本，由用户决定是否卸载。
- 安装脚本会收紧目标 `config` 目录权限，避免 Codex 后台进程因目录对其它用户可写而无法启动。
- `Test-Installation.ps1` 会检查 OCR 语言包，并运行一次本地 OCR 自检。

## 开源许可

MIT。Tesseract 与语言数据分别遵循其上游许可；安装脚本从 Tesseract 文档推荐的 Windows 安装源和官方 `tessdata_fast` 下载中文语言数据。
