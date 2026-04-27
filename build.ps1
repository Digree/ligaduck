#!/usr/bin/env pwsh

# Script di build per Flutter con versionamento automatico
# Uso: .\build.ps1 [--release] [--debug] [--apk] [--aab]

param(
    [switch]$release = $false,
    [switch]$debug = $false,
    [switch]$apk = $false,
    [switch]$aab = $false
)

# Valori di default
if (-not $release -and -not $debug) {
    $release = $true
}
if (-not $apk -and -not $aab) {
    $apk = $true
}

# Versionamento manuale - modifica version in pubspec.yaml
# Per aggiornamenti: cambia manualmente la versione in pubspec.yaml

# Determina le flag di build
$buildFlags = @()
if ($release) {
    $buildFlags += "--release"
}
if ($debug) {
    $buildFlags += "--debug"
}

# Esegui il build appropriato
if ($apk) {
    Write-Host "`n🔨 Building APK..."
    & flutter build apk $buildFlags
}

if ($aab) {
    Write-Host "`n🔨 Building AAB..."
    & flutter build appbundle $buildFlags
}

Write-Host "`n✓ Build completato!"
