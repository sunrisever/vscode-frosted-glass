# VS Code Frosted Glass — AI Coding Assistant Instructions

> This file is for AI coding assistants (Claude Code, Codex, Cursor, etc.). It is optional and can be safely deleted.

## Project Overview

Scriptable setup for VS Code frosted glass transparency effect using Vibrancy Continued extension. Tuned for One Dark Pro theme on Windows.

## Key Command

Run in **Administrator PowerShell**:

```powershell
& ".\scripts\reapply-vscode-transparency.ps1"
# Options: -Opacity 0.35 | -NoRestart | -VsCodeRoot "D:\Microsoft VS Code"
```

## Architecture

- `scripts/reapply-vscode-transparency.ps1` — Main script. Patches VS Code settings.json, main.js, and markdown CSS files. Auto-creates `.bak_*` backups before patching.

## Important Notes

- Must run as Administrator (patches VS Code install files)
- Re-run after every VS Code update (updates overwrite patched files)
- Requires `Vibrancy Continued` extension (`illixion.vscode-vibrancy-continued`)
- Script creates backups; revert by restoring `.bak_*` files or reinstalling VS Code
- Windows only
