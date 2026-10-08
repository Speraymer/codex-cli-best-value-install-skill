---
name: codex-cli-best-value-install
description: Install a local Windows Codex CLI setup using DeepSeek, including encrypted API-key onboarding, document creation, OCR, public-web reading, PDF visual analysis, and Markdown archiving. Use when the user asks to deploy this complete low-cost CLI workflow.
---

Use this skill only for a Windows local installation requested by the user.

1. Before running anything, ask exactly where to install it, for example `G:\Codex`. Do not assume a drive or overwrite a non-empty directory.
2. From this skill folder, run `scripts\Install-CodexDeepSeek.ps1 -InstallPath <user path>`. It installs Codex CLI locally, configures the DeepSeek provider without storing a key in plaintext, and adds the document/OCR/PDF/web/archive tools.
3. Let the installer finish its API-key onboarding. The user enters their own key interactively; never request it in chat or write it to a configuration file.
4. Run `scripts\Test-Installation.ps1 -InstallPath <user path>`. Report the two root-level entry points and any prerequisite failure clearly.

The installer creates exactly two CMD files at the target root: `启动-Codex CLI.cmd` for normal use and `配置-DeepSeek API Key.cmd` for first-time setup or key replacement. Other one-click helpers are placed in `quick-tools`.

Do not modify the Codex desktop app configuration. Do not delete an existing installation; ask the user to choose a new empty directory or handle any migration explicitly.
