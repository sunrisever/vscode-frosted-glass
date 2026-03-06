param(
  [string]$VsCodeRoot = 'D:\Microsoft VS Code',
  [double]$Opacity = 0.35,
  [switch]$NoRestart
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Require-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $pr = [Security.Principal.WindowsPrincipal]::new($id)
  if (-not $pr.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw 'Please run this script in Administrator PowerShell.'
  }
}

function Get-BuildDir {
  param([string]$Root)
  if (-not (Test-Path $Root)) { throw "VS Code root not found: $Root" }
  $d = Get-ChildItem $Root -Directory |
    Where-Object { $_.Name -match '^[0-9a-f]{10}$' } |
    Where-Object { Test-Path (Join-Path $_.FullName 'resources\app\out\main.js') } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if (-not $d) { throw "Cannot find hashed build dir under $Root" }
  $d.FullName
}

function Backup-File {
  param([string]$Path)
  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $bak = "$Path.bak_reapply_$stamp"
  Copy-Item $Path $bak -Force
  $bak
}

function To-Hashtable {
  param($Obj)
  $h = @{}
  if ($null -eq $Obj) { return $h }
  foreach ($p in $Obj.PSObject.Properties) { $h[$p.Name] = $p.Value }
  $h
}

function Replace-Or-Append {
  param([string]$Text, [string]$Start, [string]$End, [string]$Block)
  if ($Text.Contains($Start) -and $Text.Contains($End)) {
    $pat = "(?s)$([regex]::Escape($Start)).*?$([regex]::Escape($End))"
    return [regex]::Replace($Text, $pat, $Block)
  }
  ($Text.TrimEnd() + "`r`n`r`n" + $Block)
}

