#!/usr/bin/env pwsh

# Script per aggiornare il build number basato sul commit count
# Uso: .\scripts\update_build_number.ps1

$pubspecPath = "pubspec.yaml"
$errorActionPreference = "Stop"

try {
    # Leggi il numero totale di commit
    $commitCount = [int](git rev-list --all --count)
    if (-not $commitCount) {
        $commitCount = 1
    }

    # Leggi il commit hash corto
    $commitHash = git rev-parse --short HEAD
    if (-not $commitHash) {
        Write-Host "Error: Unable to get commit hash"
        exit 1
    }

    # Leggi il pubspec.yaml
    $content = Get-Content $pubspecPath -Raw

    # Estrai la versione attuale (format: "version: X.Y.Z+N")
    if ($content -match 'version:\s*([\d.]+)\+(\d+)') {
        $appVersion = $matches[1]
        $oldBuildNumber = [int]$matches[2]
    } else {
        Write-Host "Error: Unable to parse version from pubspec.yaml"
        exit 1
    }

    # Aggiorna il build number con il commit count
    $newBuildNumber = $commitCount
    $newContent = $content -replace 'version:\s*[\d.]+\+\d+', "version: $appVersion+$newBuildNumber"

    # Scrivi il file aggiornato
    Set-Content $pubspecPath $newContent -NoNewline

    Write-Host "✓ Build number aggiornato"
    Write-Host "  Version: $appVersion+$newBuildNumber"
    Write-Host "  Commit: $commitHash (Total commits: $commitCount)"
    Write-Host ""
    
} catch {
    Write-Host "Error: $_"
    exit 1
}
