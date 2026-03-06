# VS Code Frosted Glass (Windows)

[English](README.md) | [简体中文](README.zh-CN.md)

A stable, scriptable setup for:
- Editor/body transparency (acrylic)
- Transparent sidebars/panels/webview markdown preview
- Opaque sticky scroll area (top fold area in editor)
- Opaque title bar with transparent window control buttons
- Window resize remains normal

## Important
- Best with dark themes (light themes are not tuned).
- Recommended theme: `One Dark Pro` (optional, not forced by script)
- The script does not force a specific VS Code color theme.

## Demo
![demo-1](images/effect-demo-1.png)
![demo-2](images/effect-demo-2.png)
![demo-3](images/effect-demo-3.png)
## Environment
- OS: Windows
- VS Code install path: `D:\Microsoft VS Code`
- Theme used in demo: `One Dark Pro`
- Auto detect color scheme in demo: `false`

## One-Click Apply
Run in **Administrator PowerShell**:

```powershell
& ".\scripts\reapply-vscode-transparency.ps1"
```

Optional:

```powershell
# Change opacity
& ".\scripts\reapply-vscode-transparency.ps1" -Opacity 0.35

# Apply without restart
& ".\scripts\reapply-vscode-transparency.ps1" -NoRestart

# Custom VS Code install path
& ".\scripts\reapply-vscode-transparency.ps1" -VsCodeRoot "D:\Microsoft VS Code"
```

## What the script patches
- `%APPDATA%\Code\User\settings.json`
- `<VSCodeHashDir>\resources\app\out\main.js`
- `<VSCodeHashDir>\resources\app\extensions\markdown-language-features\media\markdown.css`
- `<VSCodeHashDir>\resources\app\extensions\github\markdown.css`

The script auto-creates backups before patching.

## Common Issues
### 1) Resize disabled
Set:
- `vscode_vibrancy.disableFramelessWindow = true`

### 2) Dark/black overlay blocks
Remove heavy `workbench.colorCustomizations` overlays or use transparent values.

### 3) Markdown preview not transparent
Patch built-in markdown css (already included in the script).

### 4) Effect disappears after VS Code update
Re-run the script (updates overwrite patched install files).

## Safety Notes
- Always run with Admin for install-path patching.
- Script creates `.bak_*` backups.
- To revert, restore backups or reinstall/update VS Code.