function Get-ThemeCss {
  $lines = @(
'html,',
'body,',
'.monaco-workbench,',
'.monaco-workbench .part,',
'.monaco-workbench .part > .content,',
'.monaco-workbench .part.editor,',
'.monaco-workbench .part.editor > .content,',
'.monaco-workbench .editor > .content,',
'.monaco-workbench .editor > .content > .one-editor-silo,',
'.monaco-workbench .editor > .content > .one-editor-silo.editor-one,',
'.monaco-workbench .editor > .content > .one-editor-silo > .container,',
'.monaco-workbench .editor > .content > .one-editor-silo > .container > .title,',
'.monaco-editor,',
'.monaco-editor-background,',
'.monaco-editor .margin,',
'.monaco-editor .overflow-guard,',
'.editor-instance,',
'.editor-container,',
'.terminal-outer-container,',
'.xterm,',
'.xterm-viewport,',
'.xterm-screen,',
'.xterm-rows,',
'.notebookOverlay.notebook-editor,',
'.cell-statusbar-container,',
'.margin-view-overlays {',
'  background: transparent !important;',
'  background-color: transparent !important;',
'}',
'',
'.monaco-workbench .part.sidebar,',
'.monaco-workbench .part.sidebar > .content,',
'.monaco-workbench .part.sidebar .composite,',
'.monaco-workbench .part.sidebar .composite > .content,',
'.monaco-workbench .part.sidebar .pane-body,',
'.monaco-workbench .part.sidebar .pane-header,',
'.monaco-workbench .part.sidebar .monaco-list,',
'.monaco-workbench .part.sidebar .monaco-list-rows,',
'.monaco-workbench .part.sidebar .monaco-scrollable-element,',
'.monaco-workbench .part.sidebar .split-view-view {',
'  background: transparent !important;',
'  background-color: transparent !important;',
'}',
'',
'.minimap,',
'.monaco-editor .minimap,',
'.editor-scrollable .minimap,',
'.editor-scrollable > .decorationsOverviewRuler,',
'.monaco-editor .decorationsOverviewRuler,',
'.decorationsOverviewRuler,',
'.minimap-slider {',
'  background: transparent !important;',
'  background-color: transparent !important;',
'}',
'',
':root {',
'  --vscode-editor-background: transparent !important;',
'  --vscode-sideBar-background: transparent !important;',
'  --vscode-activityBar-background: transparent !important;',
'  --vscode-panel-background: transparent !important;',
'  --vscode-statusBar-background: transparent !important;',
'  --vscode-terminal-background: transparent !important;',
'  --vscode-editorGroupHeader-tabsBackground: transparent !important;',
'  --vscode-tab-activeBackground: transparent !important;',
'  --vscode-tab-inactiveBackground: transparent !important;',
'  --vscode-minimap-background: transparent !important;',
'  --vscode-editorOverviewRuler-background: transparent !important;',
'  --vscode-breadcrumb-background: transparent !important;',
'}',
'',
'.editor-group-container > .tabs,',
'.editor-group-container > .tabs .tab,',
'.editor-group-container > .tabs .tab.active,',
'.editor-group-container > .tabs .monaco-breadcrumbs {',
'  background-color: transparent !important;',
'}',
'',
'.editor-group-container > .tabs .tab {',
'  border: none !important;',
'}',
'',
'.scroll-decoration {',
'  box-shadow: none !important;',
'}',
'',
'.monaco-workbench.fullscreen {',
'  background-color: transparent !important;',
'}',
'',
'/* codex_controls_statusbar_transparent:start */',
'.monaco-workbench .part.titlebar .window-controls-container,',
'.monaco-workbench .part.titlebar .window-controls,',
'.monaco-workbench .part.titlebar .window-control,',
'.monaco-workbench .part.titlebar .window-controls-container > *,',
'.monaco-workbench .part.titlebar [class*="window-control"],',
'.monaco-workbench .part.titlebar [class*="window-icon"],',
'.monaco-workbench .part.titlebar [class*="window-minimize"],',
'.monaco-workbench .part.titlebar [class*="window-maximize"],',
'.monaco-workbench .part.titlebar [class*="window-close"] {',
'  background: transparent !important;',
'  background-color: transparent !important;',
'}',
'',
'.monaco-workbench .part.titlebar .window-control:hover,',
'.monaco-workbench .part.titlebar .window-controls-container > *:hover,',
'.monaco-workbench .part.titlebar [class*="window-control"]:hover {',
'  background: rgba(255, 255, 255, 0.14) !important;',
'}',
'',
'.monaco-workbench .part.statusbar .statusbar-item,',
'.monaco-workbench .part.statusbar .statusbar-item-label,',
'.monaco-workbench .part.statusbar .statusbar-item .codicon,',
'.monaco-workbench .part.statusbar .statusbar-item.has-beak {',
'  background: transparent !important;',
'  background-color: transparent !important;',
'}',
'/* codex_controls_statusbar_transparent:end */',
'',
'/* codex_webview_preview_transparent:start */',
'.monaco-workbench .webview,',
'.monaco-workbench .webview.ready,',
'.monaco-workbench .webview > .webview-element,',
'.monaco-workbench .webview .webview-element,',
'.monaco-workbench .webview-container,',
'.monaco-workbench .webview-overlay,',
'.monaco-workbench webview,',
'.monaco-workbench iframe[src^="vscode-webview://"],',
'.monaco-workbench [class*="webview"] {',
'  background: transparent !important;',
'  background-color: transparent !important;',
'}',
'/* codex_webview_preview_transparent:end */',
'',
'/* codex_sticky_non_transparent:start */',
'.monaco-editor .sticky-widget,',
'.monaco-editor .sticky-widget *,',
'.monaco-editor .sticky-scroll-container,',
'.monaco-editor .sticky-widget-line-numbers,',
'.monaco-editor .sticky-widget-lines {',
'  background: #21252B !important;',
'  background-color: #21252B !important;',
'}',
'',
':root {',
'  --vscode-editorStickyScroll-background: #21252B !important;',
'  --vscode-editorStickyScrollHover-background: #2C313A !important;',
'}',
'/* codex_sticky_non_transparent:end */'
  )
  ($lines -join "`n")
}

function Get-MdBlock {
  $lines = @(
'/* codex_md_preview_transparent:start */',
'html,',
'body,',
'body.vscode-body,',
'main,',
'.markdown-body,',
'#preview,',
'#preview-content {',
'  background: transparent !important;',
'  background-color: transparent !important;',
'}',
'/* codex_md_preview_transparent:end */'
  )
  ($lines -join "`n")
}

function Patch-Settings {
  param([string]$Path, [double]$TargetOpacity)

  if (-not (Test-Path $Path)) { Set-Content -Path $Path -Value '{}' -Encoding UTF8 }
  $j = Get-Content -Path $Path -Raw | ConvertFrom-Json
  if ($null -eq $j) { $j = [pscustomobject]@{} }

  $j | Add-Member -NotePropertyName 'window.titleBarStyle' -NotePropertyValue 'custom' -Force
  $j | Add-Member -NotePropertyName 'vscode_vibrancy.type' -NotePropertyValue 'acrylic' -Force
  $j | Add-Member -NotePropertyName 'vscode_vibrancy.theme' -NotePropertyValue 'Default Dark' -Force
  $j | Add-Member -NotePropertyName 'vscode_vibrancy.opacity' -NotePropertyValue $TargetOpacity -Force
  $j | Add-Member -NotePropertyName 'vscode_vibrancy.disableFramelessWindow' -NotePropertyValue $true -Force
  $j | Add-Member -NotePropertyName 'vscode_vibrancy.forceFramelessWindow' -NotePropertyValue $false -Force
  $j | Add-Member -NotePropertyName 'vscode_vibrancy.disableThemeFixes' -NotePropertyValue $true -Force
  $j | Add-Member -NotePropertyName 'vscode_vibrancy.preventFlash' -NotePropertyValue $true -Force

  $cc = To-Hashtable $j.'workbench.colorCustomizations'
  $cc['editor.background'] = '#00000000'; $cc['editorGutter.background'] = '#00000000'; $cc['sideBar.background'] = '#00000000'
  $cc['activityBar.background'] = '#00000000'; $cc['panel.background'] = '#00000000'; $cc['terminal.background'] = '#00000000'
  $cc['editorGroupHeader.tabsBackground'] = '#00000000'; $cc['tab.activeBackground'] = '#00000000'; $cc['tab.inactiveBackground'] = '#00000000'
  $cc['tab.unfocusedActiveBackground'] = '#00000000'; $cc['titleBar.activeBackground'] = '#1E1E1E'; $cc['titleBar.inactiveBackground'] = '#2A2A2A'
  $cc['titleBar.activeForeground'] = '#D4D4D4'; $cc['titleBar.inactiveForeground'] = '#A9A9A9'; $cc['statusBar.background'] = '#00000000'
  $cc['statusBar.noFolderBackground'] = '#00000000'; $cc['minimap.background'] = '#00000000'; $cc['editorOverviewRuler.background'] = '#00000000'
  $cc['editorStickyScroll.background'] = '#21252B'; $cc['editorStickyScrollHover.background'] = '#2C313A'; $cc['breadcrumb.background'] = '#00000000'
  $cc['webview.background'] = '#00000000'; $cc['editorPane.background'] = '#00000000'; $cc['editorGroup.emptyBackground'] = '#00000000'
  $cc['scrollbarSlider.background'] = '#FFFFFF22'; $cc['scrollbarSlider.hoverBackground'] = '#FFFFFF33'; $cc['scrollbarSlider.activeBackground'] = '#FFFFFF44'
  $cc['list.hoverBackground'] = '#FFFFFF14'; $cc['list.activeSelectionBackground'] = '#FFFFFF1A'; $cc['list.inactiveSelectionBackground'] = '#FFFFFF12'
  $cc['statusBarItem.prominentBackground'] = '#00000000'; $cc['statusBarItem.prominentHoverBackground'] = '#FFFFFF22'; $cc['statusBarItem.compactHoverBackground'] = '#FFFFFF22'
  $cc['statusBarItem.remoteBackground'] = '#00000000'; $cc['statusBarItem.remoteHoverBackground'] = '#FFFFFF22'
  $cc['statusBarItem.errorBackground'] = '#00000000'; $cc['statusBarItem.warningBackground'] = '#00000000'; $cc['statusBarItem.offlineBackground'] = '#00000000'

  $j | Add-Member -NotePropertyName 'workbench.colorCustomizations' -NotePropertyValue $cc -Force
  if ($j.PSObject.Properties.Name -contains 'markdown.styles') { $j.PSObject.Properties.Remove('markdown.styles') }

  $out = $j | ConvertTo-Json -Depth 100
  Set-Content -Path $Path -Value $out -Encoding UTF8
}

function Patch-MainJs {
  param([string]$Path, [double]$TargetOpacity)

  $raw = Get-Content -Path $Path -Raw
  $pat = '(global\.vscode_vibrancy_plugin = )(\{.+?\})(;\s*try\{\s*import\("file:[^"]+vscode-vibrancy-runtime-v6/index\.cjs"\);\s*\}\s*catch \(err\) \{console\.error\(err\)\})'
  $re = [regex]::new($pat, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  $m = $re.Match($raw)
  if (-not $m.Success) { throw 'Cannot find vibrancy block in main.js.' }

  $obj = $m.Groups[2].Value | ConvertFrom-Json
  if ($null -eq $obj.config) { $obj | Add-Member -NotePropertyName 'config' -NotePropertyValue (@{}) }

  $obj.config.type = 'acrylic'
  $obj.config.opacity = $TargetOpacity
  $obj.config.theme = 'Default Dark'
  $obj.config.enableAutoTheme = $false
  $obj.config.preventFlash = $true
  $obj.config.disableThemeFixes = $true
  $obj.config.disableFramelessWindow = $true
  $obj.config.forceFramelessWindow = $false
  $obj.themeCSS = Get-ThemeCss

  $newJson = $obj | ConvertTo-Json -Depth 100 -Compress
  $newBlock = $m.Groups[1].Value + $newJson + $m.Groups[3].Value
  $newRaw = $raw.Substring(0, $m.Index) + $newBlock + $raw.Substring($m.Index + $m.Length)
  Set-Content -Path $Path -Value $newRaw -Encoding UTF8
}

function Patch-MarkdownCss {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return }
  $raw = Get-Content -Path $Path -Raw
  $block = Get-MdBlock
  $newRaw = Replace-Or-Append -Text $raw -Start '/* codex_md_preview_transparent:start */' -End '/* codex_md_preview_transparent:end */' -Block $block
  Set-Content -Path $Path -Value $newRaw -Encoding UTF8
}

function Restart-Code {
  param([string]$CodeExe)
  Get-Process Code -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep -Milliseconds 1200
  Start-Process -FilePath $CodeExe
}

try {
  Require-Admin

  $buildDir = Get-BuildDir -Root $VsCodeRoot
  $mainJs = Join-Path $buildDir 'resources\app\out\main.js'
  $md1 = Join-Path $buildDir 'resources\app\extensions\markdown-language-features\media\markdown.css'
  $md2 = Join-Path $buildDir 'resources\app\extensions\github\markdown.css'
  $settings = Join-Path $env:APPDATA 'Code\User\settings.json'
  $codeExe = Join-Path $VsCodeRoot 'Code.exe'

  $b1 = Backup-File -Path $settings
  $b2 = Backup-File -Path $mainJs
  if (Test-Path $md1) { [void](Backup-File -Path $md1) }
  if (Test-Path $md2) { [void](Backup-File -Path $md2) }

  Patch-Settings -Path $settings -TargetOpacity $Opacity
  Patch-MainJs -Path $mainJs -TargetOpacity $Opacity
  Patch-MarkdownCss -Path $md1
  Patch-MarkdownCss -Path $md2

  if (-not $NoRestart) { Restart-Code -CodeExe $codeExe }

  Write-Host "Done. BuildDir: $buildDir"
  Write-Host "Settings backup: $b1"
  Write-Host "Main.js backup: $b2"
  if ($NoRestart) { Write-Host 'No restart requested.' } else { Write-Host 'VS Code restarted.' }
}
catch {
  Write-Error $_
  exit 1
}



